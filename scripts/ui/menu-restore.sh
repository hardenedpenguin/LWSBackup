# LWSBackup restore from kit menu
run_restore_script() {
    check_root
    if yesno "Dry Run" "Run restore in dry-run mode first?"; then
        if ! "$script" --dry-run; then
            msgbox "Restore" "Dry-run failed. Live restore was NOT started."
            return 1
        fi
        if ! yesno "Continue Restore" "Dry-run finished.\n\nProceed with live restore?"; then
            return 0
        fi
    fi
    if ! "$script"; then
        msgbox "Restore" "Restore failed. Check restore.log in the kit folder."
        return 1
    fi
    return 0
}

find_restore_script_in_tree() {
    base="$1"
    find "$base" -maxdepth 3 -name restore.sh -type f -executable 2>/dev/null | head -n 1
}

restore_local_menu() {
    check_root
    create_folders
    initialize_defaults
    init_ui
    build_names
    kit="$(inputbox "Restore Kit" "Enter path to restore kit zip or extracted folder:" "$LATEST_RESTORE_KIT_FILE")" || return
    if [ -d "$kit" ] && [ -x "$kit/restore.sh" ]; then
        run_restore_script "$kit/restore.sh"
        pause_text
        return
    fi
    if [ -f "$kit" ]; then
        tmprestore="$TMP_DIR/manual_restore_$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$tmprestore"
        unzip -q "$kit" -d "$tmprestore" || { msgbox "Restore" "Could not unzip restore kit."; return; }
        script="$(find_restore_script_in_tree "$tmprestore")"
        if [ -n "$script" ]; then
            run_restore_script "$script"
            pause_text
        else
            msgbox "Restore" "restore.sh was not found in that kit."
        fi
        return
    fi
    msgbox "Restore" "File/folder not found:\n$kit"
}
