#!/usr/bin/env bats

@test "restore template substitutes build-time placeholders" {
    template="$LWS_SCRIPT_ROOT/templates/restore.sh"
    output="$(sed \
        -e 's|@LWS_VERSION@|17|g' \
        -e 's|@KIT_BACKUP_PATH@|backups/SiteBackup_latest.zip|g' \
        -e 's|@LWS_ROOT@|/LWS_Backup|g' \
        "$template")"
    [[ "$output" == *"LWSBackup v17"* ]]
    [[ "$output" == *'BACKUP_ZIP="$KIT_DIR/backups/SiteBackup_latest.zip"'* ]]
    [[ "$output" == *'LWS_ROOT="/LWS_Backup"'* ]]
}
