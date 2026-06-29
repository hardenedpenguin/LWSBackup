# LWSBackup cron schedule menu
configure_cron_menu() {
    if ! yesno "Cron Schedule" "Do you want LWSBackup to run automatically from cron?"; then
        remove_cron_job
        msgbox "Cron" "Automatic cron job removed/disabled."
        return
    fi
    if has_dialog; then
        sched="$(dialog_cmd --title "Cron Schedule" --menu "Choose backup schedule:" 16 76 6 \
            "daily" "Every day" \
            "weekly" "Every week" \
            "monthly" "Monthly on the 1st" \
            "custom" "Enter custom cron expression" \
            3>&1 1>&2 2>&3)"
        rc=$?
        clear_screen
        [ $rc -eq 0 ] || return
    else
        echo "daily / weekly / monthly / custom"
        read sched
    fi
    if [ "$sched" = "custom" ]; then
        expr="$(inputbox "Custom Cron" "Enter full cron expression, example: 21 18 * * 5" "21 18 * * 5")" || return
    else
        hour="$(inputbox "Hour" "Hour in 24-hour format, 0-23:" "3")" || return
        minute="$(inputbox "Minute" "Minute, 0-59:" "0")" || return
        case "$sched" in
            daily) expr="$minute $hour * * *" ;;
            monthly) expr="$minute $hour 1 * *" ;;
            *)
                dow="$(inputbox "Day of Week" "0=Sunday through 6=Saturday:" "5")" || return
                expr="$minute $hour * * $dow"
                ;;
        esac
    fi
    add_cron_job "$expr"
    msgbox "Cron Saved" "Cron job saved:\n\n$expr /usr/local/sbin/lws-backup --run"
}
