# LWSBackup self-install

install_script_tree() {
    src_root="${LWS_SCRIPT_ROOT}"
    dest_root="$SCRIPT_DIR"
    mkdir -p "$dest_root/lib" "$dest_root/ui" "$dest_root/templates" "$dest_root/commands" || \
        fail_exit "Could not create script directories under $dest_root"

    for subdir in lib ui templates commands; do
        if [ -d "$src_root/$subdir" ]; then
            cp -a "$src_root/$subdir/." "$dest_root/$subdir/" 2>/dev/null || \
                fail_exit "Could not copy $subdir to $dest_root/$subdir"
        fi
    done

    cp -f "$src_root/lws-backup" "$dest_root/lws-backup" 2>/dev/null || \
        fail_exit "Could not copy lws-backup to $dest_root"
    chmod +x "$dest_root/lws-backup" 2>/dev/null || fail_exit "Could not make lws-backup executable"

    cat > "$dest_root/lwsbackup.sh" <<'EOW'
#!/bin/bash
# Compatibility wrapper — delegates to modular lws-backup entrypoint.
exec "$(cd "$(dirname "$0")" && pwd)/lws-backup" "$@"
EOW
    chmod +x "$dest_root/lwsbackup.sh"
}

install_self() {
    create_folders
    case "$0" in
        "$SCRIPT_DIR/lws-backup"|"$SELF_SCRIPT"|/usr/local/sbin/lws-backup|/usr/local/bin/lws-backup)
            [ -f "$SCRIPT_DIR/lws-backup" ] || fail_exit "Installed entrypoint is missing: $SCRIPT_DIR/lws-backup"
            ;;
        *)
            install_script_tree
            ;;
    esac
    ln -sf "$SCRIPT_DIR/lws-backup" /usr/local/sbin/lws-backup || fail_exit "Could not create symlink /usr/local/sbin/lws-backup"
    mkdir -p /usr/local/bin 2>/dev/null
    ln -sf "$SCRIPT_DIR/lws-backup" /usr/local/bin/lws-backup 2>/dev/null
    echo_log "Installed/symlinked: /usr/local/sbin/lws-backup"
}

prepare_interactive_session() {
    [ "$SESSION_PREPARED" -eq 1 ] && return 0
    check_root
    create_folders
    initialize_defaults
    ensure_command_optional dialog dialog || true
    init_ui
    install_self
    SESSION_PREPARED=1
}
