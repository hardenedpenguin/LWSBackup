# LWSBackup FTP settings menu
configure_ftp_menu() {
    config_load
    yesno "FTP Upload" "Enable FTP upload?\n\nIf No, FTP stays saved as a disabled template." && FTP_ENABLED="yes" || FTP_ENABLED="no"
    FTP_SERVER="$(inputbox "FTP Server" "FTP server hostname or IP:" "${FTP_SERVER:-}")" || FTP_SERVER="${FTP_SERVER:-}"
    FTP_PORT="$(inputbox "FTP Port" "FTP port:" "${FTP_PORT:-21}")" || FTP_PORT="${FTP_PORT:-21}"
    FTP_USER="$(inputbox "FTP Username" "FTP username:" "${FTP_USER:-}")" || FTP_USER="${FTP_USER:-}"
    oldpw="${FTP_PASSWORD:-}"
    newpw="$(passwordbox "FTP Password" "FTP password. Leave blank to keep existing password.")" || newpw=""
    [ -n "$newpw" ] && FTP_PASSWORD="$newpw" || FTP_PASSWORD="$oldpw"
    FTP_REMOTE_DIR="$(inputbox "FTP Remote Directory" "Remote FTP folder path:" "${FTP_REMOTE_DIR:-/}")" || FTP_REMOTE_DIR="${FTP_REMOTE_DIR:-/}"
    FTP_REMOTE_DIR="$(normalize_ftp_remote_dir "${FTP_REMOTE_DIR:-/}")"
    yesno "Delete Local After FTP?" "Delete timestamped local files after successful FTP upload?\n\nRecommended: No." && FTP_DELETE_LOCAL_AFTER_UPLOAD="yes" || FTP_DELETE_LOCAL_AFTER_UPLOAD="no"
    ftp_save
    msgbox "FTP Saved" "FTP settings saved.\n\nFTP Enabled: $FTP_ENABLED"
}
