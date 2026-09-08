#!/bin/bash

# Common helpers and package-wide variables for alby_hub.

# `app`, `domain`, `path`, `port`, `install_dir` and `data_dir` are injected
# by the install/upgrade/restore scripts from the manifest resources. For
# lifecycle *hooks* (which YunoHost runs outside those scripts) they are not
# present, so resolve them from app settings as a fallback.

app="${app:-$YNH_APP_ID}"
app="${app:-alby_hub}"

resolve_dir() {
	local key="$1" fallback="$2"
	if [ -n "$fallback" ]; then
		printf '%s' "$fallback"
	else
		ynh_app_setting_get --key="$key"
	fi
}
install_dir="$(resolve_dir "install_dir" "${install_dir:-}")"
data_dir="$(resolve_dir "data_dir" "${data_dir:-}")"

# The Alby Hub server binary. The tarball unpacks to bin/albyhub with the LDK
# shared lib at lib/libldk_node.so; the binary resolves it via an RPATH of
# $ORIGIN/../lib, so the relative layout must be preserved.
alby_bin="$install_dir/bin/albyhub"

service_name="$app"

# Alby Hub writes its own JSON log to $WORK_DIR/log/nwc.log (LOG_TO_FILE is
# enabled by default upstream). We mirror that path for `yunohost service add`
# and health-wait logging.
alby_log_path="$data_dir/log/nwc.log"

# Print Alby Hub's first-run / access URL.
ynh_alby_display_url() {
	ynh_print_info "Alby Hub is reachable at: https://$domain$path"
}

# The recovery warning surfaced on install and upgrade (see doc/DISCLAIMER.md
# for the long form). Kept in one place so the wording stays consistent.
ynh_alby_recovery_warning() {
	ynh_print_warn "Alby Hub controls Bitcoin and Lightning funds."
	ynh_print_warn "Store the recovery phrase shown during first-run setup"
	ynh_print_warn "somewhere secure OUTSIDE this server. A YunoHost backup"
	ynh_print_warn "is NOT a substitute for the wallet recovery phrase."
}

# YunoHost allocates this resource independently for each multi-instance
# install.  Keep the fallback for older instances created before the resource
# existed.
ynh_alby_p2p_port() {
	local resource
	resource="$(ynh_app_setting_get --app="$app" --key=port_p2p 2>/dev/null || true)"
	printf '%s' "${resource:-9735}"
}

# Alby Hub can run multiple LDK instances, but not multiple Hub instances
# against the one packaged CLN node: they would be separate Hub databases
# controlling the same external wallet/node.  Check only the CLN case; LDK
# instances are isolated by their per-instance data and allocated P2P port.
ynh_alby_check_backend_instance_safety() {
	local requested_backend existing existing_backend
	requested_backend="${ln_backend_type:-LDK}"
	[ "$requested_backend" = "CLN" ] || return 0

	while IFS= read -r existing; do
		[ -n "$existing" ] || continue
		[ "$existing" = "$app" ] && continue
		existing_backend="$(ynh_app_setting_get --app="$existing" --key=ln_backend_type 2>/dev/null || true)"
		if [ "$existing_backend" = "CLN" ]; then
			ynh_die "Another Alby Hub instance ($existing) already uses the packaged Core Lightning node. Multiple CLN-backed Alby Hub instances are not supported because they would share the same external wallet/node."
		fi
	done < <(yunohost app list --output-as json 2>/dev/null | jq -r '.apps[]?.id | select(startswith("alby_hub"))')
}

# Unpack the downloaded release archive into $install_dir, preserving the
# bin/ + lib/ layout, then drop the archive. Fails loudly if the layout is
# not what we expect, rather than leaving a half-installed binary.
ynh_alby_unpack_release() {
	local archive="$install_dir/albyhub.tar.bz2"
	if [ ! -f "$archive" ]; then
		ynh_die "Release archive not found at $archive"
	fi
	tar -xjf "$archive" -C "$install_dir"
	ynh_safe_rm "$archive"

	if [ ! -x "$alby_bin" ]; then
		ynh_die "Release archive did not contain $alby_bin"
	fi
	if [ ! -f "$install_dir/lib/libldk_node.so" ]; then
		ynh_die "Release archive did not contain lib/libldk_node.so"
	fi

	chown -R "$app:$app" "$install_dir"
	chmod 750 "$install_dir"
	chmod 750 "$install_dir/bin" "$install_dir/lib"
	chmod -R o-rwx "$install_dir"
}

# Reads the ln_backend_type app setting and populates the shell variables
# consumed by the __LN_BACKEND_TYPE__/__CLN_ENV_BLOCK__/__CLN_LIGHTNING_DIR_RO__
# tokens in conf/systemd.service. LDK (the default) needs no extra env and no
# extra filesystem access, so both blocks are left empty in that case.
ynh_alby_build_backend_env() {
	ln_backend_type="$(ynh_app_setting_get --app="$app" --key=ln_backend_type 2>/dev/null || echo LDK)"
	cln_env_block=""
	cln_lightning_dir_ro=""
	ldk_env_block=""

	if [ "$ln_backend_type" = "LDK" ]; then
		ldk_env_block="Environment=LDK_LISTENING_ADDRESSES=[::]:$(ynh_alby_p2p_port)"
	elif [ "$ln_backend_type" = "CLN" ]; then
		local cln_address cln_lightning_dir cln_address_hold
		cln_address="$(ynh_app_setting_get --app="$app" --key=cln_address 2>/dev/null || true)"
		cln_lightning_dir="$(ynh_app_setting_get --app="$app" --key=cln_lightning_dir 2>/dev/null || true)"
		cln_address_hold="$(ynh_app_setting_get --app="$app" --key=cln_address_hold 2>/dev/null || true)"

		[ -n "$cln_address" ] || ynh_die "ln_backend_type is CLN but cln_address is not set"
		[ -n "$cln_lightning_dir" ] || ynh_die "ln_backend_type is CLN but cln_lightning_dir is not set"

		getent group core_lightning >/dev/null || ynh_die "ln_backend_type is CLN, but no 'core_lightning' system group was found. Install core-lightning_ynh with gRPC enabled first."
		usermod -aG core_lightning "$app"

		# ynh_config_add_systemd substitutes tokens with sed. Keep this as a
		# single logical line: a literal newline in the replacement makes sed
		# parse the generated command as an unterminated substitution.
		cln_env_block="Environment=CLN_ADDRESS=$cln_address CLN_LIGHTNING_DIR=$cln_lightning_dir"
		if [ -n "$cln_address_hold" ]; then
			cln_env_block="$cln_env_block CLN_ADDRESS_HOLD=$cln_address_hold"
		fi
		cln_lightning_dir_ro="$cln_lightning_dir"
	fi
}

# Records which backend the wallet was actually initialized with, once
# install has confirmed the service came up healthy. This is the value
# ynh_alby_check_backend_lock compares future ln_backend_type settings
# against - it is deliberately separate from ln_backend_type itself so a
# stray `yunohost app setting` edit can be detected instead of silently
# taking effect on the next upgrade.
ynh_alby_lock_backend() {
	ynh_app_setting_set --app="$app" --key=ln_backend_type_locked --value="$ln_backend_type"
}

# Refuses to proceed if ln_backend_type has been changed since the wallet
# was actually set up (e.g. via a manual `yunohost app setting` edit rather
# than a fresh install). Upstream Alby Hub fixes its backend at first wallet
# setup - rebuilding the systemd unit for a different backend would leave
# the env vars and the wallet's actual internal state pointing at different
# nodes. No-ops for instances that predate this check (no locked value yet).
ynh_alby_check_backend_lock() {
	local locked current
	locked="$(ynh_app_setting_get --app="$app" --key=ln_backend_type_locked 2>/dev/null || true)"
	current="$(ynh_app_setting_get --app="$app" --key=ln_backend_type 2>/dev/null || echo LDK)"
	if [ -n "$locked" ] && [ "$locked" != "$current" ]; then
		ynh_die "ln_backend_type is set to '$current' but this wallet was set up with '$locked' and Alby Hub cannot switch backends in place. Restore ln_backend_type to '$locked' (yunohost app setting $app ln_backend_type -v $locked), or see doc/ADMIN.md for the purge-and-reinstall path to actually change backends."
	fi
}
