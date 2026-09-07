# Backup & restore

## What gets backed up

`yunohost backup` captures the application's **data directory**
(`$data_dir`), which contains everything needed to recover the wallet state:

- the SQLite application database (`nwc.db`)
- the embedded LDK node state (channels, keys)
- the static channel backup / monitor data
- configuration

The upstream release **binary and archives are deliberately excluded** — they
live under `$install_dir` and are reinstalled from the pinned upstream release
on restore, so a restore always produces a consistent binary/state pair.

## What a backup is *not*

A backup is **not** your wallet's recovery phrase. See
[`DISCLAIMER.md`](./DISCLAIMER.md) for the full distinction. Store the
recovery phrase offline, separately.

## Consistency

Alby Hub does not guarantee that its on-disk state can be copied while it is
running (SQLite + LDK write continuously while the service is up). To capture
a consistent snapshot, the `backup` script:

1. stops the service (a clean stop flushes SQLite to disk and halts LDK
   background writes),
2. declares `$data_dir` for backup,
3. restarts the service.

YunoHost then builds the archive from the on-disk state shortly after the
script returns. There is a small residual window between restart and the
archive being written; closing it fully would require a staged dump, which is
a documented follow-up item (see below) rather than shipped in v1.

## Restoring — verification checklist

`yunohost backup restore` succeeding is **not** the same as a healthy wallet.
After a restore, confirm each of these before trusting the result:

1. the service is running (`yunohost service status alby_hub`);
2. the web UI loads and **recognises the existing wallet** (no first-run /
   "create wallet" prompt — if you see one, the database did not restore);
3. configuration is intact (currency, node backend, connected apps);
4. NWC connections, where present, still work;
5. Lightning channels/balance look correct (be patient — LDK may need to
   resync from the chain before balances are final).

If the wallet is not recognised after a restore, **stop** and recover from the
recovery phrase through the Alby Hub UI rather than continuing to use a
half-restored node.

## Restore vs recovery phrase

- **Full state recovery** (channels, app connections, settings): YunoHost
  backup restore.
- **Losing the unlock password**, or a server that can't be reached at all,
  or any doubt about the restored database: **recovery phrase**.

## Follow-up item: fully consistent backups

The stop → declare → restart scheme flushes SQLite but does not guarantee the
lighter LDK on-disk state is atomically consistent at archive time. Hardening
this to a staged dump (stop → copy `$data_dir` into `$YNH_APP_BACKUP_DIR` →
restart, then restore from that staged copy) is tracked as a follow-up before
calling the package stable — see the plan's backup/restore release gate.
