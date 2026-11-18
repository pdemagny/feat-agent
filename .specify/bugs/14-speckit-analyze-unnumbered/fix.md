# Bug Fix: speckit-analyze cannot find the unnumbered spec dir, and the phase 5 gate hides it

- **Slug**: 14-speckit-analyze-unnumbered
- **Fixed**: 2026-11-18
- **Assessment**: ./assessment.md
- **Status**: applied

## Summary

The tasker now hands Spec Kit's prerequisite scripts the unnumbered feature dir with a plain env-prefixed command, reports whether analyze ran (`Analyze: ran | not run (<error>; cross-checked by hand)`), and `/feat` phase 5 holds a hard gate when that line is `not run` or missing. The preferred remediation alone, as the user chose; the specifier alternative was not applied.

## Changes

| File | Change | Notes |
|------|--------|-------|
| `.apm/agents/feat-tasker.agent.md` | modified | Paragraph telling it to run `setup-tasks.sh` / `check-prerequisites.sh` as `SPECIFY_FEATURE_DIRECTORY=<absolute feature directory> SPECIFY_FEATURE_NO_PERSIST=1 .specify/scripts/bash/<script> <its arguments>` (no `$(…)`); step 2: when analyze still can't run, cross-check by hand and report `Analyze: not run`; report gains the `Analyze:` line |
| `.apm/skills/feat/SKILL.md` | modified | Gate table row 5 adds "analyze not run"; `## 5. Tasks` reads the `Analyze:` line and holds a hard gate on `not run` or a missing line, saying so under "What you should know" |
| `docs/workflow.md` | modified | Mirrors gate row 5 in the phase matrix and the `### 5 Tasks` paragraph |

## Diff Highlights (optional)

Tasker report, new line:

```
Analyze: <ran | not run (<error>; cross-checked by hand)>, for the last run
```

## Tests Added or Updated

- None: the repo has no test that checks agent report formats against the orchestrator (`mise run lint` greps only `harness.md`/`rebase.md`), so there is nothing to extend.

## Local Verification

- Commands run: `mise run lint` → pass; `mise run test:apm` → pass; `mise run test:tracker` → pass; `mise run test:spec-number` → pass.
- Manual checks: in the worktree with no `.specify/feature.json`, with a scratch unnumbered dir `specs/zz-fix14-check/` (spec.md, plan.md, tasks.md; removed afterwards), the documented command form resolved it for both scripts: `check-prerequisites.sh --json --require-spec --require-tasks --include-tasks` → `FEATURE_DIR` = that dir, exit 0; `setup-tasks.sh --json` → same `FEATURE_DIR`, exit 0; no `.specify/feature.json` written.

## Deviations from Assessment

- None. Diagrams (`gates.d2`, `chain.d2`) are unchanged: they show phase 5's gate as "fix serious gaps, if any" without listing its conditions, so the new condition needs no re-render.

## Follow-ups

- Whether a worktree guard accepts the env-prefixed command was not tested in a real `/feat` run; if it is refused, `Analyze: not run` now makes the gate hard.
- `feat-planner` (`setup-plan.sh`) and `feat-implementer` (`check-prerequisites.sh`) resolve the dir the same way; a follow-up issue if they fail too.
