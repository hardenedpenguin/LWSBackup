# LWSBackup FTP upload
upload_ftp() {
    load_config
    sanitize_runtime_settings
    [ "$FTP_ENABLED" != "yes" ] && { echo_log "FTP disabled. Skipping upload."; return 0; }
    check_commands_optional
    if [ -z "$FTP_SERVER" ] || [ -z "$FTP_USER" ] || [ -z "$FTP_PASSWORD" ]; then
        echo_log "FTP enabled but incomplete settings. Skipping upload."
        return 1
    fi
    port="${FTP_PORT:-21}"
    remote="$(normalize_ftp_remote_dir "${FTP_REMOTE_DIR:-/}")"
    echo_log "Uploading backup and restore kit to FTP server..."
    curl -T "$BACKUP_FILE" -u "$FTP_USER:$FTP_PASSWORD" "ftp://$FTP_SERVER:$port$remote/" >> "$LOG_FILE" 2>&1 || {
        echo_log "FTP upload failed for backup."
        return 1
    }
    curl -T "$RESTORE_KIT_FILE" -u "$FTP_USER:$FTP_PASSWORD" "ftp://$FTP_SERVER:$port$remote/" >> "$LOG_FILE" 2>&1 || {
        echo_log "FTP upload failed for restore kit."
        return 1
    }
    echo_log "FTP upload completed."
    if [ "$FTP_DELETE_LOCAL_AFTER_UPLOAD" = "yes" ]; then
        echo_log "Deleting timestamped local archives after successful FTP upload..."
        rm -f "$BACKUP_FILE" "$RESTORE_KIT_FILE"
    fi
}
