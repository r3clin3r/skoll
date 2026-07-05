#!/usr/bin/env bash
set -euo pipefail

# ---- Config ----
SKOLL_HOME="$HOME/.skoll"
SKOLL_BIN="$SKOLL_HOME/bin"
SKOLL_STOWED="$SKOLL_HOME/stowed"
SKOLL_INI="$SKOLL_HOME/skoll.ini"

# Find the skoll script relative to this install script
INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
SKOLL_SRC="$INSTALL_DIR/skoll"

# ---- Color helpers ----
info()  { printf '\033[36m%s\033[0m\n' "$*"; }
ok()    { printf '\033[32m  ✓ %s\033[0m\n' "$*"; }
err()   { printf '\033[31m  ✗ %s\033[0m\n' "$*"; }
warn()  { printf '\033[33m  ! %s\033[0m\n' "$*"; }

# ---- Dependency check ----
missing_deps=()

check_dep() {
  local name="$1" cmd="$2" min_version="${3:-}"
  if ! command -v "$cmd" &>/dev/null; then
    missing_deps+=("$name (not found)")
    return
  fi
  if [ -n "$min_version" ]; then
    local version major
    version=$("$cmd" --version 2>/dev/null | head -1)
    major=$(echo "$version" | grep -oE '\d+' | head -1)
    if [ -z "$major" ]; then
      missing_deps+=("$name (cannot determine version)")
      return
    fi
    if [ "$major" -lt "$min_version" ]; then
      missing_deps+=("$name (version $major < $min_version)")
      return
    fi
  fi
}

check_dep "bash" "bash" "5"
check_dep "git" "git"
check_dep "GNU stow" "stow"
check_dep "fzf" "fzf"

if [ "${#missing_deps[@]}" -gt 0 ]; then
  echo ""
  warn "Missing dependencies:"
  for dep in "${missing_deps[@]}"; do
    err "$dep"
  done
  echo ""
  info "Please install the missing dependencies and re-run install.sh"
  exit 1
fi

echo ""
info "All dependencies found."

# ---- Create directory structure ----
mkdir -p "$SKOLL_BIN"
mkdir -p "$SKOLL_STOWED"
ok "Created $SKOLL_HOME/"

# ---- Copy skoll executable ----
if [ -f "$SKOLL_SRC" ]; then
  cp "$SKOLL_SRC" "$SKOLL_BIN/skoll"
  chmod +x "$SKOLL_BIN/skoll"
  ok "Installed skoll to $SKOLL_BIN/skoll"
else
  err "skoll script not found at $SKOLL_SRC"
  exit 1
fi

# ---- Create config file ----
if [ ! -f "$SKOLL_INI" ]; then
  cat > "$SKOLL_INI" <<'INI'
# Skoll configuration
local_skills_dir=.agents/skills/
fallback=
INI
  ok "Created $SKOLL_INI"
else
  ok "$SKOLL_INI already exists"
fi

# ---- Initialize git repo ----
init_git=true
if [ "${1:-}" = "--no-git" ]; then
  init_git=false
fi

if $init_git; then
  if [ ! -d "$SKOLL_STOWED/.git" ]; then
    git -C "$SKOLL_STOWED" init
    ok "Initialized git repo in $SKOLL_STOWED"
  else
    ok "Git repo already initialized in $SKOLL_STOWED"
  fi
else
  ok "Skipped git repo initialization (--no-git)"
fi

# ---- Print PATH instructions ----
echo ""
info "Installation complete!"
echo ""
info "Add skoll to your PATH by adding the following line to your ~/.bashrc or ~/.zshrc:"
echo ""
echo "    export PATH=\"\$HOME/.skoll/bin:\$PATH\""
echo ""
info "Then run 'skoll --help' to get started."
