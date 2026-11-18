# Bug Fix: /brief writes the brief relative to the cwd and /feat only takes an exact path

- **Slug**: 18-feat-find-brief
- **Fixed**: 2026-11-18
- **Assessment**: ./assessment.md
- **Status**: applied

## Summary

`/brief` now anchors the brief (and a capability map, and a grown tiny brief) to the checkout's top level, says it is not a temporary file, asks for the repo path outside a git checkout, and prints the absolute path. `/feat` accepts a path or a short name, searches this checkout then every other worktree, and deletes the brief only from its own checkout.

## Changes

| File | Change | Notes |
|------|--------|-------|
| `.apm/skills/brief/SKILL.md` | modified | §3 writes to `<root>/specs/briefs/<short-name>.md` with `<root>` = `git rev-parse --show-toplevel`; not a temp file (`$CLAUDE_JOB_DIR/tmp` named); outside a checkout ask for the repo path, else stop and show the unsaved brief; `create-issue` run from `<root>`; closing block prints the absolute path; grown tiny brief and capability map use `<root>` |
| `.apm/skills/feat/SKILL.md` | modified | `argument-hint` and description take a short name; setup step 1 "Find the brief" (file as given, else `specs/briefs/<name>.md` in this checkout then each `git worktree list --porcelain` worktree; one → use and name it, several → ask, none → stop naming every searched path); phase 2 step 3 deletes by absolute path only in the starting checkout, else logs `- [!] brief left in another worktree: <path>`; final message names it |
| `docs/usage.md` | modified | where the brief goes, absolute path, outside-a-checkout behaviour; `/feat <brief>` accepts a short name, lookup and delete rules |
| `docs/workflow.md` | modified | phase 1 prose (anchored path), phase 0 setup (lookup), phase 2 (delete only in own checkout) |
| `README.md` | modified | `/feat <brief>` line: path or short name |

## Diff Highlights (optional)

`/feat` setup step 1:

> **Find the brief**: an existing file as given is the brief. Else take `<name>` (the argument without a leading `specs/briefs/` and a trailing `.md`) and look for `specs/briefs/<name>.md` under `git rev-parse --show-toplevel` (this checkout), then under every other worktree `git worktree list --porcelain` names. One match: use it and say its absolute path. Several: list them and ask which; never pick one. None: stop, naming every path searched, and point to `/brief`.

## Tests Added or Updated

- None: the skills are prompts with no automated test harness (as the assessment states). Behaviour is verified manually (below, not run here).

## Local Verification

- Commands run: `mise run lint` → pass (harness.md/rebase.md word grep clean, `/tiny` line cap untouched); `mise run test:apm` → pass; `mise run test:tracker` → pass; `mise run test:spec-number` → pass.
- Manual checks: not run (need interactive sessions): `/brief` from a cwd outside the repo asks for the repo path and writes under its top level with an absolute `Brief saved:` line; `/feat <short-name>` with the brief in another worktree finds and names it and leaves the file; `/feat <unknown>` stops naming each searched path.

## Deviations from Assessment

- Applied the user's answers to the open questions: the background job's temp dir is `$CLAUDE_JOB_DIR/tmp`, so `/brief` says explicitly the brief is not a temporary file; outside a checkout it asks for the repo path and, with none, stops showing the unsaved brief in full; `/feat` never deletes a brief in another worktree and names it in the final message (via a Log line, so a resumed run still names it).
- `create-issue` keeps the relative `specs/briefs/<short-name>.md` argument (the tracker script requires that form) and is run from `<root>` instead of being passed an absolute path.
- No diagram re-render: `docs/diagrams/*.d2` do not describe where the brief is written or how `/feat` finds it.

## Review fixes

- B1: `/feat` accepts a short name only in the `[a-z0-9][a-z0-9-]*` form (as tracker.sh's `RE_BRIEF_PATH`) and deletes the brief only when its path is exactly `<this checkout's top level>/specs/briefs/<short name>.md`; any other brief (another worktree, elsewhere in this checkout, outside it) stays, logged `- [!] brief left in place: <path>` and named in the final message.
- B2 and std1: `/brief` resolves `<root>` once at the start of §1 (outside a checkout it asks for the repo path then, and stops without one); `.logistics.yml`, the project docs, the code, `gh repo view` and every write use `<root>`. `<repo root>` is gone; the unsaved-brief fallback now covers only a failed write.
- docs/usage.md and docs/workflow.md follow both changes.

## Follow-ups

- Run the manual checks above once in an interactive session (and in a background job) before release.
