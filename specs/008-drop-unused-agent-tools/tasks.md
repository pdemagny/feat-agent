# Tasks: Drop unused tools from the feat-* agents' starting context

**Input**: Design documents from `specs/008-drop-unused-agent-tools/` (plan.md, spec.md, research.md, data-model.md, quickstart.md, contracts/)

**Prerequisites**: plan.md, spec.md

**Tests**: No test-first tasks (none requested). Verification tasks are the FR-011 probe, the lint fail/pass check and by-reading checks from quickstart.md.

**Organization**: Grouped by user story. All paths are relative to the worktree root `/home/pierre/Projects/logistics/.claude/worktrees/brief-drop-unused-agent-tools`. Edit with Edit/Write, never shell redirection. Commits are the shipper's (one `feat(agents): ...` commit, spec dir in `docs(specs): ...`); do not commit.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [x] T001 Run `mise run lint` and `mise run test:apm` from the worktree root and record that both pass before any edit (baseline; if either fails, report it and stop).

---

## Phase 2: Foundational (blocking: FR-011 gate check)

**CRITICAL**: No other edit (gate, docs, other agents) starts until T003 passes.

- [x] T002 Edit `.apm/agents/feat-tasker.agent.md`: append `Artifact, EnterWorktree, Skill` to its `disallowedTools` line (keep `skills:` unchanged; no `model`, `effort`, `tools` or `color`), and replace its four-line "Spec Kit hooks: the orchestrator tells you which hooks ... are allowed ..." paragraph with the contract text in `specs/008-drop-unused-agent-tools/contracts/setup-hook-gate.md` ("Agent hook line"): "Spec Kit hooks: you can't run them (`Skill` is denied; `/feat` setup told the user). Skip every hook and list each under `Skipped hooks:`." Leave the report format unchanged.
- [x] T003 Run the FR-011 probe on the real tasker file, following `specs/008-drop-unused-agent-tools/quickstart.md` section 1 and `research.md` R2 exactly: `mktemp -d` scratch project; copy `.apm/agents/feat-tasker.agent.md` to `<scratch>/.claude/agents/feat-tasker.md`; copy `.claude/skills/speckit-tasks` and `.claude/skills/speckit-analyze` to `<scratch>/.claude/skills/` (`command cp -Rf`); write `<scratch>/.specify/extensions.yml` (enabled non-git `before_tasks` hook `probe` / `speckit.probe.hello`, `optional: false`) with Write; from `<scratch>` run `claude -p --model haiku --allowedTools Agent --output-format json` with the R2 prompt; read the subagent transcript `agent-*.jsonl`. Pass only if all hold: both skills named with their first `#` heading, no `Skill` tool, `Skipped hooks:` names `before_tasks` `speckit.probe.hello`, and the transcript has no call that runs the hook; only read-only access to `.specify/extensions.yml` (an existence check or a Read). Record the command, output, transcript tool calls and `claude --version`; remove the scratch directory. On preload failure: take `Skill` back out of the tasker, restore its old hook paragraph, STOP and report under `Design problems:` (scope shrinks per R2). On hook failure: STOP and report the offending tool calls under `Design problems:`. If the nested `claude` call is refused: report T003 not done with the exact commands and do none of T004-T021.

**Checkpoint**: Preload and hook line confirmed on the real agent; remaining phases may begin.

---

## Phase 3: User Story 1 - Agents start with a smaller context (Priority: P1) MVP

**Goal**: All nine agents deny `Artifact` and `EnterWorktree`; exactly five also deny `Skill`; the specifier's amend mode carries `speckit-clarify`'s encoding rules inline.

**Independent Test**: `grep -H '^disallowedTools:' .apm/agents/*.agent.md` matches the "after" column of `specs/008-drop-unused-agent-tools/data-model.md`; `grep -lE '^(model|effort|tools|color):' .apm/agents/*.agent.md` prints nothing.

- [x] T004 [P] [US1] In `.apm/agents/feat-specifier.agent.md` append `Artifact, EnterWorktree, Skill` to `disallowedTools` (result: `NotebookEdit, Agent, Artifact, EnterWorktree, Skill`).
- [x] T005 [P] [US1] In `.apm/agents/feat-planner.agent.md` append `Artifact, EnterWorktree, Skill` to `disallowedTools`.
- [x] T006 [P] [US1] In `.apm/agents/feat-brief-reviewer.agent.md` append `Artifact, EnterWorktree, Skill` to `disallowedTools`.
- [x] T007 [P] [US1] In `.apm/agents/feat-shipper.agent.md` append `Artifact, EnterWorktree, Skill` to `disallowedTools`.
- [x] T008 [P] [US1] Append `Artifact, EnterWorktree` (not `Skill`) to `disallowedTools` in `.apm/agents/feat-bug-assessor.agent.md`, `.apm/agents/feat-design-reviewer.agent.md`, `.apm/agents/feat-code-reviewer.agent.md` and `.apm/agents/feat-implementer.agent.md`.
- [x] T009 [US1] In `.apm/agents/feat-specifier.agent.md` (after T004) rewrite the **Amend mode** paragraph per `research.md` R7 / FR-014: replace the pointer to `speckit-clarify`'s encoding rules with the rules inline (a `- Q: <question> → A: <answer>` line under `## Clarifications` / `### Session YYYY-MM-DD`, created after the overview section if missing; the marker replaced by the answer in the section it belongs to; no statement the answer contradicts left; one term throughout; no other new heading). Report format unchanged.

**Checkpoint**: US1 verifiable by the grep above.

---

## Phase 4: User Story 2 - Hooks the Skill-less agents cannot run are gated up front (Priority: P1)

**Goal**: One merged hard gate at `/feat` setup names every enabled specify/plan/tasks/analyze hook as skipped with its manual command; the three agents skip and list all hooks.

**Independent Test**: Read setup step 4 against the case table in `specs/008-drop-unused-agent-tools/quickstart.md` section 4.

- [x] T010 [US2] In `.apm/skills/feat/SKILL.md` replace setup step 4 with the text in `specs/008-drop-unused-agent-tools/contracts/setup-hook-gate.md` (one hard gate before phase 2, message shape as in the contract, key/extension/command per hook, command to run by hand with dots as hyphens, extension only when no `command`, "won't run during this run: run them by hand once the PR is open, or stop now", no "run it anyway" for the first section, `implement` hooks keep today's rule under the same gate, `rebase` applies only the `implement` part, `enabled: false` entries ignored), and change phases-table row 0's Gate cell to `hard only if a Spec Kit hook won't run (specify, plan, tasks, analyze) or would branch or commit`. Keep `/feat` thin (setup only reads the YAML); put no `/feat`-only words into `.apm/skills/feat/references/harness.md` or `rebase.md`.
- [x] T011 [US2] In `.apm/agents/feat-specifier.agent.md` (after T009) replace its four-line "Spec Kit hooks" paragraph with the contract's agent hook line; report format unchanged.
- [x] T012 [US2] In `.apm/agents/feat-planner.agent.md` (after T005) replace its four-line "Spec Kit hooks" paragraph with the contract's agent hook line; report format unchanged. (The tasker's line was done in T002.)
- [x] T013 [US2] Check by reading, against `specs/008-drop-unused-agent-tools/quickstart.md` section 4: every case in its table gives the expected outcome from the edited step 4, and `grep -n 'Skipped hooks' .apm/agents/feat-{specifier,planner,tasker}.agent.md` shows the unchanged report line in all three. Fix step 4 if a case fails.

**Checkpoint**: US1 and US2 together deliver the saving safely.

---

## Phase 5: User Story 3 - A new agent cannot forget the denials (Priority: P2)

**Goal**: `mise run lint` fails when an agent file lacks `Artifact` or `EnterWorktree`.

**Independent Test**: Remove `Artifact` from one file; lint fails naming it; restore; lint passes.

- [x] T014 [US3] In `mise.toml` add one line to `[tasks.lint] run` (and name the check in the task's `description`) implementing `specs/008-drop-unused-agent-tools/contracts/lint-denials.md`: for each `.apm/agents/*.agent.md`, take the first `disallowedTools:` line, split on commas and spaces, require whole tokens `Artifact` and `EnterWorktree` (case-sensitive; `ArtifactComments` does not count), print `<file>: disallowedTools lacks <Tool>` per miss and exit non-zero; a file with no such line fails for both. POSIX `sh` with `awk`/`grep -E`/`tr`, no GNU-only escapes. Keep `shellcheck`-clean if the line is checked by it.
- [x] T015 [US3] Verify the check (quickstart section 3): `mise run lint` passes; temporarily remove `Artifact` from one agent file, confirm lint fails with `<file>: disallowedTools lacks Artifact`, restore; same for `EnterWorktree`; restore; confirm lint passes and `git diff` shows the agent file back as T004-T008 left it.

**Checkpoint**: SC-005 holds.

---

## Phase 6: User Story 4 - The saving is documented and measured (Priority: P2)

**Goal**: Docs match the agent files and the new hook rule, with the setup-dependent line. The measured run is a user step.

**Independent Test**: Compare the "Denied tools" column to the agent files; read the setup text.

- [x] T016 [US4] In `docs/workflow.md`: set the agents table's "Denied tools" column to each file's new `disallowedTools` value (data-model "after" column); update phases-table row 0 Gate cell and the `### 0 Setup` text to the new hook rule (same wording as T010); add one sentence after the agents table saying the saving depends on the user's setup (which tools and skills their Claude Code loads; interactive, background or headless). Do not change the size tables (model, effort, `Loads`) or the `/fix` matrices.
- [x] T017 [P] [US4] In `docs/design.md` update the "all `speckit-*`" override row in a few words so it states the specifier, planner and tasker run no hook (they cannot load skills by name beyond their preloads).
- [x] T018 [US4] Check the docs against the files (quickstart section 5): "Denied tools" equals each `disallowedTools`; setup text and row 0 state the new rule; the sentence after the table is present; `/usr/bin/git diff --stat` shows `.apm/skills/feat/references/harness.md`, `rebase.md`, `.claude-plugin/plugin.json`, `.apm/skills/brief/SKILL.md` and `docs/img/` absent.

**Checkpoint**: All four stories done.

---

## Phase 7: Polish & Cross-Cutting

- [x] T019 Run `mise run lint` and `mise run test:apm`; both must pass (FR-013). Fix any failure (e.g. the `/feat`-only word grep on `harness.md`) and rerun.
- [x] T020 Run the remaining quickstart section 2 checks (denials grep, no `model|effort|tools|color` in frontmatter) and report results.
- [ ] T021 FR-012 measured run: USER STEP after ship, not for any agent. Once the PR is open and unmerged: `./install.sh` from this worktree; run one real small `/feat` on a pending small issue through its PR; `python3 -I .apm/skills/feat/scripts/measure.py --session <id>` and `claude --version`; add the before (Baseline medians in `docs/workflow.md`) / after table per agent type to this PR's body; restore with `./install.sh` from the main checkout (`quickstart.md` section 6). The implementer reports it "not verified" and writes no file.

---

## Dependencies & Execution Order

- T001 -> T002 -> T003 (hard stop on failure) -> everything else.
- US1 (T004-T009): T004-T008 parallel (distinct files); T009 after T004.
- US2: T010 independent of agent files; T011 after T009; T012 after T005; T013 after T010-T012.
- US3: T014 anytime after T003; T015 after T014 and T004-T008.
- US4: T016 after T010 and T004-T008; T017 parallel; T018 after T016-T017.
- Polish: T019, T020 after all; T021 after ship.
- Same-file sequencing: `feat-specifier.agent.md` T004 -> T009 -> T011; `feat-planner.agent.md` T005 -> T012.

## Parallel Example

```text
After T003: T004, T005, T006, T007, T008, T010, T014 can run together (distinct files).
```

## Implementation Strategy

- MVP: T001-T009 plus T010-T013 (US1 + US2 are both P1 and ship together: dropping `Skill` without the gate would silently skip hooks). Minimal safe cut if the T003 preload fails: T008-style `Artifact, EnterWorktree` denials on all nine files, T014-T015, T016's column and sentence, T019.
- Then US3, US4, polish; T021 after ship.
