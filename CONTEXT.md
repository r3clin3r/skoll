# Context: Skoll

Skoll is a local skill manager powered by git, stow, and fzf.

## Glossary

- **Skill**: A folder containing exactly one `SKILL.md` file. May contain other files and subdirectories. Identified by its folder name.
- **Skill repo**: A git repository containing one or more skill folders at its top level.
- **Stowed skill**: A skill stored in `~/.skoll/stowed/`. Can come from a skill repo (as a git submodule) or be user-created (a regular directory in the parent repo).
- **Local skill**: A symlink in a project's local skills directory pointing to a stowed skill.
- **Managed by skoll**: Any symlink in the local skills directory that resolves to a path under `~/.skoll/stowed/`.

## Commands

### `list`

List locally installed skills (symlinks in local skills directories).

- `skoll list` — list all skills found in local skills directories, grouped by directory. Walks up from cwd and discovers all `.agents/skills/` directories (or whatever `local_skills_dir` is configured), plus the fallback directory if set. Each directory is shown as a header with its skills listed underneath.
- `skoll list --stowed` — list all stowed skills managed by skoll

### `add`

Create symlinks from stowed skills into the local skills directory in the current directory (e.g. `$PWD/.agents/skills/`), never parent directories.

- `skoll add <skill> [<skill>...]` — add one or more skills
- `skoll add --ALL` — add all stowed skills
- `skoll add --interactive` / `skoll add -i` — interactively select skills via `fzf -m`, then add them
