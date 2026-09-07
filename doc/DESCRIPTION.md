Alby Hub is a self-hosted Lightning wallet: it runs an embedded LDK node and a
Nostr Wallet Connect (NWC) server on your own domain, so you hold your own
Bitcoin/Lightning keys and can connect NWC-compatible apps, wallets and
automation to it.

This package installs the upstream Alby Hub server binary in HTTP mode behind
YunoHost's nginx. It uses a dedicated domain, keeps all wallet state in a
persistent data directory, and leaves authentication and wallet management to
Alby Hub itself (no YunoHost SSO).

⚠️ **Alby Hub controls real funds.** Store the wallet recovery phrase offline
(outside this server) during setup — a YunoHost backup is not a substitute.
See the app documentation for backup/recovery guidance.
