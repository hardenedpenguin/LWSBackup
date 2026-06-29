#!/usr/bin/env bats

load 'test_helper'

@test "normalize_ftp_remote_dir ensures trailing slash" {
    [ "$(normalize_ftp_remote_dir "/backups")" = "/backups/" ]
    [ "$(normalize_ftp_remote_dir "/backups/")" = "/backups/" ]
    [ "$(normalize_ftp_remote_dir "")" = "/" ]
}

@test "config_save and config_load round-trip prefixes" {
    BACKUP_PREFIX="MyBackup"
    RESTORE_KIT_PREFIX="MyKit"
    MAX_BACKUPS=6
    config_save
    BACKUP_PREFIX="changed"
    config_load
    [ "$BACKUP_PREFIX" = "MyBackup" ]
    [ "$RESTORE_KIT_PREFIX" = "MyKit" ]
    [ "$MAX_BACKUPS" = "6" ]
}

@test "ftp_save normalizes remote directory" {
    FTP_ENABLED="yes"
    FTP_REMOTE_DIR="/remote"
    ftp_save
    [ "$FTP_REMOTE_DIR" = "/remote/" ]
    [ -f "$FTP_FILE" ]
}
