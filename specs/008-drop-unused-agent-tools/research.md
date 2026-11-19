# Research: Drop unused tools from the feat-* agents' starting context

No `NEEDS CLARIFICATION` was left in the Technical Context; these are the
decisions the spec left to planning, each checked against the code.

## R1 Where the denials go

- **Decision**: append to each agent's existing one-line `disallowedTools:`
  value, in this order: what it denies today, then `Artifact,
  EnterWorktree`, then `Skill` for the five. Example:
  `disallowedTools: NotebookEdit, Agent, Artifact, EnterWorktree, Skill`.
- **Rationale**: all nine files already use the one-line comma form; the
  lint check (R5) reads that line. Appending keeps the diff to one line per
  file and keeps today's denials first, as `docs/workflow.md` lists them.
- **Alternatives considered**: a YAML list (`disallowedTools:` then `- …`
  lines) — reshapes nine files for nothing and needs a YAML-aware lint;
  allow lists (`tools:`) — rejected by the brief and the project rule.
- **Checked**: no agent prompt mentions `Artifact` or `EnterWorktree`
  (grep of `.apm/agents/`). Of the five Skill-less agents, the planner and
  tasker load no skill by name (they preload theirs through `skills:`), and
  the shipper and brief reviewer load none; the specifier preloads
  `speckit-specify` but its amend mode says "rerun `speckit-clarify`'s
  encoding rules", a skill it does not preload. With `Skill` denied it
  would lose them silently, so those few rules move into its amend
  paragraph (R7, FR-014), not into a preload.

## R2 How the first task checks the real tasker's preload (FR-011)

- **Decision**: in a scratch directory made with `mktemp -d`, copy the
  edited `.apm/agents/feat-tasker.agent.md` (new denials and new hook
  line) to `.claude/agents/feat-tasker.md` and the worktree's
  `.claude/skills/speckit-tasks/` and `.claude/skills/speckit-analyze/` to
  `.claude/skills/`, and write `.specify/extensions.yml` with one enabled,
  non-git, mandatory hook:

  ```yaml
  hooks:
    before_tasks:
      - extension: probe
        command: speckit.probe.hello
        enabled: true
        optional: false
        description: probe hook
  ```

  Then from that directory run one
  `claude -p --model haiku --allowedTools Agent --output-format json`
  whose prompt asks the session to spawn subagent `feat-tasker` with:
  "Don't run your steps. Do only the extension-hook check that comes
  before task generation, then reply only with: the name and first `#`
  heading of every skill whose instructions are in your context, whether
  a tool named `Skill` is in your tool list, and your `Skipped hooks:`
  line." Pass, all three: both `speckit-tasks` and `speckit-analyze` are
  named with their file's first heading; `Skill` is absent; the
  `Skipped hooks:` line names `before_tasks` `speckit.probe.hello`, and the
  subagent's transcript
  (`~/.claude/projects/<scratch path, encoded>/<session_id>/subagents/agent-*.jsonl`,
  `session_id` from the JSON output) shows no call that runs the hook;
  only read-only access to `.specify/extensions.yml` (an existence check
  or a Read).
  Record the command, its output, the transcript's tool calls and
  `claude --version` in the implementer's report.
- **Rationale**: it runs the real agent file, byte for byte, with the
  real skills, as a spawned subagent (the path that `skills:` preloading
  takes). A project-level `.claude/agents/` agent wins over the user-level
  one of the same name, so the old `feat-tasker` the user has installed
  (`~/.claude/agents/feat-tasker.md` links to the main checkout, not this
  branch) is not the one spawned. Haiku and a one-line answer keep the
  probe cheap. Headless `-p` changes which tools load, not how `skills:`
  preloads. The hook part matters because the preloaded `speckit-tasks`
  says a mandatory hook MUST be invoked: only the real agent, with its new
  hook line next to that text, shows which one wins. A made-up command
  has no skill behind it, so any attempt to find or run one shows up as a
  tool call; a denied `Bash` call (`-p` allows only `Agent`) is still in
  the transcript.
- **Alternatives considered**: `--agents` JSON (the brief's probes) —
  transcribes the file, so it is a stand-in, which the brief rejected;
  spawning from the `/feat` coordinator — its installed agents are the
  main checkout's, and the coordinator does no work (principle I); waiting
  for the measured `/feat` run (R6) — too late, FR-011 must come before the
  gate and docs are written.
- **If the call is refused** (auto mode or a hook refuses a nested
  `claude`): the implementer reports the task not done with the exact
  commands, and does none of the dependent tasks; the coordinator's gate
  puts the commands to the user.
- **On preload failure**: remove `Skill` from the tasker's
  `disallowedTools` and restore its old hook paragraph, stop, and report
  it under `Design problems:`. The remaining work is then FR-001, FR-008,
  FR-010, FR-013, the "Denied tools" column and the setup-dependent line
  of FR-009, and FR-012 for the two-tool denial; the hook gate, the three
  hook lines, FR-014 and the other four `Skill` denials drop out.
- **On hook failure** (preload passes, but the tasker tries to run the
  hook): stop and report it under `Design problems:` with the offending
  tool calls; the coordinator decides the hook line's new wording before
  the gate or docs are written. The scope does not change.

## R3 Which hooks the setup gate names

- **Decision**: enabled entries (`enabled` not `false`) under
  `before_specify`, `after_specify`, `before_plan`, `after_plan`,
  `before_tasks`, `after_tasks`, `before_analyze` and `after_analyze`, git
  ones included, are named as hooks that will not run. Entries under
  `before_implement` and `after_implement` keep today's rule. Every other
  key (`clarify`, `checklist`, `constitution`, `converge`,
  `taskstoissues`, `bug_*`) is left as today: no `/feat` agent runs those
  skills, so no `/feat` agent would run their hooks.
- **Rationale**: these are exactly the keys the preloaded `speckit-specify`,
  `speckit-plan`, `speckit-tasks` and `speckit-analyze` read (grep of
  `.claude/skills/speckit-*/SKILL.md`); the spec scopes the gate to those
  four phases.
- **Manual command**: `/` followed by the entry's `command` with dots
  replaced by hyphens (`speckit.git.commit` → `/speckit-git-commit`), the
  rule the Spec Kit skills themselves use to invoke a hook.
- **Alternatives considered**: gate every non-implement key — names hooks
  that never ran in `/feat` before either, which would be a behaviour
  change the spec didn't ask for.

## R4 When the gate is hard, and `rebase`

- **Decision**: setup step 4 is a hard gate when at least one enabled hook
  of the four phases exists, or an enabled `implement` hook would create a
  branch or commit (today's test: the git extension's). One message lists
  both kinds. Enabled `implement` hooks that don't branch or commit are
  allowed, logged as the state file's allowed hooks, and raise no gate on
  their own (as today). No enabled hooks: no gate. On `/feat rebase`,
  which runs setup steps 0, 2, 3 and 4 but no specify, plan or tasks
  phase, only the `implement` part applies.
- **Rationale**: FR-004/FR-005 and scenario 5; rebase runs none of the
  three Skill-less agents' phases, so naming their hooks there would be a
  gate about nothing.
- **Alternatives considered**: a second gate for implement hooks — the
  spec asks for one.

## R5 The lint check (FR-008)

- **Decision**: one more line in `mise.toml`'s `lint` task: for each
  `.apm/agents/*.agent.md`, take the `disallowedTools:` line, split it on
  commas and spaces, and require the exact tokens `Artifact` and
  `EnterWorktree`; print `<file>: disallowedTools lacks <tool>` for every
  missing pair, then fail. POSIX `sh` (mise runs task lines with `sh`),
  `awk` or `grep -E`, no GNU-only `\b`. The task's `description` gains "check
  every agent denies Artifact and EnterWorktree".
- **Rationale**: the harness-words grep and the `/tiny` length check are
  already one-liners there (principle V: a shell one-liner over a script);
  CI's `check` workflow already runs `mise run lint`.
- **Alternatives considered**: a script under `.apm/skills/feat/scripts/`
  with tests under `tests/` — the scripts there ship to users, this check
  is for maintainers; checking the `Skill` denial too — the spec asks for
  the two tools only.

## R6 The measured run and where its numbers go (FR-012)

- **Decision**: after this run ships (its PR open, unmerged), the user
  runs `./install.sh` from this worktree (link mode: it re-points
  `~/.claude/skills/{brief,feat,fix,tiny}` and `~/.claude/agents/feat-*.md`
  at the worktree), runs one real small `/feat` on a pending small issue
  (a real feature, not a throwaway) through its PR stage, runs
  `python3 -I .apm/skills/feat/scripts/measure.py --session <id>` and
  `claude --version`, adds the before/after table (quickstart §6) to this
  feature's PR body, then runs `./install.sh` from the main checkout to
  point the links back. No `measurement.md` is written and no implementer
  is spawned for it; the task is a user step, which the implementer
  reports as not verified.
- **Rationale**: the user-level agents and skills are links to the main
  checkout, so a run started anywhere else would measure the old agents.
  `install.sh` already handles both directions (it removes its own links
  and re-links). A real `/feat` has hard gates, so only the user can drive
  it; the implementer cannot spawn agents (`Agent` is denied). Running it
  after ship, on work that was pending anyway, costs no throwaway run and
  doesn't hold this run's phases open; the PR stays unmerged until its
  body carries the numbers.
- **Alternatives considered**: project-level install
  (`./install.sh --copy --target <project>/.claude`) in a scratch clone —
  leaves the user's other sessions untouched, but needs a scratch clone
  with a GitHub remote to reach the PR stage, and leaves the old `/feat`
  skill winning if user-level skills take precedence; `claude -p "/feat …"`
  headless — loads a different tool set (no `Artifact`), so it would not
  measure the interactive saving, and can't answer the gates; a run
  before ship with an implementer writing `measurement.md` — holds this
  run open on a second run and adds a file and a spawn for a table the PR
  body carries anyway.

## R7 Agent prompt wording

- **Decision**: in the specifier, planner and tasker, the four-line
  "Spec Kit hooks: the orchestrator tells you which hooks …" paragraph
  becomes two lines (see contracts/setup-hook-gate.md). The steps that
  say "Run `speckit-plan`" etc. stay as they are. The specifier's
  **Amend mode** paragraph (FR-014) drops "rerun `speckit-clarify`'s
  encoding rules" for the rules themselves; wording may be tightened, the
  content may not change:

  > **Amend mode**: when the orchestrator sends the user's answers to open
  > markers or edits to the spec, apply exactly those to spec.md, without
  > asking anything, and report again. For each answered marker: add
  > `- Q: <question> → A: <answer>` under `## Clarifications` /
  > `### Session YYYY-MM-DD` (create them after the overview section if
  > missing); replace the marker with the answer in the section it belongs
  > to (requirement, user story, entity, success criterion or edge case);
  > leave no statement the answer contradicts; use one term throughout; add
  > no other heading.
- **Rationale**: with `Skill` denied the tool is absent from the agent's
  list and the preloaded skill text is in its context, so "run" can only
  mean follow it (the brief's probe agent quoted its preloaded skill). The
  FR-011 probe and the measured run (after ship) show whether an agent
  still tries a `Skill` call; if one does, the step gains "(preloaded:
  follow it)" (before the gate and docs if the probe shows it, as a
  follow-up issue if only the measured run does).
- **Alternatives considered**: rewording every "Run `speckit-…`" now —
  prompt lines on every spawn without evidence they are needed;
  preloading `speckit-clarify` in the specifier — puts its whole
  question-asking workflow and hook block in every spawn's context for the
  five rules amend mode uses.

## R8 Docs and diagrams

- **Decision**: `docs/workflow.md` (phases table row 0, `### 0 Setup`
  text, agents table "Denied tools", one sentence after that table on the
  denials and the setup-dependent saving) and `.apm/skills/feat/SKILL.md`
  (phases table row 0, setup step 4). `docs/design.md`'s "all `speckit-*`"
  override row is updated in a few words so it doesn't contradict the new
  rule. No diagram changes: `docs/diagrams/gates.d2` and `chain.d2` don't
  draw the setup gate, and the size tables (the source of `models.svg`)
  don't change.
- **Alternatives considered**: a new docs section — one sentence carries
  it.
