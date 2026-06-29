#!/usr/bin/env bats

@test "targets_validate_add rejects invalid type" {
    targets_ensure_file
    run targets_validate_add "LINK" "/tmp" "tmp" "/tmp"
    [ "$status" -eq 1 ]
    [ "$TARGET_LAST_ERROR" = "invalid_type" ]
}

@test "targets_validate_add rejects duplicate target" {
    targets_ensure_file
    sample_dir="$LWS_TEST_ROOT/dup"
    mkdir -p "$sample_dir"
    targets_add "DIR" "$sample_dir" "dup" "$sample_dir"
    run targets_validate_add "DIR" "$sample_dir" "dup2" "$sample_dir"
    [ "$status" -eq 1 ]
    [[ "$TARGET_LAST_ERROR" == duplicate_target|* ]]
}

@test "targets_apply_legacy_defaults writes HamVOIP paths" {
    targets_apply_legacy_defaults
    grep -q '/srv/http' "$TARGETS_FILE"
    grep -q '/etc/asterisk' "$TARGETS_FILE"
    grep -q '/var/spool/cron/root' "$TARGETS_FILE"
}

@test "config_load preserves script VERSION over config file" {
    cat > "$CONFIG_FILE" <<'EOC'
BACKUP_PREFIX="FromFile"
RESTORE_KIT_PREFIX="FromKit"
MAX_BACKUPS="3"
MAX_RESTORE_KITS="3"
MAX_LOGS="5"
ACTIVE_PROFILE="fromfile"
EOC
  cat > "$FTP_FILE" <<'EOF'
FTP_ENABLED="no"
FTP_DELETE_LOCAL_AFTER_UPLOAD="no"
EOF
    config_load
    [ "$VERSION" = "17" ]
    [ "$BACKUP_PREFIX" = "FromFile" ]
}
