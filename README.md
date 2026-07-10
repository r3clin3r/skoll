# SKOLL

The local skill manager powered by git, stow and fzf.

## Pre-requisites

Unix/Linux-like OS with bash 5, git, GNU stow, and fzf.

## Installation

```
./install.sh  # will check/ask to install deps
```

To skip git repository initialisation:
```
./install.sh --no-git
```

After installation, add `~/.skoll/bin/` to your `PATH`.

## Commands

### `list`

List locally installed skills (symlinks in your project's `.agents/skills/` directory).

```
skoll list
```

Example output:
```
./.agents/skills/
    tdd
    code-review
```

### `list --stowed`

List all skills stored in the stowed directory (`~/.skoll/stowed/`), displayed in a table with columns for name, source, and subfolder.

```
skoll list --stowed
```

Example output:
```
name                 | source                | subfolder
---                  | ---                   | ---
tdd                  | local                 | engineering
code-review          | local                 | engineering
my-skill             | local                 | _none_
root-skill           | authorstr/repo-name   | _none_
nested-skill         | authorstr/repo-name   | subdir
```

- **source**: `local` for user-created/manual entries, or `author/repo` for git submodules added via `skoll get`.
- **subfolder**: the parent directory of the skill within the stowed tree. `_none_` when the skill is at the root of its entry.

### `search`

Fuzzy-search stowed skills with fzf. Without a pattern, opens the interactive fzf picker. With a pattern, filters and outputs matching skills.

```
skoll search my-pattern
skoll search                    # interactive picker
```

Output uses the same aligned table format as `list --stowed` (name, source, subfolder columns, no header):

```
code-review          | local                 | engineering
tdd                  | local                 | engineering
```

### `add`

Symlink one or more stowed skills into the local skills directory (in the current directory only, no parent walk).

```
skoll add my-skill my-skill-2   # add specific skills
skoll add --ALL                 # add all stowed skills
skoll add --interactive         # interactive multi-select via fzf
skoll add -i                    # same as --interactive
```

If the local skills directory doesn't exist, you'll be prompted to create it.

### `rm`

Remove locally installed skills (only those managed by skoll, i.e. symlinks pointing into `~/.skoll/stowed/`).

```
skoll rm my-skill
```

### `rm --stowed`

Remove a stowed skill repository entirely. Warns if any local skills still reference it.

```
skoll rm --stowed repo-name
```

### `clean`

Remove all locally managed skills from the current directory. Without `-f`, shows a preview of what would be removed.

```
skoll clean          # preview only (dry run)
skoll clean -f       # perform removal
```

### `get`

Download a skill repository (git clone as submodule) and add it to the stowed directory.

```
skoll get https://github.com/author/skills.git
skoll get git@github.com:author/skills.git
skoll get /path/to/local/skills.git
```

### `update`

Pull latest changes for all stowed skill submodules.

```
skoll update
```

### `--help`

Show the help message.

```
skoll --help
skoll -h
```

Unrecognised commands and flags produce an error with a useful message:
```
$ skoll list --bogus
skoll: unrecognized option '--bogus' for 'list'
Usage: skoll list [--stowed]
```

## Architecture

Skoll's config files are stored in `~/.skoll/`:

- `~/.skoll/bin/skoll` — the skoll executable
- `~/.skoll/stowed/` — stowed and downloaded skill repos (git submodules)
- `~/.skoll/skoll.ini` — configuration file

## How it works

A **skill** is defined as a folder with a single `SKILL.md` file in it. Skills are identified locally (in the current directory's `.agents/skills/`) and in the directory structures under `~/.skoll/stowed/`.

GNU `stow` is used under the hood to create symlinks from `~/.skoll/stowed/` into your project's skills directory when `skoll add` is invoked.

## Config

`~/.skoll/skoll.ini` contains:

```ini
local_skills_dir=.agents/skills/
fallback=
```

- `local_skills_dir` — directory name to look for in the project root (default: `.agents/skills/`)
- `fallback` — an absolute fallback path if no project-level skills directory is found

## Data model

- Skoll only manages symlinks that point into `~/.skoll/stowed/`. Any other files or symlinks in the local skills directory are left untouched.
- By default, skoll initialises a git repository in `~/.skoll/stowed/` and adds fetched skill repos as submodules. Use `./install.sh --no-git` to disable this.
- Stowed skills can be manually created as regular directories under `~/.skoll/stowed/` alongside git submodules.

