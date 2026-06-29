# LWSBackup string/terminal utilities
# Clear the terminal without polluting command-substitution output.
clear_screen() {
    if [ -t 1 ]; then
        clear >/dev/tty 2>/dev/null || clear >&2
    fi
}

clean_number() {
    value="$(echo "$1" | tr -cd '0-9')"
    default="$2"
    [ -z "$value" ] && value="$default"
    echo "$value"
}

strip_ansi_sequences() {
    esc="$(printf '\033')"
    printf '%s' "$1" | sed "s/${esc}\[[0-9;?]*[A-Za-z]//g"
}

sanitize_name() {
    strip_ansi_sequences "$1" | tr ' ' '_' | tr -cd '[:alnum:]_.-'
}

sanitize_runtime_settings() {
    MAX_BACKUPS="$(clean_number "$MAX_BACKUPS" 4)"
    MAX_RESTORE_KITS="$(clean_number "$MAX_RESTORE_KITS" 4)"
    MAX_LOGS="$(clean_number "$MAX_LOGS" 10)"
    FTP_PORT="$(clean_number "$FTP_PORT" 21)"

    BACKUP_PREFIX="$(sanitize_name "$BACKUP_PREFIX")"
    RESTORE_KIT_PREFIX="$(sanitize_name "$RESTORE_KIT_PREFIX")"
    ACTIVE_PROFILE="$(sanitize_name "$ACTIVE_PROFILE")"

    [ -z "$BACKUP_PREFIX" ] && BACKUP_PREFIX="Backup"
    [ -z "$RESTORE_KIT_PREFIX" ] && RESTORE_KIT_PREFIX="Restore_kit"
    [ -z "$ACTIVE_PROFILE" ] && ACTIVE_PROFILE="default"
    return 0
}
