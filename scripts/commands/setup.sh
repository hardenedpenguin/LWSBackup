# LWSBackup --setup / setup wizard
run_setup_wizard() {
    msgbox "LWSBackup v$VERSION" "Welcome to LWSBackup setup.\n\nThe script will use /LWS_Backup for backups, restore kits, logs, scripts, config, and temporary files."
    configure_general_menu
    if yesno "Default Targets" "Install default HamVOIP/AllStar targets?\n\n/srv/http\n/etc/asterisk\n/var/spool/cron/root\n\nIf No, add targets manually later."; then
        targets_apply_legacy_defaults
    fi
    if yesno "Backup Targets" "Do you want to add more custom folders or files now?"; then
        configure_targets_menu
    fi
    if yesno "FTP" "Do you want to configure FTP upload now?\n\nIf skipped, FTP remains disabled but the template config stays available."; then
        configure_ftp_menu
    else
        FTP_ENABLED="no"
        ftp_save
    fi
    if yesno "Cron" "Do you want to create an automatic cron schedule now?"; then
        configure_cron_menu
    fi
    msgbox "Setup Complete" "Setup is complete.\n\nRun now:\n/usr/local/sbin/lws-backup --run\n\nOpen menu:\n/usr/local/sbin/lws-backup --menu"
}

first_run_setup() {
    prepare_interactive_session
    run_setup_wizard
}
