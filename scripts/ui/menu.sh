# LWSBackup main menu loop
handle_menu_choice() {
    case "$1" in
        1) run_backup_job; pause_text ;;
        2) configure_general_menu ;;
        3) configure_targets_menu ;;
        4) configure_ftp_menu ;;
        5) configure_cron_menu ;;
        6) restore_local_menu ;;
        7) view_logs_menu ;;
        8) profiles_menu ;;
        9) run_setup_wizard ;;
        0) return 1 ;;
    esac
    return 0
}

run_menu_loop() {
    while true; do
        config_load
        if has_dialog; then
            choice="$(dialog_cmd --title "LWSBackup v$VERSION" --menu "Host: $HOSTNAME\nRoot: $LWS_ROOT\nProfile: $ACTIVE_PROFILE\nFTP: $FTP_ENABLED\n\nChoose an option:" 22 76 12 \
                "1" "Run Backup Now" \
                "2" "General Settings" \
                "3" "Backup Targets" \
                "4" "FTP Settings" \
                "5" "Cron Schedule" \
                "6" "Restore From Restore Kit" \
                "7" "View Latest Log" \
                "8" "Profiles" \
                "9" "Run First-Time Setup Wizard" \
                "0" "Exit" \
                3>&1 1>&2 2>&3)"
            rc=$?
            clear_screen
            [ $rc -eq 0 ] || break
        else
            clear_screen
            echo "LWSBackup v$VERSION"
            echo "Host: $HOSTNAME"
            echo
            echo "1) Run Backup Now"
            echo "2) General Settings"
            echo "3) Backup Targets"
            echo "4) FTP Settings"
            echo "5) Cron Schedule"
            echo "6) Restore From Restore Kit"
            echo "7) View Latest Log"
            echo "8) Profiles"
            echo "9) First-Time Setup Wizard"
            echo "0) Exit"
            echo
            printf "Choice: "
            read choice
        fi
        handle_menu_choice "$choice" || break
    done
}
