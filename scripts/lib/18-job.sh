# LWSBackup backup job lifecycle (non-interactive; safe for cron --run)

job_prepare() {
    check_root
    create_folders
    initialize_defaults
    refresh_job_paths
    make_lock
    check_commands_core
    check_commands_optional
}

job_run() {
    echo_log "Starting LWSBackup v$VERSION"
    create_backup
    create_restore_kit
    verify_archives
    JOB_FTP_RC=0
    upload_ftp || JOB_FTP_RC=$?
}

job_finalize() {
    cleanup_old_files
    cleanup
    echo_log "Backup job completed."
    echo
    echo "Backup complete."
    echo "Backup: $BACKUP_FILE"
    echo "Restore kit: $RESTORE_KIT_FILE"
    echo "Latest backup: $LATEST_BACKUP_FILE"
    echo "Latest restore kit: $LATEST_RESTORE_KIT_FILE"
    if [ "${JOB_FTP_RC:-0}" -ne 0 ]; then
        echo_log "WARNING: Backup completed but FTP upload failed or was skipped."
        echo "Warning: FTP upload failed or was skipped. Local archives were kept."
    fi
    echo
}

run_backup_job() {
    job_prepare
    job_run
    job_finalize
}
