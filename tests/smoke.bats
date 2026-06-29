#!/usr/bin/env bats

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
