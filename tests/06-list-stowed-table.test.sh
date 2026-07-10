#!/usr/bin/env bash
# Test: skoll list --stowed table format

test_list_stowed_table_header() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  # Setup: a manually added skill directly in stowed/
  mkdir -p "$HOME/.skoll/stowed/my-skill"
  touch "$HOME/.skoll/stowed/my-skill/SKILL.md"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" list --stowed 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll list --stowed should exit 0" || exit 1
  # Check table header (with any whitespace padding)
  assert_contains "$output" "name" "should have 'name' in header" || exit 1
  assert_contains "$output" "subfolder" "should have 'subfolder' in header" || exit 1
  assert_contains "$output" "source" "should have 'source' in header" || exit 1
  # Check separator
  assert_contains "$output" "---" "should have separator row" || exit 1
  # Check data row
  assert_contains "$output" "my-skill" "should contain skill name" || exit 1
  assert_contains "$output" "_none_" "subfolder should be _none_" || exit 1
  assert_contains "$output" "local" "source should be local" || exit 1
}

run_test "skoll list --stowed shows table with header, separator, and data" test_list_stowed_table_header

test_list_stowed_skill_in_subdirectory() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  # Setup: a skill inside a category subdirectory of stowed/
  mkdir -p "$HOME/.skoll/stowed/my-engineering-skills/skill-1"
  touch "$HOME/.skoll/stowed/my-engineering-skills/skill-1/SKILL.md"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" list --stowed 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll list --stowed should exit 0" || exit 1
  assert_contains "$output" "skill-1" "should contain skill name" || exit 1
  assert_contains "$output" "my-engineering-skills" "subfolder should be my-engineering-skills" || exit 1
  assert_contains "$output" "local" "source should be local" || exit 1
  # _none_ should NOT appear for this case
  assert_not_contains "$output" "_none_" "should not have _none_ subfolder" || exit 1
}

run_test "skoll list --stowed shows skill in subdirectory" test_list_stowed_skill_in_subdirectory

test_list_stowed_git_submodule_skills() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  # Setup: simulate a git submodule at stowed/authorstr/repo-name/
  # A git submodule has a .git FILE (not directory) with a gitdir: pointer
  local submodule_dir="$HOME/.skoll/stowed/authorstr/repo-name"
  mkdir -p "$submodule_dir"
  echo "gitdir: ../../.git/modules/authorstr/repo-name" > "$submodule_dir/.git"

  # Skill at the repo root
  mkdir -p "$submodule_dir/root-skill"
  touch "$submodule_dir/root-skill/SKILL.md"

  # Skill nested in a subdirectory of the repo
  mkdir -p "$submodule_dir/subdir/nested-skill"
  touch "$submodule_dir/subdir/nested-skill/SKILL.md"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" list --stowed 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll list --stowed should exit 0" || exit 1

  # Root-level skill: subfolder=_none_, source=authorstr/repo-name
  assert_contains "$output" "root-skill" "should contain root-skill" || exit 1
  assert_contains "$output" "authorstr/repo-name" "source should be authorstr/repo-name" || exit 1

  # Nested skill: subfolder=subdir, source=authorstr/repo-name
  assert_contains "$output" "nested-skill" "should contain nested-skill" || exit 1
  assert_contains "$output" "subdir" "subfolder should be subdir" || exit 1
}

run_test "skoll list --stowed shows git submodule skills" test_list_stowed_git_submodule_skills

test_list_stowed_empty() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" list --stowed 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll list --stowed should exit 0" || exit 1
  assert_eq "$output" "" "output should be empty when no stowed skills" || exit 1
}

run_test "skoll list --stowed empty when no stowed skills" test_list_stowed_empty
