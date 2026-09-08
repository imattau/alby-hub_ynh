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
also disables browser caching at the reverse proxy so future upgrades do not
reuse an old application shell.

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
scope for this v1 package and can be layered on later via a configuration
panel.

## Known v1 limitations

- The embedded LDK node's own P2P listener (upstream default `[::]:9735`) is
  **not** firewall-opened by this package. Outbound channels/peering work, but
  other nodes cannot dial in to open channels to your node until that port is
  opened. Public inbound channels are a follow-up.
- Backups use a stop → declare → restart scheme; a fully atomic staged dump is
  a tracked follow-up before the package is marked stable (see
  `doc/BACKUP.md`).
