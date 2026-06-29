# LWSBackup logging and exit helpers
echo_log() {
    msg="$1"
    echo "$msg"
    mkdir -p "$LOG_DIR" 2>/dev/null
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $msg" >> "$LOG_FILE" 2>/dev/null
}

cleanup() {
    rm -rf "$WORK_DIR" "$KIT_DIR" "$DIALOGRC_FILE" 2>/dev/null
    rm -f "$LOCK_FILE" 2>/dev/null
}

fail_exit() {
    echo_log "ERROR: $1"
    cleanup
    exit 1
}

pause_text() {
    echo
    echo "Press ENTER to continue..."
    read dummy
}
