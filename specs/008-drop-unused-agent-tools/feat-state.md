# /feat state: Drop unused tools from the feat-* agents' starting context

- Branch: drop-unused-agent-tools Worktree: /home/pierre/Projects/logistics/.claude/worktrees/brief-drop-unused-agent-tools
- Size: small
- Agents: specifier a64b6cb65e3d448a2, planner af72fb08a4170be41, tasker a9ed7c8ce7e481b5a (for SendMessage)
- Current phase: done (shipping)
- Conventions: conventional commits `type(scope): msg`, one logical change per commit, user is sole author (no co-author lines); `Closes #N` in the PR body only, never in a commit message. Call `/usr/bin/git` directly, one plain command per call (no heredocs, pipes or globs). zsh; `rm/cp/mv` are `-i` aliases: use `command rm -f` etc. Agent frontmatter: no model/effort/tools/color, use `disallowedTools`; `docs/workflow.md` mirrors the agents table and size tables; adding/removing an agent updates `.claude-plugin/plugin.json`. `harness.md` holds no /feat-only words (lint greps). Agent report formats and their readers change together. `mise run lint` and `mise run test:apm` before committing. CHANGELOG and versions are generated: never edit by hand.
- Allowed Spec Kit hooks: none (`.specify/extensions.yml` has `hooks: {}`)
- Map: none
- Issue: #54

## Brief

- Size: small — ~12 tasks expected: frontmatter in nine agent files, three agent prompts and `/feat`'s setup hook rule, one lint check, docs, one measured `/feat` run
- Short name: drop-unused-agent-tools
- Kind: feat
- Issue: #54

### Why
Every `feat-*` agent starts at 33–41k tokens of context before its first
tool call, and each of its model calls re-reads it; a `/feat` run makes
about 430 subagent calls, so this fixed part is roughly a fifth of a run's
cost. Two tool schemas no agent ever calls (`Artifact`, `EnterWorktree`)
and the skills listing that comes with the `Skill` tool make up most of
it. Whoever runs `/feat` or `/fix` pays for them on every call.

### Today
Agent frontmatter denies only `Agent` and the editing tools each role must
not use (`docs/workflow.md`, agents table). Everything else, including
`Artifact` (about 38k characters, ~13k tokens) and `EnterWorktree` (about
4k characters), is in every agent's tool list in interactive and
background sessions. The `/feat` baseline in `docs/workflow.md` ("First
request") shows tools at ~53k characters and the skills listing at ~25k
characters of each agent's first request.

The specifier, planner and tasker preload their Spec Kit skills through
`skills:` and never load another one, but keep `Skill` and so the whole
listing. The only use they have for it is running `.specify/extensions.yml`
hooks, which `/feat` setup allows for every hook except those that create
a branch or commit (`.apm/skills/feat/SKILL.md`, setup step 4).

Verified before this brief (probe agents spawned from a `claude --bg`
session in this repo, haiku, Claude Code 2.1.328):
- `disallowedTools: Artifact, EnterWorktree` removes both schemas, not
  only the calls: first-call context 33,385 → 19,411 tokens.
- An unknown name in `disallowedTools` (`NoSuchTool`) is ignored silently:
  context identical, no error. So users without the `Artifact` tool are
  unaffected.
- Denying `Skill` removes the skills listing (another −10.5k tokens here)
  and a skill named in `skills:` is still preloaded: an agent with
  `speckit-analyze` preloaded and `Skill` denied quoted its first heading.
- In headless `claude -p`, `Artifact` is not loaded and `EnterWorktree` is
  deferred: the gain depends on how and with what tools the user runs
  Claude Code.

### Behaviour
- All nine agents deny `Artifact` and `EnterWorktree` in addition to what
  they deny today.
- `feat-specifier`, `feat-planner`, `feat-tasker`, `feat-brief-reviewer`
  and `feat-shipper` also deny `Skill`: they start without the skills
  listing. The specifier, planner and tasker still get their preloaded
  Spec Kit skills.
- `feat-code-reviewer`, `feat-design-reviewer`, `feat-bug-assessor` and
  `feat-implementer` keep `Skill`: they load skills by name (lenses,
  `speckit-bug-*`, `speckit-bug-fix` in bug mode).
- `feat-shipper` is also spawned by `/fix` (fix mode) and `rebase`, so
  `/fix` loses `Skill` in its shipper too; that is safe: the shipper runs
  no Spec Kit hook and loads no skill. `feat-brief-reviewer` is spawned
  only by `/brief`.
- `/feat` setup: any enabled hook in `.specify/extensions.yml` that the
  specifier, planner or tasker would run (the `specify`, `plan`, `tasks`
  and `analyze` hooks, git ones included) is one they cannot run. Setup
  shows one merged hard gate with one message, replacing today's
  git-hook gate for those phases: it names each hook that will not run
  and the command to run it by hand (e.g. `/speckit-…`); the user
  continues with them skipped or stops. There is no "run it anyway" for
  those phases. Hooks the implementer runs (`implement`) keep today's
  rule: allowed unless they branch or commit, and branch or commit ones
  skipped unless the user says otherwise, under the same gate.
- In each of the three agents, the line "Spec Kit hooks: the orchestrator
  tells you which hooks … are allowed. Run only those…" becomes "skip
  every hook and list it under `Skipped hooks:`". Their report format is
  unchanged: all three already end with `Skipped hooks:`. The PR body is
  unchanged: the user decided at the gate.
- `docs/workflow.md` says in one line that the saving depends on the
  user's setup (which tools and skills their Claude Code loads, and
  whether it runs interactively, in the background or headless).

### Out of scope
- `/fix`'s hook handling: its assessor and implementer keep `Skill` (its
  shipper loses it, see Behaviour).
- Allow lists (`tools:`) instead of deny lists.
- The implementer's own prompt and preloaded skill (#39).
- Trimming the CLAUDE.md chain, memory index or agent prompts.
- Any other tool: `ToolSearch` (~500 tokens) gates the deferred tools
  (WebFetch, LSP…) and stays; `ExitWorktree` is already deferred.

### Alternatives rejected
- Keep `Skill` on the specifier, planner and tasker and file its drop as a
  follow-up — the planner alone is 18% of a `/feat` run's cost at ~30
  calls a spawn, and non-git Spec Kit hooks are rare; worth the gate.
- Let the Skill-less agents run an allowed hook by reading its
  `SKILL.md` with `Read` — skills live in plugin, user or project folders,
  so the agent would guess paths; fragile.
- Allow lists (`tools:`) so new heavy tools are excluded by default — the
  project's rule is deny lists, so a new tool (an MCP server a project
  relies on) stays available unless denied.
- Prove it with the `--agents` probes only — probes use stand-in agents and
  can't show the real planner and tasker still load their skills.
- Prove it with one `/fix` run (the issue's original check) — `/fix` spawns
  none of the specifier, planner or tasker, whose behaviour changes most.

### Acceptance
- Each of the nine agent files denies `Artifact` and `EnterWorktree`; the
  five named above also deny `Skill`.
- `mise run lint` fails when an agent file in `.apm/agents/` does not deny
  `Artifact` and `EnterWorktree`.
- One small real `/feat` run on this branch goes through to its PR stage,
  the planner and tasker producing plan.md and tasks.md from their
  preloaded skills.
- The PR gives first-call context per agent type before and after. Before:
  the `ctx first` and "First request" medians in `docs/workflow.md`'s
  Baseline section (same machine, Claude Code 2.1.308–2.1.328). After:
  `measure.py --session` for the new run, with its Claude Code version. No
  agent type's first request carries the `Artifact` or `EnterWorktree`
  schema (nor the skills listing, for the five that deny `Skill`).
- With an enabled `before_plan` (or other specify/plan/tasks/analyze) hook
  in `.specify/extensions.yml`, `/feat` setup shows one hard gate that
  names it as skipped with the command to run it by hand; an enabled git
  hook in those phases appears in the same gate, not in a second one.
- `docs/workflow.md` agents table ("Denied tools") matches the agent files,
  its setup text matches the new hook rule, and it carries the one line on
  setup-dependent gain.
- `mise run lint` and `mise run test:apm` pass.

### Constraints / decisions already made
- Use `disallowedTools`; agent frontmatter carries no `model`, `effort`,
  `tools` or `color` (project rule).
- `/feat` stays thin: the hook check stays in setup reading the YAML, no
  new coordinator work; agent prompts end with their fixed report format,
  so a change to the hook line in a report changes both sides.
- Shared rules live in `.apm/skills/feat/references/harness.md` with no
  `/feat`-only words; the new hook rule is `/feat`-only and stays in
  `.apm/skills/feat/SKILL.md` and the three agent files.
- Measure with `.apm/skills/feat/scripts/measure.py` (`--session`), the
  tool epic #31 is judged by.
- Order: the first task spawns the real `feat-tasker` with `Skill` denied
  and checks that `speckit-tasks` and `speckit-analyze` are both preloaded
  (the probe used stand-in agents). If they are not, the five `Skill`
  denials and the hook gate drop out and the change is the two-tool
  denial only; stop and say so before writing the gate or docs.

## Log

- [x] 0 Setup — no Spec Kit hooks enabled; tracker ok (users/pdemagny/projects/2); #54 set to "In progress"
- [x] 2 Specify — soft
    - Stories: US1 Agents start with a smaller context (P1); US2 One merged setup hard gate for hooks the Skill-less agents can't run (P1); US3 Lint fails without the Artifact/EnterWorktree denial (P2); US4 Docs match, setup-dependent-gain line, PR carries before/after measurement (P2)
    - Requirements: 13 (FR-001–FR-013), 5 success criteria; notable: FR-002 exactly five agents deny Skill; FR-004 merged gate replaces the git-hook gate for those phases; FR-007 hook rule is /feat-only; FR-011 first task checks real feat-tasker preloads with Skill denied, else drop to two-tool denial
    - Spec assumptions: 1. Gate and lint failure wording left to planning (recommended: keep as written); 2. Only enabled hooks (`enabled` not false) are gated (recommended: keep as written); 3. "After" measurement on this machine with its Claude Code version stated (recommended: keep as written); 4. Brief's probe results taken as true, FR-011 checks the preload part (recommended: keep as written); 5. Tool and agent names appear in the spec as domain vocabulary (recommended: keep as written)
    - Unchecked checklist items: none
- [x] 3 Plan — plan.md + research, data-model, quickstart, contracts/{setup-hook-gate,lint-denials}.md; no size trigger; no diagram change; 9 assumptions, #4 (how the measured run gets this branch: user-level ./install.sh from the worktree, restore after) needs user
- [x] 4 Design review — hard (D1 high, D2/D4/D6 medium, planner assumption 4 needs user); user: "ok" → accepted D1–D7 as recommended; planner assumption 4: user-level ./install.sh from the worktree, measured run after ship on a real small pending issue, numbers added to this PR's body, restore from main; spec assumptions 1–5 kept as written; checklist: none open
    - D1 specifier amend mode loses speckit-clarify encoding rules with Skill denied — inline them in the amend paragraph; fix research R1, add file to plan
    - D2 gate doesn't say when to run skipped hooks — one sentence: won't run during this run; run by hand once the PR is open, or stop now
    - D3 gate example inconsistent — `<key>: <extension>.<command> → run it by hand: /<command, dots as hyphens>`; no command → extension only
    - D4 measured run underspecified — after ship, user runs it on a real small pending issue; numbers into this PR's body; no measurement.md, no implementer spawn
    - D5 restore step easy to forget — add "restore with ./install.sh from main" to quickstart's checklist
    - D6 preloaded speckit skills say MUST invoke hook — FR-011 probe adds an enabled non-git before_tasks hook; tasker lists it under Skipped hooks:, no Bash/Read attempt
    - D7 quickstart §6 names exact measure.py fields to read
- [x] 4 amend — planner wrote D1–D7 into spec/plan/research/quickstart/data-model/contract; new FR-014 (specifier amend rules inline); no measurement.md; no new user call
- [x] 5 Tasks — soft: 21 tasks (US1 T004–T009, US2 T010–T013, US3 T014–T015, US4 T016–T018; setup T001, foundational T002–T003 with T003 the FR-011 probe hard stop, polish T019–T021 with T021 the user's measured run); analyze ran, no open findings; no checklist items; size small confirmed
- [!] 6 US1 — hard stop at T003 (FR-011 probe, Claude Code 2.1.328, haiku, project-level copy of the edited tasker): preload PASS (speckit-tasks and speckit-analyze in context, first heading `## User Input` each; Skill not in tool list); hook PASS (`Skipped hooks: speckit.probe.hello (before_tasks) → not run`); strict pass rule FAIL on one read-only Bash `ls -la .specify/extensions.yml` (the preloaded skills' own pre-execution check), then a Read of that file. Done: T001; T002 applied (tasker denies NotebookEdit, Agent, Artifact, EnterWorktree, Skill; hook line replaced), unticked; T004–T021 not started. Baseline lint + test:apm pass.
- [x] 6 US1 — not verified: none
- [x] 6 US1 gate — hard (T003 strict rule); user: "ok" → T003 accepted as pass (purpose met: preloads present, hook not run; the Bash call was a read-only existence check of .specify/extensions.yml); pass rule reworded in T003 (tasker) and quickstart §1 (planner) to "no call that runs the hook; only read-only access to .specify/extensions.yml"; fresh US1 implementer for T004–T009
- [x] 6 rule amend — tasker reworded T003, planner reworded quickstart §1, research R2, spec FR-011 + edge case, plan step 127 to "no call that runs the hook; only read-only access to .specify/extensions.yml (an existence check or a Read)"
- [x] 6 US1 — T002–T009 done (9 agents' disallowedTools; specifier amend rules inline, FR-014); lint + test:apm pass
- [x] 6 US1 — not verified: none
- [x] 6 US2 — T010–T013 done (SKILL.md setup step 4 merged hook gate + row 0; specifier/planner hook line); T013 quickstart §4 cases checked by reading, not by a live /feat with a hook enabled; lint + test:apm pass
- [x] 6 US2 — not verified: none
- [x] 6 US3 — T014–T015 done (mise.toml lint line: each agent's disallowedTools must hold Artifact and EnterWorktree; failure shown on a temporary shipper edit, restored, cmp identical); lint + test:apm pass
- [x] 6 US3 — not verified: none
- [x] 6 US4 — T016–T020 done (docs/workflow.md agents table, row 0, 0 Setup, setup-dependent-gain line; docs/design.md speckit override row); lint + test:apm pass
- [x] 6 US4 — not verified:
    - T021 → measured /feat run + measure.py --session → user step after the PR is open
- [x] 6 Implement — soft: tasks done 20/21 (1 not verified: T021)
- [x] 7 Code review — soft: auto-applied R1, R2; skipped R3 (reviewer: "churn; unrelated rows were already uneven"), std1 (reviewer: "a formatter would reflow it; no behaviour change"), std2 (reviewer: "still correct for the implementer and for /fix"), C1 (reviewer: "the loop is correct; the alternative is riskier and no shorter"), C2 (reviewer: "required by the spec"), C3 (reviewer: "nothing to cut"), R4 (reviewer: "the description covers it"); untested: US1-3, US4-3, SC-001–SC-003 (measured run after ship)
    - R1 .apm/skills/feat/SKILL.md:187-204 + docs/workflow.md:186-196 — split setup step 4 into 3 sub-bullets — rec: apply
    - R2 docs/design.md:97 — "(`Skill` is denied; only their preloaded skills are available)" — rec: apply
    - R3 docs/workflow.md:32 + agents table — re-pad table cells — rec: skip
    - std1 docs/workflow.md:32 — table column alignment — rec: skip
    - std2 .apm/skills/feat/references/harness.md:45 — "allowed hooks" wording left — rec: skip
    - C1 mise.toml:32 — loop → two greps — rec: skip
    - C2 .apm/agents/feat-specifier.agent.md:24-32 — inlined encoding rules — rec: skip
    - C3 specifier/planner/tasker hook paragraph — rec: skip
    - R4 mise.toml:32 — comment on the lint one-liner — rec: skip
- [x] 7 review fixes — R1 applied (SKILL.md setup step 4 + workflow.md Setup split into 3 sub-bullets, wording unchanged); R2 applied (design.md:97); performance: none; lint + test:apm pass
- [x] 7 review fixes — not verified: none
- [x] 8 Ship
