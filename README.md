# LWSBackup

A lightweight Bash-based backup and restore utility designed for:

- HamVoIP nodes
- AllStarLink systems
- Raspberry Pi repeaters
- Debian servers
- Arch Linux ARM systems
- General homelab environments

Built to work even on older systems with minimal dependencies.

The project focuses on:

- Simple operation
- Automatic restore kit generation
- Portable backups
- SSH-friendly menu systems
- No database requirements
- No Python requirements

---

# Features

- Full backup creation
- Automatic restore kit generation
- Self-contained restore scripts
- Automatic dependency checking
- Automatic folder creation
- Backup rotation cleanup
- SHA256 verification
- Root privilege checking
- Compatible with:
  - apt
  - yum
  - pacman
- HamVoIP friendly
- Bash 4.x compatible
- Lightweight
- Designed for terminal/SSH use

---

# Current Backup Targets

By default the script backs up:

```text
/srv/http
/etc/asterisk
/var/spool/cron/root
```

---

# Backup Structure

Generated backup ZIP:

```text
Backup_HOSTNAME_DATE.zip
│
├── HTTP/
├── Asterisk/
└── root
```

Generated restore kit ZIP:

```text
Restore_kit_HOSTNAME_DATE.zip
│
└── Restore_kit/
    │
    ├── backups/
    │   └── Backup_latest.zip
    │
    ├── scripts/
    │   └── backup_v10.sh
    │
    ├── restore.sh
    ├── restore_config.conf
    ├── README_RESTORE.txt
    └── sha256sums.txt
```

---

# Folder Structure Created

The script automatically creates:

```text
/LWS_Backup/
│
├── backups/
├── restore_kits/
├── logs/
├── scripts/
└── tmp/
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
chmod +x backup_v10.sh
```

Run:

```bash
sudo ./backup_v10.sh
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

Extract the generated restore kit:

```bash
unzip Restore_kit_latest.zip
```

Enter the restore folder:

```bash
cd Restore_kit
```

Run restore:

```bash
sudo ./restore.sh
```

Reboot recommended afterward:

```bash
sudo reboot
```

---

# Dependency Handling

The script automatically installs missing dependencies when possible.

Required tools:

```text
zip
unzip
sha256sum
```

Package managers supported:

```text
apt-get
yum
pacman
```

---

# Backup Rotation

Currently keeps:

```text
2 backups
2 restore kits
```

Older backups are automatically deleted.

---

# Compatibility

Tested on:

```text
HamVoIP
Arch Linux ARM
Debian
Raspberry Pi systems
```

Should also work on:

- Ubuntu
- Proxmox containers
- Mini PCs
- Generic Linux systems

---

# Security Notes

- Script must run as root.
- Restore overwrites live system files.
- Always verify backups before relying on them.
- Restore kits include SHA256 verification.

---

# Planned Features

- Dialog-based menu UI
- FTP upload support
- Cron scheduling setup
- Custom backup targets
- Safer restore with automatic `.bak` creation
- Dry-run restore mode
- Configurable backup naming
- Better logging cleanup
- Multi-node backup profiles

---

# Example Cron Job

```cron
21 18 * * 5 /usr/local/sbin/lws-backup
```

Runs every Friday at 6:21 PM.

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
