# Brief: let /brief grow a tiny brief into a full one
- Size: tiny — skill and docs text only, ~6 files, an additive argument form
- Short name: brief-grow
- Issue: #44

## Why
When `/tiny` bails out on a feature, the tiny brief it wrote holds the answers
so far, but `/brief` can't take a brief and `/feat` has no rule for
`Size: tiny`, so the work starts over or builds from a cut-down brief.

## Behaviour
- `/brief <path>` with a `Size: tiny` brief takes it as the draft: it skips
  the `/tiny` offer, asks only what the tiny brief leaves open (Today, Out
  of scope, Alternatives rejected, Constraints, plus anything new), sizes
  it, and runs the usual fresh-reader review and gate.
- It keeps the short name and the `Issue:` line (so the card moves back to
  Brief) and writes the full brief to `specs/briefs/<short-name>.md` of the
  checkout `/brief` runs in: in place when the brief is already there; from
  a `/tiny` worktree it lands in this checkout, the worktree left as it was.
- `/brief <path>` with any other size points to `/feat <path>` and stops.
- `/feat` given a `Size: tiny` brief stops and points to `/tiny <path>`,
  or `/brief <path>` when it outgrew tiny.
- `/tiny`'s bail-out for a feature hands off `/brief <tiny brief's path>`
  when it wrote one, else `/brief #N` or `/brief "<ask>"`.
- `docs/usage.md` and `docs/workflow.md` say the same.

## Acceptance
- brief, feat and tiny SKILL.md and both docs describe the handoff the same
  way; `/brief`'s argument-hint and description list the brief path.
- `mise run lint` and `mise run test:apm` pass; `/tiny` stays under 200
  lines.
