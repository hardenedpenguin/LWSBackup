# LWSBackup backup targets menu
configure_targets_menu() {
    while true; do
        current="$(list_targets_text)"
        [ -z "$current" ] && current="No targets configured."
        if has_dialog; then
            choice="$(dialog_cmd --title "Backup Targets" --menu "Current targets:\n\n$current\n\nChoose an action:" 24 84 9 \
                "1" "Add folder target" \
                "2" "Add file target" \
                "3" "Remove target" \
                "4" "Show help / instructions" \
                "5" "Edit targets.conf manually" \
                "6" "Reset to default targets" \
                "7" "Show targets file path" \
                "0" "Back" \
                3>&1 1>&2 2>&3)"
            rc=$?
            clear_screen
            [ $rc -eq 0 ] || return
        else
            echo "$current"
            echo "1) Add folder target"
            echo "2) Add file target"
            echo "3) Remove target"
            echo "4) Show help / instructions"
            echo "5) Edit targets.conf manually"
            echo "6) Reset defaults"
            echo "7) Show path"
            echo "0) Back"
            read choice
        fi
        case "$choice" in
            1) prompt_add_target "DIR" "Folder" ;;
            2) prompt_add_target "FILE" "File" ;;
            3) remove_target_menu ;;
            4) show_targets_help ;;
            5) edit_targets_file ;;
            6)
                if yesno "Reset Targets" "Reset backup targets to HamVOIP/AllStar defaults?"; then
                    create_legacy_default_targets
                    msgbox "Reset" "Targets reset to legacy defaults."
                fi
                ;;
            7) msgbox "Targets File" "$TARGETS_FILE" ;;
            0) return ;;
        esac
    done
}
