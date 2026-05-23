# LWSBackup

LWSBackup is a lightweight backup and disaster recovery utility designed for:

- HamVoIP nodes
- AllStarLink systems
- Raspberry Pi repeaters
- Debian servers
- Arch Linux ARM systems
- General homelab environments

Built entirely in Bash for maximum compatibility with older Linux systems and low-resource devices.

---

# Features

## Backup Engine

- Full backup ZIP creation
- Automatic restore kit generation
- Portable disaster recovery packages
- SHA256 checksum generation
- Automatic dependency checking
- Automatic backup rotation cleanup
- Automatic log rotation cleanup
- Configurable backup naming
- Custom backup targets
- Multi-profile support

---

## Restore Engine

- Self-contained restore kits
- Automatic `.bak` safety backups before overwrite
- Restore dry-run mode
- Safe restore process
- Portable restore environment
- Restore logging

---

## User Interface

- Dialog-based terminal UI
- SSH-friendly menu system
- HamVoIP compatible
- No GUI environment required
- Automatic text fallback if `dialog` is unavailable

---

## Automation

- Cron scheduling setup
- Optional FTP upload support
- Persistent configuration system
- Automatic folder creation

---

# Supported Systems

Tested on:

- HamVoIP
- Arch Linux ARM
- Debian
- Raspberry Pi systems

Should also work on:

- Ubuntu
- Proxmox containers
- Mini PCs
- Generic Linux systems

---

# Requirements

The script automatically installs missing dependencies when possible.

Required tools:

```text
zip
unzip
sha256sum
dialog
curl (optional for FTP)
```

Supported package managers:

```text
apt-get
yum
pacman
```

---

# Folder Structure

LWSBackup automatically creates:

```text
/LWS_Backup/
│
├── backups/
├── restore_kits/
├── logs/
├── scripts/
├── profiles/
├── configs/
└── tmp/
```

---

# Default Backup Targets

By default the script backs up:

```text
/srv/http
/etc/asterisk
/var/spool/cron/root
```

Additional folders and files can be added through the setup menu.

---

# Backup Structure

Generated backup ZIP:

```text
Backup_HOSTNAME_YYYYMMDD-HHMMSS.zip
│
├── HTTP/
├── Asterisk/
├── root
├── custom/
└── system/
```

---

# Restore Kit Structure

Generated restore kit ZIP:

```text
Restore_kit_HOSTNAME_YYYYMMDD-HHMMSS.zip
│
└── Restore_kit/
    │
    ├── backups/
    │   └── Backup_latest.zip
    │
    ├── scripts/
    │   └── backup_v11.sh
    │
    ├── restore.sh
    ├── restore_config.conf
    ├── README_RESTORE.txt
    ├── sha256sums.txt
    └── logs/
```

---

# Installation

Clone the repository:

```bash
git clone https://github.com/WROG208/LWSBackup.git
cd LWSBackup
```

Make executable:

```bash
chmod +x backup_v11.sh
```

Run setup:

```bash
sudo ./backup_v11.sh --setup
```

Launch menu:

```bash
sudo ./backup_v11.sh --menu
```

Run backup directly:

```bash
sudo ./backup_v11.sh --run
```

---

# Optional Symlink

The script automatically creates:

```bash
/usr/local/sbin/lws-backup
```

You can then run:

```bash
sudo lws-backup
```

from anywhere.

---

# Restore Process

Extract the restore kit:

```bash
unzip Restore_kit_latest.zip
```

Enter the restore directory:

```bash
cd Restore_kit
```

Run dry-run restore:

```bash
sudo ./restore.sh --dry-run
```

Run actual restore:

```bash
sudo ./restore.sh
```

Reboot recommended afterward:

```bash
sudo reboot
```

---

# FTP Support

Optional FTP upload support is available.

Features:

- FTP upload toggle
- Saved FTP profiles
- Automatic upload after backup
- Local backup retention
- FTP disabled by default until configured

---

# Cron Scheduling

The setup menu can automatically configure cron jobs.

Example:

```cron
21 18 * * 5 /usr/local/sbin/lws-backup --run
```

Runs every Friday at 6:21 PM.

---

# Safety Features

- Root permission checking
- Automatic `.bak` file creation during restore
- SHA256 verification
- Dry-run restore mode
- Temporary workspace cleanup
- Lock file support
- Backup retention cleanup
- Log retention cleanup

---

# Compatibility Notes

LWSBackup is intentionally designed to support older systems commonly found in:

- HamVoIP nodes
- Older Raspberry Pi installations
- Embedded Linux systems
- Legacy AllStarLink systems

The project avoids requiring:

- Python
- Docker
- Databases
- Modern desktop environments
- Heavy dependencies

---

# Planned Future Features

- SFTP support
- SCP/RSYNC support
- Encrypted backups
- Incremental backups
- Backup verification testing
- Multi-node remote management
- Web dashboard
- Email notifications
- Telegram notifications

---

# License

MIT License

---

# Author

WROG208 / N4ASS

Website:
https://www.lonewolfsystem.org

GitHub:
https://github.com/WROG208/LWSBackup
Website:
https://www.lonewolfsystem.org

GitHub:
https://github.com/WROG208/LWSBackup
