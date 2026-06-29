# LWSBackup backup target CRUD (no UI dependencies)

targets_clear_error() {
    TARGET_LAST_ERROR=""
}

targets_set_error() {
    TARGET_LAST_ERROR="$1"
}

targets_ensure_file() {
    if [ ! -f "$TARGETS_FILE" ]; then
        cat > "$TARGETS_FILE" <<'EOT'
# LWSBackup target list
# Format: TYPE|SOURCE|ZIP_NAME|RESTORE_DESTINATION
# TYPE: DIR or FILE
# Add targets from: sudo lws-backup --menu -> Backup Targets
EOT
        chmod 600 "$TARGETS_FILE"
    fi
}

targets_apply_legacy_defaults() {
    cat > "$TARGETS_FILE" <<'EOT'
# LWSBackup target list
# Format: TYPE|SOURCE|ZIP_NAME|RESTORE_DESTINATION
# TYPE: DIR or FILE
DIR|/srv/http|HTTP|/srv/http
DIR|/etc/asterisk|Asterisk|/etc/asterisk
FILE|/var/spool/cron/root|root|/var/spool/cron/root
EOT
    chmod 600 "$TARGETS_FILE"
}

targets_list_text() {
    [ ! -f "$TARGETS_FILE" ] && { echo "No targets file found."; return; }
    awk -F'|' '/^[[:space:]]*#/ {next} NF >= 4 {printf "- %-4s %-30s -> %-18s restore: %s\n", $1, $2, $3, $4}' "$TARGETS_FILE"
}

targets_list_for_removal() {
    awk -F'|' '/^[[:space:]]*#/ {next} NF >= 4 {printf "%d) %-4s %s\n", ++i, $1, $2}' "$TARGETS_FILE"
}

targets_count() {
    awk -F'|' '/^[[:space:]]*#/ {next} NF >= 4 {++c} END {print c+0}' "$TARGETS_FILE"
}

targets_exists() {
    type="$1"
    src="$2"
    awk -F'|' -v t="$type" -v s="$src" '
        /^[[:space:]]*#/ {next}
        NF >= 4 && $1 == t && $2 == s {found=1}
        END {exit found ? 0 : 1}
    ' "$TARGETS_FILE"
}

targets_zipname_exists() {
    zipname="$1"
    awk -F'|' -v z="$zipname" '
        /^[[:space:]]*#/ {next}
        NF >= 4 && $3 == z {found=1}
        END {exit found ? 0 : 1}
    ' "$TARGETS_FILE"
}

targets_normalize_fields() {
    type="$1"
    src="$2"
    zipname="$3"
    dest="$4"

    [ -z "$zipname" ] && zipname="$(basename "$src")"
    [ -z "$dest" ] && dest="$src"
    zipname="$(sanitize_name "$zipname")"
    [ -z "$zipname" ] && zipname="$(basename "$src")"

    TARGETS_NORM_TYPE="$type"
    TARGETS_NORM_SRC="$src"
    TARGETS_NORM_ZIPNAME="$zipname"
    TARGETS_NORM_DEST="$dest"
}

targets_validate_add() {
    type="$1"
    src="$2"
    zipname="$3"
    dest="$4"

    targets_clear_error
    [ -z "$src" ] && { targets_set_error "missing_source"; return 1; }
    case "$type" in
        DIR|FILE) ;;
        *) targets_set_error "invalid_type"; return 1 ;;
    esac
    if targets_exists "$type" "$src"; then
        targets_set_error "duplicate_target|${type}|${src}"
        return 1
    fi
    case "$type" in
        DIR)
            if [ ! -d "$src" ]; then
                targets_set_error "missing_directory|${src}"
                return 1
            fi
            ;;
        FILE)
            if [ ! -f "$src" ]; then
                targets_set_error "missing_file|${src}"
                return 1
            fi
            ;;
    esac

    targets_normalize_fields "$type" "$src" "$zipname" "$dest"
    if targets_zipname_exists "$TARGETS_NORM_ZIPNAME"; then
        targets_set_error "duplicate_zipname|${TARGETS_NORM_ZIPNAME}"
        return 1
    fi
    return 0
}

targets_add() {
    type="$1"
    src="$2"
    zipname="$3"
    dest="$4"

    targets_validate_add "$type" "$src" "$zipname" "$dest" || return 1
    echo "${TARGETS_NORM_TYPE}|${TARGETS_NORM_SRC}|${TARGETS_NORM_ZIPNAME}|${TARGETS_NORM_DEST}" >> "$TARGETS_FILE"
    chmod 600 "$TARGETS_FILE" 2>/dev/null
}

targets_remove_by_index() {
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
