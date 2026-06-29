# Shared setup for LWSBackup bats tests.

LWS_SCRIPT_ROOT="$(cd "${BATS_TEST_DIRNAME}/../scripts" && pwd)"

lws_test_source_libs() {
    # shellcheck disable=SC1090
    . "$LWS_SCRIPT_ROOT/lib/01-version.sh"
    . "$LWS_SCRIPT_ROOT/lib/02-paths.sh"
    . "$LWS_SCRIPT_ROOT/lib/04-util.sh"
    . "$LWS_SCRIPT_ROOT/lib/06-config.sh"
    . "$LWS_SCRIPT_ROOT/lib/08-targets.sh"
    . "$LWS_SCRIPT_ROOT/lib/09-names.sh"
}

lws_test_init_paths() {
    LWS_TEST_ROOT="$(mktemp -d "${BATS_TMPDIR:-/tmp}/lwsbackup-bats.XXXXXX")"
    LWS_ROOT="$LWS_TEST_ROOT"
    SCRIPT_DIR="$LWS_ROOT/scripts"
    BACKUP_DIR="$LWS_ROOT/backups"
    RESTORE_KIT_DIR="$LWS_ROOT/restore_kits"
    LOG_DIR="$LWS_ROOT/logs"
    TMP_DIR="$LWS_ROOT/tmp"
    CONFIG_DIR="$LWS_ROOT/config"
    PROFILE_DIR="$CONFIG_DIR/profiles"
    CONFIG_FILE="$CONFIG_DIR/lwsbackup.conf"
    TARGETS_FILE="$CONFIG_DIR/targets.conf"
    FTP_FILE="$CONFIG_DIR/ftp.conf"
    mkdir -p "$CONFIG_DIR" "$TMP_DIR" "$BACKUP_DIR"
    TARGET_LAST_ERROR=""
}

setup() {
    lws_test_source_libs
    lws_test_init_paths
}

teardown() {
    [ -n "${LWS_TEST_ROOT:-}" ] && rm -rf "$LWS_TEST_ROOT"
}
