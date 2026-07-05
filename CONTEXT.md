# Context: Skoll

Skoll is a local skill manager powered by git, stow, and fzf.

## Glossary

- **Skill**: A folder containing exactly one `SKILL.md` file. May contain other files and subdirectories. Identified by its folder name.
- **Skill repo**: A git repository containing one or more skill folders at its top level.
- **Stowed skill**: A skill stored in `~/.skoll/stowed/`. Can come from a skill repo (as a git submodule) or be user-created (a regular directory in the parent repo).
- **Local skill**: A symlink in a project's local skills directory pointing to a stowed skill.
- **Managed by skoll**: Any symlink in the local skills directory that resolves to a path under `~/.skoll/stowed/`.

## Commands

### `add`

Create symlinks from stowed skills into the local skills directory.

- `skoll add <skill> [<skill>...]` — add one or more skills
- `skoll add --ALL` — add all stowed skills
- `skoll add --interactive` / `skoll add -i` — interactively select skills via `fzf -m`, then add them
