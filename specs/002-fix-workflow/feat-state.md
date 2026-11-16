# /feat state: /fix — a bugfix workflow wrapping Spec Kit's bug extension

- Branch: fix-workflow Worktree: .claude/worktrees/fix-workflow
- Size: medium
- Agents: specifier a6bcdb61bb4b30f9b, planner a500dfaa8b72f48c9, tasker a69db2bd79065bbd7
- Current phase: 8 Ship
- Conventions: conventional commits `type(scope): msg`, one logical change per commit, the user is sole author (no co-author lines); stage only task files; zsh, use `command rm -f` / `cp -f` / `mv -f`; call `/usr/bin/git` directly in worktrees. Project rules (`.claude/CLAUDE.md`): the size table in `.apm/skills/feat/SKILL.md` is the source of truth (mirror in docs/workflow.md); agent frontmatter has no model/effort/tools/color (use disallowedTools); new agents listed in `.claude-plugin/plugin.json`; agent reports end with a fixed format (change both sides); a cost script (since moved out) parses size tables and `REVIEW_GROUPS`; third-party skill changes touch apm.yml, install.sh deps, docs/install.md; shellcheck clean (`mise run lint`), `mise run test:apm`, `mise run test:tracker`; CHANGELOG `## Unreleased`; versions in apm.yml and plugin.json match.
- Allowed Spec Kit hooks: none (`.specify/extensions.yml` absent)
- Map: none
- Issue: #15

## Brief

# Brief: /fix — a bugfix workflow that wraps Spec Kit's bug extension in the /feat harness
- Size: medium — ~40 tasks expected: a new skill and agent, a shared harness extracted from /feat, modes in three existing agents, a tracker variant with tests and docs
- Short name: fix-workflow
- Issue: #15

## Why
feat-agent users (the maintainer first) fix bugs in projects that already run
`/feat`. `/brief` and `/feat` refuse bugfixes, so bugs get none of what makes
`/feat` worth using: **safety** (an isolated worktree and context, a
verification that isn't the fixer marking its own work, an independent code
review), **automation** (one command from report to PR), and **consistency**
(same commits, PR shape, issue link and board moves as features).

## Today
Bugs are fixed by hand, or by running Spec Kit's bundled bug extension
(`specify extension add bug`: `speckit-bug-assess` → `speckit-bug-fix` →
`speckit-bug-test`, artifacts in `.specify/bugs/<slug>/`) in the main
session, then asking for a commit and PR. That runs in whatever context and
branch you're in, has no review, and the PR comes out inconsistent (commit
type, no `Fixes #N`, no board move). `/feat` can't simply take a bug brief:
it has no assess step, and spec/plan/tasks is the wrong shape for a fix.

## Behaviour
- `/fix #N`, `/fix <issue URL>` or `/fix "<symptom>"`; `/fix resume` picks up from the state file in a fresh session: it searches `.specify/bugs/*/feat-state.md` in the checkout and in every worktree of `git worktree list`; one run not done resumes, several ask.
- Phases, each in a subagent with model and effort from `/fix`'s own size table:
  - **0 Setup** (orchestrator): same as `/feat` (conventions, worktree on branch `fix-<slug>`, board check), plus: stop with `specify extension add bug` if the extension is missing; hard gate if a `before_bug_*`/`after_bug_*` hook in `.specify/extensions.yml` (read as `/feat` step 0.4 reads it: config, not code) would branch or commit.
  - **1 Assess**: new `feat-bug-assessor` runs `speckit-bug-assess` → `assessment.md` (read-only on source). It reports whether it is a bug, root cause, confidence, files in scope, remediation(s), reproduction, public-behaviour impact, and proposes the size (small/medium/large from scope, confidence and risk area: security, data, concurrency).
  - **2 Fix**: `feat-implementer` in a new `bug` mode runs `speckit-bug-fix` → `fix.md`.
  - **3 Test**: `feat-bug-assessor` in test mode runs `speckit-bug-test` → `test.md` with a verdict. Never the agent that wrote the fix: every test run (first, retry, re-test after review fixes) is a fresh `feat-bug-assessor` spawn.
  - **4 Code review**: `feat-code-reviewer` with a lens subset — small: one reviewer on 7a+7b+7d; medium/large: 7a and 7b in parallel, plus 7c for a performance bug. The reviewer agent is unchanged; it only gets the lens subset. Picked fixes go to `feat-implementer` in fix mode, then phase 3 runs again.
  - **5 Ship**: `feat-shipper` in a new `fix` mode commits with `fix(scope)` and the `.specify/bugs/<slug>/` trail (state file included), PR body with root cause, verdict, repro and `Fixes #N` when there is an issue. Never merges.
- Gates (same message shape and hard/soft semantics as `/feat`):
  - **Assess**: hard by default; soft only when small, confident, reproduced, one remediation and no public-behaviour change. Not a bug but a missing feature → stop and point to `/brief #N`; an existing issue is left untouched (the gate shows the reasoning so the user can relabel or comment).
  - **Issue creation**: with board tracking and no issue (`/fix "<symptom>"`), the issue is created after the assess gate passes, labelled `bug`, in the repo the user confirms; never for a report that isn't a bug. An existing issue always gets `Fixes #N`, with or without board tracking and whatever its label; no issue and no board tracking → no issue created, no `Fixes` line.
  - **Fix**: soft; hard on "Deviations from Assessment" in fix.md (handled like a size increase) or failing checks.
  - **Test**: `verified` soft; `partial` hard (user supplies the missing environment or evidence); `failed` back to fix once (retry count in the state file's log), then hard with "back to 1" offered.
  - **Code review**: soft when clean (no finding above nice-to-have, no security finding) and small; hard otherwise — the user picks the fixes.
- Board moves as in `/feat`: building from setup, review from phase 4.
- `/brief` and `/feat` point bugs to `/fix`.

## Out of scope
- Re-implementing assess/fix/test: the bug extension does that; `/fix` only orchestrates it.
- Spec Kit's spec/plan/tasks for bugs.
- Refactors, features disguised as bugs (they go to `/brief`), several bugs in one run, backports to release branches.
- Merging the PR.

## Alternatives rejected
- Run the three `speckit-bug-*` commands by hand, then a manual PR — no isolation, no independent verification or review, inconsistent PRs: the three reasons this exists.
- A home-made bug workflow (own investigator, own `fix.md`) — reinvents the extension, which works well.
- Spec Kit's full feature flow for bugs — too much ceremony and cost for a fix.
- A condensed copy of the harness rules in `/fix` — drifts from `/feat`; one shared file instead.
- Always-hard assess gate (Spec Kit's advice) — stops on trivial fixes; smart gate instead, hard by default.
- Always-hard code-review gate — nothing to pick on a clean review of a small fix; the PR stays the final human gate.
- Defer issue creation for `/fix "<symptom>"` (require an existing issue or none) — rejected for consistency: every fix PR carries `Fixes #N` and shows on the board.

## Acceptance
- `/fix #N` on a real bug ends with a PR containing `Fixes #N`, the `.specify/bugs/<slug>/` trail and a `verified` verdict that still holds after the review fixes.
- A small, confident, reproduced fix with a clean review runs with no hard gate.
- A report that is a missing feature stops at assess, points to `/brief #N` and creates no issue.
- `/fix "<symptom>"` with board tracking creates a `bug` issue only after the assess gate and moves it on the board.
- A `partial` or `failed` verdict never reaches ship without the user's say.
- `/fix resume` continues from `.specify/bugs/<slug>/feat-state.md` in a fresh session.
- `/feat` behaves the same after the harness extraction (same phases, gates, state file, board moves).
- `mise run lint` and `mise run test:apm` pass; tracker bash tests cover the new issue-creation variant.

## Constraints / decisions already made
- **Shared harness file**: thin-orchestrator rules, gate message shape and semantics, state file format, board moves and resume move from `feat/SKILL.md` into one reference both skills read, under the `feat` skill dir and reached from `/fix` by a path relative to its base dir (as `/brief` already reaches `../feat/scripts/tracker.sh`); it must resolve after an APM install, a plugin install and `install.sh`.
- **State beside the artifacts**: `.specify/bugs/<slug>/feat-state.md`, `/feat`'s format.
- `/fix` stays thin like `/feat`: never reads code or edits artifacts; work goes into agents.
- Agent frontmatter carries no `model`/`effort`/`tools`/`color`; new agent listed in `.claude-plugin/plugin.json`; agent reports keep a fixed format the orchestrator depends on.
- Existing agents that change: `feat-implementer` (`bug` mode) and `feat-shipper` (`fix` mode); `feat-code-reviewer` is unchanged.
- `tracker.sh` gains an issue-creation variant from `assessment.md`: title from the assessment's symptom summary, body from the symptom, root cause and a link to the trail, label `bug` hardcoded (exact section names from the spike); `shellcheck` clean, offline tests in `tests/tracker/`.
- `install.sh check` reports the bug extension's skills (needed by `/fix` only); docs/install.md lists the extension as a `/fix` prerequisite.
- First task: install the bug extension in a scratch project, record the exact skill names the Claude integration generates, the artifact sections, verdict words, hooks and what each stage prints; build the assessor's report on that. The spike's findings override the names used in this brief; the specifier writes them into spec.md.
- Mirror in docs/workflow.md, README, CHANGELOG (`## Unreleased`).

## Log

- [x] 0 Setup — board check ok (users/pdemagny/projects/2); #15 set to "In progress"; worktree `fix-workflow` from origin/main e957175; no `.specify/extensions.yml`, no hooks
- [x] 2 Specify — approved (user: "ok"); Q1 explicit reproduction status, soft assess gate needs `reproduced`; Q2 failed-retry only on first test cycle, failed after review fixes → hard; Q3 record spike version (v1.0.1), warn-not-block on mismatch, assessor errors on missing section; checklist item closes with the markers; amended: FR-007/013/017 updated, new FR-035 (Q3), 0 markers, checklist all ticked
- [x] 3 Plan — plan.md + research/data-model/quickstart/contracts (harness, agent-reports, bug-extension, tracker-cli); constitution pass; size trigger: bug extension (new prereq), stays medium; 2 assumptions need user (board move after assess gate R8; issue creation makes assess gate hard R9)
- [x] 4 Design review — 4c paraphrase matched the brief; user "ok": accepted A1 (building move after assess gate), A2 (issue creation → hard assess gate), D1 untrusted repro commands, D2 security-bug disclosure, D3 state done before ship, D4 secret scan, D5 assessor no Edit, D6 assess opus·medium, D7 medium one 7a+7b reviewer, D8 ≤4 live runs, D9 harness values + grep invariant, D10 orchestrator command list / drop setup grep, D11 is-a-bug mapping, D12 deviation size step, D13 back-to-N log, D14 skip/partial ship, D15 remote slug check, D16–D22 nice-to-haves; none rejected. Amended: new FR-036–043, SC-009–011, many FRs amended; planner assumptions (no user needed): 7c joins the medium reviewer; non-GitHub URL report = untrusted; orchestrator reads author association at setup; failed ship resets phase to 5; D2 "ask before ship" at the code-review gate; harness grep in `mise run lint`
- [x] 5 Tasks — 48 tasks (fits medium); analyze: 0 CRITICAL/HIGH/MEDIUM, 1 LOW (FR-033 wording, no fix); checklist all ticked; soft gate. Live runs T043–T048 are [USER], left pending for the user
- [x] 6 US1 — T001–T014 done; lint, test:apm, test:tracker pass; T005 text diff ok (2 wordings generalised). Spike partial: assess ran live (Write-only, prints `Slug:`), its Write refused under ~/.claude; implementer tried a bypassPermissions retry, blocked by the classifier (flag to user); fix/test stages recorded from SKILL.md text only, first live run is T043. Spike notes for planner: FR-041 slug check reads printed line + `- **Slug**:` bullet; fix/test refuse rather than pick a new slug (R5); normalisation has no length cut
- [x] 6 planner amend (spike notes) — FR-041, FR-033, R5, R6, data-model, agent-reports aligned; IDs and parsed formats unchanged
- [x] 6 US2 — T015–T016 done; lint, test:apm pass; choice: out-of-scope found at assess → `done (not a bug)` + `stopped: out of scope (…)` Log line; several bugs → user picks one ("back to 1")
- [x] 6 US3 — T017–T023 done; lint, test:apm pass; choices: re-test after `partial` evidence or Sections/Slug error = same cycle, not logged as `back to 3`; phase 4 always logs its line before going back to 3 (data-model silent on this — note for review)
- [x] 6 US4 — T024–T027 done; lint, test:tracker (1–15, 13–15 red first), test:apm, shellcheck pass; `brief_parts` → `doc_parts`; found: shipper fix mode could write `Fixes none` (Issue: none) → shipper wording fixed with US5
- [x] 6 US5 — T028 + shipper `Issue: none` fix done; lint, test:apm pass; notes for review: a session dying after `done (shipping)` before the shipper returns is not found by resume (per FR-024); resume with `Issue: none` and no creation log line asks the user for the ref instead of re-creating
- [x] 6 US6+polish — T029–T042 done; lint, test:apm, test:tracker (15 ok), shellcheck pass; install.sh check note/warn verified on a scratch project; /feat text diff ok
- [x] 6 Implement — soft gate: T001–T042 done, all checks green; T043–T048 [USER] live runs pending (not run)
- [x] tracker: #15 set to "In review"
- [~] 7 Code review — diff base origin/main e957175 (local main is stale at b07ada5); 7a/7b opus·medium, 7c/7d/7e sonnet·medium done; B1–B9, S1–S7, P1, C1–C7, R1–R9; user "ok": fix B1–B8, S1–S7, C1–C7, R1–R8; skipped P1 and R9 (optional). Applied all picks; lint, test:apm, test:tracker (1–17; new 16 missing label, 17 secret in body), shellcheck pass; /feat untouched. Adaptations: C7 → security row widened so a security bug with findings still asks the ship go-ahead; S7 pattern `(password|token|secret)["']?\s*[:=]` can falsely block ship on ordinary code (`token = …`) — fails closed, `!` names the file; `sk-` bounded. Spec text of FR-005/025/036/037/038/042 updated (IDs unchanged)
- [ ] 8 Ship
