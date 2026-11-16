# Research: soft spec gate

No `NEEDS CLARIFICATION` was left in the Technical Context: the feature
edits prompts and docs, with no dependency or service. The decisions below
are the ones the spec left open.

## R1. Where the soft/hard record lives

- **Decision**: in the phase 2 Log line of the state file, as the word
  right after the dash: `- [x] 2 Specify — soft …` or `- [x] 2 Specify —
  hard (<why>) …`. A phase 2 line with neither word (state files written
  before this change, including this run's own) counts as hard. Every
  phase 2 run, "back to 2" and reruns included, writes its own line, and
  the latest one decides (design review D3).
- **Rationale**: the Log is already where every gate's outcome is written
  and what `/feat resume` reads. The state-file header template lives in
  `references/harness.md`, shared with `/fix`, which has no spec gate
  (FR-016): a header field would either leak `/feat` words into it or need
  a new harness value for one skill.
- **Alternatives considered**: a `Spec gate:` header line (changes the
  shared template); a separate `## Spec summary` section (a second place to
  look and to clean up, for the same content).

## R2. Where the spec summary is kept

- **Decision**: indented sub-bullets under the soft phase 2 Log line, four
  lines: stories, requirements, spec assumptions, unchecked checklist
  items. Written by the coordinator from the specifier's report fields of
  the same names. Format in [data-model.md](data-model.md).
- **Rationale**: the coordinator already copies report content into the
  Log at every gate; it never opens spec.md (FR-015). Next to the soft/hard
  word, so one read of the line answers both "show it?" and "what?".
- **Alternatives considered**: re-reading spec.md at the next gate
  (breaks the thin-coordinator rule); keeping it only in the conversation
  (lost on `/feat resume`, FR-013).

## R3. What makes phase 2 hard: blockers, surprises, and no size rule

- **Decision**: the specifier's report has no `Blockers` line, and its
  format stays unchanged (accepted spec assumption). The test the skill
  carries: the report is a blocker when it has no `Spec:` path, or its
  Assumptions or Open markers say the brief can't be specified as written.
  Anything else surprising in the report makes the soft gate hard (harness,
  "Gates"), a remark about size included. Phase 2 has no size-increase
  rule: the skill's *size triggers* are the planner's trigger and the
  phase 5 task count, and the specifier reports no size, so a size increase
  is caught at phase 3 or phase 5 (design review D1, option a; D2).
- **Rationale**: no report-format change, so no both-sides change (principle
  IV); the harness's "anything surprising" rule covers the rest; a size
  rule at phase 2 would have nothing to read.
- **Alternatives considered**: adding `Blockers:` or a size field to the
  specifier report (rejected by the accepted assumption "specifier report
  format unchanged"); keeping "or a size increase" in the phase 2 rule
  (untestable: no source at phase 2).

## R4. The recommendation for each spec assumption

- **Decision**: "keep as written". The specifier's assumption is already
  the decision it took; "ok" at the summary gate keeps them all. For the
  checklist question, the coordinator gives its recommendation (proceed, or
  fix the item first) as it does at today's phase 2 gate.
- **Rationale**: the specifier's report has no separate recommendation
  field and stays unchanged.

## R5. Order inside the summary-carrying gate

- **Decision**: the spec block comes first (summary, then its questions:
  spec assumptions, checklist question), then the gate as today: on small
  and medium the paraphrase, approach, what it touches, assumptions, any
  size increase (still the first of the remaining questions), findings; on
  large the phase 3 contents. "Your call" numbers the spec block's
  questions first.
- **Rationale**: FR-005 and US3 ask for the summary "before anything else";
  a size increase stays first among the plan and review questions as
  section 4 says today.

## R6. Who applies a spec change asked after a soft phase 2

- **Decision**: `feat-planner` in amend mode, with the accepted findings in
  the same pass (small, medium) or right away at the phase 3 gate (large),
  then phase 4's reviewers are spawned on the updated files. The *artifact
  owners* harness value in `feat/SKILL.md` names this, so the harness rule
  "changes go back to the agent that owns the artifact" still holds. After
  the phase 3 gate on large, the run goes on to phase 4 once the amend
  reports; it doesn't stop again for the amend.
- **Rationale**: brief constraint and rejected alternative (no specifier
  spawn). Continued or fresh follows the harness: the summary gate is hard
  whenever the user can ask for a change, so the planner is spawned fresh.
- **Alternatives considered**: the specifier, then the planner (rejected in
  the brief).

## R7. The planner prompt change

- **Decision**: one clause, appended after "apply edits as given;" so it
  ends that sentence, worded exactly as in
  [contracts/gates.md](contracts/gates.md) (the single source). The
  amend-mode header ("after the design review, or the user's edits at a
  gate") is left as is: naming spec changes there too would be a second
  phrase. Its report format is untouched; "one line per finding" covers a
  spec change as a line.
- **Rationale**: brief constraint "at most one phrase"; FR-014; design
  review D8.

## R8. The README sentence

- **Decision**: only the sentence "You decide at a few gates (the brief,
  the spec, which review findings to fix)" changes, to say the spec stops
  only on an open question. The paragraph under the diagram describes the
  diagram, which is out of scope and still draws the spec gate; it stays.
- **Alternatives considered**: rewording the diagram legend too (drifts
  from a diagram that is updated separately).
