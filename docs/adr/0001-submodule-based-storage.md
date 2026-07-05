# ADR 0001: Submodule-based storage for stowed skills

## Status

Accepted

## Context

Skoll needs a way to store downloaded skill repos locally. The alternatives are:

1. Plain git clones into a directory (no parent git tracking).
2. A git repo with submodules (each skill repo is a submodule).
3. A single monolithic git repo containing all skills.

## Decision

We use a git repo at `~/.skoll/stowed/` with git submodules for external skill repos. User-created skills are regular directories in the parent repo.

## Consequences

- **Pros**:
  - The entire state of `~/.skoll/stowed/` is tracked in git, so it can be recovered if deleted.
  - Skill repos are independently versioned (each submodule tracks its own remote).
  - User-created skills can coexist with downloaded skills.
- **Cons**:
  - Git submodules are complex and can be confusing for users.

## Alternatives considered

- **Plain clones**: Simpler, but no recovery if `~/.skoll/stowed/` is deleted.
- **Monolithic repo**: All skills in one repo, harder to maintain independent versions.
