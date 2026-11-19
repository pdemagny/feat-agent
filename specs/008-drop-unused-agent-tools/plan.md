# Implementation Plan: Drop unused tools from the feat-* agents' starting context

**Branch**: `drop-unused-agent-tools` | **Date**: 2026-11-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/008-drop-unused-agent-tools/spec.md` (brief: issue #54)

## Summary

Frontmatter, prompt and docs edits, plus one lint line; no new file ships.
All nine `.apm/agents/*.agent.md` append `Artifact, EnterWorktree` to their
`disallowedTools`; the specifier, planner, tasker, brief reviewer and
shipper also append `Skill`. Because the specifier, planner and tasker then
can't run Spec Kit hooks, `/feat` setup step 4 becomes one hard gate naming
every enabled `specify`/`plan`/`tasks`/`analyze` hook as one that won't run,
with its manual command and when to run it (by hand once the PR is open,
or stop now), next to today's rule for `implement` hooks; the three
agents' hook paragraph becomes "skip every hook and list it". The
specifier's amend mode gets `speckit-clarify`'s few encoding rules inline,
since it can no longer load that skill (FR-014). A `mise run lint` line
fails when an agent lacks the two denials. `docs/workflow.md` mirrors it
all and says the saving depends on the setup.

Order matters (FR-011): the first task gives `feat-tasker` its new
denials and hook line, and spawns that real agent file from a scratch
project (with an enabled non-git `before_tasks` hook) with `claude -p` to
check both Spec Kit skills are preloaded without `Skill` and the hook is
listed as skipped, not run
([research R2](research.md#r2-how-the-first-task-checks-the-real-taskers-preload-fr-011)).
If the preload fails, the work stops before the gate or docs and shrinks
to the two-tool denial; if the hook check fails, it stops before them too.
After ship, the user runs one real small `/feat` with this branch
installed and adds its `measure.py --session` figures to this feature's
PR body ([R6](research.md#r6-the-measured-run-and-where-its-numbers-go-fr-012)).

## Technical Context

**Language/Version**: Markdown prompts with YAML frontmatter (Claude Code agent and skill files); POSIX `sh` for the lint line in `mise.toml`.

**Primary Dependencies**: Claude Code (`disallowedTools`, `skills:` preloading; probed on 2.1.328 per the brief); Spec Kit's `.specify/extensions.yml` format. Nothing new.

**Storage**: N/A.

**Testing**: `mise run lint` (now including the denials check) and `mise run test:apm`; the FR-011 preload and hook probe; a by-reading check of the setup gate against [quickstart §4](quickstart.md#4-setup-gate-us2-sc-004--by-reading); after ship, the user's measured `/feat` run read with `measure.py --session` (not verified by the implementer).

**Target Platform**: Claude Code, interactive and background sessions (headless `-p` gains less: edge case).

**Project Type**: agent-workflow package (APM package, Claude Code plugin, `install.sh`).

**Performance Goals**: first-call context per agent type down versus the Baseline medians (SC-002); probe expectation ~33.4k → ~19.4k tokens for the two tools, ~10.5k more for `Skill`.

**Constraints**: deny lists only; no `model`/`effort`/`tools`/`color` in frontmatter; `harness.md` and `rebase.md` untouched (the lint grep for `/feat`-only words); coordinators stay thin; report formats unchanged.

**Scale/Scope**: 9 agent files (3 with prompt edits: specifier hook line and amend mode, planner and tasker hook line), 1 skill file, 1 `mise.toml` line, 2 docs files; no new file.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Result | Note |
| --- | --- | --- |
| I. Thin coordinators | pass | Setup step 4 already reads `.specify/extensions.yml`; it now classifies the same entries differently. No new coordinator work; the probe and the lint are done by an implementer, the measured run and its PR-body table by the user after ship. |
| II. The user decides at gates | pass | The merged gate is hard; skipped hooks are decided by the user before phase 2, never silently dropped. |
| III. One source of truth per fact | pass | Size tables (model, effort, `Loads`) unchanged, so `brief/SKILL.md` row 1 and `models.svg` don't change. The denials live in the agent files; `docs/workflow.md`'s "Denied tools" column mirrors them in the same commit. The `/feat`-only hook rule stays out of `harness.md`. |
| IV. Fixed report formats | pass | The three agents' `Skipped hooks:` line already exists and keeps its shape; the coordinator side (setup step 4) changes in the same commit. |
| V. Small and plain | pass | The agents' hook paragraph shrinks from four lines to two; the specifier's amend paragraph grows by a few lines instead of a preload of the whole `speckit-clarify`; the check is one lint line, not a script; no new shipped file. |
| Distribution | pass | Only existing files under `.apm/` change; no agent added or removed, so `.claude-plugin/plugin.json` is unchanged; `mise run test:apm` still counts the same files. |

Post-design re-check (after Phase 1, and after the design-review amend):
unchanged. The design adds no file; the measured run's numbers go into
the PR body by hand, read by no agent or coordinator.

## Project Structure

### Documentation (this feature)

```text
specs/008-drop-unused-agent-tools/
├── plan.md              # this file
├── research.md          # Phase 0: decisions R1–R8
├── data-model.md        # Phase 1: denials per agent; hook classification
├── quickstart.md        # Phase 1: validation, probe and measured-run steps
├── contracts/
│   ├── setup-hook-gate.md   # setup step 4, gate message, agents' hook line
│   └── lint-denials.md      # the lint check's input, pass and failure output
└── tasks.md             # Phase 2 (speckit-tasks), not created here
```

### Source Code (repository root)

```text
.apm/agents/
├── feat-tasker.agent.md          # + Artifact, EnterWorktree, Skill; hook paragraph (first: the probe)
├── feat-specifier.agent.md       # + Artifact, EnterWorktree, Skill; hook paragraph; amend mode: encoding rules inline (R7)
├── feat-planner.agent.md         # + Artifact, EnterWorktree, Skill; hook paragraph
├── feat-brief-reviewer.agent.md  # + Artifact, EnterWorktree, Skill
├── feat-shipper.agent.md         # + Artifact, EnterWorktree, Skill
├── feat-bug-assessor.agent.md    # + Artifact, EnterWorktree
├── feat-design-reviewer.agent.md # + Artifact, EnterWorktree
├── feat-code-reviewer.agent.md   # + Artifact, EnterWorktree
└── feat-implementer.agent.md     # + Artifact, EnterWorktree
.apm/skills/feat/SKILL.md         # phases table row 0; setup step 4 (contracts/setup-hook-gate.md)
mise.toml                         # lint: denials check line and description (contracts/lint-denials.md)
docs/workflow.md                  # phases row 0, "### 0 Setup", agents table "Denied tools", one sentence after it
docs/design.md                    # "all `speckit-*`" override row: the three agents run no hook
```

Not changed, checked: `.apm/skills/feat/references/harness.md` and
`rebase.md` (no `/feat`-only words; the harness's "which hooks are allowed"
stays true: the coordinator passes `none` to the three); `.apm/skills/fix/SKILL.md`
(out of scope; its shipper loses `Skill` through the agent file only);
`.apm/skills/brief/SKILL.md` (row 1's model, effort and `Loads` unchanged);
`docs/diagrams/gates.d2` and `chain.d2` (neither draws the setup gate) and
`models.svg` (size table unchanged): no re-render; `.claude-plugin/plugin.json`.

**Structure Decision**: edits in place; no new file.

## Implementation order (for tasks)

1. **Gate check first (FR-011)**: `feat-tasker.agent.md` frontmatter and
   its new hook line ([contract](contracts/setup-hook-gate.md#agent-hook-line-feat-specifier-feat-planner-feat-tasker)),
   then the probe ([quickstart §1](quickstart.md#1-preload-and-hook-check-first-task-fr-011)),
   which also checks that an enabled `before_tasks` hook is listed under
   `Skipped hooks:` and not run.
   On a preload failure: take `Skill` back out of the tasker, stop, report
   under `Design problems:`; the remaining scope is listed in
   [R2](research.md#r2-how-the-first-task-checks-the-real-taskers-preload-fr-011).
   On a hook failure (a call that runs the hook; only read-only access to
   `.specify/extensions.yml`, an existence check or a Read, is allowed): stop and report it under `Design problems:`
   with the transcript lines; the hook line's wording is fixed before
   going on. If the nested `claude` call is refused, report it not done
   with the commands and do none of the steps below.
2. **US1**: the other eight files' `disallowedTools` ([data-model](data-model.md#agent-file-apmagentsnameagentmd));
   the specifier's amend-mode paragraph with `speckit-clarify`'s encoding
   rules inline ([R7](research.md#r7-agent-prompt-wording), FR-014).
3. **US2**: setup step 4 and phases row 0 in `.apm/skills/feat/SKILL.md`;
   the hook paragraph in the specifier and planner (the tasker's is done in
   step 1; one commit with the step, principle IV).
4. **US3**: the lint line; verify it fails on a removed denial, then passes.
5. **US4**: `docs/workflow.md` and `docs/design.md`; then `mise run lint`
   and `mise run test:apm`.
6. **Measured run (user, after ship)**: once this feature's PR is open and
   unmerged ([quickstart §6](quickstart.md#6-measured-run-fr-012-sc-001sc-003--the-user-after-ship)):
   `./install.sh` from this worktree, one real small `/feat` on a pending
   small issue, `measure.py --session <id>` and `claude --version`, the
   before/after table added to this PR's body, then `./install.sh` from the
   main checkout. No agent is spawned for it and no file is written; the
   task stays in tasks.md as a user step, and the implementer reports it
   not verified.

Commits (shipper): one `feat(agents): …` commit with the frontmatter,
prompts, setup step, lint line and docs (they mirror each other), and the
spec dir in `docs(specs): …`.

## Complexity Tracking

No violations.
