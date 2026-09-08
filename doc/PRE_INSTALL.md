**Alby Hub controls real Bitcoin and Lightning funds. Read this before continuing.**

- During first-run setup Alby Hub will show you a wallet **recovery phrase**. Store it **offline, outside this server** — anyone with it controls the funds.
- A **YunoHost backup is not a substitute** for the recovery phrase. The two recover different scenarios.
- Alby Hub is a **hot wallet** (its keys live on this internet-connected server). Keep only amounts you can afford to lose.
- The **Lightning backend** you choose below (embedded `LDK`, or an external `CLN` node) **cannot be changed later** without discarding this wallet (`--purge` + reinstall). Pick carefully.

See `doc/DISCLAIMER.md` for the full financial notice and `doc/BACKUP.md` for backup/recovery guidance.
