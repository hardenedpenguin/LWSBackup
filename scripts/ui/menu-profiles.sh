# LWSBackup profiles menu
profiles_menu() {
    while true; do
        config_load
        if has_dialog; then
            choice="$(dialog_cmd --title "Profiles" --menu "Active profile: $ACTIVE_PROFILE\n\nProfiles are saved target/config snapshots." 18 78 7 \
                "1" "Save current config as profile" \
                "2" "Load profile" \
                "3" "List profiles" \
                "0" "Back" \
                3>&1 1>&2 2>&3)"
            rc=$?
            clear_screen
            [ $rc -eq 0 ] || return
        else
            echo "1) Save profile  2) Load profile  3) List profiles  0) Back"
            read choice
        fi
        case "$choice" in
            1)
                name="$(inputbox "Save Profile" "Profile name:" "$HOSTNAME")" || continue
                name="$(sanitize_name "$name")"
                [ -z "$name" ] && continue
                mkdir -p "$PROFILE_DIR/$name"
                cp -f "$CONFIG_FILE" "$PROFILE_DIR/$name/lwsbackup.conf" 2>/dev/null
                cp -f "$TARGETS_FILE" "$PROFILE_DIR/$name/targets.conf" 2>/dev/null
                cp -f "$FTP_FILE" "$PROFILE_DIR/$name/ftp.conf" 2>/dev/null
                ACTIVE_PROFILE="$name"
                config_save
                msgbox "Profile Saved" "Profile saved: $name"
                ;;
            2)
                names="$(list_profile_names)"
                [ -z "$names" ] && { msgbox "Profiles" "No profiles found."; continue; }
                name="$(inputbox "Load Profile" "Enter profile name:\n\n$names" "$ACTIVE_PROFILE")" || continue
                [ -d "$PROFILE_DIR/$name" ] || { msgbox "Profiles" "Profile not found: $name"; continue; }
                cp -f "$PROFILE_DIR/$name/lwsbackup.conf" "$CONFIG_FILE" 2>/dev/null
                cp -f "$PROFILE_DIR/$name/targets.conf" "$TARGETS_FILE" 2>/dev/null
                cp -f "$PROFILE_DIR/$name/ftp.conf" "$FTP_FILE" 2>/dev/null
                ACTIVE_PROFILE="$name"
                config_save
                msgbox "Profile Loaded" "Loaded profile: $name"
                ;;
            3)
                list="$(list_profile_names)"
                [ -z "$list" ] && list="No profiles found."
                msgbox "Profiles" "$list"
                ;;
            0) return ;;
        esac
    done
}
