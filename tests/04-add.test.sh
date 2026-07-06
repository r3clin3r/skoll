#!/usr/bin/env bash
# Test: skoll add, skoll add --ALL

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

# ---- skoll add single skill ----

test_add_single_skill() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir

  # Setup: create a stowed skill
  mkdir -p "$HOME/.skoll/stowed/my-repo/my-skill"
  touch "$HOME/.skoll/stowed/my-repo/my-skill/SKILL.md"

  # Setup: create local skills dir
  setup_skills_dir

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" add my-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll add should exit 0" || exit 1

  # Verify symlink was created
  local link="$SKOLL_TEST_TMPDIR/project/.agents/skills/my-skill"
  [ -L "$link" ] || { echo "  FAIL: expected symlink at $link"; exit 1; }

  # Verify it points to the right place
  local target
  target="$(readlink "$link")"
  assert_eq "$target" "$HOME/.skoll/stowed/my-repo/my-skill" "symlink should point to stowed skill" || exit 1
}

# ---- skoll add multiple skills ----

test_add_multiple_skills() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir

  # Setup: create stowed skills in two repos
  mkdir -p "$HOME/.skoll/stowed/repo-alpha/skill-one"
  touch "$HOME/.skoll/stowed/repo-alpha/skill-one/SKILL.md"
  mkdir -p "$HOME/.skoll/stowed/repo-beta/skill-two"
  touch "$HOME/.skoll/stowed/repo-beta/skill-two/SKILL.md"

  setup_skills_dir

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" add skill-one skill-two 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll add with multiple skills should exit 0" || exit 1

  # Verify both symlinks were created
  local link1="$SKOLL_TEST_TMPDIR/project/.agents/skills/skill-one"
  local link2="$SKOLL_TEST_TMPDIR/project/.agents/skills/skill-two"
  [ -L "$link1" ] || { echo "  FAIL: expected symlink at $link1"; exit 1; }
  [ -L "$link2" ] || { echo "  FAIL: expected symlink at $link2"; exit 1; }
}

# ---- skoll add fails if skill not in stowed ----

test_add_fails_skill_not_found() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir
  setup_skills_dir

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" add nonexistent-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "skoll add with nonexistent skill should exit 1" || exit 1
  assert_contains "$output" "not found" "output should say skill not found" || exit 1
}

# ---- skoll add is atomic: fails if any skill is missing ----

test_add_atomic_fails_if_any_missing() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir

  # Setup: create one stowed skill but not the other
  mkdir -p "$HOME/.skoll/stowed/repo-alpha/existing-skill"
  touch "$HOME/.skoll/stowed/repo-alpha/existing-skill/SKILL.md"

  setup_skills_dir

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" add existing-skill missing-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "skoll add should exit 1 when any skill is missing" || exit 1
  assert_contains "$output" "not found" "output should mention missing skill" || exit 1

  # Verify no symlink was created for the existing skill (atomicity)
  local link="$SKOLL_TEST_TMPDIR/project/.agents/skills/existing-skill"
  [ ! -e "$link" ] || { echo "  FAIL: existing-skill should not have been created (atomicity)"; exit 1; }
}

# ---- skoll add replaces broken symlink ----

test_add_replaces_broken_symlink() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir

  # Setup: create a stowed skill
  mkdir -p "$HOME/.skoll/stowed/my-repo/my-skill"
  touch "$HOME/.skoll/stowed/my-repo/my-skill/SKILL.md"

  # Setup: create a broken symlink for the same skill in local dir
  setup_skills_dir
  ln -s "$HOME/.skoll/stowed/removed-repo/my-skill" "$SKOLL_TEST_TMPDIR/project/.agents/skills/my-skill"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" add my-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll add should replace broken symlink" || exit 1

  # Verify the broken symlink was replaced
  local link="$SKOLL_TEST_TMPDIR/project/.agents/skills/my-skill"
  [ -L "$link" ] || { echo "  FAIL: expected symlink at $link"; exit 1; }
  [ -e "$link" ] || { echo "  FAIL: symlink should point to valid path"; exit 1; }

  local target
  target="$(readlink "$link")"
  assert_eq "$target" "$HOME/.skoll/stowed/my-repo/my-skill" "symlink should point to correct stowed skill" || exit 1
}

# ---- skoll add fails if valid non-broken skill exists ----

test_add_fails_if_skill_already_exists() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir

  # Setup: create two repos with same skill name so we can show it exists
  mkdir -p "$HOME/.skoll/stowed/my-repo/my-skill"
  touch "$HOME/.skoll/stowed/my-repo/my-skill/SKILL.md"

  # Setup: create an existing valid symlink
  setup_skills_dir
  ln -s "$HOME/.skoll/stowed/my-repo/my-skill" "$SKOLL_TEST_TMPDIR/project/.agents/skills/my-skill"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" add my-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "skoll add should fail when valid skill exists" || exit 1
  assert_contains "$output" "already exists" "output should say skill already exists" || exit 1
}

# ---- skoll add fails if target is a non-symlink file ----

test_add_fails_on_non_symlink_file() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir

  # Setup: create a stowed skill
  mkdir -p "$HOME/.skoll/stowed/my-repo/my-skill"
  touch "$HOME/.skoll/stowed/my-repo/my-skill/SKILL.md"

  # Setup: create a regular file where the symlink would go
  setup_skills_dir
  echo "not a symlink" > "$SKOLL_TEST_TMPDIR/project/.agents/skills/my-skill"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" add my-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "skoll add should fail when target is a regular file" || exit 1
  assert_contains "$output" "not a symlink" "output should mention non-symlink" || exit 1
}

test_add_fails_on_non_symlink_dir() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir

  # Setup: create a stowed skill
  mkdir -p "$HOME/.skoll/stowed/my-repo/my-skill"
  touch "$HOME/.skoll/stowed/my-repo/my-skill/SKILL.md"

  # Setup: create a real directory where the symlink would go
  setup_skills_dir
  mkdir -p "$SKOLL_TEST_TMPDIR/project/.agents/skills/my-skill"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" add my-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "skoll add should fail when target is a directory" || exit 1
  assert_contains "$output" "not a symlink" "output should mention non-symlink" || exit 1
}

# ---- skoll add --ALL ----

test_add_all_symlinks_all_stowed_skills() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir

  # Setup: create stowed skills across multiple repos
  mkdir -p "$HOME/.skoll/stowed/repo-alpha/alpha-skill"
  touch "$HOME/.skoll/stowed/repo-alpha/alpha-skill/SKILL.md"
  mkdir -p "$HOME/.skoll/stowed/repo-alpha/beta-skill"
  touch "$HOME/.skoll/stowed/repo-alpha/beta-skill/SKILL.md"
  mkdir -p "$HOME/.skoll/stowed/repo-beta/gamma-skill"
  touch "$HOME/.skoll/stowed/repo-beta/gamma-skill/SKILL.md"

  setup_skills_dir

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" add --ALL 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll add --ALL should exit 0" || exit 1

  # Verify all skills were symlinked
  local link1="$SKOLL_TEST_TMPDIR/project/.agents/skills/alpha-skill"
  local link2="$SKOLL_TEST_TMPDIR/project/.agents/skills/beta-skill"
  local link3="$SKOLL_TEST_TMPDIR/project/.agents/skills/gamma-skill"

  [ -L "$link1" ] || { echo "  FAIL: expected symlink for alpha-skill"; exit 1; }
  [ -L "$link2" ] || { echo "  FAIL: expected symlink for beta-skill"; exit 1; }
  [ -L "$link3" ] || { echo "  FAIL: expected symlink for gamma-skill"; exit 1; }
}

# ---- skoll add creates local skills dir if not found ----

test_add_creates_local_skills_dir_with_confirmation() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir

  # Setup: create a stowed skill
  mkdir -p "$HOME/.skoll/stowed/my-repo/my-skill"
  touch "$HOME/.skoll/stowed/my-repo/my-skill/SKILL.md"

  # Do NOT create the local skills dir; it should be created by skoll add
  local output exit_code
  # Pipe 'y' for confirmation
  output=$(echo "y" | bash "$ROOT_DIR/skoll" add my-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll add should create local skills dir" || exit 1

  # Verify the directory was created
  local skills_dir="$SKOLL_TEST_TMPDIR/project/.agents/skills"
  assert_dir "$skills_dir" "local skills dir should be created" || exit 1

  # Verify symlink was created
  local link="$skills_dir/my-skill"
  [ -L "$link" ] || { echo "  FAIL: expected symlink at $link"; exit 1; }
}

test_add_aborts_if_local_dir_missing_and_no_confirmation() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir

  # Setup: create a stowed skill
  mkdir -p "$HOME/.skoll/stowed/my-repo/my-skill"
  touch "$HOME/.skoll/stowed/my-repo/my-skill/SKILL.md"

  # Pipe 'n' for no confirmation
  local output exit_code
  output=$(echo "n" | bash "$ROOT_DIR/skoll" add my-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "skoll add should abort when user says no" || exit 1

  # Verify the directory was NOT created
  local skills_dir="$SKOLL_TEST_TMPDIR/project/.agents/skills"
  [ ! -d "$skills_dir" ] || { echo "  FAIL: local skills dir should not have been created"; exit 1; }
}

# ---- skoll add only operates in the current directory, not parents ----

test_add_only_operates_in_current_dir() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir

  # Setup: create a stowed skill
  mkdir -p "$HOME/.skoll/stowed/my-repo/my-skill"
  touch "$HOME/.skoll/stowed/my-repo/my-skill/SKILL.md"

  # Setup: create local skills dir in project root (parent)
  setup_skills_dir

  # Also create local skills dir in a subdirectory (current dir)
  local subdir="$SKOLL_TEST_TMPDIR/project/subdir"
  mkdir -p "$subdir/.agents/skills"

  # Run skoll add from the subdirectory
  local output exit_code
  output=$(cd "$subdir" && bash "$ROOT_DIR/skoll" add my-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll add should work from subdirectory" || exit 1

  # Verify the symlink was created in the subdirectory's skills dir, NOT the parent's
  local subdir_link="$subdir/.agents/skills/my-skill"
  [ -L "$subdir_link" ] || { echo "  FAIL: expected symlink at subdir skills dir"; exit 1; }

  # Verify the parent's skills dir was NOT touched
  local parent_link="$SKOLL_TEST_TMPDIR/project/.agents/skills/my-skill"
  [ ! -e "$parent_link" ] || { echo "  FAIL: parent skills dir should not be touched"; exit 1; }
}

test_add_from_subdir_creates_local_dir_if_missing() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1
  setup_project_dir

  # Setup: create a stowed skill
  mkdir -p "$HOME/.skoll/stowed/my-repo/my-skill"
  touch "$HOME/.skoll/stowed/my-repo/my-skill/SKILL.md"

  # Setup: create local skills dir in project root (parent)
  setup_skills_dir

  # Run skoll add from a subdirectory without a skills dir
  local subdir="$SKOLL_TEST_TMPDIR/project/subdir"
  mkdir -p "$subdir"
  local output exit_code
  output=$(cd "$subdir" && echo "y" | bash "$ROOT_DIR/skoll" add my-skill 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll add should create local skills dir in subdir" || exit 1

  # Verify the symlink was created in the subdirectory's skills dir
  local subdir_link="$subdir/.agents/skills/my-skill"
  [ -L "$subdir_link" ] || { echo "  FAIL: expected symlink at subdir skills dir"; exit 1; }

  # Verify the parent's skills dir was NOT touched
  local parent_link="$SKOLL_TEST_TMPDIR/project/.agents/skills/my-skill"
  [ ! -e "$parent_link" ] || { echo "  FAIL: parent skills dir should not be touched"; exit 1; }
}

# ---- Register tests ----

run_test "skoll add creates symlink for a single skill" test_add_single_skill
run_test "skoll add creates symlinks for multiple skills" test_add_multiple_skills
run_test "skoll add fails if skill not in stowed" test_add_fails_skill_not_found
run_test "skoll add is atomic: fails if any skill is missing" test_add_atomic_fails_if_any_missing
run_test "skoll add replaces broken symlinks" test_add_replaces_broken_symlink
run_test "skoll add fails if valid skill already exists" test_add_fails_if_skill_already_exists
run_test "skoll add fails if target is a regular file" test_add_fails_on_non_symlink_file
run_test "skoll add fails if target is a directory" test_add_fails_on_non_symlink_dir
run_test "skoll add --ALL symlinks all stowed skills" test_add_all_symlinks_all_stowed_skills
run_test "skoll add creates local skills dir with confirmation" test_add_creates_local_skills_dir_with_confirmation
run_test "skoll add aborts if local dir missing and no confirmation" test_add_aborts_if_local_dir_missing_and_no_confirmation
run_test "skoll add only operates in current directory" test_add_only_operates_in_current_dir
run_test "skoll add from subdir creates local dir if missing" test_add_from_subdir_creates_local_dir_if_missing
