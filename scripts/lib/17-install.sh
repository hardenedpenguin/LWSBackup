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

modular_scripts_ready() {
    [ -d "${LWS_SCRIPT_ROOT}/lib" ] && [ -f "${LWS_SCRIPT_ROOT}/templates/restore.sh" ]
}

upgrade_modular_tree_if_needed() {
    [ -d "$SCRIPT_DIR/lib" ] && [ -x "$SCRIPT_DIR/lws-backup" ] && return 0
    if modular_scripts_ready; then
        echo_log "Upgrading LWSBackup to modular script layout under $SCRIPT_DIR"
        install_script_tree
        return 0
    fi
    fail_exit "Modular LWSBackup files are missing. Re-install from a full checkout: sudo ./lws-backup --install"
}

install_self() {
    create_folders
    case "$0" in
        "$SCRIPT_DIR/lws-backup"|"$SELF_SCRIPT"|/usr/local/sbin/lws-backup|/usr/local/bin/lws-backup)
            upgrade_modular_tree_if_needed
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

session_prepare_minimal() {
    check_root
    create_folders
    initialize_defaults
    if ! modular_scripts_ready; then
        fail_exit "LWSBackup modular scripts are not available. Run: sudo lws-backup --install"
    fi
    ensure_command_optional dialog dialog || true
    init_ui
}

prepare_interactive_session() {
    # Dialog, install, and config bootstrap for --menu, --install, and --setup.
    [ "$SESSION_PREPARED" -eq 1 ] && return 0
    session_prepare_minimal
    install_self
    SESSION_PREPARED=1
}
