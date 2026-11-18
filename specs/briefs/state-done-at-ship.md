# Brief: a shipped /feat run's committed state file is marked done, and resume skips runs whose PR is merged or closed
- Size: tiny — the cause is plain (phase 8 marks done after the shipper commits); a few lines in the skills, harness and docs
- Short name: state-done-at-ship
- Issue: #19

## Why
`/feat` phase 8 marks the state file done only after the shipper has
committed it, and only in the local copy, so main keeps `Current phase: 8
Ship` (specs 004, 005 and 006 today) and `/feat resume` offers runs whose PR
is already merged.

## Behaviour
- Before each shipper spawn, `/feat` writes `Current phase: done
  (shipping)` and `- [x] 8 Ship` into the state file, as `/fix` does in its
  phase 5, so the copy the shipper commits is already done. That includes a
  re-spawn after a conflict, a go-back or a manual fix.
- A hard error (nothing pushed) sets `Current phase: 8 Ship` back in the
  local copy, so resume finds the run; after the PR, the local copy may say
  `done (PR #N)`.
- `/feat`'s done marker is a `Current phase:` that starts with `done`,
  except a `done (shipping)` run whose branch has no upstream yet (an
  interrupted ship stays resumable), as in `/fix`.
- Resume, for both skills, also skips a state file whose `Branch:` has a
  merged or closed PR (`gh pr list --head <branch> --state all`). If `gh`
  fails, nothing is skipped.
- The stale state files of specs 004, 005 and 006 say `done (PR #25)`,
  `done (PR #35)` and `done (PR #40)`.

## Acceptance
- `grep -n "Current phase" specs/*/feat-state.md` shows no `8 Ship` on main.
- `/feat`'s phase 8, its harness values and `docs/workflow.md` say the state
  file is marked `done (shipping)` before the shipper spawns.
- The harness's Resume names the merged-or-closed PR skip.
- `mise run lint` and `mise run test:apm` pass.
