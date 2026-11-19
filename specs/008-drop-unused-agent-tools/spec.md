# Feature Specification: Drop unused tools from the feat-* agents' starting context

**Feature Branch**: `drop-unused-agent-tools`

**Created**: 2026-11-19

**Status**: Draft

**Input**: User description: brief `specs/briefs/drop-unused-agent-tools.md` (issue #54)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Agents start with a smaller context (Priority: P1)

Whoever runs `/feat` or `/fix` pays, on every model call of every subagent, for tool schemas and a skills listing the agent never uses. Each `feat-*` agent starts at 33-41k tokens of context before its first tool call; a `/feat` run makes about 430 subagent calls, so this fixed part is roughly a fifth of a run's cost. After this change all nine agents start without the `Artifact` and `EnterWorktree` tool schemas, and the five that load no skill by name (`feat-specifier`, `feat-planner`, `feat-tasker`, `feat-brief-reviewer`, `feat-shipper`) also start without the skills listing. The specifier, planner and tasker still get their preloaded Spec Kit skills; the specifier's amend mode, which used to point at `speckit-clarify`'s encoding rules, carries those few rules in its own prompt instead.

**Why this priority**: This is the whole point of the feature: the cost saving on every run.

**Independent Test**: Read the nine agent files' denied tools; run one real `/feat` with this branch installed and check with the measurement script that no agent type's first request carries the denied schemas or listing, and that the planner and tasker still produce plan.md and tasks.md.

**Acceptance Scenarios**:

1. **Given** the nine agent files, **When** their denied tools are read, **Then** every one denies `Artifact` and `EnterWorktree` on top of what it denied before, and exactly `feat-specifier`, `feat-planner`, `feat-tasker`, `feat-brief-reviewer` and `feat-shipper` also deny `Skill`.
2. **Given** `feat-code-reviewer`, `feat-design-reviewer`, `feat-bug-assessor` and `feat-implementer`, **When** their denied tools are read, **Then** none denies `Skill` (they load lenses and `speckit-bug-*` skills by name).
3. **Given** one real small `/feat` run with this branch installed (FR-012), **When** the specifier, planner and tasker run with `Skill` denied, **Then** they use their preloaded Spec Kit skills and produce spec.md, plan.md and tasks.md, and the run reaches its PR stage.
4. **Given** a user whose Claude Code has no `Artifact` tool, **When** an agent starts, **Then** nothing changes and no error appears (an unknown denied name is ignored).
5. **Given** `/fix` spawning `feat-shipper` in fix mode, or `rebase` spawning it, **When** the shipper starts without `Skill`, **Then** it completes as before: it runs no Spec Kit hook and loads no skill.
6. **Given** the specifier in amend mode with the user's answers to open `[NEEDS CLARIFICATION]` markers, **When** it applies them with `Skill` denied, **Then** it encodes them by the rules in its own prompt (a `- Q: … → A: …` line under `## Clarifications` / `### Session <date>`, the marker replaced by the answer in its section, no contradicting statement left) without loading `speckit-clarify`.

---

### User Story 2 - Hooks the Skill-less agents cannot run are gated up front (Priority: P1)

A user of `/feat` with enabled Spec Kit hooks in `.specify/extensions.yml` is told at setup, in one hard gate, which hooks will not run in the specify, plan, tasks and analyze phases (those phases' agents cannot invoke them), with the command to run each by hand. They continue with those hooks skipped, or stop. Hooks for the implement phase keep today's rule and appear in the same gate.

**Why this priority**: Dropping `Skill` from the specifier, planner and tasker removes their ability to run hooks; without the gate a hook would silently never run. It is required by User Story 1.

**Independent Test**: With an enabled `before_plan` hook (and separately a git hook on `before_specify`) in a test `.specify/extensions.yml`, read the setup text and check that one gate names each hook as skipped with its manual command.

**Acceptance Scenarios**:

1. **Given** an enabled `before_plan` (or any specify, plan, tasks or analyze) hook, **When** `/feat` setup runs, **Then** one hard gate names the hook as one that will not run, gives the command to run it by hand (for example `/speckit-…`), and says these hooks won't run during this run: run them by hand once the PR is open, or stop now.
2. **Given** an enabled git hook (branch or commit) in those phases, **When** setup runs, **Then** it appears in that same gate, not in a second one, and replaces today's separate git-hook gate for those phases.
3. **Given** the gate for those phases, **When** the user answers, **Then** the only choices are to continue with those hooks skipped or to stop; there is no "run it anyway".
4. **Given** an enabled `implement` hook that does not branch or commit, **When** setup runs, **Then** it is allowed as today; one that branches or commits is skipped unless the user says otherwise, under the same gate.
5. **Given** no enabled hooks, **When** setup runs, **Then** no gate appears for them.
6. **Given** the specifier, planner or tasker is spawned, **When** it finishes, **Then** its prompt told it to skip every hook and list each one under `Skipped hooks:`, and its report format is otherwise unchanged; the PR body is unchanged.

---

### User Story 3 - A new agent cannot forget the denials (Priority: P2)

The maintainer adds or edits an agent file; `mise run lint` fails if any agent file in `.apm/agents/` does not deny `Artifact` and `EnterWorktree`.

**Why this priority**: Keeps the saving from eroding silently; secondary to delivering it.

**Independent Test**: Remove `Artifact` from one agent file's denied tools; `mise run lint` fails and names the file; restore it and lint passes.

**Acceptance Scenarios**:

1. **Given** an agent file lacking `Artifact` or `EnterWorktree` in its denied tools, **When** `mise run lint` runs, **Then** it fails and names the file and the missing tool.
2. **Given** all agent files deny both, **When** `mise run lint` runs, **Then** this check passes.

---

### User Story 4 - The saving is documented and measured (Priority: P2)

A reader of `docs/workflow.md` sees the agents table's "Denied tools" matching the agent files, the setup text matching the new hook rule, and one line saying the saving depends on their setup (which tools and skills their Claude Code loads, and whether it runs interactively, in the background or headless). Once this feature's PR is open, the user measures one real small `/feat` run made with this branch installed and adds to that PR's body first-call context per agent type before (the baseline medians in `docs/workflow.md`) and after (the new run, measured with `measure.py --session`, with its Claude Code version).

**Why this priority**: Epic #31 is judged on measured numbers; the docs must not drift from the agent files.

**Independent Test**: Compare the docs table against the agent files; run `measure.py --session` on the new run and compare with the baseline.

**Acceptance Scenarios**:

1. **Given** the agent files and `docs/workflow.md`, **When** compared, **Then** the "Denied tools" column matches each file and the setup text states the new hook rule.
2. **Given** the docs, **When** read, **Then** one line says the gain depends on the user's setup.
3. **Given** the measured run, **When** its first requests are inspected, **Then** no agent type's first request carries the `Artifact` or `EnterWorktree` schema, nor the skills listing for the five agents denying `Skill`.

---

### Edge Cases

- Headless `claude -p` does not load `Artifact` and defers `EnterWorktree`: the gain there is smaller or nil; the denial is harmless.
- A user with an MCP server or other tool not named in the denials keeps it available (deny lists, not allow lists).
- If the first task finds that the real `feat-tasker` with `Skill` denied does not get `speckit-tasks` and `speckit-analyze` preloaded, the five `Skill` denials and the hook gate drop out, the change shrinks to the two-tool denial, and work stops with a message before the gate or docs are written.
- If the first task finds the real `feat-tasker` trying to run the enabled `before_tasks` hook (a call that runs the hook; only read-only access to `.specify/extensions.yml`, an existence check or a Read, is allowed) instead of listing it under `Skipped hooks:`, work stops with a message before the gate or docs are written; the agents' hook line is reworded, not the scope.
- A hook entry with no `command` is named in the gate by its extension only, with no manual command.
- A hook enabled for several phases of the affected set is named once per phase or once with its phases; the gate stays one message.
- `feat-brief-reviewer` is spawned only by `/brief`, so denying `Skill` there does not touch `/feat` setup.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: All nine `feat-*` agent files MUST deny `Artifact` and `EnterWorktree` in addition to the tools each denies today.
- **FR-002**: `feat-specifier`, `feat-planner`, `feat-tasker`, `feat-brief-reviewer` and `feat-shipper` MUST also deny `Skill`; `feat-code-reviewer`, `feat-design-reviewer`, `feat-bug-assessor` and `feat-implementer` MUST keep `Skill` available.
- **FR-003**: The specifier, planner and tasker MUST still receive their preloaded Spec Kit skills with `Skill` denied.
- **FR-004**: `/feat` setup MUST show one merged hard gate, replacing today's git-hook gate for the specify, plan, tasks and analyze phases, naming each enabled hook the specifier, planner or tasker would run as one that will not run, with the command to run it by hand (a hook with no `command`: its extension only), and saying that these hooks won't run during this run and are to be run by hand once the PR is open, or the user stops now; the user continues with them skipped or stops, with no "run it anyway".
- **FR-005**: Enabled hooks of the implement phase MUST keep today's rule (allowed unless they branch or commit; branch or commit ones skipped unless the user says otherwise) and appear under the same gate.
- **FR-006**: In each of the specifier, planner and tasker prompts, the hook line MUST become: skip every hook and list it under `Skipped hooks:`; their report format MUST stay unchanged and the PR body MUST stay unchanged.
- **FR-007**: The hook rule MUST be `/feat`-only: it lives in `.apm/skills/feat/SKILL.md` and the three agent files, not in the shared `harness.md`; `/feat` stays thin (the check reads the YAML in setup, no new coordinator work).
- **FR-008**: `mise run lint` MUST fail when an agent file in `.apm/agents/` does not deny `Artifact` and `EnterWorktree`.
- **FR-009**: `docs/workflow.md` MUST have its agents table ("Denied tools") matching the agent files, its setup text matching the new hook rule, and one line stating the saving depends on the user's setup (tools and skills loaded; interactive, background or headless).
- **FR-010**: Agent frontmatter MUST keep using `disallowedTools` and carry no `model`, `effort`, `tools` or `color`.
- **FR-011**: The first task MUST spawn the real `feat-tasker` (with `Skill` denied and its new hook line) from a scratch project whose `.specify/extensions.yml` has an enabled non-git `before_tasks` hook, and check that `speckit-tasks` and `speckit-analyze` are both preloaded and that the tasker lists that hook under `Skipped hooks:` without trying to run it (no call that runs the hook; only read-only access to `.specify/extensions.yml` (an existence check or a Read)). If the preload fails, the work MUST stop and say so before the gate or docs are written, and the change reduces to FR-001; if the hook check fails, the work MUST stop and say so before the gate or docs are written.
- **FR-012**: After this feature's PR is open (unmerged), the user installs this branch (`./install.sh` from this worktree), runs one real small `/feat` on a pending small issue (a real feature, not a throwaway) through its PR stage, with the planner and tasker producing plan.md and tasks.md from their preloaded skills, runs `measure.py --session <id>` and `claude --version`, adds to this feature's PR body a table of first-call context per agent type before (baseline `ctx first` and "First request" medians in `docs/workflow.md`) and after (the new run, with its Claude Code version), then restores the install with `./install.sh` from the main checkout. This is a user step: the implementer reports it as not verified, and no measurement file is written.
- **FR-013**: `mise run lint` and `mise run test:apm` MUST pass.
- **FR-014**: `feat-specifier`'s amend mode MUST carry, in its own prompt (not as a preload or a by-name load), the `speckit-clarify` encoding rules it applies to answered markers: a `- Q: <question> → A: <answer>` line under `## Clarifications` / `### Session YYYY-MM-DD` (created after the overview section when missing), the answer applied in place of the marker in the section it belongs to, no statement left that the answer contradicts, one term used throughout, and no other new heading.

### Key Entities

- **Agent file**: one of nine `.apm/agents/*.agent.md` definitions; its frontmatter lists denied tools and preloaded skills; its prompt ends with a fixed report format.
- **Setup hook gate**: the single `/feat` setup message that lists hooks which will not run and the manual command for each.
- **Spec Kit hook**: an entry in `.specify/extensions.yml` bound to a phase (specify, plan, tasks, analyze, implement).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: No agent type's first request in the measured run carries the `Artifact` or `EnterWorktree` schema, and none of the five Skill-denying agent types carries the skills listing.
- **SC-002**: First-call context per agent type drops in the measured run versus the documented baseline medians (probe result: 33,385 to 19,411 tokens for the two-tool denial, a further ~10.5k for denying `Skill`), reported per agent type in this feature's PR body.
- **SC-003**: The real `/feat` run completes through its PR stage with spec, plan and tasks produced.
- **SC-004**: A repo with an enabled hook in the specify, plan, tasks or analyze phases sees exactly one setup gate naming it as skipped, with its manual command.
- **SC-005**: A deliberate omission of either denial in any agent file makes `mise run lint` fail.

## Assumptions

- Out of scope (binding): `/fix`'s hook handling (its assessor and implementer keep `Skill`; its shipper loses it), allow lists, the implementer's own prompt and preloaded skill (#39), trimming the CLAUDE.md chain, memory index or agent prompts, any other tool (`ToolSearch` stays; `ExitWorktree` is already deferred).
- The probe results in the brief (denied names removed from context, unknown names ignored, skills preloaded with `Skill` denied) hold for Claude Code versions in use; the real-agent check (FR-011) confirms the preload part.
- The measured "after" run is on this machine with the same Claude Code range as the baseline, or the version is stated.
- The measured run happens after this feature ships (its PR open, unmerged), on a pending small issue; while this branch is installed user-level, the user's other sessions also use it, until the restore step.
- Wording of the gate message and of the lint failure message is left to planning, within the behaviour above.
- The hook gate lists hooks from enabled entries only; entries with `enabled: false` are ignored as today.
