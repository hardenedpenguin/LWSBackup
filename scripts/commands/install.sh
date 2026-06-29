# LWSBackup --install
install_mode() {
    check_commands_core

    echo
    echo "LWSBackup v$VERSION installed."
    echo "Script location: $SELF_SCRIPT"
    echo "Command: /usr/local/sbin/lws-backup"
    echo

    if [ -t 0 ]; then
        if yesno "LWSBackup Install" "Install complete. Run the first-time setup wizard now?"; then
            run_setup_wizard
        else
            msgbox "Install Complete" "Install complete.

Run setup later with:
/usr/local/sbin/lws-backup --setup

Open menu with:
/usr/local/sbin/lws-backup --menu"
        fi
    fi
}
