#!/usr/bin/env bash
# Test: install.sh

test_install_creates_structure() {
  local output exit_code
  output=$(bash "$ROOT_DIR/install.sh" 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "install.sh should exit 0" || exit 1

  # Directory structure
  assert_dir "$HOME/.skoll"            "~/.skoll should exist" || exit 1
  assert_dir "$HOME/.skoll/bin"        "~/.skoll/bin should exist" || exit 1
  assert_dir "$HOME/.skoll/stowed"     "~/.skoll/stowed should exist" || exit 1

  # skoll executable
  assert_file "$HOME/.skoll/bin/skoll" "~/.skoll/bin/skoll should exist" || exit 1
  assert_executable "$HOME/.skoll/bin/skoll" "~/.skoll/bin/skoll should be executable" || exit 1

  # Config file
  assert_file "$HOME/.skoll/skoll.ini" "~/.skoll/skoll.ini should exist" || exit 1
  local ini_content
  ini_content=$(cat "$HOME/.skoll/skoll.ini")
  assert_contains "$ini_content" "local_skills_dir" "skoll.ini should contain local_skills_dir" || exit 1
  assert_contains "$ini_content" "fallback" "skoll.ini should contain fallback" || exit 1

  # Git repo initialized
  assert_dir "$HOME/.skoll/stowed/.git" "~/.skoll/stowed should be a git repo" || exit 1

  # PATH instructions
  assert_contains "$output" "PATH" "output should mention PATH" || exit 1
}

test_install_no_git() {
  local output exit_code
  output=$(bash "$ROOT_DIR/install.sh" --no-git 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "install.sh --no-git should exit 0" || exit 1
  assert_dir "$HOME/.skoll" "~/.skoll should exist" || exit 1
  assert_dir "$HOME/.skoll/stowed" "~/.skoll/stowed should exist" || exit 1
  assert_not_dir "$HOME/.skoll/stowed/.git" "~/.skoll/stowed should NOT be a git repo" || exit 1
}

test_install_idempotent() {
  # Running install.sh twice should be safe
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1 || true
  local output2 exit_code2
  output2=$(bash "$ROOT_DIR/install.sh" 2>&1) || exit_code2=$?
  exit_code2="${exit_code2:-0}"
  assert_exit_code "$exit_code2" 0 "second run should exit 0" || exit 1
  assert_file "$HOME/.skoll/bin/skoll" "skoll should still exist after 2nd run" || exit 1
  assert_dir "$HOME/.skoll/stowed/.git" "git repo should still exist after 2nd run" || exit 1
}

test_install_fails_on_missing_dep() {
  local sandbox="$SKOLL_TEST_TMPDIR/sandbox"
  mkdir -p "$sandbox"

  for tool in bash git grep cp mkdir ln rm cat chmod mktemp head dirname; do
    local tpath
    tpath=$(command -v "$tool" 2>/dev/null || true)
    if [ -n "$tpath" ]; then
      ln -s "$tpath" "$sandbox/$tool"
    fi
  done
  rm -f "$sandbox/stow" "$sandbox/fzf"

  local output exit_code
  output=$(PATH="$sandbox" bash "$ROOT_DIR/install.sh" 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "install.sh should exit 1 when stow and fzf are missing" || exit 1
  assert_contains "$output" "GNU stow" "output should mention stow is missing" || exit 1
  assert_contains "$output" "fzf" "output should mention fzf is missing" || exit 1
}

run_test "install.sh creates ~/.skoll/ structure" test_install_creates_structure
run_test "install.sh --no-git skips git init" test_install_no_git
run_test "install.sh is idempotent" test_install_idempotent
run_test "install.sh fails when dependencies missing" test_install_fails_on_missing_dep
