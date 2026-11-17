# Bug Assessment: Orchestrators accept reported artifacts without checking they exist

- **Slug**: 10-agents-report-files
- **Created**: 2026-11-17
- **Source**: pdemagny/feat-agent#10 (https://github.com/pdemagny/feat-agent/issues/10), fetched with `gh issue view` (host: github.com, allowlisted)
- **Verdict**: valid
- **Severity**: medium

## Report (verbatim or summarized)

> **Agents report files they never wrote**
>
> ## Problem
> An agent's report can claim a file it never wrote. In two real runs the specifier reported `spec.md` written while its write had been refused: the file was not on disk, and the run had to go back to phase 2 when the planner found it missing.
>
> The orchestrator takes reports at their word, so a gate can approve an artifact that does not exist.
>
> ## Done when
> - Every agent's report lists the paths it wrote.
> - The orchestrator checks those paths exist (a listed command, not code reading) before it accepts the report, and treats a missing one as a failed phase.
> - The report format change is made on both sides (agents and the skills that read them).

## Symptom

A phase agent (seen twice with `feat-specifier`) reports an artifact path such as `Spec: …/spec.md` although its Write was refused and the file is not on disk; `/feat` accepts the report, passes the gate (soft or hard), and the failure only surfaces a phase later when the next agent cannot find the file. Expected: the orchestrator notices the missing file when the report arrives and treats the phase as failed.

## Reproduction

1. Run `/feat <brief>` in a worktree where the specifier's Write to `specs/<short-name>/spec.md` is refused (e.g. by the worktree guard or a permission denial).
2. The specifier still returns `Spec: <path>` (its only guard is the prompt line "never report a file you haven't seen written").
3. `/feat` phase 2 gate checks only that the report has a `Spec:` line (`.apm/skills/feat/SKILL.md` §2 "A blocker: the report has no `Spec:` path"), goes soft and spawns the planner, which finds no spec.md.

Not run here: this needs a live `/feat` run with a model-generated report after a refused write [NEEDS CLARIFICATION: transcript of the two original runs]. The code-level part is confirmed by reading: no skill or harness rule checks a reported path on disk.

## Suspected Code Paths

- `.apm/skills/feat/references/harness.md` "You are a thin orchestrator" — orchestrators may run only the tracker and the skill's *commands besides the tracker*; there is no rule to check reported paths, and "A subagent's report is an input" is taken at its word.
- `.apm/skills/feat/SKILL.md:52` — *Commands besides the tracker*: only git; no existence-check command is listed, so the orchestrator has no sanctioned way to verify.
- `.apm/skills/feat/SKILL.md:168-173` (§2 gate) — the blocker test is "the report has no `Spec:` path"; a present but false path passes. Same pattern for the planner (§3), tasker (§5), implementer (§6).
- `.apm/skills/fix/SKILL.md:52-57` — same harness value for `/fix`; `Assessment:` (l.253), `Bug fix (bug mode): <fix.md path>`, `Test report:` (l.360, 404) are trusted as given.
- `.apm/agents/feat-specifier.agent.md:40-50`, `feat-planner.agent.md:53`, `feat-tasker.agent.md:42`, `feat-implementer.agent.md:80-89`, `feat-bug-assessor.agent.md:120-160`, `feat-shipper.agent.md:114-121` — report formats: some name one path (`Spec:`, `Plan: … (+ other artifacts written)`, `Tasks:`), the implementer gives only `Files changed: <count>; notable ones`, so no format lists every written path.
- `docs/workflow.md:467-477` — the agents table's `Writes` column, which documents what each agent writes and must mirror any change.

## Root Cause Hypothesis

The only defence against a false path is a prompt instruction to the agent ("never report a file you haven't seen written"); the orchestrator side has no verification step and no command allowed for one, because the thin-orchestrator rule forbids reading files and the harness lists no existence check among the permitted commands. When a Write is refused and the model still emits its fixed report template, the false path flows straight into the gate. Confidence: high.

## Proposed Remediation

**Preferred**: Add one shared line to every writing agent's report, `Wrote: <absolute paths, one per line, or "none">` (specifier, planner, tasker, implementer in all modes, bug-assessor in both modes, shipper for docs it edited), and to the read-only agents (brief, design and code reviewers) as `Wrote: none` only if the orchestrator rule needs uniformity. In `harness.md`, add a rule "Check reported files": before accepting a report, run the listed existence command on its `Wrote:` paths (e.g. `ls -d -- <path> …`, or `test -e`), never read their content; a missing path (or a report with no `Wrote:` line from an agent that must write) makes the phase failed: log `- [!] <phase>: reported <path> not on disk`, re-spawn the agent once fresh with that note, and on a second miss stop at a hard gate. Add the command to both skills' *Commands besides the tracker* harness value, and make each skill's gate text use it (feat §2 blocker test, §3, §5, §6; fix phases 1–3). Keep the wording generic in harness.md (no `/feat`-only words; `mise run lint` greps it). Mirror the report change in `docs/workflow.md` (agents table / report description).

**Alternatives**:
- Check only the known artifact per phase (spec.md, plan.md, tasks.md, assessment.md, fix.md, test.md) without a `Wrote:` line: fewer format changes, but misses extra artifacts (plan's design docs) and does not meet the issue's "every agent's report lists the paths it wrote".
- Have the next agent fail fast on a missing input instead of the orchestrator checking: no orchestrator change, but the gate can still approve a missing artifact, which is the reported harm.

**Files likely to change**:
- `.apm/skills/feat/references/harness.md`
- `.apm/skills/feat/SKILL.md`
- `.apm/skills/fix/SKILL.md`
- `.apm/agents/feat-specifier.agent.md`
- `.apm/agents/feat-planner.agent.md`
- `.apm/agents/feat-tasker.agent.md`
- `.apm/agents/feat-implementer.agent.md`
- `.apm/agents/feat-bug-assessor.agent.md`
- `.apm/agents/feat-shipper.agent.md`
- `docs/workflow.md`
- possibly `.apm/skills/brief/SKILL.md` and the reviewer agents (`feat-brief-reviewer`, `feat-design-reviewer`, `feat-code-reviewer`) if read-only agents also get `Wrote: none`

**Tests to add or update**:
- `mise run lint` must stay green (harness.md generic-word grep; shellcheck if any script is touched).
- `mise run test:apm` (package still installs/validates).
- If a small helper script is added for the check, a bash test under `tests/` like the tracker/spec-number tests (no network).

## Risks & Considerations

- Changes the agent/orchestrator report contract on both sides at once (project rule: change both together); a half-changed pair breaks every run.
- The check must stay a listed command, not file reading, to keep the orchestrator thin; `ls` output is data only.
- Implementer writes many code files; listing all of them lengthens reports and the orchestrator's context. Untracked-vs-modified files: an edited existing file always "exists", so the check only catches refused creations, not refused edits.
- The shipper renames `specs/<short-name>/` to `specs/<NNN>-<short-name>/`; its listed paths must be post-rename.
- harness.md is shared by `/feat` and `/fix`: phase names and artifact names must stay out of it.

## Open Questions

- [NEEDS CLARIFICATION: Do read-only agents (brief, design, code reviewers) also carry `Wrote: none`, or is the line required only from agents that write?]
- [NEEDS CLARIFICATION: Should the implementer list every code file it touched, or only the files it created plus its artifacts (fix.md, tasks.md)?]
- [NEEDS CLARIFICATION: On a missing path, retry the agent once automatically, or go straight to a hard gate?]
