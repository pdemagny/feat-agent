# Quickstart: validating the soft spec gate

The change is prompt and doc text, so most checks are reads and greps in
this repo. Live runs need a scratch project with Spec Kit and this checkout
installed (`./install.sh`).

## Offline

| #  | Check | Expect |
| -- | ----- | ------ |
| Q1 | `mise run lint` | passes; the harness grep finds no `/feat`-only word, and `references/harness.md` is unchanged (`git diff --quiet -- .apm/skills/feat/references/harness.md`) |
| Q2 | `mise run test:apm` | passes |
| Q3 | `grep -Pzo 'only\s+place' .apm/skills/feat/SKILL.md docs/workflow.md` (multiline-safe: the phrase wraps across lines in both files today) | no output, exit 1 (phase 2 is no longer "the only place questions are asked") |
| Q4 | `grep -Pzo 'phase\s+2\s+answer' .apm/skills/feat/SKILL.md docs/workflow.md` | no output, exit 1: the checklist answer is the one already given, at phase 2 or at the summary gate |
| Q4b | `grep -n '^. 2 . Specify' .apm/skills/feat/SKILL.md docs/workflow.md`, then read both rows (the phases-and-gates row 2 of SKILL.md, the phases-at-a-glance row 2 of docs/workflow.md, line 27 today) | each gate cell says hard only on an open marker (question) or a blocker, else soft with the summary at the next gate; neither says "the only place questions are asked" nor names a size increase |
| Q5 | Read the phases-and-gates table and sections 2–5 of `.apm/skills/feat/SKILL.md`, then `docs/workflow.md` (phases at a glance rows 2–4, the "Hard gates" row, phase details 2–5), `docs/usage.md` ("Answering a gate"), `docs/design.md` (`speckit-implement` row) and README.md's "You decide at a few gates" sentence | each states the four points of [contracts/gates.md](contracts/gates.md), "Wording to carry", and none contradicts them (SC-005) |
| Q6 | `git diff .apm/agents/feat-planner.agent.md` and `git diff --quiet -- .apm/agents/feat-specifier.agent.md` | the planner gains exactly the clause of [contracts/gates.md](contracts/gates.md), after "apply edits as given;", with the header and the report block unchanged (FR-014); the specifier is unchanged |
| Q6b | Read sections 2–4 of `.apm/skills/feat/SKILL.md` | section 2 makes no size increase a phase 2 condition (FR-001), and carries the blocker test (FR-019) and "the latest phase 2 line decides" (FR-020); sections 3 (large) and 4 carry the data-model sentence on the gate's Log line verbatim (FR-021); section 4, large, says the phase 4 gate notes a plan amended after phase 3 (FR-022) |
| Q7 | `git diff --stat` | only the files in plan.md's Source Code list, plus this feature dir |

## Live (optional, one scratch project)

| #  | Scenario | Expect |
| -- | -------- | ------ |
| L1 | `/feat` on a small brief precise enough to leave no open marker (US1, US3, US4) | phase 2 prints one line and goes on; Log `2 Specify — soft` with the four summary lines; the 3–4 gate opens with `**The spec (phase 2 didn't stop):**` and numbers the spec assumptions first; "ok" logs them as kept |
| L2 | Same, but stop the session after phase 2, `/clear`, `/feat resume` (US6) | the 3–4 gate shows the summary, taken from the Log |
| L3 | At the 3–4 gate of L1, overturn one spec assumption and accept a finding (US5) | one fresh `feat-planner` amend; spec.md and plan.md both carry the change; no specifier spawn |
| L4 | A brief with a deliberate ambiguity (US2) | phase 2 stops with the marker and a recommended answer; Log `2 Specify — hard (1 open marker)`; the 3–4 gate has no spec block |
| L5 | `/feat` on a brief with `Size: large` and no open marker (US3, US5) | phase 2 soft; the phase 3 gate opens with the spec block; a spec change asked there reaches the planner before the design reviewers start; the phase 4 gate's "What you should know" says the plan was amended |
| L6 | After L1's soft phase 2, say "back to 2" at the 3–4 gate with a change that leaves a marker open | the rerun writes `2 Specify — hard (…)`; the next 3–4 gate has no spec block (the latest phase 2 line decides) |
