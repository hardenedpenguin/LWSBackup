# LWSBackup archive verification
verify_zip_file() {
    zipfile="$1"
    label="$2"
    [ -f "$zipfile" ] || fail_exit "$label not found for verification: $zipfile"
    echo_log "Verifying $label: $zipfile"
    unzip -t "$zipfile" >> "$LOG_FILE" 2>&1 || fail_exit "$label failed ZIP integrity test"
    echo_log "$label verified successfully."
}

verify_archives() {
    verify_zip_file "$BACKUP_FILE" "Backup ZIP"
    verify_zip_file "$RESTORE_KIT_FILE" "Restore kit ZIP"
}
