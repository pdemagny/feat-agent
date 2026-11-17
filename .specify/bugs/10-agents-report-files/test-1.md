# Bug Verification: Orchestrators accept reported artifacts without checking they exist

- **Slug**: 10-agents-report-files
- **Tested**: 2026-11-17
- **Assessment**: ./assessment.md
- **Fix**: ./fix.md
- **Result**: partial

## Summary

The report contract now agrees on both sides: all 9 agent formats end with a `Wrote:` line, the shared harness has the existence-check rule (hard gate straight away, no retry), both skills list `ls -d --` among their commands and apply it in their gates, and docs/workflow.md mirrors it. All four project checks pass. The original symptom (a model-generated report naming a file whose write was refused) needs a live `/feat` or `/fix` run and was not exercised, so the result is partial.

## Checks Performed

| Check | Command / Action | Result | Notes |
|-------|------------------|--------|-------|
| Reproduction (post-fix) | live `/feat` run with a refused specifier Write | not-run | needs a live run with a model-generated report; only the check command was exercised (see below) |
| Existence command behaviour | `ls -d -- <present> <missing>`; `ls -d -- <present>` | pass | missing path: stderr names it, exit 2; present only: exit 0 |
| Every agent format ends with `Wrote:` | read the diff and `grep -c 'Wrote:' .apm/agents/*.agent.md` | pass | 9 of 9 agents; reviewers (brief, design, code) `Wrote: none`; `Wrote:` is the last line of each report block (bug-assessor: both modes) |
| Implementer scope | read `.apm/agents/feat-implementer.agent.md` | pass | created files plus artifacts (tasks.md, fix.md, renamed fix-<n>.md); modified and deleted files excluded |
| Harness rule | read `.apm/skills/feat/references/harness.md` `## Reported files` | pass | generic; `ls -d` on each `Wrote:` path; missing path, missing `Wrote:` line or artifact path absent from it = failed phase = hard gate, no automatic retry |
| Command listed in both Harness values | read `/feat` SKILL.md l.52-54 and `/fix` SKILL.md l.54-58 | pass | `ls -d -- '<path>' …` in "commands besides the tracker" of both |
| Gates apply the check | read `/feat` §2, §3, §5, §6 and `/fix` phases 1, 2, 3 | pass | plus a generic note under each phases table covering the other phases; `/brief` says reviewer ends with `Wrote: none` |
| Both sides agree | compared every report line the skills expect against the agent formats | pass | `Spec:`, `Plan:`, `Tasks:`, `Assessment:`, `Bug fix (bug mode):`, `Test report:` paths are each listed in the agent's `Wrote:`; `Assessment: none` goes with `Wrote: none` in both |
| docs/workflow.md mirror | read the diff | pass | gate legend, `/fix` Gates bullet, agents table paragraph |
| harness.md has no /feat-only words | `grep -Eic 'specifier\|planner\|tasker\|spec\.md\|brief\|phase [0-9]\|/feat'` on harness.md | pass | 0 matches |
| Lint | `mise run lint` | pass | exit 0; plugin validate warns only about a missing icon (pre-existing, not part of the result) |
| APM package | `mise run test:apm` | pass | exit 0; 9 agents, 6 skills |
| Tracker tests | `mise run test:tracker` | pass | exit 0 |
| Spec-number tests | `mise run test:spec-number` | pass | exit 0, "all spec-number tests passed" |

## Output Excerpts

```
ls: cannot access '/tmp/t10-no-such-spec.md': No such file or directory   (exit 2)
.claude/agents     9
.claude/skills     6
all spec-number tests passed
```

## Residual Risks

- The symptom was never reproduced or shown fixed end to end: whether live agents emit the `Wrote:` line and the orchestrator runs `ls -d` on it is untested.
- A refused edit to an existing file is not caught (the file exists); only refused creations and rewrites of missing files are.
- The new hard-gate condition is a gate change; `docs/diagrams/gates.d2` and `chain.d2` were not touched. The `check` workflow only compares a fresh render of the unchanged sources, so CI will not flag it; whether the diagrams should show it is a judgement call.
- Wording nit: the closing sentence of the `/feat` §6 gate edit in SKILL.md runs a long line (no lint impact).

## Recommendation

Hold at partial. The static contract, docs and all four project checks are good. To reach verified, run the next `/feat` or `/fix` and confirm the agents emit `Wrote:` and the orchestrator runs `ls -d --` on it (ideally with one refused Write), or accept the static evidence and go on explicitly.
