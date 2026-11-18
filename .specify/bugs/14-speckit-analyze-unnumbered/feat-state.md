# /fix state: speckit-analyze cannot find the unnumbered spec dir, and the phase 5 gate hides it

- Branch: fix-14-speckit-analyze-unnumbered Worktree: /home/pierre/Projects/logistics/.claude/worktrees/fix-14-speckit-analyze-unnumbered
- Size: medium
- Agents: none (every spawn is fresh)
- Current phase: done (shipping)
- Conventions: conventional commits `type(scope): short message`, one logical change per commit, concise; never co-author commits (the user is the only author); stage only task files; PR body says `Fixes #N`, never a commit message. Shell is zsh: quote variables; `rm`/`cp`/`mv` are interactive aliases, use `command rm -f` etc. In the worktree call `/usr/bin/git` directly, one plain command per call (no heredocs, pipes or globs). Follow `.claude/CLAUDE.md`: size tables in `.apm/skills/feat/SKILL.md` / `fix/SKILL.md` mirrored in `docs/workflow.md`; agent prompts end with a fixed report format the orchestrator depends on (change both sides together); `/feat` and `/fix` stay thin; shared rules in `.apm/skills/feat/references/harness.md` carry no `/feat`-only words; diagrams re-rendered with `mise run diagrams` when phases/gates change. Checks: `mise run lint` and `mise run test:apm` (plus `mise run test:tracker`, `mise run test:spec-number`); shellcheck clean. Never edit CHANGELOG.md or release versions by hand.
- Allowed Spec Kit hooks: none (extensions.yml has no hooks)
- Map: none
- Issue: #14

## Report

#14

## Log

- [x] 0 Setup — tracker: ok users/pdemagny/projects/2 (Brief, In progress, In review); slug 14-speckit-analyze-unnumbered; bug extension 1.0.2; report author OWNER
- [x] 1 Assess — answer: what did the worktree guard refuse? → not investigated; the fix uses a plain env-prefixed command, and `Analyze: not run` makes the gate hard if it is refused (user: "ok")
- [x] 1 Assess — answer: also cover plan/implement? → no, tasker only as the issue asks; a follow-up issue if they fail too (user: "ok")
- [x] 1 Assess — answer: feature.json missing or stale in the 8 runs? → unknown; the preferred fix covers both (user: "ok")
- [x] 1 Assess — remediation: preferred alone, not combined with the specifier alternative (user: "ok")
- [x] 1 Assess — hard gate: valid, medium confidence, reproduced, 2 remediation(s); size medium
- [x] 2 implementer — not verified:
    - n/a → worktree guard accepting the env-prefixed command in a real tasker spawn → no live /feat run in this phase (if it is refused, `Analyze: not run` now makes the gate hard)
- [x] 2 Fix — applied; no deviations; checks pass
- [x] 3 Test — partial: a real /feat run or feat-tasker spawn showing the worktree guard accepts the env-prefixed command
- [x] ship with partial (user: "ship with partial")
- [x] 4 Code review — soft gate; auto-applied B1, B2, std1; skipped std2 (reviewer: "the gate column on the same row already states the not-run case")
    - B1 .apm/agents/feat-tasker.agent.md:19 — feature dir unquoted in the env-prefixed command — rec: apply
    - B2 .apm/skills/feat/SKILL.md:302-305 — missing `Analyze:` line worded as "not run, cross-checked by hand" — rec: apply
    - std1 docs/design.md:93,95,98 — Spec Kit overrides table omits the tasker's prerequisite-dir override — rec: apply
    - std2 docs/workflow.md:36 — row 5 "Produces" still says "analysis clean" — rec: skip
- [x] 4 implementer — B1, B2, std1 applied; checks pass; not verified:
    - n/a → worktree guard accepting the env-prefixed command (now quoted) in a real tasker spawn → no live /feat run in this phase
- [x] 3 Test — partial: a real /feat run or feat-tasker spawn showing the worktree guard accepts the env-prefixed, single-quoted command (after review fixes)
- [x] ship with partial (user: "ship with partial") — after review fixes
- [x] 5 Ship
