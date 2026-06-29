# LWSBackup backup target CRUD
list_targets_text() {
    [ ! -f "$TARGETS_FILE" ] && { echo "No targets file found."; return; }
    awk -F'|' '/^[[:space:]]*#/ {next} NF >= 4 {printf "- %-4s %-30s -> %-18s restore: %s\n", $1, $2, $3, $4}' "$TARGETS_FILE"
}

list_targets_for_removal() {
    awk -F'|' '/^[[:space:]]*#/ {next} NF >= 4 {printf "%d) %-4s %s\n", ++i, $1, $2}' "$TARGETS_FILE"
}

count_targets() {
    awk -F'|' '/^[[:space:]]*#/ {next} NF >= 4 {++c} END {print c+0}' "$TARGETS_FILE"
}

target_exists() {
    type="$1"
    src="$2"
    awk -F'|' -v t="$type" -v s="$src" '
        /^[[:space:]]*#/ {next}
        NF >= 4 && $1 == t && $2 == s {found=1}
        END {exit found ? 0 : 1}
    ' "$TARGETS_FILE"
}

zipname_exists() {
    zipname="$1"
    awk -F'|' -v z="$zipname" '
        /^[[:space:]]*#/ {next}
        NF >= 4 && $3 == z {found=1}
        END {exit found ? 0 : 1}
    ' "$TARGETS_FILE"
}

validate_target_path() {
    type="$1"
    src="$2"
    case "$type" in
        DIR)
            if [ ! -d "$src" ]; then
                msgbox "Path Not Found" "Directory not found:\n$src\n\nTarget was not added."
                return 1
            fi
            ;;
        FILE)
            if [ ! -f "$src" ]; then
                msgbox "Path Not Found" "File not found:\n$src\n\nTarget was not added."
                return 1
            fi
            ;;
        *)
            msgbox "Invalid Type" "Target type must be DIR or FILE."
            return 1
            ;;
    esac
    return 0
}

add_target() {
    type="$1"
    src="$2"
    zipname="$3"
    dest="$4"

    [ -z "$src" ] && return 1
    case "$type" in
        DIR|FILE) ;;
        *) return 1 ;;
    esac
    if target_exists "$type" "$src"; then
        msgbox "Duplicate Target" "This target already exists:\n$type | $src"
        return 1
    fi
    validate_target_path "$type" "$src" || return 1

    [ -z "$zipname" ] && zipname="$(basename "$src")"
    [ -z "$dest" ] && dest="$src"
    zipname="$(sanitize_name "$zipname")"
    [ -z "$zipname" ] && zipname="$(basename "$src")"
    if zipname_exists "$zipname"; then
        msgbox "Duplicate ZIP Name" "Another target already uses ZIP name:\n$zipname\n\nChoose a different ZIP name."
        return 1
    fi

    echo "${type}|${src}|${zipname}|${dest}" >> "$TARGETS_FILE"
    chmod 600 "$TARGETS_FILE" 2>/dev/null
}

remove_target_by_index() {
    index="$1"
    tmp="$TMP_DIR/targets_edit.$$"
    awk -F'|' -v n="$index" '
        /^[[:space:]]*#/ {print; next}
        NF < 4 {print; next}
        {++i; if (i != n) print}
    ' "$TARGETS_FILE" > "$tmp" || return 1
    mv "$tmp" "$TARGETS_FILE"
    chmod 600 "$TARGETS_FILE"
}

prompt_add_target() {
    type="$1"
    label="$2"
    src="$(inputbox "Add $label" "Enter path to back up:" "")" || return
    zipname="$(inputbox "ZIP Name" "Name inside the backup ZIP:" "$(basename "$src")")" || return
    dest="$(inputbox "Restore Destination" "Restore destination path:" "$src")" || return
    if add_target "$type" "$src" "$zipname" "$dest"; then
        msgbox "Added" "$label target added."
    fi
}

remove_target_menu() {
    list="$(list_targets_for_removal)"
    max="$(count_targets)"
    [ -z "$list" ] || [ "$max" -eq 0 ] && { msgbox "Remove Target" "No targets to remove."; return; }
    pick="$(inputbox "Remove Target" "Enter target number to remove (1-$max):\n\n$list" "")" || return
    pick="$(clean_number "$pick" "")"
    [ -z "$pick" ] && return
    if [ "$pick" -lt 1 ] || [ "$pick" -gt "$max" ]; then
        msgbox "Invalid Selection" "Enter a number from 1 to $max."
        return
    fi
    if yesno "Confirm Remove" "Remove target #$pick?"; then
        remove_target_by_index "$pick"
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
