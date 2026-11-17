# Bug Verification: Orchestrators accept reported artifacts without checking they exist

- **Slug**: 10-agents-report-files
- **Tested**: 2026-11-17
- **Assessment**: ./assessment.md
- **Fix**: ./fix.md
- **Result**: partial

## Summary

Cycle: after review fixes (previous attempt: ./test-1.md, partial). The six review fixes (B1, B2, B3, S1, [std]1, C1) are all present and the two sides of the report contract still agree. All 9 agent prompts end with their report-format block and a `Wrote:` line. The harness now accepts only absolute, in-worktree paths free of `'`, newline, `$` and backtick, and logs the actual failure reason. All four project checks pass. The original symptom (a model-generated report naming a file whose write was refused) needs a live `/feat` or `/fix` run, which the user accepted is not available, so the result stays partial.

## Checks Performed

| Check | Command / Action | Result | Notes |
|-------|------------------|--------|-------|
| Reproduction (post-fix) | live `/feat` or `/fix` run with a refused Write | not-run | no live run available (accepted by the user); judged on static evidence plus the check command |
| Existence command | `ls -d -- <present> <missing>`; `ls -d -- <present>` | pass | missing path named on stderr, exit 2; present only: exit 0 |
| Path-acceptance rule (S1) | scratch script under /tmp modelling the harness rule on 8 sample paths | pass | good path and a missing in-worktree path accepted; path with `'`, `$(…)`, backticks, a newline, a relative path and `/etc/passwd` all refused before `ls` |
| B1 specifier/planner/tasker `Wrote:` | read the diff of the three agent files | pass | spec.md / plan.md / tasks.md "always, plus every other file you created or changed in this spawn"; /feat §2 (`Spec:` on `Wrote:`) and §5 (`Tasks:` on `Wrote:`) agree |
| B2 absolute artifact lines | read the diff of bug-assessor and implementer | pass | `Assessment:`, `Test report:` and `Bug fix (bug mode):` say `<absolute path>` |
| B3 logged failure reason | read harness.md `## Reported files` | pass | reason is `no Wrote: line`, `<path> refused (<why>)`, `<path> not on Wrote:` or `<path> not on disk`; hard gate, no retry, "back to N" |
| [std]1 agents end with the report block | `tail -n 3` of all 9 `.apm/agents/*.agent.md` | pass | each ends with `Wrote: …` then the closing fence; no paragraph after it; "never report a file you haven't seen written" appears once per agent (notes merged, not duplicated) |
| C1 skills point to the harness | read `/feat` §3, §6 and `/fix` phases 1, 2, 3 | pass | each says "(harness, Reported files)" with only the artifact-on-`Wrote:` condition restated; generic note under each phases table |
| Both sides agree | compared every report line the skills expect against the agent formats | pass | `Spec:`, `Plan:`, `Tasks:`, `Assessment:`, `Bug fix (bug mode):`, `Test report:` paths each belong on the agent's `Wrote:`; `Assessment: none` goes with `Wrote: none`; reviewers `Wrote: none` (/brief says so) |
| harness.md free of /feat-only words | `grep -Eic 'specifier\|planner\|tasker\|spec\.md\|brief\|phase [0-9]\|/feat'` | pass | 0 matches |
| docs/workflow.md mirrors | read the diff | pass | gate legend (refusal rules, `ls -d`, hard gate, no retry), `/fix` Gates bullet, agents-table paragraph on `Wrote:` |
| Lint | `mise run lint` | pass | exit 0; plugin validate passes (advice about README install line only) |
| APM package | `mise run test:apm` | pass | exit 0; 9 agents, 6 skills |
| Tracker tests | `mise run test:tracker` | pass | exit 0 |
| Spec-number tests | `mise run test:spec-number` | pass | exit 0, "all spec-number tests passed" |

## Output Excerpts

```
ACCEPTED: <worktree>/.specify/bugs/10-agents-report-files/assessment.md
ACCEPTED: <worktree>/.specify/bugs/10-agents-report-files/nope.md
REFUSED (quote): <worktree>/it's.md
REFUSED (dollar): <worktree>/a$(id).md
REFUSED (backtick): <worktree>/a`id`.md
REFUSED (newline)
REFUSED (not absolute): relative/spec.md
REFUSED (outside worktree): /etc/passwd
ls: cannot access '<worktree>/.specify/bugs/10-agents-report-files/nope.md': No such file or directory   (exit 2)
.claude/agents     9
.claude/skills     6
all spec-number tests passed
```

## Residual Risks

- The symptom was never reproduced or shown fixed end to end: whether live agents emit the `Wrote:` line and the orchestrator applies the acceptance rule and runs `ls -d --` is untested.
- The harness says "inside the worktree" without saying to refuse `..` segments; a path such as `<worktree>/../x` passes a prefix check. Minor: `ls` only prints names, so the effect is an existence probe, not a read.
- A refused edit to an existing file is not caught (the file exists); only refused creations and rewrites of missing files are. The shipper's `Wrote:` also omits edited docs (B4, rejected by the user).
- Gate change not in `docs/diagrams/gates.d2` / `chain.d2` (rejected by the user, logged).

## Recommendation

Hold at partial. The static contract, docs, the path rule, the existence command and all four project checks are good. To reach verified, run the next `/feat` or `/fix` and confirm the agents emit `Wrote:` and the orchestrator applies the check (ideally with one refused Write), or accept the static evidence and go on explicitly.
