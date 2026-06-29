#!/usr/bin/env bats

load 'test_helper'

@test "targets_ensure_file creates empty targets.conf" {
    targets_ensure_file
    [ -f "$TARGETS_FILE" ]
    grep -q "TYPE|SOURCE|ZIP_NAME|RESTORE_DESTINATION" "$TARGETS_FILE"
}

@test "targets_add rejects missing directory" {
    targets_ensure_file
    set +e
    targets_add "DIR" "/no/such/path" "missing" "/no/such/path"
    status=$?
    set -e
    [ "$status" -eq 1 ]
    [ "$TARGET_LAST_ERROR" = "missing_directory|/no/such/path" ]
}

@test "targets_add and targets_count accept valid directory" {
    targets_ensure_file
    sample_dir="$LWS_TEST_ROOT/sample_data"
    mkdir -p "$sample_dir"
    targets_add "DIR" "$sample_dir" "sample" "$sample_dir"
    [ "$?" -eq 0 ]
    [ "$(targets_count)" = "1" ]
    targets_exists "DIR" "$sample_dir"
}

@test "targets_add rejects duplicate zip name" {
    targets_ensure_file
    one="$LWS_TEST_ROOT/one"
    two="$LWS_TEST_ROOT/two"
    mkdir -p "$one" "$two"
    targets_add "DIR" "$one" "samezip" "$one"
    set +e
    targets_add "DIR" "$two" "samezip" "$two"
    status=$?
    set -e
    [ "$status" -eq 1 ]
    [[ "$TARGET_LAST_ERROR" == duplicate_zipname* ]]
}

@test "targets_remove_by_index removes selected target" {
    targets_ensure_file
    dir="$LWS_TEST_ROOT/removable"
    mkdir -p "$dir"
    targets_add "DIR" "$dir" "rem" "$dir"
    [ "$(targets_count)" = "1" ]
    targets_remove_by_index 1
    [ "$(targets_count)" = "0" ]
}
