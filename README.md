<h1>
  <img src="https://avatars.githubusercontent.com/u/3909721?s=200&v=4" width="32px" alt="Logo of Alby Hub">
  Alby Hub, packaged for YunoHost
</h1>

Self-hosted Lightning wallet (embedded LDK node + Nostr Wallet Connect)

[![🌐 Official app website](https://img.shields.io/badge/Official_app_website-darkgreen?style=for-the-badge)](https://albyhub.com/)
[![Version: 1.24.0~ynh5](https://img.shields.io/badge/Version-1.24.0~ynh5-rgb(18,138,11)?style=for-the-badge)](https://github.com/getAlby/hub/releases/tag/v1.24.0)

> ⚠️ **Alby Hub controls Bitcoin and Lightning funds.** During first-run setup
> you will be shown a wallet **recovery phrase** — store it offline, outside
> this server. A YunoHost backup is **not** a substitute for the recovery
> phrase. Read the full disclaimer in `doc/DISCLAIMER.md` and the
> backup/recovery guidance in `doc/BACKUP.md` before putting funds on this app.

## Overview

Alby Hub is a self-hosted Lightning wallet: it runs an embedded LDK node plus
a Nostr Wallet Connect (NWC) server on your own domain. You hold your own
keys and can connect NWC-compatible apps, wallets and automation to it.

This package installs the upstream server binary in HTTP mode behind
YunoHost's nginx on a dedicated domain.

- Embedded `LDK` Lightning node (no Bitcoin Core / LND / CLN required)
- Native Alby Hub authentication (no YunoHost SSO in front)
- Persistent wallet state in a dedicated data directory
- Stop → snapshot → archive → restart backup scheme
- Conservative upgrades that never touch wallet state on failure

Currently supports `amd64` and `arm64`.

## Distributing through the Nostr Catalogue

This package is distributed through the Nostr YunoHost application catalogue
(a signed, relay-visible declaration) rather than the official
`YunoHost/apps` GitHub catalogue. Contact an admin to publish a new version;
see `install` instructions below.

## Install

```
# fresh install (test `main` branch):
sudo yunohost app install https://github.com/<org>/alby-hub_ynh
```

Then open the app's URL and complete wallet creation in Alby Hub's own UI.

## Documentation

- `doc/DISCLAIMER.md` — financial safety
- `doc/BACKUP.md` — backup/restore, restore-test checklist
- `doc/ADMIN.md` — service, logs, upgrade and removal semantics

## Developer info

🛠️ Upstream repository: <https://github.com/getAlby/hub>

Pull requests are welcome and should target the `main` branch.
