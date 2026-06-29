# LWSBackup log viewer menu
view_logs_menu() {
    [ -z "$latest" ] && { msgbox "Logs" "No log files found."; return; }
    if has_dialog; then
        dialog_cmd --title "Latest Log: $(basename "$latest")" --textbox "$latest" 22 90
        clear_screen
    else
        less "$latest"
    fi
}
