# Brief: feat-implementer lists its artifacts on Wrote: even when it only modified them
- Size: tiny — two files, the wording of one rule and one report line
- Short name: wrote-line-artifacts
- Kind: bug
- Issue: pdemagny/logistics#65

## Why
feat-implementer's prose says `Wrote:` leaves out files it only modified,
but its format lists tasks.md, which it only ever modifies. US3 of
size-data reported `Wrote: none (modified only: …)`, which is neither a
path list nor `none`.

## Behaviour
- The report format says tasks.md always in story mode (phase 6), fix.md
  in bug mode, even when only modified.
- The prose rule leaving out modified files covers source files only.
- harness.md's Reported files says `Wrote:` is a list of absolute paths
  or the bare word `none`, nothing else.

## Acceptance
- The prose and the format of feat-implementer.agent.md agree on tasks.md
  and fix.md.
- harness.md states the `Wrote:` shape; `mise run lint` and `mise run
  test:apm` pass.
