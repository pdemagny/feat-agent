# Brief: label issues created from a brief with a Kind line
- Size: tiny — one header line, ~20 lines of tracker.sh, its tests and docs
- Short name: brief-kind-label
- Kind: feat
- Issue: #45

## Why
`tracker.sh create-issue` labels an issue made from a bug assessment `bug`
but leaves one made from a brief unlabelled, while the roadmap wants every
issue labelled `feat` or `bug`; with `/tiny`, a brief can describe a fix.

## Behaviour
- A brief's header may hold `- Kind: feat | bug | none`: `/brief` writes
  `feat`; `/tiny` takes it from its commit type (`feat` → `feat`, `fix` →
  `bug`, anything else, e.g. a refactor or docs, → `none`). Size stays on
  the board's Size field: no `tiny` label.
- `create-issue` on a brief passes `--label feat` or `--label bug`, no label
  for `none`, and `--label feat` when the line is missing (older `/brief`
  briefs); a `Kind:` line holding anything else is refused (exit 2) before
  any gh call.
- The existing retry without the label applies when the repo has none,
  naming the label in its note.

## Acceptance
- `mise run test:tracker` covers the line present (`bug`, `none`), missing
  (`feat`), malformed (exit 2, no gh call) and a missing `feat` label
  (retry).
- The contract (`specs/001-board-tracking/contracts/tracker-cli.md`), both
  brief templates and `docs/install.md` say the same.
- `mise run lint` and `mise run test:apm` pass; `/tiny` stays under 200
  lines.
