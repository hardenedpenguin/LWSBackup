# LWSBackup retention cleanup
cleanup_old_files() {
    config_load
    build_names
    echo_log "Cleaning old backups, restore kits, and logs..."
    find "$BACKUP_DIR" -name "*.zip" ! -name "$LATEST_BACKUP_NAME" -type f | sort | head -n -"$MAX_BACKUPS" | xargs -r rm --
    find "$RESTORE_KIT_DIR" -name "*.zip" ! -name "$LATEST_RESTORE_KIT_NAME" -type f | sort | head -n -"$MAX_RESTORE_KITS" | xargs -r rm --
    find "$LOG_DIR" -name "*.log" -type f | sort | head -n -"$MAX_LOGS" | xargs -r rm --
}
