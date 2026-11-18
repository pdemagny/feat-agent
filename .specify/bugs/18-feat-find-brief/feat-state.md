# /fix state: /brief writes the brief relative to the cwd and /feat only takes an exact path

- Branch: fix-18-feat-find-brief Worktree: /home/pierre/Projects/logistics/.claude/worktrees/fix-18-feat-find-brief
- Size: medium
- Agents: none (every spawn is fresh)
- Current phase: done (shipping)
- Conventions: conventional commits `type(scope): short message`, one logical change per commit, concise; never co-author commits (user is sole author); stage only task files. Shell is zsh: quote variables; `rm`/`cp`/`mv` are aliased to -i: use `command rm -f` etc. In this worktree call `/usr/bin/git` directly, one plain command per call (no heredocs, pipes or globs). Project rules: .claude/CLAUDE.md (size tables mirrored in docs/workflow.md; harness.md/rebase.md shared /feat+/fix, no /feat-only words; diagrams in docs/diagrams rendered by `mise run diagrams`; CHANGELOG generated, don't edit; versions never by hand). Checks: `mise run lint`, `mise run test:apm`, `mise run test:tracker`, `mise run test:spec-number`.
- Allowed Spec Kit hooks: none configured (extensions.yml hooks: {})
- Map: none
- Issue: pdemagny/logistics#18

## Report

#18

## Log

- [x] 0 Setup — tracker: ok users/pdemagny/projects/2 (Brief, In progress, In review); slug 18-feat-find-brief; bug extension 1.0.2; report author OWNER
- [x] 1 Assess — answer: what background job ran /brief and its cwd → a Claude Code background job whose temp dir is `$CLAUDE_JOB_DIR/tmp`; /brief must say the brief is not a temporary file and goes in the repo (or its worktree when run in one)
- [x] 1 Assess — answer: /brief outside a git checkout, stop or ask? → ask for the repo path; stop if none is given
- [x] 1 Assess — answer: should /feat delete a brief found in another worktree? → no; delete only in its own checkout, name the other one in the final message
- [x] 1 Assess — hard gate: likely valid, needs reproduction, medium confidence, not reproducible here (static evidence), 2 remediation(s); size medium; preferred remediation (instructions only) (user: "ok")
- [x] 1 Assess — tracker: pdemagny/logistics#18 set to "In progress"
- [x] 2 implementer — not verified:
    - n/a → manual: /brief run from a cwd outside the repo (asks for the repo path, writes under <root>, prints an absolute "Brief saved:" path) → needs an interactive session
    - n/a → manual: /feat <short-name> with the brief in another worktree (finds and names it, leaves the file there) and with no brief (stops and names each path searched) → needs an interactive session
- [x] 2 Fix — hard gate: applied; checks pass; deviations: create-issue keeps the relative specs/briefs path and runs from <root>; size kept medium (user: "go on with size medium")
- [x] 3 Test — partial: an interactive (and background-job) run of /brief from a cwd outside the repo, and of /feat <short-name> with the brief in another worktree and with no brief
- [x] ship with partial (user: "ship with partial")
- [x] 4 Code review — tracker: pdemagny/logistics#18 set to "In review"
- [x] 4 Code review — hard gate: picked B1, B2, [std]1 (user: "fix, ok")
    - B1 feat/SKILL.md:161,208-211 — delete target not tied to specs/briefs/<name>.md — rec: apply
    - B2 brief/SKILL.md:118 — repo root resolved only at write, after .logistics.yml/docs/code/gh steps ran — rec: user (changes when /brief asks)
    - [std]1 brief/SKILL.md:32 — <repo root> and <root> name the same thing — rec: apply
- [x] 4 implementer — applied B1, B2, [std]1; checks pass; not verified:
    - n/a → manual /brief and /feat checks (outside-a-checkout prompt, short-name lookup, delete only this checkout's specs/briefs/<name>.md) → need interactive Claude Code sessions
- [x] 3 Test — partial (after review fixes): interactive runs of /brief outside the repo and in a background job; /feat <short-name> with the brief in another worktree, two matches, no brief; the brief-left-in-place Log line surviving /feat resume
- [x] ship with partial (user: "ship with partial") — after review fixes
- [x] 5 Ship
