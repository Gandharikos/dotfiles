---
title: Calibre-Web storage
description: Upload staging, bounded audit logs, backup placement, and capacity alerts on Athena.
---

Calibre-Web serves `book.huwenqiang.dev` through the existing authentication proxy. Uploads are
staged before they reach the library, so free library space alone does not guarantee uploads work.

## Filesystem layout

Athena has a roughly 36 GiB root filesystem and a separate volume split between `/nix` and
`/var/lib` (100 GiB partitions each). These filesystems do not share free space automatically.

| Data                                    | Location                                                    |
| --------------------------------------- | ----------------------------------------------------------- |
| Calibre application and default library | `/var/lib/calibre-web`                                      |
| Upload staging                          | `/var/lib/calibre-web-upload`                               |
| Restic repository                       | `/var/lib/selfhosted-backup/storage/restic/selfhosted`      |
| Portable export                         | `/var/lib/selfhosted-backup/storage/selfhosted`             |
| PostgreSQL export                       | `/var/lib/selfhosted-backup/storage/postgresql/all.sql.zst` |
| Restic cache and temporary work         | `/var/lib/selfhosted-backup/{cache,tmp}`                    |

`/var/backup` remains a compatibility symlink to the data-disk backup directory. Existing data must
be copied and verified before replacing an old directory with this symlink; the tmpfiles rule does
not perform a migration or delete an existing directory.

Calibre's `TMPDIR` points to its private, mode-0700 state directory on `/var/lib`. `PrivateTmp` and
the other service sandbox protections remain enabled. Upload staging is outside the library's backup
paths; tmpfiles ages out staging entries after seven days. Backup state directories and
`RequiresMountsFor` dependencies ensure the relevant mounts are available before the job starts.

## Preventing another full root filesystem

Audit logs use auditd's native size-based rotation: **64 MiB per file, eight retained files** by
default (approximately 512 MiB). `dot.security.auditd.autoPrune.size` and `.keep` control these
limits. The scheduled check requests rotation rather than deleting the active log.

**Never `rm` an active audit log to free space.** The daemon can retain the deleted inode and keep
writing to it. If this has already happened, preserve the held log before asking auditd to reopen or
rotate it. The October 2026 repair retained the recovered audit history privately on the data disk.

The database dump and portable archive are written to unique temporary files, checked with zstd, and
renamed only after success. Pipeline failures stop the backup; a partial export cannot replace the
previous successful artifact. Normal failure cleanup removes the temporary files.

The portable export includes the default `/var/lib/calibre-web` directory, including its library,
and the existing Taildrop job sends exports to `ymir`. A library configured outside that directory
needs a corresponding portable-export adjustment; Restic separately uses the configured library
path. Local backups share the data volume with applications, so they are **not** protection against
loss of that volume. Keep the off-host copy and periodically test restoration.

## Monitoring

The backup health endpoint checks `/`, `/nix`, and `/var/lib` on Athena. It fails when:

- Block or inode usage reaches **85%**. Reserved filesystem blocks are not counted as available to
  ordinary application users.
- A filesystem cannot be inspected.
- The successful-backup marker is more than 48 hours old, missing, invalid, or in the future.
- The PostgreSQL dump is missing or empty.

Gatus checks this endpoint every five minutes and sends a notification after two consecutive
failures, plus a recovery notification after two successes. Notifications use the existing ntfy
`selfhosted-backups` topic; **subscribe to that topic** to receive them. Successful publication to
ntfy does not establish that a particular phone or desktop is subscribed.

The checker intentionally does not infer host read-only status from its own mount flags: its
`ProtectSystem=strict` sandbox makes those flags read-only even when the host filesystem is
writable. A healthy endpoint is not a full restore or off-host-delivery verification.

```sh
ssh athena 'df -h / /nix /var/lib'
ssh athena 'curl -fsS http://127.0.0.1:9191/health'
ssh athena 'systemctl show restic-backups-selfhosted -p Result -p ExecMainStatus'
```

## Validation and deployment

```sh
python3 -m unittest discover -s scripts/tests -p 'test_backup_health.py'
nix build --no-link --impure --file scripts/tests/test_restic_prepare.nix
nix build --no-link --impure --file scripts/tests/test_storage_configuration.nix
```

The regression tests cover capacity/inode failures, stale metadata, failed or corrupt dumps,
leftover temporary files, archive failure preservation, and inclusion of the default Calibre data.

The incident deployment retained Athena's existing dependency lock and Home Manager generation to
avoid unrelated upgrades. The repository's `flake.lock` was not changed. Review pending upgrades
with `dry-activate` before a later normal deployment from the current checkout.
