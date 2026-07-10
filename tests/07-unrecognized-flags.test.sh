#!/usr/bin/env bash
# Test: unrecognized flags/options produce useful errors

test_list_unrecognised_flag() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" list --bogus 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "skoll list --bogus should exit 1" || exit 1
  assert_contains "$output" "unrecognized" "should mention unrecognized" || exit 1
}

run_test "skoll list --bogus errors" test_list_unrecognised_flag

test_clean_unrecognised_flag() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" clean --bogus 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "skoll clean --bogus should exit 1" || exit 1
  assert_contains "$output" "unrecognized" "should mention unrecognized" || exit 1
}

run_test "skoll clean --bogus errors" test_clean_unrecognised_flag

test_add_unrecognised_flag() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" add --bogus 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "skoll add --bogus should exit 1" || exit 1
  assert_contains "$output" "unrecognized" "should mention unrecognized" || exit 1
}

run_test "skoll add --bogus errors" test_add_unrecognised_flag

test_update_unrecognised_flag() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" update --bogus 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "skoll update --bogus should exit 1" || exit 1
  assert_contains "$output" "unrecognized" "should mention unrecognized" || exit 1
}

run_test "skoll update --bogus errors" test_update_unrecognised_flag

test_get_unrecognised_flag() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" get --bogus 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "skoll get --bogus should exit 1" || exit 1
  assert_contains "$output" "unrecognized" "should mention unrecognized" || exit 1
}

run_test "skoll get --bogus errors" test_get_unrecognised_flag

test_rm_unrecognised_flag() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" rm --bogus 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "skoll rm --bogus should exit 1" || exit 1
  assert_contains "$output" "unrecognized" "should mention unrecognized" || exit 1
}

run_test "skoll rm --bogus errors" test_rm_unrecognised_flag
