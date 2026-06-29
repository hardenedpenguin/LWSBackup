# LWSBackup configuration load/save

config_load() {
    script_version="$VERSION"
    [ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"
    [ -f "$FTP_FILE" ] && . "$FTP_FILE"
    VERSION="$script_version"
    sanitize_runtime_settings
}

config_save() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" <<EOC
# LWSBackup configuration
# Script version is intentionally NOT stored here.
# The running script owns VERSION so old configs cannot downgrade the displayed version.
BACKUP_PREFIX="$BACKUP_PREFIX"
RESTORE_KIT_PREFIX="$RESTORE_KIT_PREFIX"
MAX_BACKUPS="$MAX_BACKUPS"
MAX_RESTORE_KITS="$MAX_RESTORE_KITS"
MAX_LOGS="$MAX_LOGS"
ACTIVE_PROFILE="$ACTIVE_PROFILE"
EOC
    chmod 600 "$CONFIG_FILE"
}

normalize_ftp_remote_dir() {
    remote="${1:-/}"
    [ -z "$remote" ] && remote="/"
    case "$remote" in
        */) printf '%s' "$remote" ;;
        *) printf '%s/' "$remote" ;;
    esac
}

ftp_save() {
    mkdir -p "$CONFIG_DIR"
    FTP_REMOTE_DIR="$(normalize_ftp_remote_dir "${FTP_REMOTE_DIR:-/}")"
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

initialize_defaults() {
    create_folders
    config_load
    sanitize_runtime_settings
    [ -f "$CONFIG_FILE" ] || config_save
    [ -f "$FTP_FILE" ] || ftp_save
    targets_ensure_file
}
