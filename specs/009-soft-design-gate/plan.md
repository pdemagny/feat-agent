# Implementation Plan: Design review stops only on findings that need the user

**Branch**: `soft-design-gate` | **Date**: 2026-11-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/009-soft-design-gate/spec.md`

## Summary

Give phase 4 the rule phase 7 already has. `feat-design-reviewer` ends
every finding with `rec: apply | skip (<why>) | user (<why>)`; `/feat`
merges the findings into `D1…` with harness merge rules 2, 3 and 5 and never
writes its own recommendation; the small/medium "Plan and design review"
gate is hard only on a `user` finding or one of the seven other triggers
kept from today, soft otherwise (the `apply` findings go to the planner
unasked, or no planner call when there is none; after the 4c paraphrase,
one status line names the counts, the applied `[sec]` ids and any skipped
`[sec]` ids);
large is always hard with phase 7's large rule. The rules are written in
`/feat`'s section 4, referring to the harness; `harness.md` is not touched.
Docs, the two diagrams and their renders follow. Text only: no script, no
new file outside the feature dir.

## Technical Context

**Language/Version**: Markdown prompts (agent and skill files), D2 diagram sources

**Primary Dependencies**: none new; `d2` 0.9.0 (already pinned in `mise.toml`) for `mise run diagrams`

**Storage**: N/A (the state file's Log is the record; its format is set by the harness)

**Testing**: `mise run lint`, `mise run test:apm`, `mise run diagrams` with a clean `git diff --exit-code docs/img` afterwards (what the `check` workflow does); grep checks in [quickstart.md](quickstart.md)

**Target Platform**: Claude Code (the only platform `/feat` runs on)

**Project Type**: prompt package (skills + subagents) distributed by APM, plugin and `install.sh`

**Performance Goals**: fewer user stops at the design gate (SC-001); no new agent spawn, no new file read by `/feat`

**Constraints**: `harness.md` unchanged (shared with `/fix`, grepped for `/feat`-only words); reviewer report and `/feat` phase 4 change in the same commit (constitution IV); `/feat` reads no spec or plan for this (constitution I, FR-013); size table unchanged

**Scale/Scope**: about 9 files changed plus 2 re-rendered SVGs

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --------- | ----- | ------ |
| I. Thin coordinators | `/feat` compares report text only (rec values, tags, spots); no new reading of spec.md or plan.md; the judgement moves into the reviewer agent | pass |
| II. The user decides at gates | every decision that is the user's (`rec: user`, `needs user: yes`, constitution violation, blocker, size increase, contradicting paraphrase, carried checklist item, failed report check) keeps a hard gate; a soft gate reports what was applied, as phase 7's soft gate already does | pass |
| III. One source of truth | harness merge rules are referred to, not copied; size table unchanged; `docs/workflow.md`, README and `docs/usage.md` mirror `/feat` in the same commit | pass |
| IV. Fixed report formats | `feat-design-reviewer`'s report format and `/feat` section 4 change in the same commit | pass |
| V. Small and plain | rules added to existing files; section 4 replaces today's paragraph with a three-row table modelled on phase 7's; no script, no new file outside the feature dir | pass |

Post-design re-check: pass (the design below adds no file, script, agent or dependency).

## Project Structure

### Documentation (this feature)

```text
specs/009-soft-design-gate/
├── spec.md
├── plan.md              # this file
├── research.md          # decisions taken here
├── data-model.md        # finding, rec, gate, Log line
├── quickstart.md        # how to check it
├── contracts/
│   └── phase4-gate.md   # reviewer report line, merge, gate table, soft line, Log words
└── tasks.md             # phase 5
```

### Source code (repository root)

All files below exist and are changed; none is created.

```text
.apm/agents/feat-design-reviewer.agent.md   # new "## Recommendation" section; rec on every finding line of the report format
.apm/skills/feat/SKILL.md                   # phase table row 4; section 4 rewritten
.apm/agents/feat-shipper.agent.md           # "accepted design findings" read from the new Log words
docs/workflow.md                            # phase table row 4; "### 4 Design review" gate paragraph
docs/usage.md                               # "Answering a gate" example and the paragraph under it
docs/diagrams/gates.d2                      # line 26 label
docs/diagrams/chain.d2                      # g4 label
docs/img/gates.svg, docs/img/chain.svg      # re-rendered by `mise run diagrams`
README.md                                   # chain alt text
```

Not changed: `.apm/skills/feat/references/harness.md`, `.apm/skills/fix/SKILL.md`,
`.apm/agents/feat-code-reviewer.agent.md`, `.apm/agents/feat-planner.agent.md`
(its amend mode already takes "accepted findings"), the size table,
`docs/diagrams/models.py`, `docs/img/models.svg`.

**Structure Decision**: the package's existing layout; every change lands
in a file that already holds the rule it changes.

## What changes, file by file

The exact wording to aim for is in [contracts/phase4-gate.md](contracts/phase4-gate.md);
the implementer may tighten the prose but not change the values, triggers or formats.

### 1. `.apm/agents/feat-design-reviewer.agent.md` (FR-001, FR-002)

- After the severity paragraph (the one starting "Severity: **high**"), add
  a `## Recommendation` section (contract §1): every finding line ends with
  `— rec:` and one of three values, nice-to-have included; what each value
  means; the `user` rule of FR-002, including a finding that weakens a
  control the spec or plan sets (relaxes validation, widens access); the
  paraphrase carries no rec.
- Report format: append `— rec: apply | skip (<why>) | user (<why>)` to the
  three finding lines (`[sec]`, `[cost]`, `[design]`), after `severity: …`;
  `[sec]` and `[cost]` gain `: <section or line>`, and one line beside the
  format says it is the section heading as written in the artifact, or a
  line number (contract §1), so that spots compare as identical text.
  The paraphrase block, `Checked and fine:` and `Wrote: none` are unchanged.
- The lenses' content (4a, 4b, 4c passes, severity definitions) is unchanged.

### 2. `.apm/skills/feat/SKILL.md` (FR-003 to FR-013)

- **Phase table row 4** (line 131): replace the Gate cell with
  `small/medium: one gate for 3+4, **hard** on a `user` finding, a user-call
  assumption, a constitution violation, a blocker, a size increase, a
  paraphrase that contradicts the brief or a carried checklist item, else
  soft (the `apply` findings are applied); large: **hard**, findings shown
  with their recommendations`. The phase table is not fixed-width (row 7
  already runs past the separator row), so it needs no re-alignment: edit
  the cell only.
- **Section 4** (lines 279–310): rewrite as contract §2–§6:
  1. Spawn paragraph unchanged except its last sentence: "Merge the
     findings into `D1…`, drop duplicates, give each a recommendation"
     becomes the merge rule (contract §2): harness rules 2, 3 and 5
     referred to, not restated (constitution III); the same spot defined as
     the same artifact and an identical section heading or line; the same
     section as the same tag; findings with different tags on the same spot
     kept separate, each with its own rec.
  2. Paraphrase paragraph unchanged.
  3. A gate table, first match wins (contract §3), in the shape of
     section 7's.
  4. What the small/medium gate shows (today's list, with "the findings
     with their recommendations" now meaning the reviewer's `rec`).
  5. **Soft** (contract §4: the paraphrase, then the one line with
     `; security: <ids>` and, only when non-empty, `; security skipped:
     <ids>`) and **Hard** (contract §5) paragraphs.
  6. Log paragraph (contract §6), including which ids are "accepted" for
     phase 7 (7b) and the shipper, and that `skip`ped and rejected `D`
     findings are rejected findings in the reviewer context.
  7. The amend-pass paragraph (lines 304–310) unchanged except for one
     clause: accepted findings are now the `apply` findings on a soft gate
     and the picked ones on a hard gate; continued planner after soft, fresh
     after hard; a soft gate with no `apply` finding sends nothing to the
     planner (no `SendMessage`) and goes straight to phase 5.
- Nothing else in the file changes (Harness values, size table, phases 2,
  3, 5–8).

### 3. `.apm/agents/feat-shipper.agent.md` (FR-010, follows from the Log change)

Line 74, "accepted design findings": add where they come from, "(the
`auto-applied` and `picked` ids of the `4 Design review` Log line; `accepted`
in older runs)". The report format is unchanged. See research R4.

### 4. `docs/workflow.md` (FR-014)

- Phase table row 4, Gate cell: "one gate with 3: hard only on a finding
  that needs you (`user`), a user-call assumption, a constitution
  violation, a blocker, a size increase, a paraphrase that contradicts the
  brief or an unchecked checklist item after a soft phase 2, else soft and
  the `apply` findings are applied (always hard for large)". Its "Produces"
  cell becomes "a paraphrase, findings D1… with recommendations". Like
  `/feat`'s, this table is not fixed-width: edit the cells, no
  re-alignment.
- `### 4 Design review`: replace the paragraph starting "Each `D…` gets a
  recommendation" up to "…the accepted ones" with: each finding ends with
  the reviewer's recommendation (the three values; a finding that removes
  or changes what the brief asked for, or overturns a spec assumption, is
  `user`); the coordinator merges by the code review's fixed rules except
  the two that are about code; small/medium hard triggers; soft gate
  applies the `apply` findings unasked and names the applied security
  findings and any skipped ones; hard gate lists `user` first, "ok" rule; large always stops
  with every finding shown. The rest of the section (planner amend pass,
  continued vs fresh) stays.

### 5. `docs/usage.md` (SC-003, SC-004: no recommendation written by `/feat`)

The "Answering a gate" example shows `/feat`'s own "I recommend accepting".
Replace its Your call with the reviewer's recs, `user` first (contract §7),
and the paragraph below: on small and medium the gate stops only when
something needs your call; "ok" applies every `apply` and leaves every
`skip`, a `user` finding needs its own answer. Change the plain-words
example to "apply D1, leave D2: behind the VPN". See research R3.

### 6. Diagrams and renders (FR-014)

- `docs/diagrams/gates.d2` line 26: `cc -> you: check the spec, decide on
  findings that need you, if any {class: maybe}`.
- `docs/diagrams/chain.d2` `g4` label: `you check the spec,\ndecide on findings\nthat need you`
  (class `maybe` unchanged).
- Run `mise run diagrams`; commit `docs/img/gates.svg` and
  `docs/img/chain.svg`. `models.svg` must come out unchanged.

### 7. `README.md` (FR-014)

Chain alt text: "you check the spec and decide on findings, then spec and
plan are amended" becomes "you check the spec and decide on findings that
need you, then spec and plan are amended". The gates alt text already says
"when the plan and design review need your call": unchanged.

## Order and commit

One `feat(feat)` commit for items 1–7 (constitution III and IV: report
format, coordinator and mirrors together), subject written for users, e.g.
`feat(feat): stop the design review gate only for findings that need you`;
the shipper adds `docs(specs)` for the feature dir. Order inside the
work: 1, 2, 3, then docs 4–7, then `mise run diagrams`, `mise run lint`,
`mise run test:apm`, and SC-004's four greps (quickstart §2), each with no
match.

## Complexity Tracking

No violations.
