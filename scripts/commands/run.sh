# LWSBackup --run
run_backup_job() {
    create_folders
    initialize_defaults
    refresh_job_paths
    make_lock
    check_commands_core
    check_commands_optional
    echo_log "Starting LWSBackup v$VERSION"
    create_backup
    create_restore_kit
    verify_archives
    ftp_rc=0
    upload_ftp || ftp_rc=$?
    cleanup_old_files
    cleanup
    echo_log "Backup job completed."
    echo
    echo "Backup complete."
    echo "Backup: $BACKUP_FILE"
    echo "Restore kit: $RESTORE_KIT_FILE"
    echo "Latest backup: $LATEST_BACKUP_FILE"
    echo "Latest restore kit: $LATEST_RESTORE_KIT_FILE"
    if [ "$ftp_rc" -ne 0 ]; then
        echo_log "WARNING: Backup completed but FTP upload failed or was skipped."
        echo "Warning: FTP upload failed or was skipped. Local archives were kept."
    fi
    echo
}
