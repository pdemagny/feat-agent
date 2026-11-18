# Bug Verification: speckit-analyze cannot find the unnumbered spec dir, and the phase 5 gate hides it

- **Slug**: 14-speckit-analyze-unnumbered
- **Tested**: 2026-11-18
- **Assessment**: ./assessment.md
- **Fix**: ./fix.md
- **Result**: partial

## Summary

Re-verified the whole fix after the code-review fixes (B1 single-quoted feature dir, B2 separate wording for `Analyze: not run` and a missing line, std1 design.md overrides row). The resolver failure still reproduces when the dir is not handed over and is gone with the tasker's documented command, in its single-quoted form too, also for a scratch path containing a space, for both `check-prerequisites.sh` and `setup-tasks.sh`, with no `.specify/feature.json` written. The tasker's `Analyze:` line, the phase 5 gate reading of it and the docs mirror agree, and all four project checks pass. One implementer-listed item (a real tasker spawn under the worktree guard) could not be exercised without a live /feat run, so the result is partial. A previous report is kept as `test-1.md`.

## Checks Performed

| Check | Command / Action | Result | Notes |
|-------|------------------|--------|-------|
| Baseline (bug still present when the dir is not handed over) | `.specify/scripts/bash/check-prerequisites.sh --json --require-spec --require-tasks --include-tasks` (no env, no `.specify/feature.json`) | pass | Exit 1, "Feature directory not found": the original symptom |
| Reproduction (post-fix): analyze prerequisite, path with a space | `SPECIFY_FEATURE_DIRECTORY="/tmp/fix14 test space/specs/some-feature" SPECIFY_FEATURE_NO_PERSIST=1 .specify/scripts/bash/check-prerequisites.sh --json --require-spec --require-tasks --include-tasks` | pass | Exit 0, `FEATURE_DIR` is the unnumbered dir with the space; scratch dir (spec.md, plan.md, tasks.md) under the system temp dir, since removed |
| Reproduction (post-fix): analyze prerequisite, literal single-quoted form as documented in the tasker | `SPECIFY_FEATURE_DIRECTORY='/tmp/fix14 test space/specs/some-feature' SPECIFY_FEATURE_NO_PERSIST=1 .specify/scripts/bash/check-prerequisites.sh --json --require-spec --require-tasks --include-tasks` | pass | Exit 0, same `FEATURE_DIR` |
| Reproduction (post-fix): tasks prerequisite, path with a space | `SPECIFY_FEATURE_DIRECTORY="/tmp/fix14 test space/specs/some-feature" SPECIFY_FEATURE_NO_PERSIST=1 .specify/scripts/bash/setup-tasks.sh --json` | pass | Exit 0, same `FEATURE_DIR`, template returned |
| Why B1 matters (unquoted path with a space) | same env prefix without quotes | pass | The shell splits the path and fails (`condition expected: space/specs/some-feature`), so the quoting is needed |
| No per-checkout state written | `ls .specify/feature.json`; `/usr/bin/git status --short` | pass | No feature.json; only the four intended modified files and the bug dir |
| Report-format contract in sync | `rtk grep -n Analyze` over `.apm/agents/feat-tasker.agent.md`, `.apm/skills/feat/SKILL.md`, `docs/workflow.md`, `docs/design.md`; read the diff | pass | Tasker report line `Analyze: <ran \| not run (<error>; cross-checked by hand)>, for the last run`; SKILL.md `## 5. Tasks` is hard on `not run` and, worded separately, on a missing line; gate table row 5 and docs/workflow.md (matrix row and `### 5 Tasks`) mirror it; docs/design.md overrides table lists the tasker's override for `speckit-tasks` and `speckit-analyze` |
| Diagrams | `rtk grep -rn analyze docs/diagrams/*.d2` | pass | Gate nodes carry no conditions, so no re-render is needed |
| Lint | `mise run lint` | pass | "Validation passed"; harness/rebase grep and /tiny length cap pass; README marketplace advice is pre-existing and non-blocking |
| APM test | `mise run test:apm` | pass | Exit 0 |
| Tracker test | `mise run test:tracker` | pass | Exit 0, all cases ok |
| Spec-number test | `mise run test:spec-number` | pass | "all spec-number tests passed" |
| Worktree guard accepting the env-prefixed command (now quoted) in a real tasker spawn | needs a live /feat run | not-run | No live /feat run in this phase (see Residual Risks) |

## Output Excerpts

```
baseline:  ERROR: Feature directory not found. Set SPECIFY_FEATURE_DIRECTORY or run the specify command to create .specify/feature.json.
           ERROR: Failed to resolve feature paths   (exit 1)
check-prerequisites (quoted, space): {"FEATURE_DIR":"/tmp/fix14 test space/specs/some-feature","AVAILABLE_DOCS":["tasks.md"]}   (exit 0)
setup-tasks (quoted, space):         {"FEATURE_DIR":"/tmp/fix14 test space/specs/some-feature","AVAILABLE_DOCS":[],"TASKS_TEMPLATE":...}   (exit 0)
unquoted, space: (eval):1: condition expected: space/specs/some-feature
test:spec-number: all spec-number tests passed
```

## Residual Risks

- Whether the worktree guard accepts the env-prefixed command inside a real `feat-tasker` spawn was not tested. The same command shape, quoted and with a space in the path, ran without refusal in this test agent's own worktree session, which is suggestive but is not a tasker spawn. If it is refused, the tasker reports `Analyze: not run` and the phase 5 gate is hard, so the failure is visible rather than hidden.
- The agent prompt and gate wording are prose read by models; no automated test checks the tasker report against the orchestrator, so the contract is verified only by inspection.
- `feat-planner` (`setup-plan.sh`) and `feat-implementer` (`check-prerequisites.sh`) resolve the dir the same way and were left out by the user's decision.
- `docs/workflow.md` row 5 "Produces" still says "analysis clean" (code review std2, skipped by the reviewer: the gate column states the not-run case).

## Recommendation

Hold for the one unverified item, or accept it: the fix, including the quoted form and a path with a space, is correct as far as it can be checked offline, and its worst case (guard refusal) now surfaces as a hard gate. Confirm on the next real /feat run that the tasker's report shows `Analyze: ran`.
