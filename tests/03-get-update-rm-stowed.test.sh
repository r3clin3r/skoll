#!/usr/bin/env bash
# Test: skoll get, skoll update, skoll rm --stowed

# Fixture: path to the local clone of mattpocock/skills repo
SKILLS_FIXTURE="$(cd "$(dirname "$0")" && pwd)/fixtures/skills-repo"

# ---- skoll get ----

test_get_adds_submodule() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" get "$SKILLS_FIXTURE" 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll get should exit 0" || exit 1
  assert_contains "$output" "skills-repo" "output should mention repo name" || exit 1

  # Verify submodule was created
  assert_dir "$HOME/.skoll/stowed/skills-repo" "submodule directory should exist" || exit 1

  # Verify it's actually a git submodule (has .git file pointing to parent)
  assert_file "$HOME/.skoll/stowed/skills-repo/.git" "submodule should have .git file" || exit 1
}

test_get_repo_skills_appear_in_list_stowed() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  # Create a test repo with proper top-level skills
  local test_repo="$SKOLL_TEST_TMPDIR/test-skills.git"
  git init --bare "$test_repo" >/dev/null 2>&1
  local working="$SKOLL_TEST_TMPDIR/working-skills"
  git clone "$test_repo" "$working" >/dev/null 2>&1
  mkdir -p "$working/alpha-skill"
  touch "$working/alpha-skill/SKILL.md"
  mkdir -p "$working/beta-skill"
  touch "$working/beta-skill/SKILL.md"
  # Non-skill file at root (should be ignored)
  touch "$working/README.md"
  git -C "$working" add -A >/dev/null 2>&1
  git -C "$working" commit -m "init" >/dev/null 2>&1
  git -C "$working" push origin master >/dev/null 2>&1

  # Add via skoll get
  bash "$ROOT_DIR/skoll" get "$test_repo" >/dev/null 2>&1

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" list --stowed 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll list --stowed should exit 0" || exit 1
  assert_contains "$output" "alpha-skill (test-skills)" "should show alpha-skill from repo" || exit 1
  assert_contains "$output" "beta-skill (test-skills)" "should show beta-skill from repo" || exit 1
  assert_not_contains "$output" "README.md" "non-skill files should be ignored" || exit 1
}

test_get_colliding_name_errors() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  # Add first repo named skills-repo
  bash "$ROOT_DIR/skoll" get "$SKILLS_FIXTURE" >/dev/null 2>&1

  # Try to add another repo with same basename (different path, same name)
  local dup_repo="$SKOLL_TEST_TMPDIR/skills-repo"
  git init --bare "$dup_repo" >/dev/null 2>&1
  local dup_working="$SKOLL_TEST_TMPDIR/working-dup"
  git clone "$dup_repo" "$dup_working" >/dev/null 2>&1
  mkdir -p "$dup_working/other-skill"
  touch "$dup_working/other-skill/SKILL.md"
  git -C "$dup_working" add -A >/dev/null 2>&1
  git -C "$dup_working" commit -m "init" >/dev/null 2>&1
  git -C "$dup_working" push origin master >/dev/null 2>&1

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" get "$dup_repo" 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 1 "skoll get should exit 1 on collision" || exit 1
  assert_contains "$output" "already exists" "output should mention collision" || exit 1
  assert_contains "$output" "skills-repo" "output should mention the conflicting name" || exit 1
}

# ---- skoll update ----

test_update_pulls_and_updates_submodules() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  # Create a remote repo
  local remote="$SKOLL_TEST_TMPDIR/upstream.git"
  git init --bare "$remote" >/dev/null 2>&1

  # Clone and add an initial skill
  local working="$SKOLL_TEST_TMPDIR/working"
  git clone "$remote" "$working" >/dev/null 2>&1
  mkdir -p "$working/initial-skill"
  touch "$working/initial-skill/SKILL.md"
  git -C "$working" add -A >/dev/null 2>&1
  git -C "$working" commit -m "initial" >/dev/null 2>&1
  git -C "$working" push origin master >/dev/null 2>&1

  # Add it as a submodule via skoll get
  bash "$ROOT_DIR/skoll" get "$remote" >/dev/null 2>&1

  # Now add a new skill to the remote (simulate upstream change)
  mkdir -p "$working/new-skill"
  touch "$working/new-skill/SKILL.md"
  git -C "$working" add -A >/dev/null 2>&1
  git -C "$working" commit -m "add new skill" >/dev/null 2>&1
  git -C "$working" push origin master >/dev/null 2>&1

  # Run skoll update
  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" update 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll update should exit 0" || exit 1

  # The submodule should now have the new skill
  assert_dir "$HOME/.skoll/stowed/upstream/new-skill" "new skill should exist after update" || exit 1
  assert_file "$HOME/.skoll/stowed/upstream/new-skill/SKILL.md" "new skill SKILL.md should exist" || exit 1
}

# ---- skoll rm --stowed ----

test_rm_stowed_removes_submodule() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  # Create a remote repo
  local remote="$SKOLL_TEST_TMPDIR/to-remove.git"
  git init --bare "$remote" >/dev/null 2>&1
  local working="$SKOLL_TEST_TMPDIR/working-rm"
  git clone "$remote" "$working" >/dev/null 2>&1
  mkdir -p "$working/a-skill"
  touch "$working/a-skill/SKILL.md"
  git -C "$working" add -A >/dev/null 2>&1
  git -C "$working" commit -m "init" >/dev/null 2>&1
  git -C "$working" push origin master >/dev/null 2>&1

  # Add it
  bash "$ROOT_DIR/skoll" get "$remote" >/dev/null 2>&1
  assert_dir "$HOME/.skoll/stowed/to-remove" "submodule should exist before removal" || exit 1

  # Remove it
  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" rm --stowed to-remove 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll rm --stowed should exit 0" || exit 1
  assert_not_dir "$HOME/.skoll/stowed/to-remove" "submodule dir should be removed" || exit 1

  # Verify .git/modules is cleaned up
  assert_not_dir "$HOME/.skoll/stowed/.git/modules/to-remove" "git modules dir should be cleaned" || exit 1
}

test_rm_stowed_warns_if_skills_in_use() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  # Create a remote repo with one skill
  local remote="$SKOLL_TEST_TMPDIR/in-use.git"
  git init --bare "$remote" >/dev/null 2>&1
  local working="$SKOLL_TEST_TMPDIR/working-inuse"
  git clone "$remote" "$working" >/dev/null 2>&1
  mkdir -p "$working/used-skill"
  touch "$working/used-skill/SKILL.md"
  git -C "$working" add -A >/dev/null 2>&1
  git -C "$working" commit -m "init" >/dev/null 2>&1
  git -C "$working" push origin master >/dev/null 2>&1

  # Add it
  bash "$ROOT_DIR/skoll" get "$remote" >/dev/null 2>&1

  # Create a project with a local symlink to one of the repo's skills
  local project_dir="$SKOLL_TEST_TMPDIR/my-project"
  mkdir -p "$project_dir/.agents/skills"
  ln -s "$HOME/.skoll/stowed/in-use/used-skill" "$project_dir/.agents/skills/used-skill"

  # Run rm --stowed from the project dir
  local output exit_code
  output=$(cd "$project_dir" && bash "$ROOT_DIR/skoll" rm --stowed in-use 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "skoll rm --stowed should exit 0 even with in-use warning" || exit 1
  assert_contains "$output" "in use" "should warn about in-use skills" || exit 1
  assert_contains "$output" "used-skill" "should mention the in-use skill name" || exit 1

  # But the submodule should still be removed
  assert_not_dir "$HOME/.skoll/stowed/in-use" "submodule should be removed despite warning" || exit 1
}

# ---- User-created skills coexist ----

test_user_created_skills_coexist_with_submodules() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  # Create a user-created skill (regular directory, not a submodule)
  mkdir -p "$HOME/.skoll/stowed/user-repo"
  mkdir -p "$HOME/.skoll/stowed/user-repo/my-custom-skill"
  touch "$HOME/.skoll/stowed/user-repo/my-custom-skill/SKILL.md"

  # Also create a non-skill file at the repo root (should be ignored)
  touch "$HOME/.skoll/stowed/user-repo/README.md"

  # Add a submodule repo alongside
  local remote="$SKOLL_TEST_TMPDIR/submodule-repo.git"
  git init --bare "$remote" >/dev/null 2>&1
  local working="$SKOLL_TEST_TMPDIR/working-coexist"
  git clone "$remote" "$working" >/dev/null 2>&1
  mkdir -p "$working/sub-skill"
  touch "$working/sub-skill/SKILL.md"
  git -C "$working" add -A >/dev/null 2>&1
  git -C "$working" commit -m "init" >/dev/null 2>&1
  git -C "$working" push origin master >/dev/null 2>&1

  bash "$ROOT_DIR/skoll" get "$remote" >/dev/null 2>&1

  # list --stowed should show both
  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" list --stowed 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "list --stowed should exit 0" || exit 1
  assert_contains "$output" "my-custom-skill (user-repo)" "should show user-created skill" || exit 1
  assert_contains "$output" "sub-skill (submodule-repo)" "should show submodule skill" || exit 1
  assert_not_contains "$output" "README.md" "non-skill files should be ignored" || exit 1
}

# ---- Nested skill discovery ----

test_nested_skill_discovery() {
  bash "$ROOT_DIR/install.sh" >/dev/null 2>&1

  # Create a repo with nested skill structure like mattpocock/skills
  mkdir -p "$HOME/.skoll/stowed/nested-repo"
  mkdir -p "$HOME/.skoll/stowed/nested-repo/skills/engineering"
  mkdir -p "$HOME/.skoll/stowed/nested-repo/skills/productivity"
  mkdir -p "$HOME/.skoll/stowed/nested-repo/misc"

  # Skills nested under category dirs
  mkdir -p "$HOME/.skoll/stowed/nested-repo/skills/engineering/code-review"
  touch "$HOME/.skoll/stowed/nested-repo/skills/engineering/code-review/SKILL.md"
  mkdir -p "$HOME/.skoll/stowed/nested-repo/skills/engineering/tdd"
  touch "$HOME/.skoll/stowed/nested-repo/skills/engineering/tdd/SKILL.md"
  mkdir -p "$HOME/.skoll/stowed/nested-repo/skills/productivity/grilling"
  touch "$HOME/.skoll/stowed/nested-repo/skills/productivity/grilling/SKILL.md"

  # A top-level skill alongside nested ones
  mkdir -p "$HOME/.skoll/stowed/nested-repo/misc/my-tool"
  touch "$HOME/.skoll/stowed/nested-repo/misc/my-tool/SKILL.md"

  # Non-skill files at various levels
  touch "$HOME/.skoll/stowed/nested-repo/README.md"
  touch "$HOME/.skoll/stowed/nested-repo/skills/engineering/README.md"

  local output exit_code
  output=$(bash "$ROOT_DIR/skoll" list --stowed 2>&1) || exit_code=$?
  exit_code="${exit_code:-0}"

  assert_exit_code "$exit_code" 0 "list --stowed should exit 0" || exit 1
  assert_contains "$output" "code-review (nested-repo)" "should find nested skill under engineering" || exit 1
  assert_contains "$output" "tdd (nested-repo)" "should find nested skill under engineering" || exit 1
  assert_contains "$output" "grilling (nested-repo)" "should find nested skill under productivity" || exit 1
  assert_contains "$output" "my-tool (nested-repo)" "should find top-level skill" || exit 1
  assert_not_contains "$output" "README.md" "non-skill files should be ignored" || exit 1
}

# ---- Register tests ----

run_test "skoll get adds a submodule" test_get_adds_submodule
run_test "skoll get repo skills appear in list --stowed" test_get_repo_skills_appear_in_list_stowed
run_test "skoll get colliding name produces error" test_get_colliding_name_errors
run_test "skoll update pulls and updates submodules" test_update_pulls_and_updates_submodules
run_test "skoll rm --stowed removes submodule fully" test_rm_stowed_removes_submodule
run_test "skoll rm --stowed warns if skills in use" test_rm_stowed_warns_if_skills_in_use
run_test "user-created skills coexist with submodules" test_user_created_skills_coexist_with_submodules
run_test "nested skill discovery (like mattpocock/skills)" test_nested_skill_discovery
