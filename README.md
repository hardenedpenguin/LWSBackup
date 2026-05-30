# LWSBackup V17

## Overview

LWSBackup is a Bash-based backup and disaster recovery utility designed for:

- HamVoIP Nodes
- AllStarLink Systems
- Raspberry Pi Systems
- Debian Servers
- Arch Linux ARM
- Homelab Environments

The goal of the project is to provide a simple, reliable, and portable backup solution that can be operated entirely from a terminal or SSH session.

---

## What Was Accomplished In V17

### Backup Engine

- Full system backup creation
- Automatic ZIP generation
- Automatic restore kit generation
- SHA256 checksum generation
- Backup ZIP verification using `unzip -t`
- Restore kit ZIP verification using `unzip -t`
- Automatic backup rotation
- Automatic restore kit rotation
- Automatic log cleanup

### Restore System

- Self-contained restore kit creation
- Dry-run restore support
- Automatic `.bak` creation before overwrite
- Restore verification
- Portable restore package

### Installation Improvements

Added installer mode:

```bash
./lwsbackup.sh --install
```

The installer automatically:

1. Creates required folders
2. Copies the script to its permanent location
3. Creates symlinks
4. Installs dependencies when possible
5. Launches initial setup

---

## Folder Structure

LWSBackup automatically creates:

```text
/LWS_Backup/
├── backups/
├── restore_kits/
├── logs/
├── scripts/
├── profiles/
├── config/
└── tmp/
```

---

## Script Installation Location

```text
/LWS_Backup/scripts/lwsbackup.sh
```

---

## Symlinks Created

```text
/usr/local/sbin/lws-backup
/usr/local/bin/lws-backup
```

This allows the command to be executed from anywhere:

```bash
lws-backup
```

---

## Default Backup Targets

By default, the following paths are backed up:

```text
/srv/http
/etc/asterisk
/var/spool/cron/root
```

---

## Custom Backup Targets

Additional folders and files may be added through:

```text
Main Menu
└── Backup Targets
```

Users may:

- Add folders
- Add files
- Remove custom targets
- Edit target lists

---

## FTP Support

Optional FTP upload support is available.

Features:

- Enable or disable FTP uploads
- Save FTP credentials
- Upload backups automatically after completion
- Keep local backups regardless of FTP status

FTP is disabled by default.

---

## Cron Scheduling

Integrated cron management allows users to:

- Create scheduled backups
- Remove scheduled backups
- Modify backup schedules

Managed through:

```text
Main Menu
└── Cron Settings
```

---

## Profile Support

Multiple configuration profiles are supported.

Examples:

```text
Default
GMRS
Repeater
Portable
Test
```

Each profile may maintain separate:

- Backup settings
- FTP settings
- Target selections

---

## Backup Naming

Backup names are configurable.

Example:

```text
Backup_NodeUSB190504_20260530-135712.zip
```

Users may define custom prefixes.

---

## Logging

Logs are stored in:

```text
/LWS_Backup/logs/
```

Automatic cleanup removes older logs based on configured retention limits.

---

## ZIP Verification

After creation, both the backup ZIP and restore kit ZIP are automatically verified before the backup process completes.

---

## Dependency Management

LWSBackup automatically checks for required tools.

Supported package managers:

```text
apt-get
yum
pacman
```

Dependencies are installed automatically when possible.

---

## Menu System

LWSBackup includes a dialog-based interface.

Features:

- SSH-friendly
- Colorized menus
- Red menu selections for improved visibility
- HamVoIP compatible
- No GUI required

---

## Command Line Options

Install:

```bash
lws-backup --install
```

Run Backup:

```bash
lws-backup --run
```

Launch Menu:

```bash
lws-backup --menu
```

Run Setup Wizard:

```bash
lws-backup --setup
```

Show Help:

```bash
lws-backup --help
```

---

## Tested Environment

```text
OS: Arch Linux ARM
Kernel: 5.4.75
Bash: 4.3.42
Dialog: 1.3-20160209
Package Manager: pacman
```

Verified working on:

- HamVoIP
- Arch Linux ARM

---

## Current Status

```text
Version: V17
Status: Beta Testing
```

The backup engine, restore kit generation, ZIP verification, symlink installation, and cleanup systems are functioning correctly.

---

## Planned V18 Features

- Backup progress indicators
- Improved profile selection menu
- SFTP support
- SCP support
- RSYNC support
- Enhanced restore validation
- Installer refinements
- Windows Desktop Companion Application

---

## Author

WROG208 / N4ASS

Website:

```text
https://www.lonewolfsystem.org
```

GitHub:

```text
https://github.com/WROG208/LWSBackup
```
