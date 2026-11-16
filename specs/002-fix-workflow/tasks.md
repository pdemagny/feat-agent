# Tasks: /fix, a bugfix workflow wrapping Spec Kit's bug extension

**Input**: `specs/002-fix-workflow/` (spec.md, plan.md, research.md, data-model.md, quickstart.md, contracts/)

**Prerequisites**: plan.md, spec.md. Project rules: `.claude/CLAUDE.md` (the constitution template is unfilled).

**Tests**: Requested by the spec for the tracker (FR-023: offline cases 13-15 in `tests/tracker/run.sh`, written first). Everything else is checked by `mise run lint`, `mise run test:apm`, `mise run test:tracker` and the quickstart; the live runs are marked `[USER]`.

**Organization**: by user story (US1-US6 of spec.md). Paths are relative to the repository root.

## Format: `- [ ] T### [P?] [Story?] Description with file path`

- **[P]**: different file, no dependency on an incomplete task.
- **[USER]**: needs the user's scratch project, GitHub or a real Claude session. The implementer reports these as pending; it must never fake or simulate their result.
- Rules for every task: agent frontmatter carries no `model`, `effort`, `tools` or `color` (use `disallowedTools`); the extension's names are those recorded by T001 in `contracts/bug-extension.md`, never the literals of the spec; write files with Write/Edit; never commit.

---

## Phase 1: Setup (the spike)

**Purpose**: record the bug extension's real names before any dependent work (FR-033, FR-035).

- [X] T001 Run the spike in a scratch dir outside the repo (`mktemp -d`, `git init`, pinned specify-cli 1.2.1 from `mise.toml`, `specify init --here --integration claude`, `specify extension add bug`), run `speckit-bug-assess`, `speckit-bug-fix`, `speckit-bug-test` once on a toy bug with a passed `slug=<slug>`, and rewrite `specs/002-fix-workflow/contracts/bug-extension.md`: replace the "provisional" status line with "recorded by the spike on <date>, specify-cli <x>, bug <y>"; record the exact generated skill names for the Claude integration, extension version (v1.0.1 observed), artifact headings, verdict and status words, hook event names, the exact lines each stage prints (`Slug:` included), the slug normalisation rules (case, allowed characters, length cut, leading digit; research R6 must yield a slug the extension keeps unchanged), that no unattended stage uses Edit (only Write), and how an existing report is handled. If any name differs from spec.md/plan.md, STOP and report it as a design problem (the planner amends spec.md; the implementer never edits it) before T002.

**Checkpoint**: names recorded; every later task uses them.

---

## Phase 2: Foundational (shared harness extraction)

**Purpose**: move the rules both skills share out of `feat/SKILL.md` (FR-026, FR-027). Blocks every story: `/fix` reads this file.

- [X] T002 Create `.apm/skills/feat/references/harness.md` by moving, verbatim, the sections listed in `specs/002-fix-workflow/contracts/harness.md` ("Sections the harness holds") from `.apm/skills/feat/SKILL.md`: thin orchestrator, gates, state file, board moves, resume. Replace `/feat`-specific nouns by the named values of that contract's table (artifact dir noun, reviewer context, `Agents`/`Map`/`Size` lines, board-check step, commands besides the tracker, phases that can't be skipped, logged gate commands, building and review moves, resume search; header `# /<skill> state: <title>`; spawn example `feat-<name>` / `feat-agent:feat-<name>`); add "entering a sibling worktree" to resume. The file contains none of `specifier`, `planner`, `tasker`, `spec.md`, `brief`, `phase [0-9]`, `/feat` (case-insensitive).
- [X] T003 Edit `.apm/skills/feat/SKILL.md`: delete the moved sections; open with "Read `<this skill's base dir>/references/harness.md` now: it holds the rules this skill follows. The values it refers to are below."; add the `## Harness values` block with the `/feat` column of `contracts/harness.md` (each value is the exact wording the moved text had); keep frontmatter, intro, size table, reviewer groups, phases-and-gates table, setup and phase sections unchanged. Behaviour identical (FR-027).
- [X] T004 [P] Edit `mise.toml`: add to `[tasks.lint]` run list `"! grep -Eiq 'specifier|planner|tasker|spec\\.md|brief|phase [0-9]|/feat' .apm/skills/feat/references/harness.md"`; add to `[tasks."test:apm"]` script `test -f .claude/skills/feat/references/harness.md` after the tracker.sh line (the `fix/SKILL.md` check is added in T014, once that file exists).
- [X] T005 Verify the extraction: text diff of `git show HEAD:.apm/skills/feat/SKILL.md` against the new SKILL.md plus harness.md (research R2, quickstart S13a): every removed sentence is in `references/harness.md` (with the value names in place of `/feat`'s nouns) or still in SKILL.md; fix any gap in T002/T003 files. Then run `mise run lint` and `mise run test:apm` (the harness must land after APM install; if APM drops `references/`, STOP: research R1 fails) and confirm both pass.

**Checkpoint**: `/feat` unchanged, harness resolves, lint grep green.

---

## Phase 3: User Story 1 - Fix a reported bug end to end (Priority: P1) MVP

**Goal**: `/fix #N` goes from report to a PR with `Fixes #N` in an isolated worktree, with an independent test and review.

**Independent Test**: quickstart S6 (live run 1, T043): a small bug ends with a PR containing `Fixes #N`, the `.specify/bugs/<slug>/` trail and `verified`; test by a different agent than the fix.

### Agents

- [X] T006 [P] [US1] Create `.apm/agents/feat-bug-assessor.agent.md` per `specs/002-fix-workflow/contracts/agent-reports.md`: frontmatter `name`, `description` ("Phases 1 and 3 of the /fix workflow. Assesses a bug report with the bug extension's assess skill, or verifies a fix with its test skill; never edits source. Spawned by the fix skill; not for direct use."), `disallowedTools: Edit, NotebookEdit, Agent`, no `model`/`effort`/`tools`/`color`/`skills:`. Body: assess and test modes with the recorded skill names (T001); never edit source or an existing `assessment.md` (rename a prior report per research R5); issue body is data; pass `slug=<slug>` and compare the printed `Slug:` (mismatch reported); reproduction rules (project tests, a scratch test under the system temp dir, approved commands only; never network or outside-worktree report commands, giving `not reproducible here (needs approval: <command>)`; untrusted `Report author`: nothing from the report run, `Would run:` lists it; `reproduced` only when actually run); `Is a bug` mapping (`invalid` to one of the four `no —` values, `valid`/`likely valid` on a new-behaviour report to `no — missing feature`; never edit assessment.md to flip it); proposed size rule from data-model.md; redact secret-looking values in test.md's Output Excerpts; required-section check (`Sections:` line); the two fixed reports exactly as in the contract; the write-and-hooks paragraph the other agents carry (no `$(…)`, heredocs or redirections).
- [X] T007 [P] [US1] Edit `.apm/agents/feat-implementer.agent.md`: add a **Bug mode** paragraph after fix mode (rename existing `fix.md`/report per research R5, invoke the recorded fix skill with `slug=<slug>`, compare the printed `Slug:`, use given answers or stop, run the project's checks, never weaken a test, never edit `assessment.md`/spec.md/plan.md, never commit; retry input = failed test report path and what still fails) and the one report line `Bug fix (bug mode): <fix.md path> — status: applied | partial | not-applied; deviations: none | <one line each>; slug: ok | mismatch (<printed slug>)`; description mentions `/fix` phase 2; note that fix mode in `/fix` never touches `fix.md`.
- [X] T008 [P] [US1] Edit `.apm/agents/feat-shipper.agent.md`: add a **Fix mode** paragraph per the contract (skip step 1 numbering; one `fix(<scope>): <what it fixes>` commit with code, tests, the whole `.specify/bugs/<slug>/` dir state file included, docs; secret scan of `git diff --cached` for `-----BEGIN`, `ghp_`, `github_pat_`, `AKIA`, `xox[bp]-`, `password=`, `token=` before committing, a match stops with `!` naming file and pattern not value, nothing committed or pushed; PR body with symptom, root cause, fix, verdict and checks, reproduction status and, unless `Security bug: yes`, steps, review fixes, points to look at, state-file link, `Fixes <ref>` only when the state file has an `Issue:` line, and when the last test verdict in the Log is not `verified` the actual verdict plus "shipped on the user's decision (logged)" quoting the logged decision; never merge or force-push); report format unchanged; description mentions `/fix` phase 5.
- [X] T009 [US1] Edit `.claude-plugin/plugin.json` (add `./agents/feat-bug-assessor.agent.md` to the explicit `agents` list, same path style as the others; description mentions `/fix`) and `apm.yml` (description mentions `/fix`); do not touch `version` in either file.

### /fix skill

- [X] T010 [US1] Create `.apm/skills/fix/SKILL.md` head: frontmatter (`name: fix`, trigger-style description per plan "Frontmatter", `argument-hint: '#N | issue-url | "symptom" | resume'`); two-line intro; "read `<this skill's base dir>/../feat/references/harness.md` now", missing → stop with "/fix needs feat-agent's `feat` skill (references/harness.md); install or update feat-agent"; `## Harness values` block with the `/fix` column of `contracts/harness.md`; `## Size table` exactly as plan.md's table (format `| <N><a-e> <name> | \`feat-x\` | <loads> | model · effort | … |`, assess row `opus · medium` in every column, rows 1, 2, 3, 4a-4d, 5) with the note under it (assess size-independent, 4a-4d = lenses 7a-7d, reviewer groups small `7a+7b+7d` / medium `7a+7b` (+`7c` for a performance bug) / large `7a`,`7b` parallel (+`7c`), strongest model among rows, picked fixes use the phase 2 row); `## Phases and gates` table (phases 0-5 with the gate column of data-model.md); plugin-name rule (`/feat-agent:fix`, `/feat-agent:brief`).
- [X] T011 [US1] In `.apm/skills/fix/SKILL.md` add `## 0. Setup` steps 1-7 per plan.md: Claude Code only; argument forms (`#N`, `owner/repo#N`, issue URL, quoted symptom, `resume`; a brief path → `/feat <path>`; empty → usage and stop); conventions as `/feat`; `.specify/` present, agents installed incl. `feat-bug-assessor`, bug extension present (no `.specify/extensions/bug/` and no recorded skill → stop with `specify extension add bug`, FR-003); read `.specify/extensions.yml` as config only, a `before_bug_*`/`after_bug_*` hook that would branch or commit → hard gate (FR-004); board `check` only, no move (FR-022); title and author association via the commands of FR-005 (typed symptom → `user`, non-GitHub URL → `unknown`), slug derivation (`[a-z0-9-]`, ≤ 40 chars, unique among `.specify/bugs/*`, local branches and `git ls-remote --heads origin fix-<slug>`, suffix `-2`, `-3`), EnterWorktree and rename to `fix-<slug>`, missing `.feat-agent.yml` → `[!]` line, create `.specify/bugs/<slug>/feat-state.md` in the data-model.md template (`Agents: none (every spawn is fresh)`, `Map: none`); Setup Log line names slug, extension version and report author (FR-002, FR-005).
- [X] T012 [US1] In `.apm/skills/fix/SKILL.md` add `## 1. Assess`, `## 2. Fix`, `## 3. Test` spawn mechanics: assess spawns `feat-bug-assessor` (assess mode, size-table row 1) with the report, author association and approved commands and parses the report of `contracts/agent-reports.md`; on pass sets `Size:` and the title (the user may say `size <s>`); fix spawns `feat-implementer` (bug mode, row 2) with answers to open questions and, on a retry, the failed report path and `Still failing`; test spawns a fresh `feat-bug-assessor` (test mode, row 3) with the cycle (`first`, `retry`, `after review fixes`), author, approved commands and user evidence, never the fix's agent (FR-009); soft-gate path per data-model.md "Assessment report → gate", "Fix report → gate", "Test report → gate" (the hard rows are added by US2/US3 tasks).
- [X] T013 [US1] In `.apm/skills/fix/SKILL.md` add `## 4. Code review` and `## 5. Ship`: review move at phase start; diff as `/feat`'s review phase (`git add -N` on new files, `git diff <merge-base>`, non-empty); reviewers per the groups with the inputs of the contract's "feat-code-reviewer (unchanged file)" (bug dir as feature dir, no-spec.md note pointing to assessment.md and fix.md, lens names, size, rejected findings plus assessment alternatives not chosen); merge into `B…`, `S…`, `P…`, `C…`, `[std]`; picks → `feat-implementer` fix mode (row 2) → test again with a fresh spawn (cycle `after review fixes`); ship writes `Current phase: done (shipping)` and `[x] 5 Ship` into the state file BEFORE spawning `feat-shipper` (fix mode, row 5) with state file, conventions, worktree, default branch, bug dir, issue and `Security bug: yes|no` (FR-042); after the PR may write `done (PR #N)` in the local copy only; a `!` report → set `Current phase: 5 Ship` back locally; never merge; final message with PR link, branch, worktree, two or three things to look at.
- [X] T014 [US1] Edit `mise.toml` `test:apm`: add `test -f .claude/skills/fix/SKILL.md`; run `mise run lint` and `mise run test:apm` (counts now 9 agents, 3 skills plus deps) and confirm both pass.

**Checkpoint**: `/fix #N` runs the happy path with soft gates; ship commits the trail.

---

## Phase 4: User Story 2 - Stop when the report is not a bug (Priority: P1)

**Goal**: a missing feature, expected behaviour, duplicate or unintelligible report stops at assess without creating or touching an issue.

**Independent Test**: quickstart S7 and S8 (live run 4, T047).

- [X] T015 [US2] In `.apm/skills/fix/SKILL.md` phase 1 add the stop rule (first row of data-model.md "Assessment report → gate"): `Assessment: none`, `Verdict: invalid` or `Is a bug: no — …` (whatever the verdict, FR-039) stops the run at the gate showing the assessor's reasoning and the extension's reason; missing feature → point to `/brief #N` (or `/brief "<symptom>"`, plugin form too); no issue created, moved or edited; no later phase starts; state `done (not a bug)` or `done (invalid)` with the matching Log line (FR-014, FR-015, FR-024).
- [X] T016 [US2] In `.apm/skills/fix/SKILL.md` phase 1 and setup step 2: a report with several bugs, a refactor request or a backport request is refused or redirected (out of scope, spec Edge Cases) before or at the assess gate without creating an issue; an issue URL on an unrecognised host keeps the extension's own trust policy (not weakened) and counts as `unknown` author (FR-036).

**Checkpoint**: not-a-bug reports end cleanly at assess.

---

## Phase 5: User Story 3 - Gates that match the risk (Priority: P1)

**Goal**: gates carry `/feat`'s message shape and hard/soft semantics; every verdict and risk drives the right stop.

**Independent Test**: quickstart S6 (soft path), S10/S11 (failed then verified, review picks, security), S7 (untrusted author): drive `verified`, `partial`, `failed` twice and observe the gates.

- [X] T017 [US3] In `.apm/skills/fix/SKILL.md` phase 1 add the full assess gate from data-model.md "Assessment report → gate" (every applicable row listed in the message): hard by default; soft only for small + high confidence + `Reproduction: reproduced` + one remediation + no public-behaviour change + trusted author + no security + no issue to create (FR-013); hard rows for untrusted author (nothing from the report was run, gate lists `Would run:`), `not reproducible here (needs approval: …)`, `likely valid, needs reproduction`, open questions; commands the user approves are logged and passed to later assessor spawns (re-assess to run them now); answers to open questions logged and passed to the fix (FR-036).
- [X] T018 [US3] In `.apm/skills/fix/SKILL.md` phase 1 add the security-bug rules (FR-037): risk area includes `security` → hard gate, no issue by default and a private security advisory suggested (the user may still ask for an issue), the gate states from `gh repo view --json visibility` whether the PR, its body and the committed trail will be public once pushed.
- [X] T019 [US3] In `.apm/skills/fix/SKILL.md` phase 2 add the fix gate (FR-016, data-model.md "Fix report → gate"): soft unless `deviations` ≠ none (hard, handled like a size increase: name the deviation, propose one size step up small → medium, medium → large, large stays large, options "back to 1" or "go on with size <s>"), a failing check or status ≠ `applied` (hard); same gate for the retry fix after a first `failed` test; then test.
- [X] T020 [US3] In `.apm/skills/fix/SKILL.md` phase 3 add the test gate and retry rules (FR-017, FR-018, data-model.md "Test cycle and retry counter"): `verified` soft (to review, or to ship after a re-test that followed review fixes); `partial` hard (show `Missing for verified`; the user supplies it for a fresh re-test or decides explicitly, logged); first `failed` returns to fix once with Log line `3 Test — failed (retry 1 of 1)`; second `failed`, or any `failed` after review fixes, is a hard gate with "back to 1" offered; retry count and first-cycle test read only the Log lines after the last `back to` line; every arrow into 3 a fresh assessor spawn.
- [X] T021 [US3] In `.apm/skills/fix/SKILL.md` phase 4 add the review gate (FR-019, data-model.md "Review → gate"): soft only when no finding above nice-to-have, no security finding, size small and risk area not security; otherwise hard with the user picking fixes (picks → implementer fix mode → fresh test with cycle `after review fixes`, `verified` must hold again before ship); security bug: hard gate restating what becomes public and asking for the go-ahead to ship (the ship step passes `Security bug: yes`).
- [X] T022 [US3] In `.apm/skills/fix/SKILL.md` add the `/fix`-only gate rules from data-model.md "Gate commands": "skip 1", "skip 2", "skip 3" refused, other skips allowed and logged with the reason (FR-040); every "back to N" logged as `- [x] back to N — <reason>`; a ship with a verdict other than `verified` only on the user's explicit decision at a hard gate, logged as `ship with <verdict> (user: "<words>")` (FR-018); building move on "back to N" per the harness values.
- [X] T023 [US3] In `.apm/skills/fix/SKILL.md` phases 1-3 add the hard-gate rows for `Slug: mismatch …` and `Sections: error …` (assessor and test reports) and `slug: mismatch` (implementer): the agent's error is shown, the gate is hard (FR-035, FR-041).

**Checkpoint**: each verdict and risk reaches the right gate.

---

## Phase 6: User Story 4 - Issue creation and board moves (Priority: P2)

**Goal**: `/fix "<symptom>"` with board tracking creates one `bug` issue after the assess gate and moves it; an existing issue always gets `Fixes #N`.

**Independent Test**: `mise run test:tracker` (cases 13-15) offline; quickstart S9 (live run 2, T045).

- [X] T024 [US4] Add offline cases 13-15 to `tests/tracker/run.sh` FIRST, from `specs/002-fix-workflow/contracts/tracker-cli.md` "New offline cases": 13 bug issue (`up/r`, issue-url `https://github.com/up/r/issues/8`, an assessment whose Symptom holds a fenced `## ` line; prints `tracker: created up/r#8`; `calls` show `issue create -R up/r --title <title> --body-file <f> --label bug`; body holds Symptom incl. the fence line, Root Cause Hypothesis and last line `Trail: .specify/bugs/login-timeout/` and nothing from Report, Reproduction or Proposed Remediation; then `… other/r` exits 1 with no `issue create`); 14 bad path (`.specify/bugs` a symlink outside the repo → exit 2 no calls; `.specify/bugs/x/fix.md` → exit 2 pattern error no calls); 15 missing `## Root Cause Hypothesis` → exit 2 naming the section, no calls. The existing brief case still asserts no label. Cases fail before T025. Use the section names recorded by T001.
- [X] T025 [US4] Edit `.apm/skills/feat/scripts/tracker.sh` `create-issue` per `contracts/tracker-cli.md`: usage names both sources; path pattern decides the source (`^specs/briefs/…\.md$` brief unchanged, `^\.specify/bugs/[a-z0-9][a-z0-9-]*/assessment\.md$` assessment, else exit 2 `brief path must be specs/briefs/<name>.md or .specify/bugs/<slug>/assessment.md`); physical-directory `cd -P` check and regular-not-symlink check before any `gh` call; one section parser (`brief_parts` generalised: title prefix and the two section names as arguments) used by both; assessment title = first line minus `# Bug Assessment: ` (missing → exit 2 `assessment has no "# Bug Assessment: " first line`, empty → `assessment title is empty`), sections `## Symptom` and `## Root Cause Hypothesis` (missing → exit 2 naming it); body `## Symptom`, `## Root cause`, blank, `Trail: .specify/bugs/<slug>/`; `--label bug` only for assessments; same current-repo check as briefs (mismatch → exit 1, nothing created); never retried; output `tracker: created <owner>/<repo>#<N>`.
- [X] T026 [US4] Run `mise run test:tracker` (cases 1-15 print `ok …`) and `shellcheck .apm/skills/feat/scripts/* tests/tracker/run.sh tests/tracker/bin/gh` (clean); fix T024/T025 until both pass.
- [X] T027 [US4] In `.apm/skills/fix/SKILL.md` phase 1 (and the Harness values) add issue creation and board moves (FR-020, FR-021, FR-022): with board tracking and no issue, only after the assess gate passes, for a real bug, not by default for a security bug; the repo from `gh repo view --json nameWithOwner` is named at the gate (this makes it hard) and the user confirms or answers "no issue" (logged, no `Fixes` line); then `tracker.sh create-issue .specify/bugs/<slug>/assessment.md <owner/repo>` and write the `Issue:` line; building move right after (immediately for an existing issue, after creation for a new one; never for a report that is not a bug); review move at phase 4 start; setup runs `check` only; an existing issue always gets `Fixes #N` with or without board tracking and whatever its label; no issue and no board tracking → none created, no `Fixes` line.

**Checkpoint**: issue creation tested offline; moves wired.

---

## Phase 7: User Story 5 - Resume in a fresh session (Priority: P2)

**Goal**: `/fix resume` finds and continues an unfinished run in the checkout or any worktree.

**Independent Test**: quickstart S12 (live run 2, T045) and SC-006 check in S6 (T043).

- [X] T028 [US5] In `.apm/skills/fix/SKILL.md` add the `resume` path (FR-025, FR-024): search `.specify/bugs/*/feat-state.md` in the checkout and every path of `git worktree list --porcelain`, `Current phase:` not starting with `done` = unfinished; one → resume (EnterWorktree with `path` when it is another worktree), several → ask which, none → say so (a merged run's committed state already says `done (shipping)`); board `check` first (Setup step 6), then the building move in phases 1-3 once the assess gate has passed and the review move in 4-5; continue at the recorded phase without redoing finished ones; a stop after the shipping marker with `!` resets to `5 Ship` (T013).

**Checkpoint**: resume covers worktrees and several runs.

---

## Phase 8: User Story 6 - /feat unchanged, bugs point to /fix (Priority: P2)

**Goal**: `/feat` behaves as before; `/brief` and `/feat` send bugs to `/fix`.

**Independent Test**: text diff (T005, re-run in T031), `mise run lint`/`test:apm`, and live checks S13b, S14, S15 (T048).

- [X] T029 [P] [US6] Edit `.apm/skills/brief/SKILL.md` (FR-028): description "Not for bugfixes (use /fix) or pure refactors"; "An issue labelled as a bug is not for this workflow: say so and stop" → "…: point to `/fix #N` (`/feat-agent:fix #N` as a plugin) and stop"; an idea that is a bug → `/fix "<symptom>"`; keep "Nothing is created for a … bug-stopped … brief".
- [X] T030 [US6] Edit `.apm/skills/feat/SKILL.md` (FR-028): description "Not for bugfixes (use /fix) or pure refactors"; setup step 1: an argument describing a bug → `/fix "<symptom>"` (or `/fix #N`), plugin form too. No other behaviour change.
- [X] T031 [US6] Re-run the T005 text diff after T029/T030 (only the description and the setup-step-1 line differ in `feat/SKILL.md` beyond the extraction), then `mise run lint` and `mise run test:apm`; confirm green.

**Checkpoint**: `/feat` regression check passes offline.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: installer, docs, final checks (FR-031, FR-032, FR-034, FR-035). Tasks marked [P] touch different files.

- [X] T033 [P] Edit `install.sh` (FR-031, FR-035, research R14): `check` with a project dir prints, after the speckit skills, `ok skill <s>` or `note skill <s> (needed by /fix only: specify extension add bug)` for each recorded bug skill (names from T001); when present, one `grep -c` per skill for its recorded headings and verdict words, short → `warn <skill> differs from the names /fix was tested with (bug <version>)`; neither sets `missing`; `uninstall` removes `"$target"/skills/fix`. `shellcheck install.sh` clean.
- [X] T034 [P] Edit `docs/workflow.md`: a `/fix` section (roles, phases at a glance, gates, size matrix mirroring the `/fix` table with review rows named by lens 7a-7d, reviewer groups, "why these choices" lines, board moments, state file location); Agents table gains the `feat-bug-assessor` row and `/fix` phases and modes on the implementer and shipper rows (FR-032, project rule: mirror size tables).
- [X] T035 [P] Edit `docs/install.md`: prerequisites row "Spec Kit bug extension, `/fix` only, `specify extension add bug` in each project"; section 3 command for `/fix`; APM paragraph counts 3 skills and 9 agents; plugin names add `/feat-agent:fix`; section 4 mentions the `note`/`warn` lines (FR-031).
- [X] T036 [P] Edit `docs/usage.md`: a `/fix` section limited to arguments, the gates the user sees and resume, linking `docs/workflow.md` for the rest; "not for bugfixes (use Spec Kit's bug commands)" → `/fix` (FR-032).
- [X] T037 [P] Edit `docs/design.md`: one paragraph on the bug extension's overrides (interactive slug → passed and checked; overwrite refusal → renamed attempts; "re-run assess" on failed → one retry then the user; hooks read as config; report commands not run blindly) pointing to `.apm/skills/feat/references/harness.md`, `.apm/skills/fix/SKILL.md`, `.apm/agents/feat-bug-assessor.agent.md`; one line on the harness file under "Distribution" (FR-032).
- [X] T038 [P] Edit `README.md`: `/fix` in the intro and quick start; Layout adds `.apm/skills/fix/` and `references/`; leave the `Version x.y.z.` line alone.
- [X] T039 [P] Edit `CHANGELOG.md` under `## Unreleased`: one entry for `/fix` (new prerequisite `specify extension add bug`), one for `/brief` and `/feat` pointing bugs to it, one for the harness extraction and `tracker.sh create-issue` from an assessment.
- [X] T040 [P] Edit `.claude/CLAUDE.md`: three skills (`brief`, `feat`, `fix`); both size tables are sources of truth, mirror both in `docs/workflow.md`; note the harness file (`references/harness.md`) and its lint grep.
- [X] T041 Cross-check, both sides of every contract (project rule): read `.apm/agents/feat-bug-assessor.agent.md`, `feat-implementer.agent.md`, `feat-shipper.agent.md`, `.apm/skills/fix/SKILL.md`, `contracts/agent-reports.md` and `contracts/bug-extension.md` side by side: each report field the orchestrator parses is in the agent's fixed format with the same words; names equal those recorded by T001; fix any drift in the implementation files (report, do not edit, spec.md/plan.md).
- [X] T042 Final offline checks: run `mise run lint` (shellcheck on `install.sh`, tracker script and tests clean, py_compile, `claude plugin validate .`, harness grep), `mise run test:apm`, `mise run test:tracker` (cases 1-15 ok), quickstart S1-S5 and S13a, and `grep -c '\[ \]' specs/002-fix-workflow/checklists/requirements.md` is 0; all must be green.

**Checkpoint**: all offline checks pass; implementation complete.

---

## Phase 10: Live validation (needs the user; at most four `/fix` runs, FR-043)

**Purpose**: the scenarios that need a scratch project, GitHub and real Claude sessions (quickstart "Live"). Not run as scripted: since the merge, `/fix` has been used on real bugs instead (e.g. #21). **The implementer reports each task below as pending for the user and must never simulate its result.**

- [ ] T043 [USER] Run 1, small bug end to end (quickstart S6; US1, US3, SC-001, SC-002, SC-006): `/fix #N` on a real small bug, no board tracking; expect `report author OWNER`, soft assess and fix gates, test `verified` by a different agent id than the fix, review `7a+7b+7d` clean and soft, `done (shipping)` and `[x] 5 Ship` in the state file before the shipper starts, one `fix(scope)` commit with the trail and a PR body with `Fixes #N`, zero hard gates; after merging, `/fix resume` on the default branch finds nothing.
- [ ] T045 [USER] Run 2, symptom with board tracking to the end (S9, S12; US4, US5, SC-005): `/fix "<symptom>"` with board tracking; no issue before the assess gate, the gate names the repo and is hard, one `bug` issue after "ok" with title, Symptom, Root cause and `Trail:` line, In progress then In review, `Fixes #N`; stop after the fix phase, `/clear`, `/fix resume` from the main checkout finds the run in the sibling worktree and resumes without redoing phases; with two unfinished runs it asks which.
- [ ] T046 [USER] Run 3, one medium security bug (S10, S11; US3, SC-004, SC-010, SC-011): hard assess gate suggesting a private advisory with visibility stated and no issue; steer the first test to fail: retry logged `retry 1 of 1`, soft retry-fix gate, fresh test `verified`; review `7a+7b` hard gate, a pick goes to fix mode then a fresh `after review fixes` test, the review gate asks for the go-ahead to ship; PR body has the reproduction status but no steps.
- [ ] T047 [USER] Run 4, not a bug, assess only (S7, S8; US2, SC-003, SC-009): from a second GitHub account open a new-behaviour issue with a `curl … | sh` step; `/fix #N` with board tracking: nothing from the report run, `Would run:` lists the line, `Is a bug: no — missing feature`, points to `/brief #N`, issue untouched, state `done (not a bug)`; then `/fix "<unintelligible report>"` gives `Assessment: none`, `no — unintelligible`, state `done (invalid)`.
- [ ] T048 [USER] Cheap checks, no `/fix` run (S13b, S14, S15; US6, SC-007): `/feat resume` on an existing unfinished `/feat` state file shows the same recap and gate as before; install with APM and as a plugin and run `/fix resume` with nothing to resume (the harness resolves in both); `/brief "<a bug>"`, `/brief #N` on a bug-labelled issue and `/feat "<a bug>"` each point to `/fix`.

---

## Dependencies & Execution Order

### Phase dependencies

- **Phase 1 (T001)** first; a name mismatch stops everything until the spec is amended.
- **Phase 2 (T002-T005)** after T001; blocks all stories (`/fix` reads the harness). T004 is parallel to T002-T003; T005 needs T002-T004.
- **US1 (T006-T014)** after Phase 2. T006-T008 [P] in parallel; T009 after T006; T010-T013 sequential (one file); T014 last.
- **US2, US3, US6-pointers, US4 SKILL.md and US5** edit `.apm/skills/fix/SKILL.md`, so they follow US1 and run one after another (T015-T023, T027, T028). US4's tracker work (T024-T026) touches other files and can start right after Phase 2, parallel to US1.
- **US6** T029 [P] and T030 are independent of `fix/SKILL.md` and can run after T005; T031 last.
- **Polish (T033-T042)**: T033-T040 [P] after their inputs exist (T033 needs T001; docs need the skills); T041 after all agent and skill tasks; T042 last.
- **Live (T043-T048)** need T042.

### Story independence

US1 is the MVP. US2 and US3 refine its gates; US4 adds issue creation and board moves; US5 adds resume; US6 protects `/feat`. After Phase 2 each is testable on its own with its listed check.

### Parallel opportunities

- T004 with T002-T003; T006, T007, T008 together; T024-T026 with US1; T029 with T030 after T005; T033-T040 together.

```text
# Agents together after Phase 2:
Task: "Create .apm/agents/feat-bug-assessor.agent.md"        (T006)
Task: "Edit .apm/agents/feat-implementer.agent.md"           (T007)
Task: "Edit .apm/agents/feat-shipper.agent.md"               (T008)
Task: "tests/tracker/run.sh cases 13-15, then tracker.sh"    (T024-T026)
```

## Implementation Strategy

### MVP first (US1)

1. T001 spike; stop on any name difference.
2. Phase 2 harness extraction, text diff green.
3. US1 T006-T014; then run T043 (live run 1) before anything else.

### Incremental delivery

US1 (MVP) → US2/US3 gates → US4 issue creation and board → US5 resume → US6 pointers → Polish → remaining live runs. Each step keeps `mise run lint` and `mise run test:apm` green.

## Notes

- Never commit; stage nothing. The orchestrator ships.
- A run of live validation is a user task: report it, do not fake it.
- The extension's names come from T001, not from the spec's literals.
