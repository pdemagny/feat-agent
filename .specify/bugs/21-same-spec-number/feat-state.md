# /fix state: Parallel /feat runs can ship the same spec number

- Branch: fix-21-same-spec-number Worktree: .claude/worktrees/fix-21-same-spec-number
- Size: medium
- Agents: none (every spawn is fresh)
- Current phase: done (shipping)
- Conventions: conventional commits `type(scope): short message`, one logical change per commit, concise, no co-author/attribution lines; stage only this task's files by path. Sources live in `.apm/` (skills `.apm/skills/*/SKILL.md`, agents `.apm/agents/*.agent.md`, tracker script `.apm/skills/feat/scripts/`, bash tests `tests/tracker/`). Checks: `mise run lint` (shellcheck on install.sh, scripts, tests/tracker; harness grep), `mise run test:tracker`, `mise run test:apm`. Agent report formats are coupled to `/feat`/`/fix`: change both sides together; `/feat`/`/fix` stay thin. User-visible changes go in CHANGELOG.md `## Unreleased`.
- Allowed Spec Kit hooks: none (extensions.yml has `hooks: {}`)
- Map: none
- Issue: issue 21 of the pre-release repo

## Report

#21

## Log

- [x] 0 Setup — tracker: ok users/pdemagny/projects/2 (Brief, In progress, In review); slug 21-same-spec-number; bug extension 1.0.2 (installed by the user, committed on this branch as 51acf5a `chore(specify): add bug extension`); report author OWNER
- [x] 1 Assess — answer: drop the branch rename, or keep it optional? → drop it; the script still reads branch names as an extra source, so older open `NNN-…` PRs count (user: "ok")
- [x] 1 Assess — answer: also check after `gh pr create`? → no: renumbering after push would need a force-push; the seconds-wide window is closed by the project's up-to-date-branch protection (user: "ok")
- [x] 1 Assess — answer: why did #363/#369 shippers skip `git branch -m`? → not investigated; doesn't change the fix (user: "ok")
- [x] 1 Assess — hard gate: valid, high confidence, reproduced, 3 remediation(s); size medium
- [x] 1 Assess — building move: tracker: issue 21 of the pre-release repo set to "In progress"
- [x] 2 Fix — applied; checks pass (lint, test:tracker, test:spec-number 16 cases, test:apm); hard gate on deviations: second check runs before push (not just before `gh pr create`), renumber uses fixup + `rebase --autosquash` without -i (git ≥ 2.44), stale `<NNN>-` branch mentions also fixed in docs/design.md, docs/usage.md, README.md
- [x] 2 Fix — size medium kept (user: "ok"); git ≥ 2.44 accepted, add the minimum to docs/install.md requirements during review fixes (user: "ok")
- [x] 3 Test — verified
- [x] 4 Code review — review move: tracker: issue 21 of the pre-release repo set to "In review"; diff `git diff HEAD` (excludes the vendored extension commit 51acf5a), 11 files, +415/−22
- [x] 4 Code review — hard: B1 /feat phase 8 doesn't handle shipper's `PR: blocked`/`! spec-number:` (marks done, hands a non-command); B2 ls-tree specs/ relative to cwd (needs --full-tree); B3 issue-style branch names (`370-foo`) waste numbers; B4 doubled `spec-number:` prefix; Spec git ≥ 2.44 missing from docs/install.md; S1 [sec, medium] PR branch/paths (forks included) steer the number, unbounded digits overflow bash arithmetic; C1 highest/taken duplicate loop; C2 RE_OWN re-match only to refill BASH_REMATCH
- [x] 4 Code review — picked B1, B2, B3, B4, Spec, S1, C1, C2 (user: "ok")
- [x] 4 Code review — fixes: B1, B2, B3, B4, Spec, S1 (a+b), C1, C2 applied; lint, test:tracker, test:spec-number (21 cases, 5 new), test:apm pass
- [x] 3 Test — verified (after review fixes; first cycle's report kept as test-1.md). Residual: shipper prompt's "its stderr line" is ambiguous when git/gh print their own lines first; suggested "the stderr line starting with `spec-number: error:`" (noted for review, not changed)
- [x] 5 Ship
