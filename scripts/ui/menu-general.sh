# LWSBackup general settings menu
configure_general_menu() {
    config_load
    old_backup_prefix="$BACKUP_PREFIX"
    old_restore_prefix="$RESTORE_KIT_PREFIX"
    newprefix="$(inputbox "Backup Name Prefix" "Backup ZIP prefix. Timestamp and hostname are added automatically:" "$BACKUP_PREFIX")" || return
    [ -n "$newprefix" ] && BACKUP_PREFIX="$(sanitize_name "$newprefix")"
    newkitprefix="$(inputbox "Restore Kit Prefix" "Restore kit ZIP prefix. Timestamp and hostname are added automatically:" "$RESTORE_KIT_PREFIX")" || return
    [ -n "$newkitprefix" ] && RESTORE_KIT_PREFIX="$(sanitize_name "$newkitprefix")"
    MAX_BACKUPS="$(inputbox "Max Backups" "How many timestamped backups to keep locally:" "$MAX_BACKUPS")" || true
    MAX_RESTORE_KITS="$(inputbox "Max Restore Kits" "How many timestamped restore kits to keep locally:" "$MAX_RESTORE_KITS")" || true
    MAX_LOGS="$(inputbox "Max Logs" "How many logs to keep:" "$MAX_LOGS")" || true
    sanitize_runtime_settings
    if [ "$BACKUP_PREFIX" != "$old_backup_prefix" ]; then
        rm -f "$BACKUP_DIR/${old_backup_prefix}_latest.zip"
    fi
    if [ "$RESTORE_KIT_PREFIX" != "$old_restore_prefix" ]; then
        rm -f "$RESTORE_KIT_DIR/${old_restore_prefix}_latest.zip"
    fi
    config_save
    msgbox "Settings Saved" "Settings saved."
}
