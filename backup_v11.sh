#!/bin/bash
# LWS Backup v11
# Backup + Restore Kit Builder + Dialog UI + Optional FTP + Cron + Custom Targets
# WROG208 / N4ASS
# Designed for HamVoIP / Arch Linux ARM / Debian / Raspberry Pi / AllStar-style nodes.
# Bash 4.x compatible. No Python required.

VERSION="11"
LWS_ROOT="/LWS_Backup"
SCRIPT_DIR="$LWS_ROOT/scripts"
BACKUP_DIR="$LWS_ROOT/backups"
RESTORE_KIT_DIR="$LWS_ROOT/restore_kits"
LOG_DIR="$LWS_ROOT/logs"
TMP_DIR="$LWS_ROOT/tmp"
CONFIG_DIR="$LWS_ROOT/config"
PROFILE_DIR="$CONFIG_DIR/profiles"
CONFIG_FILE="$CONFIG_DIR/lwsbackup.conf"
TARGETS_FILE="$CONFIG_DIR/targets.conf"
FTP_FILE="$CONFIG_DIR/ftp.conf"
CRON_MARKER_BEGIN="# BEGIN LWSBackup managed cron job"
CRON_MARKER_END="# END LWSBackup managed cron job"
DATESTAMP="$(date +%Y%m%d-%H%M%S)"
HOSTNAME="$(hostname 2>/dev/null || echo unknown-host)"
LOCK_FILE="/tmp/lwsbackup.lock"
LOG_FILE="$LOG_DIR/lwsbackup_v${VERSION}_${DATESTAMP}.log"
WORK_DIR="$TMP_DIR/work_${DATESTAMP}"
KIT_DIR="$TMP_DIR/Restore_kit_${DATESTAMP}"
SELF_SCRIPT="$SCRIPT_DIR/lwsbackup.sh"
BACKUP_PREFIX="Backup"
RESTORE_KIT_PREFIX="Restore_kit"
MAX_BACKUPS=4
MAX_RESTORE_KITS=4
MAX_LOGS=10
FTP_ENABLED="no"
FTP_DELETE_LOCAL_AFTER_UPLOAD="no"
FTP_SERVER=""
FTP_PORT="21"
FTP_USER=""
FTP_PASSWORD=""
FTP_REMOTE_DIR="/"
ACTIVE_PROFILE="default"
DIALOG_BIN=""
DIALOGRC_FILE="/tmp/lwsbackup-dialogrc.$$"

# ---------------- Basic helpers ---------------- #
echo_log() {
    msg="$1"
    echo "$msg"
    mkdir -p "$LOG_DIR" 2>/dev/null
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $msg" >> "$LOG_FILE" 2>/dev/null
}

cleanup() {
    rm -rf "$WORK_DIR" "$KIT_DIR" "$DIALOGRC_FILE" 2>/dev/null
    rm -f "$LOCK_FILE" 2>/dev/null
}

fail_exit() {
    echo_log "ERROR: $1"
    cleanup
    exit 1
}

pause_text() {
    echo
    echo "Press ENTER to continue..."
    read dummy
}

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root."
        exit 1
    fi
}

create_folders() {
    mkdir -p "$SCRIPT_DIR" "$BACKUP_DIR" "$RESTORE_KIT_DIR" "$LOG_DIR" "$TMP_DIR" "$CONFIG_DIR" "$PROFILE_DIR" || {
        echo "Could not create $LWS_ROOT folders."
        exit 1
    }
}

make_lock() {
    if [ -f "$LOCK_FILE" ]; then
        oldpid="$(cat "$LOCK_FILE" 2>/dev/null)"
        if [ -n "$oldpid" ] && kill -0 "$oldpid" 2>/dev/null; then
            fail_exit "Another LWSBackup job appears to be running. Lock: $LOCK_FILE"
        fi
    fi
    echo "$$" > "$LOCK_FILE"
}

sanitize_name() {
    echo "$1" | tr ' ' '_' | tr -cd '[:alnum:]_.-'
}

load_config() {
    [ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"
    [ -f "$FTP_FILE" ] && . "$FTP_FILE"
}

save_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" <<EOC
# LWSBackup configuration
VERSION="$VERSION"
BACKUP_PREFIX="$BACKUP_PREFIX"
RESTORE_KIT_PREFIX="$RESTORE_KIT_PREFIX"
MAX_BACKUPS="$MAX_BACKUPS"
MAX_RESTORE_KITS="$MAX_RESTORE_KITS"
MAX_LOGS="$MAX_LOGS"
ACTIVE_PROFILE="$ACTIVE_PROFILE"
EOC
    chmod 600 "$CONFIG_FILE"
}

save_ftp_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$FTP_FILE" <<EOC
# LWSBackup FTP configuration
# FTP is disabled unless FTP_ENABLED="yes".
FTP_ENABLED="$FTP_ENABLED"
FTP_SERVER="${FTP_SERVER:-}"
FTP_PORT="${FTP_PORT:-21}"
FTP_USER="${FTP_USER:-}"
FTP_PASSWORD="${FTP_PASSWORD:-}"
FTP_REMOTE_DIR="${FTP_REMOTE_DIR:-/}"
FTP_DELETE_LOCAL_AFTER_UPLOAD="$FTP_DELETE_LOCAL_AFTER_UPLOAD"
EOC
    chmod 600 "$FTP_FILE"
}

create_default_targets_if_missing() {
    if [ ! -f "$TARGETS_FILE" ]; then
        cat > "$TARGETS_FILE" <<'EOT'
# LWSBackup target list
# Format: TYPE|SOURCE|ZIP_NAME|RESTORE_DESTINATION
# TYPE: DIR or FILE
DIR|/srv/http|HTTP|/srv/http
DIR|/etc/asterisk|Asterisk|/etc/asterisk
FILE|/var/spool/cron/root|root|/var/spool/cron/root
EOT
        chmod 600 "$TARGETS_FILE"
    fi
}

initialize_defaults() {
    create_folders
    load_config
    [ -f "$CONFIG_FILE" ] || save_config
    [ -f "$FTP_FILE" ] || save_ftp_config
    create_default_targets_if_missing
}

# ---------------- Dependencies ---------------- #
install_package_for_command() {
    cmd="$1"
    pkg="$2"
    if command -v "$cmd" >/dev/null 2>&1; then return 0; fi
    echo "$cmd is missing. Attempting to install package: $pkg"
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq && apt-get install -y "$pkg"
    elif command -v yum >/dev/null 2>&1; then
        yum install -y "$pkg"
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y "$pkg"
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm "$pkg"
    elif command -v zypper >/dev/null 2>&1; then
        zypper --non-interactive install "$pkg"
    else
        fail_exit "No supported package manager found. Install $cmd manually."
    fi
    command -v "$cmd" >/dev/null 2>&1 || fail_exit "Installation failed for $cmd."
}

check_commands_core() {
    install_package_for_command zip zip
    install_package_for_command unzip unzip
    install_package_for_command sha256sum coreutils
}

check_commands_optional() {
    load_config
    if [ "$FTP_ENABLED" = "yes" ]; then
        install_package_for_command curl curl
    fi
}

check_dialog() {
    if command -v dialog >/dev/null 2>&1; then
        DIALOG_BIN="$(command -v dialog)"
        return 0
    fi
    return 1
}

install_dialog_if_possible() {
    command -v dialog >/dev/null 2>&1 && return 0
    echo "dialog is missing. Attempting to install..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq && apt-get install -y dialog
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm dialog
    elif command -v yum >/dev/null 2>&1; then
        yum install -y dialog
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y dialog
    fi
}

# ---------------- Dialog UI ---------------- #
setup_dialog_theme() {
    cat > "$DIALOGRC_FILE" <<'EOD'
use_shadow = OFF
use_colors = ON
screen_color = (BLACK,BLACK,OFF)
shadow_color = (BLACK,BLACK,OFF)
dialog_color = (BLACK,WHITE,OFF)
title_color = (RED,WHITE,ON)
border_color = (BLACK,WHITE,OFF)
border2_color = (BLACK,WHITE,OFF)
button_active_color = (WHITE,RED,ON)
button_inactive_color = (BLACK,WHITE,OFF)
button_key_active_color = (YELLOW,RED,ON)
button_key_inactive_color = (RED,WHITE,OFF)
button_label_active_color = (WHITE,RED,ON)
button_label_inactive_color = (BLACK,WHITE,OFF)
inputbox_color = (BLACK,WHITE,OFF)
inputbox_border_color = (BLACK,WHITE,OFF)
menubox_color = (BLACK,WHITE,OFF)
menubox_border_color = (BLACK,WHITE,OFF)
item_color = (RED,WHITE,OFF)
item_selected_color = (WHITE,RED,ON)
tag_color = (RED,WHITE,ON)
tag_selected_color = (WHITE,RED,ON)
tag_key_color = (RED,WHITE,ON)
tag_key_selected_color = (YELLOW,RED,ON)
check_color = (BLACK,WHITE,OFF)
check_selected_color = (WHITE,RED,ON)
uarrow_color = (RED,WHITE,ON)
darrow_color = (RED,WHITE,ON)
gauge_color = (RED,WHITE,ON)
EOD
}

dialog_cmd() {
    DIALOGRC="$DIALOGRC_FILE" "$DIALOG_BIN" --ascii-lines --no-shadow --colors "$@"
}

msgbox() {
    title="$1"; text="$2"
    if check_dialog; then
        setup_dialog_theme
        dialog_cmd --title "$title" --msgbox "$text" 16 76
        clear
    else
        echo; echo "==== $title ===="; echo "$text"; pause_text
    fi
}

yesno() {
    title="$1"; text="$2"
    if check_dialog; then
        setup_dialog_theme
        dialog_cmd --title "$title" --yesno "$text" 12 76
        rc=$?; clear; return $rc
    else
        echo; echo "$title"; echo "$text"; printf "Yes or No? [y/N]: "; read ans
        [ "$ans" = "y" ] || [ "$ans" = "Y" ]
    fi
}

inputbox() {
    title="$1"; text="$2"; default="$3"
    if check_dialog; then
        setup_dialog_theme
        result="$(dialog_cmd --title "$title" --inputbox "$text" 12 76 "$default" 3>&1 1>&2 2>&3)"
        rc=$?; clear; [ $rc -eq 0 ] || return 1; echo "$result"; return 0
    else
        echo; echo "$title"; printf "%s [%s]: " "$text" "$default"; read result
        [ -z "$result" ] && result="$default"; echo "$result"; return 0
    fi
}

passwordbox() {
    title="$1"; text="$2"
    if check_dialog; then
        setup_dialog_theme
        result="$(dialog_cmd --title "$title" --passwordbox "$text" 12 76 3>&1 1>&2 2>&3)"
        rc=$?; clear; [ $rc -eq 0 ] || return 1; echo "$result"; return 0
    else
        echo; echo "$title"; printf "%s: " "$text"; stty -echo; read result; stty echo; echo; echo "$result"; return 0
    fi
}

# ---------------- Targets ---------------- #
list_targets_text() {
    [ ! -f "$TARGETS_FILE" ] && { echo "No targets file found."; return; }
    awk -F'|' '/^[[:space:]]*#/ {next} NF >= 4 {printf "- %-4s %-30s -> %-18s restore: %s\n", $1, $2, $3, $4}' "$TARGETS_FILE"
}

add_target() {
    type="$1"; src="$2"; zipname="$3"; dest="$4"
    [ -z "$src" ] && return 1
    [ -z "$zipname" ] && zipname="$(basename "$src")"
    [ -z "$dest" ] && dest="$src"
    zipname="$(sanitize_name "$zipname")"
    echo "${type}|${src}|${zipname}|${dest}" >> "$TARGETS_FILE"
}

configure_targets_menu() {
    while true; do
        current="$(list_targets_text)"; [ -z "$current" ] && current="No targets configured."
        if check_dialog; then
            setup_dialog_theme
            choice="$(dialog_cmd --title "Backup Targets" --menu "Current targets:\n\n$current\n\nChoose an action:" 24 84 8 \
                "1" "Add folder target" "2" "Add file target" "3" "Reset to default targets" "4" "Show targets file path" "0" "Back" \
                3>&1 1>&2 2>&3)"
            rc=$?; clear; [ $rc -eq 0 ] || return
        else
            echo "$current"; echo "1) Add folder target"; echo "2) Add file target"; echo "3) Reset defaults"; echo "4) Show path"; echo "0) Back"; read choice
        fi
        case "$choice" in
            1) src="$(inputbox "Add Folder" "Enter folder path to back up:" "")" || continue
               zipname="$(inputbox "ZIP Folder Name" "Name inside the backup ZIP:" "$(basename "$src")")" || continue
               dest="$(inputbox "Restore Destination" "Restore destination path:" "$src")" || continue
               add_target "DIR" "$src" "$zipname" "$dest"; msgbox "Added" "Folder target added." ;;
            2) src="$(inputbox "Add File" "Enter file path to back up:" "")" || continue
               zipname="$(inputbox "ZIP File Name" "Name inside the backup ZIP:" "$(basename "$src")")" || continue
               dest="$(inputbox "Restore Destination" "Restore destination path:" "$src")" || continue
               add_target "FILE" "$src" "$zipname" "$dest"; msgbox "Added" "File target added." ;;
            3) if yesno "Reset Targets" "Reset backup targets to defaults?"; then rm -f "$TARGETS_FILE"; create_default_targets_if_missing; msgbox "Reset" "Targets reset."; fi ;;
            4) msgbox "Targets File" "$TARGETS_FILE" ;;
            0) return ;;
        esac
    done
}

# ---------------- Backup engine ---------------- #
build_names() {
    safe_prefix="$(sanitize_name "$BACKUP_PREFIX")"; [ -z "$safe_prefix" ] && safe_prefix="Backup"
    BACKUP_NAME="${safe_prefix}_${HOSTNAME}_${DATESTAMP}.zip"
    RESTORE_KIT_NAME="${RESTORE_KIT_PREFIX}_${HOSTNAME}_${DATESTAMP}.zip"
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME"
    LATEST_BACKUP_FILE="$BACKUP_DIR/Backup_latest.zip"
    RESTORE_KIT_FILE="$RESTORE_KIT_DIR/$RESTORE_KIT_NAME"
    LATEST_RESTORE_KIT_FILE="$RESTORE_KIT_DIR/Restore_kit_latest.zip"
}

create_backup_metadata() {
    mkdir -p "$WORK_DIR/system" "$WORK_DIR/logs"
    {
        echo "LWSBackup Version: $VERSION"
        echo "Created: $DATESTAMP"
        echo "Hostname: $HOSTNAME"
        echo "Backup Prefix: $BACKUP_PREFIX"
        echo "Active Profile: $ACTIVE_PROFILE"
        echo
        echo "Targets:"
        cat "$TARGETS_FILE"
    } > "$WORK_DIR/system/backup_info.txt"
    cp /etc/os-release "$WORK_DIR/system/os-release.txt" 2>/dev/null
    hostname > "$WORK_DIR/system/hostname.txt" 2>/dev/null
    uname -a > "$WORK_DIR/system/uname.txt" 2>/dev/null
    crontab -l > "$WORK_DIR/system/root-crontab.txt" 2>/dev/null
    if command -v ip >/dev/null 2>&1; then ip addr > "$WORK_DIR/system/network.txt" 2>/dev/null; elif command -v ifconfig >/dev/null 2>&1; then ifconfig -a > "$WORK_DIR/system/network.txt" 2>/dev/null; fi
    cp "$LOG_FILE" "$WORK_DIR/logs/backup.log" 2>/dev/null
}

backup_targets() {
    echo_log "Creating backup workspace..."
    mkdir -p "$WORK_DIR" || fail_exit "Could not create work directory"
    echo_log "Collecting backup targets..."
    [ ! -f "$TARGETS_FILE" ] && create_default_targets_if_missing
    while IFS='|' read type src zipname dest; do
        case "$type" in ""|\#*) continue ;; esac
        [ -z "$src" ] && continue
        [ -z "$zipname" ] && zipname="$(basename "$src")"
        if [ "$type" = "DIR" ]; then
            if [ -d "$src" ]; then cp -a "$src" "$WORK_DIR/$zipname" || fail_exit "Failed copying $src"; echo_log "Added directory: $src -> $zipname"; else echo_log "Skipped missing directory: $src"; fi
        elif [ "$type" = "FILE" ]; then
            if [ -f "$src" ]; then cp -a "$src" "$WORK_DIR/$zipname" || fail_exit "Failed copying $src"; echo_log "Added file: $src -> $zipname"; else echo_log "Skipped missing file: $src"; fi
        fi
    done < "$TARGETS_FILE"
    create_backup_metadata
}

create_backup() {
    build_names
    backup_targets
    echo_log "Creating backup zip: $BACKUP_FILE"
    ( cd "$WORK_DIR" || exit 1; zip -r "$BACKUP_FILE" ./* ) >> "$LOG_FILE" 2>&1 || fail_exit "Backup zip failed"
    cp -f "$BACKUP_FILE" "$LATEST_BACKUP_FILE" || fail_exit "Could not update latest backup"
    echo_log "Backup created successfully."
}

# ---------------- Restore kit ---------------- #
create_restore_script() {
    cat > "$KIT_DIR/restore.sh" <<'EOS'
#!/bin/bash
# Restore Script generated by LWSBackup v11
KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_ZIP="$KIT_DIR/backups/Backup_latest.zip"
TARGETS_FILE="$KIT_DIR/restore_targets.conf"
RESTORE_WORK="/tmp/LWSBackup_restore_work_$$"
LOG_FILE="$KIT_DIR/restore.log"
DRY_RUN="no"

echo_log() { echo "$1"; echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"; }
fail_exit() { echo_log "ERROR: $1"; rm -rf "$RESTORE_WORK"; exit 1; }
usage() { echo "Usage: sudo ./restore.sh [--dry-run]"; }
[ "$1" = "--dry-run" ] && DRY_RUN="yes"
[ "$1" = "--help" ] || [ "$1" = "-h" ] && { usage; exit 0; }
[ "$(id -u)" != "0" ] && { echo "This restore script must be run as root."; exit 1; }
command -v unzip >/dev/null 2>&1 || fail_exit "unzip is missing"
command -v cp >/dev/null 2>&1 || fail_exit "cp is missing"
[ -f "$BACKUP_ZIP" ] || fail_exit "Backup zip not found: $BACKUP_ZIP"
[ -f "$TARGETS_FILE" ] || fail_exit "Restore target file not found: $TARGETS_FILE"
echo_log "Starting restore..."
[ "$DRY_RUN" = "yes" ] && echo_log "DRY RUN MODE: No files will be changed."
mkdir -p "$RESTORE_WORK"
unzip -q "$BACKUP_ZIP" -d "$RESTORE_WORK" || fail_exit "Could not unzip backup"
backup_existing_path() {
    dest="$1"
    if [ -e "$dest" ]; then
        bak="${dest}.bak.$(date +%Y%m%d-%H%M%S)"
        echo_log "Existing path found: $dest"
        echo_log "Creating safety backup: $bak"
        [ "$DRY_RUN" = "no" ] && cp -a "$dest" "$bak" || true
    fi
}
restore_dir() {
    zipname="$1"; dest="$2"; src="$RESTORE_WORK/$zipname"
    [ -d "$src" ] || { echo_log "Skipped missing ZIP directory: $zipname"; return; }
    echo_log "Restore directory: $zipname -> $dest"
    backup_existing_path "$dest"
    if [ "$DRY_RUN" = "no" ]; then mkdir -p "$dest" || fail_exit "Could not create $dest"; cp -a "$src/." "$dest/" || fail_exit "Failed restoring $dest"; fi
}
restore_file() {
    zipname="$1"; dest="$2"; src="$RESTORE_WORK/$zipname"
    [ -f "$src" ] || { echo_log "Skipped missing ZIP file: $zipname"; return; }
    echo_log "Restore file: $zipname -> $dest"
    backup_existing_path "$dest"
    if [ "$DRY_RUN" = "no" ]; then mkdir -p "$(dirname "$dest")" || fail_exit "Could not create parent folder for $dest"; cp -a "$src" "$dest" || fail_exit "Failed restoring $dest"; fi
}
while IFS='|' read type src zipname dest; do
    case "$type" in ""|\#*) continue ;; esac
    [ -z "$dest" ] && dest="$src"
    [ "$type" = "DIR" ] && restore_dir "$zipname" "$dest"
    [ "$type" = "FILE" ] && restore_file "$zipname" "$dest"
done < "$TARGETS_FILE"
chmod +x /LWS_Backup/scripts/*.sh 2>/dev/null
[ "$DRY_RUN" = "yes" ] && echo_log "Dry-run restore completed. No files were changed." || echo_log "Restore completed. Reboot recommended."
rm -rf "$RESTORE_WORK"
exit 0
EOS
    chmod +x "$KIT_DIR/restore.sh"
}

create_restore_kit() {
    build_names
    echo_log "Creating restore kit..."
    mkdir -p "$KIT_DIR/backups" "$KIT_DIR/scripts" || fail_exit "Could not create restore kit folders"
    cp -f "$LATEST_BACKUP_FILE" "$KIT_DIR/backups/Backup_latest.zip" || fail_exit "Could not copy latest backup into restore kit"
    cp -f "$TARGETS_FILE" "$KIT_DIR/restore_targets.conf" || fail_exit "Could not copy targets file into restore kit"
    cp -f "$SELF_SCRIPT" "$KIT_DIR/scripts/lwsbackup.sh" 2>/dev/null || cp -f "$0" "$KIT_DIR/scripts/lwsbackup.sh"
    create_restore_script
    cat > "$KIT_DIR/restore_config.conf" <<EOC
VERSION="$VERSION"
HOSTNAME="$HOSTNAME"
CREATED="$DATESTAMP"
BACKUP_FILE="backups/Backup_latest.zip"
TARGETS_FILE="restore_targets.conf"
EOC
    cat > "$KIT_DIR/README_RESTORE.txt" <<EOR
LWSBackup Restore Kit
Created: $DATESTAMP
Host: $HOSTNAME
Generated by: LWSBackup v$VERSION

Restore instructions:
1. unzip Restore_kit_latest.zip
2. cd Restore_kit
3. sudo ./restore.sh --dry-run
4. sudo ./restore.sh
5. sudo reboot

Existing restore destinations are copied to .bak.YYYYMMDD-HHMMSS before overwrite.
EOR
    ( cd "$KIT_DIR" || exit 1; sha256sum backups/Backup_latest.zip > sha256sums.txt ) >> "$LOG_FILE" 2>&1
    echo_log "Zipping restore kit: $RESTORE_KIT_FILE"
    ( cd "$TMP_DIR" || exit 1; rm -rf "$TMP_DIR/Restore_kit"; mv "$KIT_DIR" "$TMP_DIR/Restore_kit"; zip -r "$RESTORE_KIT_FILE" "Restore_kit" ) >> "$LOG_FILE" 2>&1 || fail_exit "Restore kit zip failed"
    cp -f "$RESTORE_KIT_FILE" "$LATEST_RESTORE_KIT_FILE" || fail_exit "Could not update latest restore kit"
    echo_log "Restore kit created successfully."
}

# ---------------- FTP / cleanup / cron / profiles ---------------- #
upload_ftp() {
    load_config
    [ "$FTP_ENABLED" != "yes" ] && { echo_log "FTP disabled. Skipping upload."; return 0; }
    check_commands_optional
    [ -z "$FTP_SERVER" ] || [ -z "$FTP_USER" ] || [ -z "$FTP_PASSWORD" ] && { echo_log "FTP enabled but incomplete settings. Skipping upload."; return 1; }
    port="${FTP_PORT:-21}"; remote="${FTP_REMOTE_DIR:-/}"
    echo_log "Uploading backup and restore kit to FTP server..."
    curl -T "$BACKUP_FILE" -u "$FTP_USER:$FTP_PASSWORD" "ftp://$FTP_SERVER:$port$remote/" >> "$LOG_FILE" 2>&1 || { echo_log "FTP upload failed for backup."; return 1; }
    curl -T "$RESTORE_KIT_FILE" -u "$FTP_USER:$FTP_PASSWORD" "ftp://$FTP_SERVER:$port$remote/" >> "$LOG_FILE" 2>&1 || { echo_log "FTP upload failed for restore kit."; return 1; }
    echo_log "FTP upload completed."
}

configure_ftp_menu() {
    load_config
    yesno "FTP Upload" "Enable FTP upload?\n\nIf No, FTP stays saved as a disabled template." && FTP_ENABLED="yes" || FTP_ENABLED="no"
    FTP_SERVER="$(inputbox "FTP Server" "FTP server hostname or IP:" "${FTP_SERVER:-}")" || FTP_SERVER="${FTP_SERVER:-}"
    FTP_PORT="$(inputbox "FTP Port" "FTP port:" "${FTP_PORT:-21}")" || FTP_PORT="${FTP_PORT:-21}"
    FTP_USER="$(inputbox "FTP Username" "FTP username:" "${FTP_USER:-}")" || FTP_USER="${FTP_USER:-}"
    oldpw="${FTP_PASSWORD:-}"; newpw="$(passwordbox "FTP Password" "FTP password. Leave blank to keep existing password.")" || newpw=""
    [ -n "$newpw" ] && FTP_PASSWORD="$newpw" || FTP_PASSWORD="$oldpw"
    FTP_REMOTE_DIR="$(inputbox "FTP Remote Directory" "Remote FTP folder path:" "${FTP_REMOTE_DIR:-/}")" || FTP_REMOTE_DIR="${FTP_REMOTE_DIR:-/}"
    yesno "Delete Local After FTP?" "Delete timestamped local files after successful FTP upload?\n\nRecommended: No." && FTP_DELETE_LOCAL_AFTER_UPLOAD="yes" || FTP_DELETE_LOCAL_AFTER_UPLOAD="no"
    save_ftp_config
    msgbox "FTP Saved" "FTP settings saved.\n\nFTP Enabled: $FTP_ENABLED"
}

cleanup_old_files() {
    load_config
    echo_log "Cleaning old backups, restore kits, and logs..."
    find "$BACKUP_DIR" -name "*.zip" ! -name "Backup_latest.zip" -type f | sort | head -n -"$MAX_BACKUPS" | xargs -r rm --
    find "$RESTORE_KIT_DIR" -name "*.zip" ! -name "Restore_kit_latest.zip" -type f | sort | head -n -"$MAX_RESTORE_KITS" | xargs -r rm --
    find "$LOG_DIR" -name "*.log" -type f | sort | head -n -"$MAX_LOGS" | xargs -r rm --
}

view_logs_menu() {
    latest="$(ls -1t "$LOG_DIR"/*.log 2>/dev/null | head -n 1)"
    [ -z "$latest" ] && { msgbox "Logs" "No log files found."; return; }
    if check_dialog; then setup_dialog_theme; dialog_cmd --title "Latest Log: $(basename "$latest")" --textbox "$latest" 22 90; clear; else less "$latest"; fi
}

install_cron_if_missing() {
    command -v crontab >/dev/null 2>&1 && return 0
    if command -v pacman >/dev/null 2>&1; then pacman -Sy --noconfirm cronie; elif command -v apt-get >/dev/null 2>&1; then apt-get update -qq && apt-get install -y cron; elif command -v yum >/dev/null 2>&1; then yum install -y cronie; elif command -v dnf >/dev/null 2>&1; then dnf install -y cronie; fi
    command -v crontab >/dev/null 2>&1 || fail_exit "crontab is missing. Install cron/cronie manually."
}

remove_cron_job() {
    tmp="/tmp/lwsbackup_cron.$$"
    crontab -l 2>/dev/null | awk "/$CRON_MARKER_BEGIN/ {skip=1; next} /$CRON_MARKER_END/ {skip=0; next} skip != 1 {print}" > "$tmp"
    crontab "$tmp"; rm -f "$tmp"
}

add_cron_job() {
    expr="$1"; tmp="/tmp/lwsbackup_cron.$$"
    crontab -l 2>/dev/null | awk "/$CRON_MARKER_BEGIN/ {skip=1; next} /$CRON_MARKER_END/ {skip=0; next} skip != 1 {print}" > "$tmp"
    { echo "$CRON_MARKER_BEGIN"; echo "$expr /usr/local/sbin/lws-backup --run"; echo "$CRON_MARKER_END"; } >> "$tmp"
    crontab "$tmp"; rm -f "$tmp"
}

configure_cron_menu() {
    install_cron_if_missing
    if ! yesno "Cron Schedule" "Do you want LWSBackup to run automatically from cron?"; then remove_cron_job; msgbox "Cron" "Automatic cron job removed/disabled."; return; fi
    if check_dialog; then
        setup_dialog_theme
        sched="$(dialog_cmd --title "Cron Schedule" --menu "Choose backup schedule:" 16 76 6 "daily" "Every day" "weekly" "Every week" "monthly" "Monthly on the 1st" "custom" "Enter custom cron expression" 3>&1 1>&2 2>&3)"
        rc=$?; clear; [ $rc -eq 0 ] || return
    else echo "daily / weekly / monthly / custom"; read sched; fi
    if [ "$sched" = "custom" ]; then
        expr="$(inputbox "Custom Cron" "Enter full cron expression, example: 21 18 * * 5" "21 18 * * 5")" || return
    else
        hour="$(inputbox "Hour" "Hour in 24-hour format, 0-23:" "3")" || return
        minute="$(inputbox "Minute" "Minute, 0-59:" "0")" || return
        if [ "$sched" = "daily" ]; then expr="$minute $hour * * *"; elif [ "$sched" = "monthly" ]; then expr="$minute $hour 1 * *"; else dow="$(inputbox "Day of Week" "0=Sunday through 6=Saturday:" "5")" || return; expr="$minute $hour * * $dow"; fi
    fi
    add_cron_job "$expr"; msgbox "Cron Saved" "Cron job saved:\n\n$expr /usr/local/sbin/lws-backup --run"
}

configure_general_menu() {
    load_config
    newprefix="$(inputbox "Backup Name Prefix" "Backup ZIP prefix. Timestamp and hostname are added automatically:" "$BACKUP_PREFIX")" || return
    [ -n "$newprefix" ] && BACKUP_PREFIX="$(sanitize_name "$newprefix")"
    MAX_BACKUPS="$(inputbox "Max Backups" "How many timestamped backups to keep locally:" "$MAX_BACKUPS")" || true
    MAX_RESTORE_KITS="$(inputbox "Max Restore Kits" "How many timestamped restore kits to keep locally:" "$MAX_RESTORE_KITS")" || true
    MAX_LOGS="$(inputbox "Max Logs" "How many logs to keep:" "$MAX_LOGS")" || true
    save_config; msgbox "Settings Saved" "Settings saved."
}

profiles_menu() {
    while true; do
        load_config
        if check_dialog; then
            setup_dialog_theme
            choice="$(dialog_cmd --title "Profiles" --menu "Active profile: $ACTIVE_PROFILE\n\nProfiles are saved target/config snapshots." 18 78 7 "1" "Save current config as profile" "2" "Load profile" "3" "List profiles" "0" "Back" 3>&1 1>&2 2>&3)"
            rc=$?; clear; [ $rc -eq 0 ] || return
        else echo "1) Save profile  2) Load profile  3) List profiles  0) Back"; read choice; fi
        case "$choice" in
            1) name="$(inputbox "Save Profile" "Profile name:" "$HOSTNAME")" || continue; name="$(sanitize_name "$name")"; [ -z "$name" ] && continue; mkdir -p "$PROFILE_DIR/$name"; cp -f "$CONFIG_FILE" "$PROFILE_DIR/$name/lwsbackup.conf" 2>/dev/null; cp -f "$TARGETS_FILE" "$PROFILE_DIR/$name/targets.conf" 2>/dev/null; cp -f "$FTP_FILE" "$PROFILE_DIR/$name/ftp.conf" 2>/dev/null; ACTIVE_PROFILE="$name"; save_config; msgbox "Profile Saved" "Profile saved: $name" ;;
            2) names="$(find "$PROFILE_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null)"; [ -z "$names" ] && { msgbox "Profiles" "No profiles found."; continue; }; name="$(inputbox "Load Profile" "Enter profile name:\n\n$names" "$ACTIVE_PROFILE")" || continue; [ -d "$PROFILE_DIR/$name" ] || { msgbox "Profiles" "Profile not found: $name"; continue; }; cp -f "$PROFILE_DIR/$name/lwsbackup.conf" "$CONFIG_FILE" 2>/dev/null; cp -f "$PROFILE_DIR/$name/targets.conf" "$TARGETS_FILE" 2>/dev/null; cp -f "$PROFILE_DIR/$name/ftp.conf" "$FTP_FILE" 2>/dev/null; ACTIVE_PROFILE="$name"; save_config; msgbox "Profile Loaded" "Loaded profile: $name" ;;
            3) list="$(find "$PROFILE_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null)"; [ -z "$list" ] && list="No profiles found."; msgbox "Profiles" "$list" ;;
            0) return ;;
        esac
    done
}

restore_local_menu() {
    kit="$(inputbox "Restore Kit" "Enter path to Restore_kit zip or extracted Restore_kit folder:" "$RESTORE_KIT_DIR/Restore_kit_latest.zip")" || return
    if [ -d "$kit" ] && [ -x "$kit/restore.sh" ]; then yesno "Dry Run" "Run restore in dry-run mode first?" && "$kit/restore.sh" --dry-run || "$kit/restore.sh"; pause_text; return; fi
    if [ -f "$kit" ]; then
        tmprestore="$TMP_DIR/manual_restore_${DATESTAMP}"; mkdir -p "$tmprestore"; unzip -q "$kit" -d "$tmprestore" || { msgbox "Restore" "Could not unzip restore kit."; return; }
        if [ -x "$tmprestore/Restore_kit/restore.sh" ]; then yesno "Dry Run" "Run restore in dry-run mode first?" && "$tmprestore/Restore_kit/restore.sh" --dry-run || "$tmprestore/Restore_kit/restore.sh"; pause_text; else msgbox "Restore" "restore.sh was not found in that kit."; fi
        return
    fi
    msgbox "Restore" "File/folder not found:\n$kit"
}

install_self() {
    create_folders
    if [ "$0" != "$SELF_SCRIPT" ]; then cp -f "$0" "$SELF_SCRIPT" 2>/dev/null; chmod +x "$SELF_SCRIPT" 2>/dev/null; fi
    ln -sf "$SELF_SCRIPT" /usr/local/sbin/lws-backup
    echo_log "Installed/symlinked: /usr/local/sbin/lws-backup"
}

run_backup_job() {
    check_root; create_folders; initialize_defaults; make_lock; check_commands_core; check_commands_optional; install_self
    echo_log "Starting LWSBackup v$VERSION"
    create_backup; create_restore_kit; upload_ftp; cleanup_old_files; cleanup
    echo_log "Backup job completed."
    echo; echo "Backup complete."; echo "Backup: $BACKUP_FILE"; echo "Restore kit: $RESTORE_KIT_FILE"; echo "Latest backup: $LATEST_BACKUP_FILE"; echo "Latest restore kit: $LATEST_RESTORE_KIT_FILE"; echo
}

first_run_setup() {
    check_root; create_folders; initialize_defaults; install_dialog_if_possible; install_self
    msgbox "LWSBackup v$VERSION" "Welcome to LWSBackup setup.\n\nThe script will use /LWS_Backup for backups, restore kits, logs, scripts, config, and temporary files."
    configure_general_menu
    yesno "Backup Targets" "Do you want to add custom folders or files now?\n\nIf No, defaults remain:\n/srv/http\n/etc/asterisk\n/var/spool/cron/root" && configure_targets_menu
    yesno "FTP" "Do you want to configure FTP upload now?\n\nIf skipped, FTP remains disabled but the template config stays available." && configure_ftp_menu || { FTP_ENABLED="no"; save_ftp_config; }
    yesno "Cron" "Do you want to create an automatic cron schedule now?" && configure_cron_menu
    msgbox "Setup Complete" "Setup is complete.\n\nRun now:\n/usr/local/sbin/lws-backup --run\n\nOpen menu:\n/usr/local/sbin/lws-backup --menu"
}

main_menu() {
    check_root; create_folders; initialize_defaults; install_dialog_if_possible; install_self
    if ! check_dialog; then text_menu; return; fi
    while true; do
        load_config; setup_dialog_theme
        choice="$(dialog_cmd --title "LWSBackup v$VERSION" --menu "Host: $HOSTNAME\nRoot: $LWS_ROOT\nProfile: $ACTIVE_PROFILE\nFTP: $FTP_ENABLED\n\nChoose an option:" 22 76 12 \
            "1" "Run Backup Now" "2" "General Settings" "3" "Backup Targets" "4" "FTP Settings" "5" "Cron Schedule" "6" "Restore From Restore Kit" "7" "View Latest Log" "8" "Profiles" "9" "Run First-Time Setup Wizard" "0" "Exit" \
            3>&1 1>&2 2>&3)"
        rc=$?; clear; [ $rc -eq 0 ] || break
        case "$choice" in
            1) run_backup_job; pause_text ;; 2) configure_general_menu ;; 3) configure_targets_menu ;; 4) configure_ftp_menu ;; 5) configure_cron_menu ;; 6) restore_local_menu ;; 7) view_logs_menu ;; 8) profiles_menu ;; 9) first_run_setup ;; 0) break ;;
        esac
    done
    cleanup
}

text_menu() {
    while true; do
        clear; echo "LWSBackup v$VERSION"; echo "Host: $HOSTNAME"; echo; echo "1) Run Backup Now"; echo "2) General Settings"; echo "3) Backup Targets"; echo "4) FTP Settings"; echo "5) Cron Schedule"; echo "6) Restore From Restore Kit"; echo "7) View Latest Log"; echo "8) Profiles"; echo "9) First-Time Setup Wizard"; echo "0) Exit"; echo; printf "Choice: "; read choice
        case "$choice" in
            1) run_backup_job; pause_text ;; 2) configure_general_menu ;; 3) configure_targets_menu ;; 4) configure_ftp_menu ;; 5) configure_cron_menu ;; 6) restore_local_menu ;; 7) view_logs_menu ;; 8) profiles_menu ;; 9) first_run_setup ;; 0) break ;;
        esac
    done
}

usage() {
    cat <<EOH
LWSBackup v$VERSION

Usage:
  sudo $0 --menu        Open dialog/text menu
  sudo $0 --setup       Run first-time setup wizard
  sudo $0 --run         Run backup immediately
  sudo $0 --restore     Restore from latest restore kit using menu prompt
  sudo $0 --help        Show this help

No option opens menu when interactive, or runs backup when non-interactive.

Paths:
  Root:          $LWS_ROOT
  Backups:       $BACKUP_DIR
  Restore kits:  $RESTORE_KIT_DIR
  Logs:          $LOG_DIR
  Config:        $CONFIG_DIR
EOH
}

main() {
    case "$1" in
        --run) run_backup_job ;;
        --setup) first_run_setup ;;
        --menu) main_menu ;;
        --restore) restore_local_menu ;;
        --help|-h) usage ;;
        "") if [ -t 0 ]; then main_menu; else run_backup_job; fi ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
}

trap cleanup EXIT INT TERM
main "$@"
