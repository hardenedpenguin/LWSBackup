# LWSBackup backup targets menu

targets_error_title() {
    case "$TARGET_LAST_ERROR" in
        duplicate_target|*) echo "Duplicate Target" ;;
        duplicate_zipname|*) echo "Duplicate ZIP Name" ;;
        missing_directory|*) echo "Path Not Found" ;;
        missing_file|*) echo "Path Not Found" ;;
        invalid_type) echo "Invalid Type" ;;
        *) echo "Target Error" ;;
    esac
}

targets_error_message() {
    case "$TARGET_LAST_ERROR" in
        duplicate_target|*)
            details="${TARGET_LAST_ERROR#duplicate_target|}"
            type="${details%%|*}"
            src="${details#*|}"
            printf 'This target already exists:\n%s | %s' "$type" "$src"
            ;;
        duplicate_zipname|*)
            zipname="${TARGET_LAST_ERROR#duplicate_zipname|}"
            printf 'Another target already uses ZIP name:\n%s\n\nChoose a different ZIP name.' "$zipname"
            ;;
        missing_directory|*)
            src="${TARGET_LAST_ERROR#missing_directory|}"
            printf 'Directory not found:\n%s\n\nTarget was not added.' "$src"
            ;;
        missing_file|*)
            src="${TARGET_LAST_ERROR#missing_file|}"
            printf 'File not found:\n%s\n\nTarget was not added.' "$src"
            ;;
        invalid_type)
            echo "Target type must be DIR or FILE."
            ;;
        *)
            echo "Could not add target."
            ;;
    esac
}

targets_show_add_error() {
    [ -z "$TARGET_LAST_ERROR" ] && return 0
    msgbox "$(targets_error_title)" "$(targets_error_message)"
}

prompt_add_target() {
    type="$1"
    label="$2"
    src="$(inputbox "Add $label" "Enter path to back up:" "")" || return
    zipname="$(inputbox "ZIP Name" "Name inside the backup ZIP:" "$(basename "$src")")" || return
    dest="$(inputbox "Restore Destination" "Restore destination path:" "$src")" || return
    if targets_add "$type" "$src" "$zipname" "$dest"; then
        msgbox "Added" "$label target added."
    else
        targets_show_add_error
    fi
}

remove_target_menu() {
    list="$(targets_list_for_removal)"
    max="$(targets_count)"
    [ -z "$list" ] || [ "$max" -eq 0 ] && { msgbox "Remove Target" "No targets to remove."; return; }
    pick="$(inputbox "Remove Target" "Enter target number to remove (1-$max):\n\n$list" "")" || return
    pick="$(clean_number "$pick" "")"
    [ -z "$pick" ] && return
    if [ "$pick" -lt 1 ] || [ "$pick" -gt "$max" ]; then
        msgbox "Invalid Selection" "Enter a number from 1 to $max."
        return
    fi
    if yesno "Confirm Remove" "Remove target #$pick?"; then
        targets_remove_by_index "$pick"
        msgbox "Removed" "Target removed."
    fi
}

targets_help_text() {
    cat <<'EOHELP'
Backup targets tell LWSBackup what to save and where to restore it later.

Current optional HamVOIP/AllStar default targets:

  /srv/http
  /etc/asterisk
  /var/spool/cron/root

These are offered during first-time setup. You are not required to use them.

Targets are saved in:

  /LWS_Backup/config/targets.conf

Format:

  TYPE|SOURCE|ZIP_NAME|RESTORE_DESTINATION

TYPE can be:

  DIR   for a folder
  FILE  for a single file

Examples:

  DIR|/opt/myapp|myapp|/opt/myapp
  FILE|/etc/hosts|hosts|/etc/hosts

SOURCE is the real folder/file on the machine.
ZIP_NAME is what it will be called inside the backup ZIP.
RESTORE_DESTINATION is where restore.sh will put it back.

Recommended way:

  Main Menu -> Backup Targets -> Add folder/file target
  Main Menu -> Backup Targets -> Remove target

That avoids typing the pipe-separated format manually.
EOHELP
}

show_targets_help() {
    msgbox "Backup Target Help" "$(targets_help_text)"
}

edit_targets_file() {
    editor="${EDITOR:-vi}"
    "$editor" "$TARGETS_FILE"
}

configure_targets_menu() {
    while true; do
        current="$(targets_list_text)"
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
                    targets_apply_legacy_defaults
                    msgbox "Reset" "Targets reset to legacy defaults."
                fi
                ;;
            7) msgbox "Targets File" "$TARGETS_FILE" ;;
            0) return ;;
        esac
    done
}
