# Alby Hub administration

## What it is

Alby Hub is a self-hosted Lightning wallet with an embedded LDK node and a
Nostr Wallet Connect (NWC) server. This package runs the upstream server
binary in "HTTP mode" behind YunoHost's nginx, on its own dedicated domain.

- **Wallet security, authentication, Lightning and NWC permissions are all
  handled by Alby Hub itself** — not by YunoHost. There is no YunoHost SSO in
  front of the app (see below).
- The service runs as its own unprivileged user and listens on an internal
  port (`:__PORT__`) that the firewall keeps closed; nginx is the only public
  entry point.

## Service & logs

```bash
yunohost service status alby_hub
journalctl -u alby_hub -f
```

Alby Hub also writes its own JSON log to `$data_dir/log/nwc.log`.

## Diagnostics

`yunohost app diagnosis show alby_hub` reports version, service and HTTP
reachability. It never exposes the recovery phrase, NWC secrets, wallet tokens
or private keys.

## No YunoHost SSO (deliberate)

Alby Hub's API, NWC, mobile and browser-extension flows authenticate against
Alby Hub itself (unlock password over the initial session, then token/NWC
auth). Putting YunoHost SSO in front would break those. The web endpoint is
reachable by anyone who can dial the domain ("visitors" by default), but the
wallet remains locked behind Alby Hub's own authentication.

## Troubleshooting — "can't get past the login" (401 on everything)

Alby Hub authenticates the web UI with a JWT stored in your browser's local
storage (not a cookie). A stale token or stale frontend bundle can cause the
login screen to remain visible while API requests return 401.

This can happen after:

- you change the unlock password (Alby Hub rotates its JWT signing secret on
  purpose, logging out all sessions);
- the token expires or is otherwise invalidated;
- the server is upgraded while the browser still has an older frontend bundle.

When that happens the login screen appears, but the browser keeps sending the
stale token, so every request comes back 401 until it is cleared. This is not
a database or wallet problem — the wallet and funds are unaffected.

To fix: clear the site data for this domain (DevTools → Application → Local
Storage → remove `authToken`), reload the page, and log in again. Clearing only
the local storage is enough; do not reinstall or restore the app. The package
forwards the authorization header explicitly through nginx; stale frontend
cache invalidation remains an upstream Alby Hub concern.

## Changing the domain

`yunohost app change-url` moves Alby Hub to another dedicated domain (or a new
path on one) by re-rendering the nginx config only; the wallet data and binary
are untouched.

## Upgrade safety

Upgrades run: stop → replace binary → start → health-check. Wallet state under
`$data_dir` is **never modified** by the upgrade script. If a newer Alby Hub
migrates the database in a way an older binary cannot read, the upgrade does
**not** attempt automatic database/LDK rollback — take a backup (and keep your
recovery phrase) before upgrading, per normal wallet discipline.

## Removing the app

`yunohost app remove` stops and removes the app but **keeps the wallet data**
under `$data_dir`. Pass `--purge` to delete the data directory too. Removing
without `--purge` intentionally never destroys funds.

## Configuration

Alby Hub is configured through its own web UI after first run. Environment-
level defaults (port, data dir, embedded LDK node, esplora backend) are fixed
in the systemd unit and should not normally need editing. Selectively
overridable upstream settings (`LDK_*`, `RELAY`, `NETWORK`, ...) are out of
scope for this v1 package.

## Lightning backend (LDK vs Core Lightning)

The Lightning backend (`ln_backend_type`, `LDK` or `CLN`) is an **install-time
choice only** — there is no config-panel option to switch it after install.
This is not a packaging limitation: upstream Alby Hub reads `LN_BACKEND_TYPE`
and fixes the backend the moment a wallet is created during first-run setup
(`service/start.go`); changing the env var afterwards has no effect on an
existing wallet. To switch backends, remove the app with `--purge` (destroying
the current wallet's local state — see `doc/DISCLAIMER.md`) and reinstall with
the other choice.

Choosing `CLN` requires a `core_lightning` app (from `core-lightning_ynh`)
already installed on this server with gRPC enabled (its config panel's
`grpc_enabled` setting — see that package's `doc/GRPC_BACKEND.md`). The
install/upgrade/restore scripts then:

- read `cln_address` / `cln_lightning_dir` / `cln_address_hold` and set them as
  `CLN_ADDRESS` / `CLN_LIGHTNING_DIR` / `CLN_ADDRESS_HOLD` in the systemd unit;
- join this app's system user to the `core_lightning` unix group, which is
  what actually grants read access to Core Lightning's gRPC client certs
  (`ca.pem`, `client.pem`, `client-key.pem`) — nothing else in Core Lightning's
  data directory is exposed;
- add `cln_lightning_dir` to the systemd sandbox's `ReadOnlyPaths=`, since
  `ProtectSystem=strict` would otherwise block reading it regardless of unix
  permissions.

If `core_lightning`'s group doesn't exist yet, install/upgrade fails with a
clear error rather than silently falling back to LDK.

### Guard against manually editing `ln_backend_type`

A normal `yunohost app upgrade` never changes `ln_backend_type` — the upgrade
script only ever re-reads whatever was persisted at install. But nothing
stops an admin from running
`yunohost app setting alby_hub ln_backend_type -v CLN` (or `LDK`) by hand
outside the intended flow. If that value no longer matches what the wallet
was actually set up with, rebuilding the systemd unit from it would point
Alby Hub's env vars at a different backend than its internal wallet state
actually uses.

To prevent that, install records the backend it actually brought up as
`ln_backend_type_locked` once the health check passes. Every upgrade and
restore calls `ynh_alby_check_backend_lock` before doing anything else, and
refuses to proceed (`ynh_die`) if `ln_backend_type` no longer matches
`ln_backend_type_locked`. **Do not hand-edit `ln_backend_type` on an existing
instance** — see "The Lightning backend cannot be changed later" above for
the only supported way to actually switch backends.

## Known v1 limitations

- The embedded LDK node's own P2P listener (upstream default `[::]:9735`) is
  **not** firewall-opened by this package. Outbound channels/peering work, but
  other nodes cannot dial in to open channels to your node until that port is
  opened. Public inbound channels are a follow-up. (Not applicable when
  `ln_backend_type = CLN` — Core Lightning manages its own P2P port.)
- Backups use a stop → declare → restart scheme; a fully atomic staged dump is
  a tracked follow-up before the package is marked stable (see
  `doc/BACKUP.md`).
