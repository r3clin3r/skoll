This is a fresh project--read README.md to understand the desired API.

When creating, removing, updating detroying command or command flags, i.e. when changing the skoll API, make sure that the CONTEXT is updated and the CLI help message is updated. 

Experiments should be done on a new git branch.

## Agent skills

### Issue tracker

Issues and PRDs live as markdown files under `.scratch/`. No external PRs. See `docs/agents/issue-tracker.md`.

### Triage labels

Default canonical labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo: one `CONTEXT.md` and `docs/adr/` at the root. See `docs/agents/domain.md`.
