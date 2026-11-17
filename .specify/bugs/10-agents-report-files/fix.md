# Bug Fix: Orchestrators accept reported artifacts without checking they exist

- **Slug**: 10-agents-report-files
- **Fixed**: 2026-11-17
- **Assessment**: ./assessment.md
- **Status**: applied

## Summary

Every agent's report format now ends with a `Wrote:` line (absolute paths, or `none`), and the shared harness gained a "Reported files" rule: before accepting a report, the orchestrator runs a listed existence command (`ls -d -- '<path>' …`) on those paths and treats a missing one (or a missing `Wrote:` line, or an artifact path left off it) as a failed phase, which is a hard gate straight away with no automatic retry. Both `/feat` and `/fix` list the command among their *commands besides the tracker* and name the check in their gate text.

## Changes

| File | Change | Notes |
|------|--------|-------|
| `.apm/skills/feat/references/harness.md` | modified | new `## Reported files` section: the `Wrote:` contract, the `ls -d` check, failed phase = hard gate, log `- [!] <N> <phase> — reported <path> not on disk`, recommend "back to N"; generic wording (lint grep clean) |
| `.apm/skills/feat/SKILL.md` | modified | *Commands besides the tracker* adds `ls -d -- '<path>' …`; a note under the phases table; §2 blocker text (Spec path missing or not on `Wrote:`); §3 no-gate case turns hard on a missing path; §5 hard gate row; §6 check after each implementer |
| `.apm/skills/fix/SKILL.md` | modified | same harness value; note under the phases table; phase 1 "Reported files first" before the stop rows; phase 2 soft condition and a gate row; phase 3 a first gate row (no verdict logged) |
| `.apm/skills/brief/SKILL.md` | modified | the brief reviewer's report ends with `Wrote: none`; a path there is surprising |
| `.apm/agents/feat-specifier.agent.md` | modified | `Wrote:` line (spec.md, checklists) and the note that the orchestrator checks it |
| `.apm/agents/feat-planner.agent.md` | modified | `Wrote:` line (plan.md, design docs, spec.md in amend mode) |
| `.apm/agents/feat-tasker.agent.md` | modified | `Wrote:` line (tasks.md, artifacts fixed) |
| `.apm/agents/feat-implementer.agent.md` | modified | `Wrote:` line: created files plus artifacts (tasks.md, fix.md, renamed fix-<n>.md); never modified-only or deleted files |
| `.apm/agents/feat-bug-assessor.agent.md` | modified | `Wrote:` in both modes (assessment.md / test.md and renamed attempts; `none` with `Assessment: none`); never temp scratch files |
| `.apm/agents/feat-shipper.agent.md` | modified | `Wrote:` line: created files/dirs at final paths (numbered spec dir, new docs; not the PR body file) |
| `.apm/agents/feat-brief-reviewer.agent.md` | modified | `Wrote: none` |
| `.apm/agents/feat-design-reviewer.agent.md` | modified | `Wrote: none` |
| `.apm/agents/feat-code-reviewer.agent.md` | modified | `Wrote: none` |
| `docs/workflow.md` | modified | the check after the gate legend, a `/fix` Gates bullet, and the `Wrote:` contract under the agents table |

## Diff Highlights (optional)

harness.md, `## Reported files`:

> - Run `ls -d -- '<path>' …` on every path of its `Wrote:` line (listed among the *commands besides the tracker*). It prints names, never content: it is not code reading. Skip it for `Wrote: none`.
> - A failed phase is a **hard gate** straight away, whatever the gate would have been, with no automatic retry …

## Tests Added or Updated

- None: the change is to prompts and docs; no script was added, so no bash test under `tests/` (the assessment asked for one only if a helper script was added).

## Local Verification

- Commands run: `mise run lint` → pass (shellcheck, actionlint, py_compile, plugin validate, harness.md word grep); `mise run test:apm` → pass (9 agents, 6 skills); `mise run test:tracker` → pass; `mise run test:spec-number` → pass
- Manual checks: harness.md grep for `/feat`-only words is clean; diagrams (`gates.d2`, `chain.d2`, `models.svg`) unchanged since no phase, gate kind or size-table row changed, so no re-render.

## Deviations from Assessment

None. The user's answers replaced the assessment's open points: read-only agents report `Wrote: none`; the implementer lists created files plus its artifacts, not modified or deleted ones; a missing path is a hard gate straight away (no automatic retry, unlike the preferred remediation's "re-spawn once").

## Follow-ups

- Live check in the next `/feat` or `/fix` run that agents emit the `Wrote:` line and the orchestrator runs `ls -d` on it.
- A refused edit to an existing file is still not caught (the file exists); only refused creations and rewrites of missing files are.
