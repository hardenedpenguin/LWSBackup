# Changelog

All notable changes to the Linux `lws-backup` script (currently **v17**) are documented here.

Desktop app releases (for example v1.0.4) are versioned separately from the script.

## [17] — Unreleased

### Added

- Modular `scripts/` layout (`lib/`, `ui/`, `commands/`, `templates/`)
- Repo-root `lws-backup` wrapper matching the installed command name
- Optional HamVOIP/AllStar default targets during setup (not forced on new installs)
- Backup target menu: validation, duplicate detection, and remove-target action
- Configurable backup and restore kit ZIP name prefixes
- Prefix-aware `*_latest.zip` archives and restore kit folder naming
- `job_prepare`, `job_run`, and `job_finalize` for cron-safe `--run`
- `session_prepare_minimal` for `--restore` without running install
- `targets_*` and `config_*` APIs with `TARGET_LAST_ERROR` for core validation
- Standalone `scripts/templates/restore.sh` (no generated heredoc)
- `--version` / `-V` flag
- Modular upgrade path when `scripts/lib/` is missing on an existing node
- Bats tests and GitHub Actions CI (ShellCheck + bats)

### Changed

- New installs start with an empty `targets.conf` until setup or the menu adds targets
- FTP upload failure no longer rolls back a successful backup; local archives are kept
- Restore flow requires dry-run success before live restore when dry-run is chosen
- `install_self` copies the full script tree to `/LWS_Backup/scripts`
- README: install-from-git, development layout, and Desktop vs script version note

### Removed

- Monolithic `backup_v17.sh` (replaced by modular entrypoint + wrapper)
- Legacy API aliases (`load_config`, `add_target`, etc.) — use `config_*` and `targets_*`

### Fixed

- Per-run timestamps when backup is launched from a long-lived menu session
- Backup fails clearly when no targets are copied
- Setup wizard welcome dialog regression after modular split
- Restore menu missing `script="$1"` for kit restore helper
