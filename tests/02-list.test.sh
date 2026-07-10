#!/usr/bin/env bash
# Test: skoll list, skoll list --stowed, skoll search

# Helper: set up a project directory inside the test temp dir
# and cd into it so skoll resolves skills relative to it.
setup_project_dir() {
  local project_dir="$SKOLL_TEST_TMPDIR/project"
  mkdir -p "$project_dir"
  cd "$project_dir"
}

setup_skills_dir() {
  local project_dir="$SKOLL_TEST_TMPDIR/project"
  mkdir -p "$project_dir/.agents/skills"
}

test_list_empty() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" list 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll list should exit 0" || exit 1
  assert_eq "$output" "" "output should be empty when no local skills" || exit 1
}

test_list_with_local_skills() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir

  # Setup: create a stowed skill
  mkdir -p "$HOME/.skoll/stowed/my-repo/my-skill"
  touch "$HOME/.skoll/stowed/my-repo/my-skill/SKILL.md"

  # Setup: create local skills dir and symlink
  mkdir -p "$SKOLL_TEST_TMPDIR/project/.agents/skills"
  ln -s "$HOME/.skoll/stowed/my-repo/my-skill" "$SKOLL_TEST_TMPDIR/project/.agents/skills/my-skill"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" list 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll list should exit 0" || exit 1
  assert_contains "$output" "./.agents/skills/" "output should contain directory header" || exit 1
  assert_contains "$output" "    my-skill" "output should contain indented skill name" || exit 1
}

test_list_stowed_empty() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" list --stowed 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll list --stowed should exit 0" || exit 1
  assert_eq "$output" "" "output should be empty when no stowed skills" || exit 1
}

test_list_stowed_shows_skills() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  # Setup: create stowed skills in two repos
  mkdir -p "$HOME/.skoll/stowed/repo-a/skill-one"
  touch "$HOME/.skoll/stowed/repo-a/skill-one/SKILL.md"
  mkdir -p "$HOME/.skoll/stowed/repo-a/skill-two"
  touch "$HOME/.skoll/stowed/repo-a/skill-two/SKILL.md"
  mkdir -p "$HOME/.skoll/stowed/repo-b/other-skill"
  touch "$HOME/.skoll/stowed/repo-b/other-skill/SKILL.md"

  # A non-skill directory at repo root (should be ignored)
  mkdir -p "$HOME/.skoll/stowed/repo-b/README.md"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" list --stowed 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll list --stowed should exit 0" || exit 1
  # Check table headers exist
  assert_contains "$output" "name" "should have name column" || exit 1
  assert_contains "$output" "subfolder" "should have subfolder column" || exit 1
  assert_contains "$output" "source" "should have source column" || exit 1
  # Check skill names appear
  assert_contains "$output" "skill-one" "should show skill-one" || exit 1
  assert_contains "$output" "skill-two" "should show skill-two" || exit 1
  assert_contains "$output" "other-skill" "should show other-skill" || exit 1
  # Check subfolder (parent dir) info
  assert_contains "$output" "repo-a" "should show repo-a as subfolder" || exit 1
  assert_contains "$output" "repo-b" "should show repo-b as subfolder" || exit 1
  # Check source
  assert_contains "$output" "local" "source should be local" || exit 1
  assert_not_contains "$output" "README.md" "non-skill files should be ignored" || exit 1
}

test_list_stowed_collisions() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  # Setup: same skill name in two different repos
  mkdir -p "$HOME/.skoll/stowed/repo-alpha/common-skill"
  touch "$HOME/.skoll/stowed/repo-alpha/common-skill/SKILL.md"
  mkdir -p "$HOME/.skoll/stowed/repo-beta/common-skill"
  touch "$HOME/.skoll/stowed/repo-beta/common-skill/SKILL.md"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" list --stowed 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll list --stowed should exit 0" || exit 1
  # Both should appear with their subfolder disambiguation
  assert_contains "$output" "common-skill" "should show common-skill name" || exit 1
  assert_contains "$output" "repo-alpha" "should show repo-alpha as subfolder" || exit 1
  assert_contains "$output" "repo-beta" "should show repo-beta as subfolder" || exit 1
}

test_list_broken_skill() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir

  # Setup: local skills dir with a broken symlink
  mkdir -p "$SKOLL_TEST_TMPDIR/project/.agents/skills"
  ln -s "$HOME/.skoll/stowed/removed-repo/broken-skill" "$SKOLL_TEST_TMPDIR/project/.agents/skills/broken-skill"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" list 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll list should exit 0" || exit 1
  # Should indicate the skill is broken
  assert_contains "$output" "./.agents/skills/" "output should contain directory header" || exit 1
  assert_contains "$output" "    broken-skill [broken]" "output should indicate broken skill" || exit 1
}

test_search_with_pattern() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  # Setup: create stowed skills in two repos
  mkdir -p "$HOME/.skoll/stowed/repo-alpha/my-skill"
  touch "$HOME/.skoll/stowed/repo-alpha/my-skill/SKILL.md"
  mkdir -p "$HOME/.skoll/stowed/repo-beta/other-skill"
  touch "$HOME/.skoll/stowed/repo-beta/other-skill/SKILL.md"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" search my 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll search <pattern> should exit 0" || exit 1
  # Search uses same table format as add -i: aligned columns
  assert_contains "$output" "my-skill" "should show my-skill name" || exit 1
  assert_contains "$output" "repo-alpha" "should show repo-alpha as subfolder" || exit 1
  assert_contains "$output" "other-skill" "should show other-skill name" || exit 1
  assert_contains "$output" "repo-beta" "should show repo-beta as subfolder" || exit 1
  assert_contains "$output" "local" "source should be local" || exit 1
}

test_search_no_args() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  # Setup: create stowed skills
  mkdir -p "$HOME/.skoll/stowed/repo-alpha/skill-one"
  touch "$HOME/.skoll/stowed/repo-alpha/skill-one/SKILL.md"
  mkdir -p "$HOME/.skoll/stowed/repo-alpha/skill-two"
  touch "$HOME/.skoll/stowed/repo-alpha/skill-two/SKILL.md"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" search 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll search (no args) should exit 0" || exit 1
  # Interactive fzf: the stub cats all input, so all skills should appear
  assert_contains "$output" "skill-one" "should show skill-one name" || exit 1
  assert_contains "$output" "skill-two" "should show skill-two name" || exit 1
  assert_contains "$output" "repo-alpha" "should show repo-alpha as subfolder" || exit 1
  assert_contains "$output" "local" "source should be local" || exit 1
}

test_search_empty_stowed() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" search foo 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll search with empty stowed should exit 0" || exit 1
  assert_eq "$output" "" "output should be empty when no stowed skills" || exit 1
}

run_test "skoll list shows empty when no local skills" test_list_empty
run_test "skoll list shows local skills" test_list_with_local_skills
run_test "skoll list indicates broken symlinks" test_list_broken_skill
run_test "skoll list --stowed shows empty when no stowed skills" test_list_stowed_empty
run_test "skoll list --stowed shows stowed skills" test_list_stowed_shows_skills
run_test "skoll list --stowed handles name collisions" test_list_stowed_collisions
run_test "skoll search <pattern> filters stowed skills" test_search_with_pattern
run_test "skoll search (no args) shows all stowed skills" test_search_no_args
run_test "skoll search with empty stowed shows nothing" test_search_empty_stowed
