# SKOLL

The local skill manager powered by git, stow and fzf.

## Usage

```
skoll list                   # lists installed

skoll list --stowed          # list all skills mananged by skoll 

skoll search my-pattern          # fuzzy search in stowed skills, outputs matches as `skill-name (parent-dir)` one per line

skoll add my-skill my-skill-2    # symlink stowed skills to local skills (e.g. in $PWD/.agents/skills only)

skoll add --ALL                  # symlink all stowed skills locally (e.g. in $PWD/.agents/skills only)

skoll rm my-skill                # remove my-skill locally (if it is managed by skoll)

skoll clean -f                   # remove all local skills (that are managed by skoll), with out -f it outputs what will happen (no rm)

skoll get url-to-skill-repo/some-skills.git            # download repo containing folderised SKILL.md files (e.g. tmux/SKILL.md)

skoll rm --stowed url-to-skill-repo/some-skills.git    # remove stowed skill, warn if the stowed skills are in use

skoll update    # git pull existing skill repos
```

## Pre-requisites

Unix/Linux-like OS with bash 5, git, GNU stow, and fzf.

## Installation

```
./install.sh  # will check/ask to install deps
```

## Architecture

Skoll's config files are stored in ~/.skoll/

The skoll executable is copied to ~/.skoll/bin/skoll

The stowed and downloaded skills are stored in directories under ~/.skoll/stowed/

## How it works

A skill is defined as a folder with a single SKILL.md file in it. These are identified locally (in the cwd) and in the directory structures under ~/.skoll/stowed/.
GNU `stow -S`  is used under the hood to create symlinks in the configured /skills/ directory for each skill's folder when `skoll add` is invoked with the folder name as an argument (`stow -D` is used to remove).

## Config

`~/.skoll/skoll.ini`

contains the definiton of local skills directory, i.e. $(pwd)/.pi/skills/
and a fallback, i.e. $(pwd)/.pi/agent/skills

The defaults are `.agents/skills/` and blank fallback.

## Data model

Skoll can only remove real files/folders in ~/.skoll/stowed/, so you should be careful if you have skoll-stowed skills that are not stored anywhere else.

Other than managin the .skoll/stowed dir, Skoll only ads and removes symlinks using GNU stow.

By default skoll initislises a git repo in ~/.skoll/stowed and adds other repos as submodules. You can disable this with `.install.sh --no-git`.

