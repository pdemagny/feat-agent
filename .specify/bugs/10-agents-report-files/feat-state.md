# /fix state: Orchestrators accept reported artifacts without checking they exist

- Branch: fix-10-agents-report-files Worktree: /home/pierre/Projects/feat-agent/.claude/worktrees/fix-10-agents-report-files
- Size: medium
- Agents: none (every spawn is fresh)
- Current phase: done (shipping)
- Conventions: conventional commits `type(scope): short message`, one logical change per commit, never co-author (user is sole author); stage only task files; zsh, quote variables; `rm/cp/mv` are aliased -i: use `command rm -f` etc.; in the worktree call `/usr/bin/git` directly, one plain command per call. Project rules in `.claude/CLAUDE.md`: agent prompts end with a fixed report format the orchestrator depends on — change both sides together (agents in `.apm/agents/*.agent.md`, skills `.apm/skills/{feat,fix,brief}/SKILL.md`, shared rules in `.apm/skills/feat/references/harness.md`, which must stay free of /feat-only words: `mise run lint` greps it); `/feat` and `/fix` stay thin (never read code); mirror size-table/agent changes in `docs/workflow.md`; checks: `mise run lint`, `mise run test:apm`, `mise run test:tracker`, `mise run test:spec-number`; shellcheck clean; CHANGELOG is generated, don't edit; never hand-edit versions.
- Allowed Spec Kit hooks: none configured (`hooks: {}`)
- Map: none
- Issue: #10

## Report

#10

## Log

- [x] 0 Setup — tracker: ok users/pdemagny/projects/2 (Brief, In progress, In review); slug 10-agents-report-files; bug extension 1.0.2; report author OWNER
- [x] 1 Assess — size medium (user; proposed large)
- [x] 1 Assess — answer: should read-only agents (brief, design and code reviewers) also report `Wrote: none`? → yes
- [x] 1 Assess — answer: implementer lists every code file touched, or only created ones? → the new files plus its artifacts (not modified files)
- [x] 1 Assess — answer: on a missing path, retry once or hard gate? → a hard gate straight away (no automatic retry)
- [x] 1 Assess — answer: remediation → the preferred one (`Wrote:` line + listed existence check)
- [x] 1 Assess — hard gate: valid, high confidence, not reproducible here (confirmed by reading), 3 remediation(s); size medium
- [x] 2 Fix — applied; no deviations; checks pass (15 files: 14 modified, 1 created; lint, test:apm, test:tracker, test:spec-number pass)
- [x] 3 Test — partial: a live /feat or /fix run (ideally with one refused Write) showing agents emit `Wrote:` and the orchestrator runs `ls -d --` on it; all static checks and the four mise tasks pass
- [x] ship with partial (user: "go on")
- [x] 3 Test — rejected: update gates.d2/chain.d2 for the new hard-gate condition (user: "this fix would trigger on very rare occasion, that doesn't deserve adding complexity to diagrams that needs to be readable to convey the main value of feat-agent, not describe all it's details")
- [x] 4 Code review — picked B1, B2, B3, S1, [std]1, C1; rejected B4 (shipper `Wrote:` omits edited docs; user: "ok" to skip — they are on `Docs updated:` and always exist)
- [x] 4 Code review fixes — B1, B2, B3, S1, [std]1, C1 applied (11 files); lint, test:apm, test:tracker, test:spec-number pass
- [x] 3 Test — partial: (after review fixes) a live /feat or /fix run; B1, B2, B3, S1, [std]1, C1 pass, S1 rule exercised on 8 sample paths, four mise tasks pass; previous report kept as test-1.md
- [x] ship with partial (user: "go on")
- [x] 5 Ship
