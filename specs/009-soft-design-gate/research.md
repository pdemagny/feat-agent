# Research: soft-design-gate

No `NEEDS CLARIFICATION` was left in the Technical Context. These are the
decisions the spec didn't take, made against the code as it is.

## R1 The 4c paraphrase on a soft gate

- **Decision** (approved by the user at the phase 4 gate; now FR-006): the
  soft gate still prints the paraphrase, then the one soft line (after the
  spec block when phase 2 was soft).
- **Rationale**: section 4 says every gate of this phase starts with the
  paraphrase so the user can check it against what they meant, and the spec
  keeps the paraphrase "unchanged". It costs a read, not a stop, and it is
  the only place the user sees how a fresh reader understood the design;
  `/feat` alone can't judge every contradiction with the brief.
- **Alternatives considered**: the one line only, like phase 7's soft gate
  (shorter, but the paraphrase would be seen by nobody on most small and
  medium runs; the README promises it "for you to check").

## R2 A section on every finding line

- **Decision**: `[sec]` and `[cost]` lines gain `: <section or line>` after
  the artifact, as `[design]` lines already have.
- **Rationale**: FR-004 defines the same spot as the same artifact and the
  same section or line; today only `[design]` lines carry a section, so two
  `[sec]` findings on plan.md would compare as the same spot.
- **Alternatives considered**: compare on artifact alone for `[sec]` and
  `[cost]` (false merges and false "reviewers disagree").
- **Note**: with "same section" meaning the same tag, and one lens per tag,
  rule 3 ("from different reviewers or lenses") rarely fires at phase 4;
  this follows the spec and brief and was kept at the phase 4 gate, with
  one line added: findings with different tags on the same spot stay
  separate, each with its own rec (FR-004). The section is the heading as
  written in the artifact, or a line number, so "same spot" means an
  identical heading or line.

## R3 `docs/usage.md`

- **Decision**: update its "Answering a gate" example and the paragraph
  under it.
- **Rationale**: it shows `/feat` writing "I recommend accepting" on `D`
  findings, which FR-003 removes, and says "ok" accepts every
  recommendation; SC-004 searches `docs/`. The precedent commit for phase 7
  (`9a7d55f`) changed `docs/usage.md` too.
- **Alternatives considered**: leave it (the user's guide would contradict
  the gate they see).

## R4 Shipper's "accepted design findings"

- **Decision**: `feat-shipper.agent.md` names where they come from: the
  `auto-applied` and `picked` ids of the `4 Design review` Log line, or
  `accepted` in older runs.
- **Rationale**: the Log words change from `accepted D1` to phase 7's
  `auto-applied` / `picked`; the shipper builds the PR body from the Log and
  already reads those words for its code review part. One clause, report
  format unchanged.
- **Alternatives considered**: leave it (the shipper would have to guess
  that `auto-applied` means accepted at phase 4).

## R5 "What the brief asked for" from the reviewer's seat

- **Decision**: the reviewer applies the `user` rule to the spec's stories,
  requirements, acceptance criteria and assumptions.
- **Rationale**: the reviewer gets spec and plan paths only (4c is a fresh
  reader); spec.md is written from the brief and the specifier adds little
  to it. Passing the state file (brief plus Log) would add input and show
  the reviewer earlier decisions. Errs towards `user`, which is the safe
  side.
- **Alternatives considered**: give the reviewer the state file path
  (more tokens on every phase 4 spawn, and a less fresh reader).

## R6 Log line of a `[sec]` design finding

- **Decision**: its indented Log line gives id, spot and title only.
- **Rationale**: a skipped or rejected `[sec]` finding describes a weakness
  of what ships; the state file is committed and linked from the PR, and
  the harness already keeps exploit detail out of the Log for `S` findings.
- **Alternatives considered**: a few words like other findings.

## R7 Where the rules live

- **Decision**: section 4 of `/feat` refers to harness merge rules 2, 3, 5
  and to its "ok" follow-up and Log words; `harness.md` is untouched.
- **Rationale**: brief constraint; `mise run lint` greps `harness.md` for
  `/feat`-only words, and `/fix` reads it.
- **Alternatives considered**: generalise the harness's Review findings to
  any phase (rejected by the brief: it would touch `/fix`'s file).
