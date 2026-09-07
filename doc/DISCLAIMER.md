# Financial application disclaimer

Alby Hub **controls Bitcoin and Lightning funds**. This package installs and
keeps the software running, but it is **your responsibility** to secure the
money it manages.

## On the recovery phrase (unlocked via your Alby Hub password)

During first-run setup Alby Hub creates a wallet backed by a **recovery
phrase**. You are shown this phrase during setup and can redisplay it from the
Alby Hub settings (using your unlock password).

- Store the recovery phrase **offline, outside this server** — on paper or in
  a dedicated password manager. Do not store it on the same host.
- Anyone with the recovery phrase controls the funds, regardless of the state
  of this server.
- Neither the YunoHost package nor its logs ever ask for, capture, or store
  the recovery phrase, the unlock password, NWC secrets, auth tokens, or any
  wallet private key.

## On YunoHost backups

A YunoHost backup captures the application's data directory (the SQLite
database, configuration and embedded LDK node state). A **backup is not a
substitute for the recovery phrase** — the two recover different things:

| Scenario | What you need |
| --- | --- |
| Server disk loss / reinstall | YunoHost backup (restores the app + state) **and** recovery phrase (verifies/funds) |
| Lost or forgotten unlock password | Recovery phrase only |
| Corrupted database / botched upgrade | YunoHost backup or recovery phrase |

Always keep **both** the recovery phrase and a current YunoHost backup.

## It is a hot wallet

Alby Hub is a **hot wallet**: its keys live on an internet-connected server.
This is fundamentally riskier than a hardware wallet. Keep the amounts on the
hub appropriate to what you can afford to lose, and treat the host's security
(SSH access, YunoHost admin accounts, upstream Alby Hub releases) as part of
your wallet's security.
