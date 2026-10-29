# Changelog

## Unreleased

- `/feat-brief #N` (or an issue URL) starts the brief from a GitHub issue,
  read with `gh`: its title and body are the idea, its unchecked checklist
  items are questions to answer, and a bug issue is refused. The brief and
  the state file record the issue, and the shipper's PR says `Closes #N`.
  `/feat #N` points to `/feat-brief #N`.

## 0.6.1 — 2026-10-29

- `mise run release` dates the `## Unreleased` section itself and opens a
  new empty one in the same commit; it refuses to release when Unreleased
  has no entries. Write changes there; no hand-written version heading.

## 0.6.0 — 2026-10-29

- `/feat-brief` has every brief read by a fresh agent before you confirm
  it: `feat-brief-reviewer` (phase 1, sonnet · medium, opus · medium for
  large) never sees the interview. It paraphrases the brief (the gate shows
  it), asks whether existing code, a dependency or a smaller version would
  do, flags undecided failure and edge cases, uncheckable acceptance and
  effects on existing data, and estimates the size on its own. Adapted from
  google/elephant-goldfish-model's brainstorm (Apache-2.0).
- The interview pushes back: each decision gets its strongest
  counter-argument before it is written down, and it asks how the problem
  is handled today.
- Briefs gain "Today" and "Alternatives rejected". The specifier treats
  rejected alternatives as binding, the planner doesn't bring them back,
  and reviewers get them with the rejected findings. Older briefs still
  work.

## 0.5.0 — 2026-10-29

- a cost script (since moved out) attributes phases correctly again: since the size
  table was column-aligned, only the 4b and 7 rows parsed, so most runs
  showed phases 0, 4 and 7 only; and a spawn's phase was applied one call
  late, so each subagent landed in the previous phase.
- a cost script (since moved out) prices subagent cache writes at the 5-minute TTL (1.25×
  input) Claude Code uses for them, not 2×: runs measured ~15% too high.
- the cost notes (since moved out) records the first measured runs of the current workflow.
- An agent is continued with `SendMessage` only while it is warm (no stop
  for the user since its report); after a hard gate you answered, it is
  spawned fresh in amend mode. Subagent caches last 5 minutes, and a cold
  planner rewrote 150–200k of context on Opus in 7 of 15 runs. Implementers
  are never continued into the next story.
- Agents write files with Write/Edit instead of shell heredocs and
  redirections, which the worktree guard refused 190 times in 15 runs, and
  report only once their writes have returned: 4 of 15 specifiers reported
  a spec.md that wasn't written.
- New design reviewer in phase 4 (4c clarity and fit, `feat-design-reviewer`),
  next to security and cost. It reads spec and plan as someone new to the
  project: it paraphrases them (the gate shows it, so you can check it against
  what you meant), and flags undefined terms, statements the code contradicts,
  references to things that don't exist, helpers the codebase already has,
  speculative abstractions, and decisions left to the implementer. Adapted
  from google/elephant-goldfish-model's review (Apache-2.0).
- Phase 4 is one agent with lenses, like phase 7: `feat-design-reviewer`
  runs 4a security, 4b cost and 4c clarity and fit. A small feature gets one
  reviewer with all three lenses (one cold start instead of three; spec 022
  simulated: phase 4 $0.34 from $0.52, the run $7.93 from $8.10); medium
  and large keep one per lens in
  parallel. `feat-sec-reviewer` and `feat-cost-reviewer` are removed: after
  `./install.sh`, delete their dangling links in `~/.claude/agents/`.
- docs/workflow.md listed the large-size phase 5 row as sonnet · high; it
  is opus · high, as in the skill.

## 0.4.0 — 2026-10-28

- Fewer stops on small and medium features: questions are asked only at
  the spec gate (the planner reports assumptions instead of asking), and
  plan and design review share one gate that is hard only on a real
  finding, an assumption needing your call, a blocker or a size increase.
  The tasks gate is soft unless analyze finds CRITICAL/HIGH issues, the
  size grows or a checklist item is unanswered. Large keeps its gates.
- A size increase is always a hard gate, in any phase; a decrease is
  applied and logged.
- The specifier, planner and tasker are continued with `SendMessage` for
  amendments instead of being spawned cold again (their agent ids go in the
  state file).
- Size thresholds follow the task count: small up to ~30, medium ~31–60, large
  over ~60 (were 25 / 50).
- Claude Code is the only supported harness. The install docs, README and
  `mise run test:apm` no longer cover Codex, OpenCode, Gemini or
  Antigravity: `/feat` never ran there, so they only got a partial install.
  APM stays as the Claude installer because it also installs the
  third-party skills.
- The shipper commits less: numbering happens before the first commit (no
  `number … as NNN` commit), and docs go in the feat commit instead of
  trailing `docs` commits. Usually two commits: specs, then feat.

## 0.3.3 — 2026-10-27

- The spec dir is numbered in phase 8, not phase 2. Features started in
  parallel worktrees can't see each other's numbers and picked the same
  `NNN`. The branch and `specs/<short-name>/` stay unnumbered; the shipper
  takes the next free number from `origin/<default>` and the open PRs,
  renames the dir and the branch, and commits that on its own before the
  push.

## 0.3.2 — 2026-10-24

- Efforts lowered for medium and large features.

## 0.3.1 — 2026-10-23

- Sizes follow the expected task count: small up to ~25, medium ~26–50,
  large over ~50. Spreading over several packages no longer makes a
  feature large, and medium is no longer the fallback. A new service,
  permissions, exposure or dependency raises small to medium; docs-only
  work is small. Phase 5 proposes a smaller size as well as a bigger one.

## 0.3.0 — 2026-10-22

- Sizes renamed: small / medium / large / huge (were small / normal / big /
  huge). `/feat` still reads "normal" and "big" in older briefs and state
  files.
- `mise.toml`: pinned tools (claude, gh, specify-cli, apm, node, uv,
  shellcheck) and tasks: `lint`, `check`, `test:apm`, `dev:install`,
  `dev:uninstall`, `cost`, `release <version>`, `pin <tag>`.
- a cost script (since moved out) for the project's Spec Kit skills.

## 0.2.0 — 2026-10-22

- Docs say what works where: `/feat` runs only in Claude Code (and now
  stops with a message elsewhere); `/feat-brief` and the agents on their
  own can be installed for Codex, OpenCode and other harnesses.
- The third-party skills are pinned to addyosmani/agent-skills `0.6.13` in
  `apm.yml`.
- Install with one command for any harness: `apm install -g
  pdemagny/feat-agents` (APM) installs the skills, the agents (converted for
  Codex, copied for OpenCode) and the three third-party skills, declared in
  the new `apm.yml`. Claude Code users can install it as a plugin instead:
  `/plugin install feat-agents --marketplace pdemagny/feat-agents`.
- Skills and agents moved to `.apm/skills/` and `.apm/agents/*.agent.md`,
  the layout both APM and the plugin read. `./install.sh` follows; rerun it
  to update existing links.
- Agent frontmatter is harness-neutral: no `model`, `effort` or `color`, and
  `disallowedTools` instead of `tools`. `/feat` already passed model and
  effort on every spawn.
- `/feat` accepts plugin-namespaced agent names (`feat-agents:feat-planner`);
  a cost script (since moved out) strips the prefix.
- `./install.sh deps` installs the three skills in one `npx skills add`;
  `./install.sh check` recognises a plugin install.
- The repo's `CLAUDE.md` moved to `.claude/CLAUDE.md` (plugins don't load a
  root `CLAUDE.md`, and the validator warns about it).
- `code-simplification` is no longer a dependency: its behaviour-preserving
  rule, readability signals and over-simplification traps are inlined in
  `feat-code-reviewer` lens 7e (Addy Osmani, MIT, credited).
- Matt Pocock's `code-review` is no longer downloaded: its standards and
  spec axes and smell baseline are inlined in `feat-code-reviewer` lens 7a
  (MIT, credited), run as passes in the reviewer's own context instead of
  two sub-agents. `install.sh` no longer vendors anything;
  `~/.claude/feat-agents/` is gone. No feat agent spawns agents.
- `ponytail-review` is no longer a dependency: Ponytail 5 made it a general
  review overlapping the other lenses. Its earlier over-engineering
  checklist is inlined in `feat-code-reviewer` lens 7d (MIT, credited).
- `install.sh` keeps backups in `~/.claude/feat-agents-backups/`, out of
  `skills/` and `agents/`.
- Fewer tokens per run (spec 022 simulated: 10.2M on small, from 14.7M in
  0.1.0 and 28.9M with the old skill):
  - Phase 1 is a separate `/feat-brief` skill that writes
    `specs/briefs/<name>.md` (or the capability map); `/feat <brief>` then
    starts from a cleared context.
  - `/feat` is a thin coordinator: it reads reports and keeps the state
    file; gate changes go back to the owning agent (amend modes for the
    specifier and planner), reviewers verify their own findings.
  - New `feat-shipper` (Haiku) for phase 8; picked review fixes are applied
    by `feat-implementer` in fix mode.
  - One implementer per user story at every size.
  - Phase 7 reviewers merged into one `feat-code-reviewer` with lenses;
    small runs two of them (7a+7b, 7c+7d+7e). Removed `feat-bug-reviewer`, `feat-perf-reviewer`,
    `feat-cut-reviewer`, `feat-simplifier`; `feat-sec-reviewer` is design
    only.
  - Medium effort on small for design security, implementation and code
    review.
- `install.sh` installs every skill in `skills/`.
- a cost script (since moved out) models the new shape (`--stories`).
- Phase 7 correctness review uses Matt Pocock's `code-review` (standards and
  spec axes) instead of the built-in one; `feat-bug-reviewer` adds its own
  bug pass. `install.sh deps` saves it outside `skills/` so it doesn't
  replace `/code-review`.
- README: mermaid flow diagram.
- a cost script (since moved out) (find, measure, simulate) and the cost notes (since moved out), with the spec
  022 run as baseline ($14.24 measured; split simulated at $11.21 small).
- Huge features: the capability-map rules are inlined in `SKILL.md`
  (adapted from addyosmani/agent-skills' `spec-driven-development`, MIT);
  that skill is no longer a dependency.
- Dropped `incremental-implementation`: its commit-per-slice workflow
  conflicted with the harness.
- New `feat-perf-reviewer` in phase 7 (performance-optimization's measure
  and identify steps on the built code); the orchestrator applies picked
  fixes with before/after measurement, keeps or reverts them, and commits
  kept ones as `perf(scope)`.
- Overrides for the remaining skills' standalone behaviour (interview-me
  hand-offs, code-simplification applying fixes, speckit checklist and
  remediation prompts, Spec Kit hooks that branch or commit).
- Fixed: phase 7 reviewed an empty `...HEAD` diff, since nothing is
  committed before phase 8; reviewers now get `git diff <merge-base>` after
  `git add -N`.
- Big features implement stories one after the other (parallel worktrees
  couldn't see uncommitted work). EnterWorktree's branch is renamed to match
  the spec directory.

## 0.1.0 — 2026-10-22

- `feat` skill moved out of `~/.claude/skills` into its own project.
- Phases 2–7 run in dedicated `feat-*` subagents; model and effort per
  phase follow the feature's size (small, normal, big), from one size table.
- New sizes: big (one implementer per user story, gate after each) and huge
  (split into a capability map, one `/feat` run and PR per capability).
- Agent defaults equal the small size (Sonnet medium/high, Opus high for
  planning).
- `install.sh`: install (link or copy), deps, check, uninstall.
