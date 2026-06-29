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
