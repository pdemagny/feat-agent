# Brief: a security finding the reviewer would skip needs the user's answer
- Size: tiny — one merge rule in harness.md and its summary in docs/workflow.md
- Short name: s-skip-user
- Kind: feat
- Issue: pdemagny/logistics#64

## Why
At a hard code review gate, "ok" leaves every `skip`, `S` findings
included: a security finding can stay unfixed without the user ever
deciding on it.

## Behaviour
- harness.md, Review findings, gets merge rule 6: an `S` finding with
  `rec: skip` becomes `user (<the reviewer's why>)`, like rule 4 for
  high-confidence bugs. It applies to `/feat` and `/fix` alike.
- The "ok" sentence no longer says it leaves `S` findings: "ok" fixes every
  `apply` (`S` ones included) and leaves every `skip`, and no `S` finding is
  a `skip` any more.
- docs/workflow.md's summary of the merge rules names the security finding
  the reviewer would skip among those that become `user`.

## Acceptance
- harness.md lists rule 6 after rule 5; `mise run lint` passes (no
  `/feat`-only words in harness.md).
- docs/workflow.md's merge-rule summary matches harness.md.
- `mise run test:apm` passes.
