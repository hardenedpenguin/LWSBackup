# LWSBackup backup engine
create_backup_metadata() {
    mkdir -p "$WORK_DIR/system" "$WORK_DIR/logs"
    {
        echo "LWSBackup Version: $VERSION"
        echo "Created: $DATESTAMP"
        echo "Hostname: $HOSTNAME"
        echo "Backup Prefix: $BACKUP_PREFIX"
        echo "Restore Kit Prefix: $RESTORE_KIT_PREFIX"
        echo "Active Profile: $ACTIVE_PROFILE"
        echo
        echo "Targets:"
        cat "$TARGETS_FILE"
    } > "$WORK_DIR/system/backup_info.txt"
    cp /etc/os-release "$WORK_DIR/system/os-release.txt" 2>/dev/null
    hostname > "$WORK_DIR/system/hostname.txt" 2>/dev/null
    uname -a > "$WORK_DIR/system/uname.txt" 2>/dev/null
    crontab -l > "$WORK_DIR/system/root-crontab.txt" 2>/dev/null
    if command -v ip >/dev/null 2>&1; then
        ip addr > "$WORK_DIR/system/network.txt" 2>/dev/null
    elif command -v ifconfig >/dev/null 2>&1; then
        ifconfig -a > "$WORK_DIR/system/network.txt" 2>/dev/null
    fi
    cp "$LOG_FILE" "$WORK_DIR/logs/backup.log" 2>/dev/null
}

copy_target_entry() {
    type="$1"
    src="$2"
    zipname="$3"

    case "$type" in
        DIR)
            [ -d "$src" ] || { echo_log "Skipped missing directory: $src"; return 1; }
            ;;
        FILE)
            [ -f "$src" ] || { echo_log "Skipped missing file: $src"; return 1; }
            ;;
        *)
            return 1
            ;;
    esac

    if [ -e "$WORK_DIR/$zipname" ]; then
        echo_log "WARNING: ZIP name collision for $zipname (source: $src). Skipping to avoid overwrite."
        return 1
    fi

    cp -a "$src" "$WORK_DIR/$zipname" || fail_exit "Failed copying $src"
    echo_log "Added $type: $src -> $zipname"
    return 0
}

backup_targets() {
    copied=0
    echo_log "Creating backup workspace..."
    mkdir -p "$WORK_DIR" || fail_exit "Could not create work directory"
    echo_log "Collecting backup targets..."
    [ ! -f "$TARGETS_FILE" ] && targets_ensure_file

    while IFS='|' read -r type src zipname dest; do
        case "$type" in
            ""|\#*) continue ;;
        esac
        [ -z "$src" ] && continue
        [ -z "$zipname" ] && zipname="$(basename "$src")"
        if copy_target_entry "$type" "$src" "$zipname"; then
            copied=$((copied + 1))
        fi
    done < "$TARGETS_FILE"

    [ "$copied" -eq 0 ] && fail_exit "No backup targets were found or copied. Add targets with: sudo lws-backup --menu"
    create_backup_metadata
}

create_backup() {
    build_names
    backup_targets
    echo_log "Creating backup zip: $BACKUP_FILE"
    ( cd "$WORK_DIR" || exit 1; zip -r "$BACKUP_FILE" . ) >> "$LOG_FILE" 2>&1 || fail_exit "Backup zip failed"
    cp -f "$BACKUP_FILE" "$LATEST_BACKUP_FILE" || fail_exit "Could not update latest backup"
    echo_log "Backup created successfully."
}
