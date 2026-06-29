#!/usr/bin/env bats

load 'test_helper'

@test "repo wrapper runs --help" {
    run "$BATS_TEST_DIRNAME/../lws-backup" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"LWSBackup v"* ]]
    [[ "$output" == *"--install"* ]]
}

@test "repo wrapper reports version" {
    run "$BATS_TEST_DIRNAME/../lws-backup" --version
    [ "$status" -eq 0 ]
    [ "$output" = "LWSBackup 17" ]
}

@test "entrypoint works when invoked through a symlink" {
    root="$(mktemp -d "${BATS_TMPDIR:-/tmp}/lwsbackup-symlink.XXXXXX")"
    mkdir -p "$root/sbin"
    cp -a "$BATS_TEST_DIRNAME/../scripts" "$root/scripts"
    ln -sf "$root/scripts/lws-backup" "$root/sbin/lws-backup"
    run "$root/sbin/lws-backup" --version
    [ "$status" -eq 0 ]
    [ "$output" = "LWSBackup 17" ]
    rm -rf "$root"
}
