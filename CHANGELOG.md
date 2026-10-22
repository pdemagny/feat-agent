# Changelog

## Unreleased

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
