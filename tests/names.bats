#!/usr/bin/env bats

@test "build_names honors custom prefixes" {
    BACKUP_PREFIX="SiteBackup"
    RESTORE_KIT_PREFIX="SiteKit"
    HOSTNAME="test-node"
    DATESTAMP="20260101-120000"
    build_names
    [ "$BACKUP_NAME" = "SiteBackup_test-node_20260101-120000.zip" ]
    [ "$LATEST_BACKUP_NAME" = "SiteBackup_latest.zip" ]
    [ "$LATEST_RESTORE_KIT_NAME" = "SiteKit_latest.zip" ]
    [ "$KIT_BACKUP_PATH" = "backups/SiteBackup_latest.zip" ]
    [ "$KIT_FOLDER_NAME" = "SiteKit" ]
}
