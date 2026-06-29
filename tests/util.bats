#!/usr/bin/env bats

@test "clean_number keeps digits and applies default" {
    [ "$(clean_number "abc12x3" 9)" = "123" ]
    [ "$(clean_number "" 7)" = "7" ]
    [ "$(clean_number "no-digits" 4)" = "4" ]
}

@test "sanitize_name strips spaces and unsafe characters" {
    [ "$(sanitize_name "My Backup")" = "My_Backup" ]
    [ "$(sanitize_name "hosts.conf")" = "hosts.conf" ]
}

@test "sanitize_name strips ANSI clear contamination" {
    esc="$(printf '\033')"
    dirty="${esc}[3J${esc}[H${esc}[2JBackup"
    [ "$(sanitize_name "$dirty")" = "Backup" ]
}

@test "sanitize_runtime_settings repairs contaminated backup prefix" {
    esc="$(printf '\033')"
    BACKUP_PREFIX="${esc}[3J${esc}[H${esc}[2JBackup"
    RESTORE_KIT_PREFIX="Restore_kit"
    MAX_BACKUPS=4
    MAX_RESTORE_KITS=4
    MAX_LOGS=10
    ACTIVE_PROFILE="default"
    FTP_PORT=21
    sanitize_runtime_settings
    [ "$BACKUP_PREFIX" = "Backup" ]
    [ "$RESTORE_KIT_PREFIX" = "Restore_kit" ]
}

@test "sanitize_runtime_settings coerces numeric settings" {
    MAX_BACKUPS="abc2def"
    MAX_RESTORE_KITS="9"
    MAX_LOGS=""
    FTP_PORT="not-a-port"
    BACKUP_PREFIX="Backup"
    RESTORE_KIT_PREFIX="Restore_kit"
    ACTIVE_PROFILE="default"
    sanitize_runtime_settings
    [ "$MAX_BACKUPS" = "2" ]
    [ "$MAX_RESTORE_KITS" = "9" ]
    [ "$MAX_LOGS" = "10" ]
    [ "$FTP_PORT" = "21" ]
}
