#!/usr/bin/env bash
# Test: skoll rm <skill> and skoll clean

# Helper: set up a project directory inside the test temp dir
setup_project_dir() {
  local project_dir="$SKOLL_TEST_TMPDIR/project"
  mkdir -p "$project_dir"
  cd "$project_dir"
}

setup_skills_dir() {
  local project_dir="$SKOLL_TEST_TMPDIR/project"
  mkdir -p "$project_dir/.agents/skills"
}

setup_managed_skill() {
  local name="$1"
  mkdir -p "$HOME/.skoll/stowed/my-repo/$name"
  touch "$HOME/.skoll/stowed/my-repo/$name/SKILL.md"
  ln -s "$HOME/.skoll/stowed/my-repo/$name" "$SKOLL_TEST_TMPDIR/project/.agents/skills/$name"
}

# ---- skoll rm <skill> ----

test_rm_removes_managed_symlink() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir
  setup_managed_skill "my-skill"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" rm my-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll rm should exit 0" || exit 1

  # Verify symlink is removed
  local link="$SKOLL_TEST_TMPDIR/project/.agents/skills/my-skill"
  [ ! -e "$link" ] && [ ! -L "$link" ] || { echo "  FAIL: symlink should be removed"; exit 1; }

  # Verify stowed copy is still there
  assert_dir "$HOME/.skoll/stowed/my-repo/my-skill" "stowed copy should remain" || exit 1

  # Verify output mentions the skill
  assert_contains "$output" "my-skill" "output should mention skill name" || exit 1
}

test_rm_does_not_remove_non_managed_symlink() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir

  # Create a symlink that points outside stowed
  ln -s "/some/external/path" "$SKOLL_TEST_TMPDIR/project/.agents/skills/external-skill"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" rm external-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll rm should exit 0 for non-managed symlink" || exit 1

  # Verify the non-managed symlink is still there
  local link="$SKOLL_TEST_TMPDIR/project/.agents/skills/external-skill"
  [ -L "$link" ] || { echo "  FAIL: non-managed symlink should be left alone"; exit 1; }

  # Output should mention it's not managed
  assert_contains "$output" "not managed by skoll" "output should say not managed" || exit 1
}

test_rm_does_not_remove_non_symlink_file() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir

  # Create a regular file
  echo "hello" > "$SKOLL_TEST_TMPDIR/project/.agents/skills/manual-file"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" rm manual-file 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll rm should exit 0 for non-managed file" || exit 1

  # Verify the file is still there
  local f="$SKOLL_TEST_TMPDIR/project/.agents/skills/manual-file"
  [ -f "$f" ] || { echo "  FAIL: non-managed file should be left alone"; exit 1; }

  assert_contains "$output" "not managed by skoll" "output should say not managed" || exit 1
}

test_rm_does_not_remove_non_symlink_directory() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir

  # Create a real directory
  mkdir -p "$SKOLL_TEST_TMPDIR/project/.agents/skills/manual-dir"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" rm manual-dir 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll rm should exit 0 for non-managed directory" || exit 1

  # Verify the directory is still there
  local d="$SKOLL_TEST_TMPDIR/project/.agents/skills/manual-dir"
  [ -d "$d" ] || { echo "  FAIL: non-managed directory should be left alone"; exit 1; }

  assert_contains "$output" "not managed by skoll" "output should say not managed" || exit 1
}

test_rm_removes_multiple_skills() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir
  setup_managed_skill "skill-one"
  setup_managed_skill "skill-two"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" rm skill-one skill-two 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll rm with multiple skills should exit 0" || exit 1

  # Verify both symlinks are removed
  [ ! -e "$SKOLL_TEST_TMPDIR/project/.agents/skills/skill-one" ] || { echo "  FAIL: skill-one should be removed"; exit 1; }
  [ ! -e "$SKOLL_TEST_TMPDIR/project/.agents/skills/skill-two" ] || { echo "  FAIL: skill-two should be removed"; exit 1; }

  # Verify stowed copies remain
  assert_dir "$HOME/.skoll/stowed/my-repo/skill-one" "stowed copy of skill-one should remain" || exit 1
  assert_dir "$HOME/.skoll/stowed/my-repo/skill-two" "stowed copy of skill-two should remain" || exit 1
}

test_rm_removes_broken_managed_symlink() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir

  # Create a broken symlink pointing into stowed (simulating a removed repo)
  ln -s "$HOME/.skoll/stowed/removed-repo/gone-skill" "$SKOLL_TEST_TMPDIR/project/.agents/skills/gone-skill"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" rm gone-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll rm should remove broken managed symlink" || exit 1

  # Verify the broken symlink is removed
  [ ! -L "$SKOLL_TEST_TMPDIR/project/.agents/skills/gone-skill" ] || { echo "  FAIL: broken symlink should be removed"; exit 1; }
}

test_rm_fails_if_skill_not_found_locally() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" rm nonexistent 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "skoll rm with nonexistent skill should exit 1" || exit 1
  assert_contains "$output" "not found" "output should say skill not found" || exit 1
}

# ---- skoll clean ----

test_clean_previews_without_f() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir
  setup_managed_skill "skill-one"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" clean 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll clean should exit 0" || exit 1

  # Should show what would be removed
  assert_contains "$output" "skill-one" "preview should mention skill-one" || exit 1
  assert_contains "$output" "would" "preview should indicate dry-run" || exit 1

  # Should NOT actually remove the symlink
  local link="$SKOLL_TEST_TMPDIR/project/.agents/skills/skill-one"
  [ -L "$link" ] || { echo "  FAIL: symlink should still exist in preview mode"; exit 1; }
}

test_clean_f_removes_managed_skills() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir
  setup_managed_skill "skill-one"
  setup_managed_skill "skill-two"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" clean -f 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll clean -f should exit 0" || exit 1

  # Verify both symlinks are removed
  [ ! -e "$SKOLL_TEST_TMPDIR/project/.agents/skills/skill-one" ] || { echo "  FAIL: skill-one should be removed"; exit 1; }
  [ ! -e "$SKOLL_TEST_TMPDIR/project/.agents/skills/skill-two" ] || { echo "  FAIL: skill-two should be removed"; exit 1; }

  # Verify stowed copies remain
  assert_dir "$HOME/.skoll/stowed/my-repo/skill-one" "stowed copy should remain" || exit 1
  assert_dir "$HOME/.skoll/stowed/my-repo/skill-two" "stowed copy should remain" || exit 1

  # Verify output mentions removed skills
  assert_contains "$output" "skill-one" "output should mention skill-one" || exit 1
  assert_contains "$output" "skill-two" "output should mention skill-two" || exit 1
}

test_clean_f_removes_broken_managed_symlinks() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir

  # Create a broken symlink pointing into stowed
  ln -s "$HOME/.skoll/stowed/removed-repo/gone-skill" "$SKOLL_TEST_TMPDIR/project/.agents/skills/gone-skill"
  # Create a valid managed symlink
  setup_managed_skill "good-skill"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" clean -f 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll clean -f should exit 0" || exit 1

  # Verify broken symlink is removed
  [ ! -L "$SKOLL_TEST_TMPDIR/project/.agents/skills/gone-skill" ] || { echo "  FAIL: broken symlink should be removed"; exit 1; }
  # Verify valid managed symlink is removed
  [ ! -e "$SKOLL_TEST_TMPDIR/project/.agents/skills/good-skill" ] || { echo "  FAIL: good-skill should be removed"; exit 1; }
}

test_clean_leaves_local_skills_dir_intact() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir
  setup_managed_skill "skill-one"

  # Run clean -f
  bash "$ROOT_DIR/skoll" clean -f >/dev/null 2>&1

  # The local skills directory should still exist
  assert_dir "$SKOLL_TEST_TMPDIR/project/.agents/skills" "local skills dir should remain" || exit 1
}

test_clean_does_nothing_when_no_managed_skills() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" clean 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll clean should exit 0 when empty" || exit 1

  # Should not show any skills
  assert_eq "$output" "" "output should be empty when no managed skills" || exit 1

  # -f variant should also do nothing
  local output2 exit_code2
  output2=$(bash "$ROOT_DIR/skoll" clean -f 2>&1) || exit_code2=$?
  exit_code2="${exit_code2:-0}"
  assert_exit_code "$exit_code2" 0 "skoll clean -f should exit 0 when empty" || exit 1
  assert_eq "$output2" "" "output should be empty when no managed skills" || exit 1
}

test_clean_preview_does_not_modify() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir
  setup_managed_skill "skill-one"

  # Run clean (preview) twice; second run should still find the skill
  bash "$ROOT_DIR/skoll" clean >/dev/null 2>&1

  # Skill should still be there after preview
  local link="$SKOLL_TEST_TMPDIR/project/.agents/skills/skill-one"
  [ -L "$link" ] || { echo "  FAIL: symlink should still exist after preview"; exit 1; }

  # Running clean again should still preview it
  local output exit_code
  output=$(HOME="$HOME" bash "$ROOT_DIR/skoll" clean 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"
  assert_contains "$output" "skill-one" "second preview should still show skill" || exit 1
  [ -L "$link" ] || { echo "  FAIL: symlink should still exist after second preview"; exit 1; }
}

# ---- skoll rm leaves non-managed files alone alongside managed ones ----

test_rm_leaves_non_managed_when_mixed_with_managed() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir

  # Managed symlink
  setup_managed_skill "managed-skill"

  # Non-managed file
  echo "manual" > "$SKOLL_TEST_TMPDIR/project/.agents/skills/manual-file"

  # Run rm with just the managed skill
  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" rm managed-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll rm should exit 0" || exit 1

  # Managed skill should be removed
  [ ! -e "$SKOLL_TEST_TMPDIR/project/.agents/skills/managed-skill" ] || { echo "  FAIL: managed skill should be removed"; exit 1; }

  # Non-managed file should still exist
  [ -f "$SKOLL_TEST_TMPDIR/project/.agents/skills/manual-file" ] || { echo "  FAIL: manual file should remain"; exit 1; }
}

# ---- skoll clean leaves non-managed files alone ----

test_clean_f_leaves_non_managed_files() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir

  # Managed symlink
  setup_managed_skill "managed-skill"

  # Non-managed file
  echo "manual" > "$SKOLL_TEST_TMPDIR/project/.agents/skills/manual-file"

  # Run clean -f
  bash "$ROOT_DIR/skoll" clean -f >/dev/null 2>&1

  # Managed skill should be removed
  [ ! -e "$SKOLL_TEST_TMPDIR/project/.agents/skills/managed-skill" ] || { echo "  FAIL: managed skill should be removed"; exit 1; }

  # Non-managed file should still exist
  [ -f "$SKOLL_TEST_TMPDIR/project/.agents/skills/manual-file" ] || { echo "  FAIL: manual file should remain"; exit 1; }
}

# ---- Register tests ----

# skoll rm
run_test "skoll rm removes managed symlink" test_rm_removes_managed_symlink
run_test "skoll rm does not remove non-managed symlink" test_rm_does_not_remove_non_managed_symlink
run_test "skoll rm does not remove non-symlink file" test_rm_does_not_remove_non_symlink_file
run_test "skoll rm does not remove non-symlink directory" test_rm_does_not_remove_non_symlink_directory
run_test "skoll rm removes multiple skills" test_rm_removes_multiple_skills
run_test "skoll rm removes broken managed symlink" test_rm_removes_broken_managed_symlink
run_test "skoll rm fails if skill not found locally" test_rm_fails_if_skill_not_found_locally
run_test "skoll rm leaves non-managed files alone alongside managed" test_rm_leaves_non_managed_when_mixed_with_managed

# skoll clean
run_test "skoll clean previews without -f" test_clean_previews_without_f
run_test "skoll clean -f removes managed skills" test_clean_f_removes_managed_skills
run_test "skoll clean -f removes broken managed symlinks" test_clean_f_removes_broken_managed_symlinks
run_test "skoll clean leaves local skills dir intact" test_clean_leaves_local_skills_dir_intact
run_test "skoll clean does nothing when no managed skills" test_clean_does_nothing_when_no_managed_skills
run_test "skoll clean preview does not modify state" test_clean_preview_does_not_modify
run_test "skoll clean -f leaves non-managed files" test_clean_f_leaves_non_managed_files
