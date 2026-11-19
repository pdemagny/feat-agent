# Quickstart: validating the change

Run from the worktree root unless a step says otherwise. Paths are
project-relative.

## 1. Preload and hook check (first task, FR-011)

Prerequisite: `.apm/agents/feat-tasker.agent.md` already denies `Skill`
and carries the new hook line
([contract](contracts/setup-hook-gate.md#agent-hook-line-feat-specifier-feat-planner-feat-tasker)).
Method and pass rule: [research.md R2](research.md#r2-how-the-first-task-checks-the-real-taskers-preload-fr-011).

1. `mktemp -d` → `<scratch>`; create `<scratch>/.claude/agents`,
   `<scratch>/.claude/skills` and `<scratch>/.specify`.
2. Copy `.apm/agents/feat-tasker.agent.md` to
   `<scratch>/.claude/agents/feat-tasker.md`, and `.claude/skills/speckit-tasks`
   and `.claude/skills/speckit-analyze` into `<scratch>/.claude/skills/`
   (`command cp -Rf`). Write `<scratch>/.specify/extensions.yml` with the
   R2 `before_tasks` hook (`probe`, `speckit.probe.hello`, enabled,
   mandatory) using Write.
3. From `<scratch>`: `claude -p --model haiku --allowedTools Agent --output-format json "<the R2 prompt>"`;
   note `session_id`.
4. Read the subagent transcript
   `~/.claude/projects/<scratch path, encoded>/<session_id>/subagents/agent-*.jsonl`
   and list its `tool_use` names and inputs.

Expected: both skills named with their `SKILL.md`'s first `#` heading; no
`Skill` tool; `Skipped hooks:` names `before_tasks` `speckit.probe.hello`;
the transcript has no call that runs the hook; only read-only access to
`.specify/extensions.yml` (an existence check or a Read). Preload failure or hook failure:
stop (R2, On preload failure / On hook failure). Remove `<scratch>`.

## 2. Denials (US1, FR-001, FR-002, FR-010)

`grep -H '^disallowedTools:' .apm/agents/*.agent.md` matches the "after"
column of [data-model.md](data-model.md#agent-file-apmagentsnameagentmd);
`grep -lE '^(model|effort|tools|color):' .apm/agents/*.agent.md` prints
nothing.

## 3. Lint (US3, FR-008, SC-005)

1. `mise run lint` passes.
2. Remove `Artifact` from one file's `disallowedTools`; `mise run lint`
   fails with `<file>: disallowedTools lacks Artifact`
   ([contracts/lint-denials.md](contracts/lint-denials.md)). Restore it;
   same with `EnterWorktree`. Restore; lint passes.
3. `mise run test:apm` passes.

## 4. Setup gate (US2, SC-004) — by reading

Against [contracts/setup-hook-gate.md](contracts/setup-hook-gate.md),
read setup step 4 of `.apm/skills/feat/SKILL.md` with each of these
`.specify/extensions.yml` cases in mind and check the outcome it gives:

| Case                                                         | Expected                                                    |
| ------------------------------------------------------------ | ----------------------------------------------------------- |
| `hooks: {}`                                                  | no gate                                                     |
| enabled `before_plan` (non-git)                              | one hard gate: won't run, `/speckit-…` command, "run by hand once the PR is open, or stop now"; continue or stop |
| enabled `before_plan` with no `command`                      | the same gate, the hook shown by its extension only         |
| enabled git hook on `before_specify`                         | the same single gate, not a second one                      |
| both of the above, plus a git `after_implement`              | one message, two sections                                   |
| only a non-git `after_implement`                             | no gate; listed as allowed in the state file                |
| `before_plan` with `enabled: false`                          | no gate                                                     |
| `/feat rebase` with an enabled `before_plan`                 | no gate                                                     |

The three agent files carry the new hook line and an unchanged report
format: `grep -n 'Skipped hooks' .apm/agents/feat-{specifier,planner,tasker}.agent.md`.

## 5. Docs (US4, FR-009)

The "Denied tools" column of `docs/workflow.md`'s agents table equals the
`disallowedTools` value of each file; `### 0 Setup` and the phases table
row 0 state the new rule; the sentence after the agents table says the
saving depends on the user's setup. `harness.md` is unchanged
(`/usr/bin/git diff --stat` shows it absent).

## 6. Measured run (FR-012, SC-001–SC-003) — the user, after ship

When: this feature's PR is open and unmerged. The implementer reports this
step not verified; no agent runs it and no file is written
([R6](research.md#r6-the-measured-run-and-where-its-numbers-go-fr-012)).

1. From this worktree: `./install.sh` (points the user-level skills and
   agents at this branch).
2. In a fresh session, run `/feat` on a pending small issue (a real
   feature, not a throwaway) through to its PR. Note `claude --version`
   and the session id.
3. `python3 -I .apm/skills/feat/scripts/measure.py --session <id>`, and
   read:
   - the **Agents** block, `ctx first` column, one row per agent type;
   - the **First request (characters, from each type's first spawn in a
     run)** block, per agent type: the `tools` line, the `skills listing`
     line, and the `tool schemas:` line.
4. Compare with `docs/workflow.md`'s Baseline: the `/feat` **Agents**
   table's `ctx first` column, and the `/feat` table under
   **### First request**, columns `tools` and `skills listing`.

Expected: no type's `tool schemas:` line names `Artifact` or
`EnterWorktree`; `skills listing` is 0 for `feat-specifier`,
`feat-planner`, `feat-tasker` and `feat-shipper` (`feat-brief-reviewer`
runs under `/brief`, measured only if that session is given too);
`ctx first` per type is below the Baseline medians; spec.md, plan.md and
tasks.md exist in the run's spec dir.

Post-run checklist:

- [ ] Add to this feature's PR body a table per agent type: `ctx first`,
      `tools` and `skills listing`, before (Baseline medians) and after
      (this run), with the run's Claude Code version.
- [ ] Restore the install: `./install.sh` from the main checkout (until
      then, every session uses this branch's agents and skills).
