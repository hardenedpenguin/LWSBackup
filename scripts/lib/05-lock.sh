# LWSBackup root check, folders, lock, job paths
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root."
        exit 1
    fi
}

create_folders() {
    mkdir -p "$SCRIPT_DIR" "$BACKUP_DIR" "$RESTORE_KIT_DIR" "$LOG_DIR" "$TMP_DIR" "$CONFIG_DIR" "$PROFILE_DIR" || {
        echo "Could not create $LWS_ROOT folders."
        exit 1
    }
}

make_lock() {
    if [ -f "$LOCK_FILE" ]; then
        oldpid="$(cat "$LOCK_FILE" 2>/dev/null)"
        if [ -n "$oldpid" ] && kill -0 "$oldpid" 2>/dev/null; then
            fail_exit "Another LWSBackup job appears to be running. Lock: $LOCK_FILE"
        fi
    fi
    echo "$$" > "$LOCK_FILE"
}

# Fresh timestamps for each backup job (menu sessions can stay open a long time).
refresh_job_paths() {
    DATESTAMP="$(date +%Y%m%d-%H%M%S)"
    LOG_FILE="$LOG_DIR/lwsbackup_v${VERSION}_${DATESTAMP}.log"
    WORK_DIR="$TMP_DIR/work_${DATESTAMP}"
    KIT_FOLDER_NAME="${RESTORE_KIT_PREFIX:-Restore_kit}"
    KIT_DIR="$TMP_DIR/${KIT_FOLDER_NAME}_${DATESTAMP}"
}
