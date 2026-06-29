# LWSBackup profile helpers
list_profile_names() {
    find "$PROFILE_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null
}
