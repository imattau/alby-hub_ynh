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

	if [ "$ln_backend_type" = "CLN" ]; then
		local cln_address cln_lightning_dir cln_address_hold
		cln_address="$(ynh_app_setting_get --app="$app" --key=cln_address 2>/dev/null || true)"
		cln_lightning_dir="$(ynh_app_setting_get --app="$app" --key=cln_lightning_dir 2>/dev/null || true)"
		cln_address_hold="$(ynh_app_setting_get --app="$app" --key=cln_address_hold 2>/dev/null || true)"

		[ -n "$cln_address" ] || ynh_die "ln_backend_type is CLN but cln_address is not set"
		[ -n "$cln_lightning_dir" ] || ynh_die "ln_backend_type is CLN but cln_lightning_dir is not set"

		getent group core_lightning >/dev/null || ynh_die "ln_backend_type is CLN, but no 'core_lightning' system group was found. Install core-lightning_ynh with gRPC enabled first."
		usermod -aG core_lightning "$app"

		cln_env_block="Environment=CLN_ADDRESS=$cln_address
Environment=CLN_LIGHTNING_DIR=$cln_lightning_dir"
		if [ -n "$cln_address_hold" ]; then
			cln_env_block="$cln_env_block
Environment=CLN_ADDRESS_HOLD=$cln_address_hold"
		fi
		cln_lightning_dir_ro="$cln_lightning_dir"
	fi
}
