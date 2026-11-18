# Bug Verification: speckit-analyze cannot find the unnumbered spec dir, and the phase 5 gate hides it

- **Slug**: 14-speckit-analyze-unnumbered
- **Tested**: 2026-11-18
- **Assessment**: ./assessment.md
- **Fix**: ./fix.md
- **Result**: partial

## Summary

The resolver failure still reproduces without the dir and is gone when the tasker's documented env-prefixed command is used, for both `check-prerequisites.sh` and `setup-tasks.sh`, with no `.specify/feature.json` written. The tasker's `Analyze:` report line, the phase 5 gate reading of it, and the docs mirror are in place and consistent, and all four project checks pass. One implementer-listed item (a real tasker spawn under the worktree guard) could not be exercised without a live /feat run, so the result is partial.

## Checks Performed

| Check | Command / Action | Result | Notes |
|-------|------------------|--------|-------|
| Baseline (bug still present when the dir is not handed over) | `.specify/scripts/bash/check-prerequisites.sh --json --require-spec --require-tasks --include-tasks` (no env, no `.specify/feature.json`) | pass | Exit 1, "Feature directory not found": the original symptom, confirming the cause |
| Reproduction (post-fix): analyze prerequisite | `SPECIFY_FEATURE_DIRECTORY=<scratch>/specs/some-feature SPECIFY_FEATURE_NO_PERSIST=1 .specify/scripts/bash/check-prerequisites.sh --json --require-spec --require-tasks --include-tasks` | pass | Exit 0, `FEATURE_DIR` is the unnumbered dir; scratch dir (spec.md, plan.md, tasks.md) was under the system temp dir, since removed |
| Reproduction (post-fix): tasks prerequisite | `SPECIFY_FEATURE_DIRECTORY=<scratch>/specs/some-feature SPECIFY_FEATURE_NO_PERSIST=1 .specify/scripts/bash/setup-tasks.sh --json` | pass | Exit 0, same `FEATURE_DIR` |
| No per-checkout state written | `ls .specify/feature.json`; `/usr/bin/git status --short` | pass | No feature.json; only the three intended modified files and the bug dir |
| Report-format contract in sync | `grep -n Analyze` over `.apm/agents/feat-tasker.agent.md`, `.apm/skills/feat/SKILL.md`, `docs/workflow.md` | pass | Tasker report line `Analyze: <ran \| not run (...)>`; SKILL.md `## 5. Tasks` hard gate on `not run` or missing line; gate table row 5 and docs/workflow.md (matrix row and `### 5 Tasks`) mirror it |
| Lint | `mise run lint` | pass | "Validation passed"; harness/rebase grep and /tiny length cap pass; README marketplace advice is pre-existing and non-blocking |
| APM test | `mise run test:apm` | pass | Exit 0 |
| Tracker test | `mise run test:tracker` | pass | Exit 0, all cases ok |
| Spec-number test | `mise run test:spec-number` | pass | "all spec-number tests passed" |
| Worktree guard accepting the env-prefixed command in a real tasker spawn | needs a live /feat run | not-run | No live /feat run in this phase (see Residual Risks) |

## Output Excerpts

```
baseline:  ERROR: Feature directory not found. Set SPECIFY_FEATURE_DIRECTORY or run the specify command to create .specify/feature.json.
           ERROR: Failed to resolve feature paths   (exit 1)
check-prerequisites (documented form): {"FEATURE_DIR":"<scratch>/specs/some-feature","AVAILABLE_DOCS":["tasks.md"]}   (exit 0)
setup-tasks (documented form): {"FEATURE_DIR":"<scratch>/specs/some-feature","AVAILABLE_DOCS":[],"TASKS_TEMPLATE":...}   (exit 0)
test:spec-number: all spec-number tests passed
```

## Residual Risks

- Whether the worktree guard accepts the env-prefixed command inside a real `feat-tasker` spawn was not tested. (An env-prefixed plain command ran without refusal in this test agent's own worktree session, which is suggestive but is not a tasker spawn.) If it is refused, the tasker reports `Analyze: not run` and the phase 5 gate is now hard, so the failure is visible rather than hidden.
- The agent prompt and gate wording are prose read by models; no automated test checks the tasker report against the orchestrator, so the contract is verified only by inspection.
- `feat-planner` (`setup-plan.sh`) and `feat-implementer` (`check-prerequisites.sh`) resolve the dir the same way and were left out by the user's decision.

## Recommendation

Hold for the one unverified item, or accept it: the fix is correct as far as it can be checked offline, and its worst case (guard refusal) now surfaces as a hard gate. Confirm on the next real /feat run that the tasker's report shows `Analyze: ran`.
