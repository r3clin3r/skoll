#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0

# ---- Assertion helpers ----

assert_eq() {
  local actual="$1" expected="$2" msg="${3:-}"
  if [ "$actual" != "$expected" ]; then
    echo "  FAIL: $msg"
    echo "    expected: $expected"
    echo "    actual:   $actual"
    return 1
  fi
  return 0
}

assert_dir() {
  local path="$1" msg="${2:-expected directory $path}"
  if [ ! -d "$path" ]; then
    echo "  FAIL: $msg"
    return 1
  fi
  return 0
}

assert_file() {
  local path="$1" msg="${2:-expected file $path}"
  if [ ! -f "$path" ]; then
    echo "  FAIL: $msg"
    return 1
  fi
  return 0
}

assert_executable() {
  local path="$1" msg="${2:-expected executable $path}"
  if [ ! -x "$path" ]; then
    echo "  FAIL: $msg"
    return 1
  fi
  return 0
}

assert_not_dir() {
  local path="$1" msg="${2:-expected $path to not exist}"
  if [ -d "$path" ]; then
    echo "  FAIL: $msg"
    return 1
  fi
  return 0
}

assert_contains() {
  local output="$1" pattern="$2" msg="${3:-}"
  if ! echo "$output" | grep -qF "$pattern"; then
    echo "  FAIL: $msg"
    echo "    expected output to contain: $pattern"
    echo "    actual output: $output"
    return 1
  fi
  return 0
}

assert_not_contains() {
  local output="$1" pattern="$2" msg="${3:-}"
  if echo "$output" | grep -qF "$pattern"; then
    echo "  FAIL: $msg"
    echo "    output unexpectedly contains: $pattern"
    return 1
  fi
  return 0
}

assert_exit_code() {
  local actual="$1" expected="$2" msg="${3:-}"
  if [ "$actual" -ne "$expected" ]; then
    echo "  FAIL: $msg"
    echo "    expected exit code: $expected"
    echo "    actual exit code:   $actual"
    return 1
  fi
  return 0
}

# ---- Setup isolated environment (with stubs) ----

run_test() {
  local name="$1"
  local func="$2"
  echo ""
  echo "=== $name ==="

  local tmpdir
  tmpdir="$(mktemp -d /tmp/skoll-test.XXXXXX)"
  local test_home="$tmpdir/home"
  mkdir -p "$test_home"

  # Create stub stow and fzf on PATH
  mkdir -p "$tmpdir/bin"
  cat > "$tmpdir/bin/stow" <<'STUB'
#!/usr/bin/env bash
echo "stow stub: $@" >&2
STUB
  chmod +x "$tmpdir/bin/stow"

  cat > "$tmpdir/bin/fzf" <<'STUB'
#!/usr/bin/env bash
cat
STUB
  chmod +x "$tmpdir/bin/fzf"

  # Export tmpdir for test functions to use
  export SKOLL_TEST_TMPDIR="$tmpdir"

  local rc=0
  (
    set -euo pipefail
    export HOME="$test_home"
    export PATH="$tmpdir/bin:$PATH"
    cd "$ROOT_DIR"
    # Configure git for tests
    git config --global protocol.file.allow always 2>/dev/null || true
    git config --global user.email "test@skoll.test" 2>/dev/null || true
    git config --global user.name "Skoll Test" 2>/dev/null || true
    "$func"
  ) || rc=$?
  rm -rf "$tmpdir"
  if [ $rc -eq 0 ]; then
    echo "  PASS"
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
  fi
}

# ---- Load and run all test files ----

if [ $# -gt 0 ]; then
  for f in "$@"; do
    source "$TESTS_DIR/$f"
  done
else
  for f in "$TESTS_DIR"/*.test.sh; do
    source "$f"
  done
fi

# ---- Summary ----

echo ""
echo "=============================="
echo "Tests: $((PASS + FAIL))  Passed: $PASS  Failed: $FAIL"
echo "=============================="
[ "$FAIL" -eq 0 ]
