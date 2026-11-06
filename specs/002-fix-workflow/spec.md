# Feature Specification: /fix, a bugfix workflow wrapping Spec Kit's bug extension

**Feature Branch**: `fix-workflow`

**Created**: 2026-11-06

**Status**: Draft

**Input**: Brief for issue #15 (state file `specs/002-fix-workflow/feat-state.md`, section "Brief")

## Naming note (provisional names)

Spec Kit names below (`speckit-bug-assess`, `speckit-bug-fix`, `speckit-bug-test`, the artifacts `assessment.md`, `fix.md`, `test.md`, the verdict words, the section names, the `before_bug_*`/`after_bug_*` hooks) come from the brief. A read-only look at the bug extension bundled with the installed Spec Kit CLI (extension id `bug`, v1.0.1, commands `speckit.bug.assess|fix|test`) agrees with them, but the first task of this feature is a spike in a scratch project whose recorded findings (exact generated skill names for the Claude integration, artifact sections, verdict words, hooks, what each stage prints) **override every name in this spec**. Requirements below depend on the recorded names, not on the literals.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fix a reported bug end to end (Priority: P1)

A maintainer of a project that already runs `/feat` has a bug, as an issue (`/fix #N`, `/fix <issue URL>`) or as a described symptom (`/fix "<symptom>"`). One command takes it from report to a pull request: an isolated worktree and branch `fix-<slug>`, an assessment, a fix, an independent verification, an independent code review and a PR that says `Fixes #N`. The PR is never merged by the workflow.

**Why this priority**: This is the reason the feature exists: safety (isolation, independent verification and review), automation (one command) and consistency (same commits, PR shape, issue link and board moves as features).

**Independent Test**: Run `/fix #N` on a real bug in a project with the bug extension installed; the run ends with a PR containing `Fixes #N`, the `.specify/bugs/<slug>/` trail and a `verified` verdict that still holds after any review fixes.

**Acceptance Scenarios**:

1. **Given** an open issue describing a real bug, **When** the user runs `/fix #N` and passes the gates, **Then** a PR on branch `fix-<slug>` is opened with a `fix(scope)` commit, a body giving root cause, verdict and reproduction, `Fixes #N`, and the `.specify/bugs/<slug>/` files (state file included, already marked done) committed.
2. **Given** a small, confident, reproduced bug with one remediation, no public-behaviour change, a trusted report author, no security risk area, no issue to create and a clean review, **When** `/fix` runs it, **Then** no hard gate stops the run.
3. **Given** any run, **When** the test phase runs (first test, retry, or re-test after review fixes), **Then** it is performed by a fresh agent spawn that did not write the fix.

---

### User Story 2 - Stop when the report is not a bug (Priority: P1)

A report turns out to be a missing feature, expected behaviour, or an unintelligible report. `/fix` stops at the assess gate, shows the reasoning, points to `/brief #N` for a feature, creates no issue and leaves an existing issue untouched.

**Why this priority**: Without it `/fix` becomes a back door for features and would pollute the board with non-bugs.

**Independent Test**: Run `/fix "<a feature request phrased as a symptom>"` with board tracking on; the run stops at assess, no issue exists afterwards.

**Acceptance Scenarios**:

1. **Given** a report that is a missing feature, **When** the assessment concludes it is not a bug, **Then** the gate shows the reasoning, names `/brief #N` as the next step, and no issue is created or modified.
2. **Given** a report the bug extension judges invalid, **When** assess ends without an assessment file, **Then** the run still stops cleanly with the extension's reason shown and no later phase starts.

---

### User Story 3 - Gates that match the risk (Priority: P1)

Gates use `/feat`'s message shape and hard/soft semantics. The assess gate is hard by default and soft only for a small, confident, reproduced, single-remediation fix with no public-behaviour change, from a trusted author, outside the security risk area, with no issue to create. The fix gate is soft unless the fix records deviations from the assessment or checks fail. A `verified` verdict is soft; `partial` is hard; `failed` returns to fix once, then is hard with "back to 1" offered. The code-review gate is soft only when clean and small.

**Why this priority**: The gates are what make a verdict trustworthy and keep trivial fixes fast.

**Independent Test**: Drive each verdict (`verified`, `partial`, `failed` twice) through the workflow and observe which gates stop.

**Acceptance Scenarios**:

1. **Given** a `partial` verdict, **When** the test phase ends, **Then** the user must supply the missing environment or evidence before anything ships.
2. **Given** a `failed` verdict for the first time, **When** the test phase ends, **Then** the run returns to fix once, with the retry count in the state file's log; a second `failed` stops at a hard gate offering "back to 1".
3. **Given** a fix whose `fix.md` lists "Deviations from Assessment", **When** the fix phase ends, **Then** the gate is hard and handled like a size increase.
4. **Given** a review with a finding above nice-to-have or any security finding, **When** the review phase ends, **Then** the gate is hard and the user picks the fixes; the picked fixes go to the implementer in fix mode, then the test phase runs again with a fresh agent.
5. **Given** an assessment whose risk area includes security, **When** the assess phase ends, **Then** the gate is hard, no issue is created unless the user asks (a private security advisory is suggested), the gate says whether the PR, its body and the trail will be public once pushed, the run asks again before ship, and the PR body omits the reproduction steps.
6. **Given** an issue opened by an author who is not OWNER, MEMBER or COLLABORATOR, **When** the assess phase runs, **Then** no command, script or code from the report is run, and the assess gate is hard and lists the commands the assessor would run.
7. **Given** a fix that records deviations from the assessment, **When** the fix gate shows, **Then** it proposes one size step up and offers "back to 1" or "go on with size <s>".

---

### User Story 4 - Issue creation and board moves (Priority: P2)

With board tracking and `/fix "<symptom>"`, the issue is created only after the assess gate passes, labelled `bug`, in the repo the user confirms (which makes that gate hard), then moved on the board like a `/feat` issue (building once the assess gate passes, review from the code-review phase). A security bug gets no issue unless the user asks. An existing issue always gets `Fixes #N`, with or without board tracking and whatever its label. No issue and no board tracking means no issue created and no `Fixes` line.

**Why this priority**: Gives every fix PR a trail on the board, but the core fix flow works without it.

**Independent Test**: Run `/fix "<symptom>"` with board tracking: no issue before the assess gate; a `bug` issue after it; the board status moves.

**Acceptance Scenarios**:

1. **Given** board tracking and no issue, **When** the assess gate passes on a real bug, **Then** an issue titled from the assessment's symptom summary, with a body from symptom, root cause and a link to the trail, is created with label `bug` after the user confirms the repo.
2. **Given** an existing issue labelled `enhancement`, **When** the fix ships, **Then** the PR still says `Fixes #N`.
3. **Given** no board tracking and no issue, **When** the fix ships, **Then** no issue is created and the PR has no `Fixes` line.

---

### User Story 5 - Resume in a fresh session (Priority: P2)

`/fix resume` finds an unfinished run from `.specify/bugs/*/feat-state.md` in the checkout and in every worktree listed by `git worktree list`. One unfinished run resumes; several ask which.

**Why this priority**: Runs are long and cross sessions; losing state would defeat the isolation benefit.

**Independent Test**: Stop a run mid-way, start a fresh session, run `/fix resume`; it continues at the recorded phase.

**Acceptance Scenarios**:

1. **Given** one unfinished run in a sibling worktree, **When** `/fix resume` runs from the main checkout, **Then** it resumes that run.
2. **Given** two unfinished runs, **When** `/fix resume` runs, **Then** the user is asked which to resume.
3. **Given** a shipped run whose PR was merged, **When** `/fix resume` runs on the default branch, **Then** it finds nothing to resume (the committed state file already says done).

---

### User Story 6 - /feat is unchanged, and points bugs to /fix (Priority: P2)

The rules `/feat` and `/fix` share (thin orchestrator, gate message shape and semantics, state file format, board moves, resume) live in one reference both read. After the extraction `/feat` behaves as before, and `/brief` and `/feat` send bugs to `/fix` instead of refusing them.

**Why this priority**: A copied rule set would drift; but this is internal to the maintainers, and `/feat` must not regress.

**Independent Test**: Run the existing checks and a `/feat` run: same phases, gates, state file and board moves; the shared reference resolves after an APM install, a plugin install and `install.sh`.

**Acceptance Scenarios**:

1. **Given** the extraction, **When** `/feat` runs, **Then** phases, gates, state file and board moves are the same as before.
2. **Given** a bug described to `/brief` or `/feat`, **When** they refuse it, **Then** the message points to `/fix`.

---

### Edge Cases

- The bug extension is not installed: setup stops and says to run `specify extension add bug`.
- `.specify/extensions.yml` registers a `before_bug_*` or `after_bug_*` hook that would create a branch or commit: hard gate at setup (config is read, not executed, as `/feat` step 0.4 does).
- The assessment says "likely valid, needs reproduction" or leaves open questions: the assess gate is hard.
- The assessor cannot reproduce the bug: the gate is not soft.
- The fix discovers the assessment was wrong (extension stops and records deviations): hard fix gate, handled like a size increase.
- The review and re-test cycle: after review fixes, `verified` must hold again before ship.
- The assess gate's proposed size is higher than the user's expectation: the size drives model and effort for later phases.
- An issue URL pointing to an unrecognised host: the extension's own URL trust policy applies; `/fix` does not weaken it.
- Several bugs in one report, a refactor, a backport request: refused or redirected, out of scope.
- Reproduction steps that fetch from the network or touch paths outside the worktree: not run; the reproduction status says `not reproducible here (needs approval: <command>)`.
- A report by an author outside OWNER/MEMBER/COLLABORATOR: nothing from it is run; the assess gate is hard.
- A security bug in a public repo: no issue by default, the gate says what becomes public, the run asks again before ship, the PR body leaves out the reproduction steps.
- Branch `fix-<slug>` already exists on `origin`: the slug gets a `-2`, `-3`, … suffix.
- The staged diff matches a secret pattern: ship stops before committing.
- The extension uses a slug other than the one passed (assess's printed `Slug:` line, a report's `- **Slug**:` bullet, or a report written under another `.specify/bugs/<dir>/`): the agent reports an error and the gate is hard.
- The user says "skip 1", "skip 2" or "skip 3": refused.
- A ship that stops with `!` after the state file was marked done: with nothing committed, the local copy is set back to phase 5 so resume finds it; with a command for the user (git blocked), the state stays done and resume finds the run while its branch has no upstream.

## Requirements *(mandatory)*

### Functional Requirements

**Entry and setup**

- **FR-001**: `/fix` MUST accept `#N`, an issue URL, a quoted symptom, and `resume`.
- **FR-002**: Setup MUST do what `/feat` setup does (conventions, isolated worktree on branch `fix-<slug>`, board `check`), derive the slug itself, unique among the worktree's `.specify/bugs/*`, its local branches and `origin`'s branches (`git ls-remote --heads origin fix-<slug>`; taken → suffix `-2`, `-3`, …), and pass it to the extension so state and branch agree.
- **FR-003**: Setup MUST stop with the instruction `specify extension add bug` when the bug extension is missing.
- **FR-004**: Setup MUST hard-gate when a `before_bug_*` or `after_bug_*` hook in `.specify/extensions.yml` would create a branch or commit, reading the file as configuration without executing it.
- **FR-005**: `/fix` MUST stay a thin orchestrator: it never reads code or edits artifacts; all work is done by agents. Besides the tracker script it runs only git for the worktree and the diff, `gh issue view` (issue title), `gh api repos/<o>/<r>/issues/<N> --jq .author_association` (report author), `gh repo view` (repo name and visibility), `git ls-remote` (slug check) and `git for-each-ref` (the branch's upstream, at resume).

**Phases**

- **FR-006**: Each phase MUST run in a subagent whose model and effort come from `/fix`'s own size table, in the format a cost script (since moved out) parses. The assess row MUST be `opus · medium` in every column: the first assess costs the same whatever the size, and a deeper look comes only from "back to 1", a re-assess after which the later phases run at the larger size set at that gate.
- **FR-007**: The assess phase MUST run the bug extension's assess stage in a new `feat-bug-assessor` agent, read-only on source, producing `assessment.md`. Its fixed-format report MUST give: whether it is a bug (FR-039), root cause, confidence, files in scope, remediation(s), reproduction status (`reproduced` / `not reproduced` / `not reproducible here`, `reproduced` only when the assessor actually ran the reproduction under FR-036), public-behaviour impact, the report author's association (FR-036), the slug check (FR-041), and a proposed size (small/medium/large from scope, confidence and risk area: security, data, concurrency). The report is built on the spike's recorded sections and verdict words.
- **FR-008**: The fix phase MUST run the extension's fix stage in `feat-implementer` in a new `bug` mode, producing `fix.md`.
- **FR-009**: The test phase MUST run the extension's test stage in `feat-bug-assessor` in a test mode, producing `test.md` with a verdict. Every test run (first, retry, re-test after review fixes) MUST be a fresh spawn, never the agent that wrote the fix.
- **FR-010**: The code-review phase MUST use `feat-code-reviewer` unchanged, given only a lens subset (rows 4a–4d of `/fix`'s table are lenses 7a–7d of `feat-code-reviewer`): small, one reviewer on 7a+7b+7d; medium, one reviewer on 7a+7b, with 7c joining that reviewer (7a+7b+7c) for a performance bug; large, 7a and 7b in parallel, plus a third reviewer on 7c in parallel for a performance bug. Reviewers get the rejected findings and the assessment's remediation alternatives not chosen, instead of a brief's "Alternatives rejected". Picked fixes go to `feat-implementer` in fix mode, then the test phase runs again.
- **FR-011**: The ship phase MUST run `feat-shipper` in a new `fix` mode: commit as `fix(scope)` including the `.specify/bugs/<slug>/` trail and the state file; PR body with root cause, verdict, reproduction (status always; steps omitted for a security bug, FR-037) and `Fixes #N` when there is an issue; when the verdict shipped is not `verified`, the body gives the actual verdict and "shipped on the user's decision (logged)", read from the state file's Log; the secret scan of FR-038 before committing; never merge.

**Gates**

- **FR-012**: Gates MUST use `/feat`'s message shape and hard/soft semantics.
- **FR-013**: The assess gate MUST be hard by default and soft only when the fix is small, confident, has reproduction status `reproduced`, has one remediation and no public-behaviour change, the report author is trusted (FR-036), the risk area does not include security (FR-037) and no issue is to be created (FR-020).
- **FR-014**: A report that is a missing feature MUST stop at the assess gate pointing to `/brief #N`, with the reasoning shown so the user can relabel or comment; an existing issue is left untouched.
- **FR-015**: An assessment verdict of invalid, where the extension writes no assessment file, MUST end the run at the assess gate with the extension's reason; no later phase starts.
- **FR-016**: The fix gate MUST be soft, and hard on "Deviations from Assessment" in `fix.md` (handled like a size increase) or on failing checks. On deviations the orchestrator proposes one size step up (small → medium, medium → large; large stays large) and offers "back to 1" (re-assess) or "go on with size <s>". The retry fix after a first `failed` test (FR-017) is gated the same way, then the test phase runs.
- **FR-017**: The test gate MUST be soft on `verified`, hard on `partial` (the user supplies the missing environment or evidence), and on `failed` return to fix once with the retry count in the state file's log, then be hard with "back to 1" offered. The single retry covers the first test cycle only: a `failed` re-test after review fixes goes straight to a hard gate. Every "back to N" is logged as a `back to N` line, and the retry count and the first-cycle test read only the Log lines after the last `back to` line.
- **FR-018**: A `partial` or `failed` verdict MUST NOT reach ship without the user's say.
- **FR-019**: The code-review gate MUST be soft only when the review is clean (no finding above nice-to-have, no security finding) and the fix is small, and the risk area does not include security (FR-037); otherwise hard, with the user picking the fixes.

**Issues and board**

- **FR-020**: With board tracking and no issue, the issue MUST be created only after the assess gate passes, labelled `bug`, in the repo the user confirms, never for a report that is not a bug, and not by default for a security bug (FR-037). The repo confirmation makes the assess gate hard (it names the repo from `gh repo view --json nameWithOwner`); the user may answer "no issue" (logged; no `Fixes` line).
- **FR-021**: An existing issue MUST always get `Fixes #N` in the PR, with or without board tracking and whatever its label. With no issue and no board tracking, no issue is created and the PR has no `Fixes` line.
- **FR-022**: Board moves MUST follow `/feat`'s tracker rules with `/fix`'s moments: setup runs only `check`; the building move runs once the assess gate passes (right away for an existing issue, after creation for a new one), so a report that is not a bug never moves; the review move runs when the code-review phase starts.
- **FR-023**: The tracker script MUST gain an issue-creation variant fed by `assessment.md`: title from the assessment's symptom summary, body from symptom, root cause and a link to the trail, label `bug` fixed in the script; section names are those recorded by the spike. It MUST be shellcheck clean and covered by offline tests in `tests/tracker/`.

**State and resume**

- **FR-024**: State MUST live beside the artifacts at `.specify/bugs/<slug>/feat-state.md` in `/feat`'s state file format. Its done markers are `done (shipping)` (committed, FR-042), `done (PR #N)` (local copy only), `done (not a bug)` and `done (invalid)`.
- **FR-025**: `/fix resume` MUST search `.specify/bugs/*/feat-state.md` in the checkout and every worktree of `git worktree list`, resume the single unfinished run (a `done (shipping)` run whose branch `fix-<slug>` has no upstream counts as unfinished), and ask when there are several.

**Shared harness**

- **FR-026**: The thin-orchestrator rules, gate message shape and semantics, state file format, board moves and resume MUST move from `feat/SKILL.md` into one reference under the `feat` skill directory, read by both skills, reached from `/fix` by a path relative to its base directory, and resolving after an APM install, a plugin install and `install.sh`. Each skill declares every value the harness refers to in a `## Harness values` block (contracts/harness.md), including the artifact-dir noun, the context handed to reviewers, the state template's `Agents` and `Map` lines, the board-check and setup step references, and the commands the orchestrator may run besides the tracker. The harness contains none of `specifier`, `planner`, `tasker`, `spec.md`, `brief`, `phase [0-9]`, `/feat` (case-insensitive), checked by a grep in `mise run lint`.
- **FR-027**: After the extraction `/feat` MUST behave identically: same phases, gates, state file, board moves.
- **FR-028**: `/brief` and `/feat` MUST point bugs to `/fix`.

**Packaging, cost, docs**

- **FR-029**: New and changed agents MUST carry no `model`, `effort`, `tools` or `color` in frontmatter (use `disallowedTools`); `feat-bug-assessor` MUST carry `disallowedTools: Edit, NotebookEdit, Agent` and be listed in `.claude-plugin/plugin.json`; every agent report keeps a fixed format and the orchestrator and agent change together.
- **FR-030**: a cost script (since moved out) MUST parse `/fix`'s size table (`size_table(skill)`, `measure --skill feat|fix`) and its review groups, which live under the table in `fix/SKILL.md` and in `REVIEW_GROUPS` keyed by skill (`"fix"` is data kept for the project rule; `simulate` stays `/feat`-only and unchanged). An agent on several rows is attributed to its first phase at or after the current one, else stays in the current phase, so retry fixes count under phase 3 and post-review fixes and re-tests under phase 4 (said in a code comment). A real `/fix` run (the small end-to-end run of FR-043) MUST be measured with a cost script (since moved out) and recorded in the cost notes (since moved out), with the per-spawn overhead of `feat-implementer`'s unused `speckit-implement` preload in bug mode; a follow-up issue is opened if that overhead is large.
- **FR-031**: `install.sh check` MUST report the bug extension's skills (needed by `/fix` only), and `docs/install.md` MUST list the extension as a `/fix` prerequisite.
- **FR-032**: `docs/workflow.md`, the README and `CHANGELOG.md` (`## Unreleased`) MUST describe `/fix`, mirroring size-table changes as the project rules require; `docs/workflow.md` names `/fix`'s review rows by lens (7a–7d). `docs/usage.md`'s `/fix` section is limited to arguments, the gates the user sees and resume, and links `docs/workflow.md`; `docs/design.md` states the bug-extension overrides in one paragraph pointing to the harness and `/fix` files.
- **FR-033**: The first task MUST be the spike (install the bug extension in a scratch project; record skill names, artifact sections, verdict words, hooks, and what each stage prints). The spike MUST record its findings in contracts/bug-extension.md before dependent work; where they differ from this spec, the planner amends spec.md (and the design docs) to the recorded names.
- **FR-034**: `mise run lint` and `mise run test:apm` MUST pass.
- **FR-035**: The spike MUST record the bug extension version tested (v1.0.1 observed). `install.sh check` MUST warn, without blocking, when the installed skills or sections differ from the recorded names; setup checks only that the extension exists (FR-003); the assessor MUST report a clear error if a required section is missing.

**Untrusted input, disclosure and secrets**

- **FR-036**: Reproduction (assess step 3 and test mode) MUST run only the project's own test runner and tests, plus a scratch test the assessor writes under the system temp dir that calls repo code. A command from the report that fetches from the network or touches paths outside the worktree is never run; the reproduction status becomes `not reproducible here (needs approval: <command>)`. The orchestrator reads the issue author's association with `gh api repos/<o>/<r>/issues/<N> --jq .author_association` and passes it to the assessor and the bug-mode implementer; it counts only for an issue whose `<o>/<r>` equals `gh repo view --json nameWithOwner` (else `unknown`); unless it is `OWNER`, `MEMBER` or `COLLABORATOR` (a symptom typed by the user counts as trusted, a non-GitHub URL as untrusted), nothing from the report (command, script or code) is run and the assess gate is hard, listing the commands the assessor would run. Commands the user approves at that gate are logged and passed to later assessor spawns. The assessor report gives `Report author: <association>`.
- **FR-037**: When the assessment's risk area includes security: the assess gate MUST be hard; issue creation is off by default and the gate suggests a private security advisory instead (the user may still ask for an issue); the gate states, from `gh repo view --json visibility`, whether the PR, its body and the committed trail will be public once pushed; the code-review gate is hard and asks for the go-ahead to ship ("skip 4" asks for it too); the shipper omits the reproduction steps from the PR body.
- **FR-038**: Before committing, `feat-shipper` in fix mode MUST scan the staged diff (`git diff --cached --name-only -G'<pattern>'`) for `-----BEGIN`, `gh[opsur]_`, `github_pat_`, `AKIA`, `xox[bp]-`, `sk-` and `(password|token|secret)["']?\s*[:=]`; a match, or a scan that can't run, stops with `!`, nothing committed or pushed (in the git-blocked fallback it scans the files to be staged before returning the command). The assessor MUST redact, in both modes, every section with command output it writes, replacing the whole secret-looking value with `<redacted>` so the scan does not match it again; `tracker.sh create-issue` MUST refuse (exit 2) an assessment-derived body that matches these patterns.

**Assessment rules, skips, slug and ship state**

- **FR-039**: The assessor MUST map a Verdict `invalid` to one of `no — missing feature`, `no — expected behaviour`, `no — duplicate`, `no — unintelligible` from the extension's reason, and a Verdict `valid` or `likely valid` on a report asking for new behaviour (no current behaviour is wrong) to `no — missing feature`. `Is a bug: no` stops the run whatever the extension's verdict; the assessor never edits `assessment.md` to flip it.
- **FR-040**: `/fix` MUST refuse "skip 1", "skip 2" and "skip 3" (assess, fix and test can't be skipped); other skips are allowed and logged with the reason.
- **FR-041**: The assessor (both modes) and the implementer in bug mode MUST compare the slug passed with the slug the stage used, and report an error on a mismatch, which makes the gate hard. Only the assess stage prints a fixed `Slug:` line, which may wrap the slug in backticks and add a parenthesised resolution (``Slug: `<slug>` (user-provided)``): the assessor compares it after stripping both. Every stage (assess, fix, test) writes `- **Slug**: <slug>` as its report's first header bullet: the agent compares that bullet too. A difference in either, or a report written under another `.specify/bugs/<dir>/`, is a mismatch. The spike records the extension's slug normalisation rules in contracts/bug-extension.md.
- **FR-042**: Before spawning the shipper, the orchestrator MUST write `Current phase: done (shipping)` and `[x] 5 Ship` into the state file, so the committed copy is already done; after the PR it may write `done (PR #N)` into the local copy, uncommitted. If the shipper returns a `!` command for the user to run (git blocked), the state stays done, since that command commits it, and `/fix resume` still lists a `done (shipping)` run whose branch `fix-<slug>` has no upstream; if it stops with `!` and nothing will be committed (secret-scan block or another hard failure), the orchestrator sets `Current phase: 5 Ship` back in the local copy so `/fix resume` finds the run.

**Validation budget**

- **FR-043**: Live validation MUST stay within four `/fix` runs: (1) a small bug end to end, also the measured run of FR-030; (2) `/fix "<symptom>"` with board tracking to the end (issue creation, board moves, `Fixes #N`); (3) one medium run with a first `failed` test, the retry, review picks and the re-test; (4) the not-a-bug and unintelligible reports, assess only. `/feat`'s regression is checked by the text diff (every sentence removed from `feat/SKILL.md` is in the harness or still in SKILL.md) and one `/feat resume` on an existing state file.

### Key Entities

- **Bug run**: one report fixed in one worktree, identified by its slug; owns a branch `fix-<slug>`, a state file, and a trail directory.
- **Trail** (`.specify/bugs/<slug>/`): the state file plus the extension's assessment, fix and test artifacts; committed with the PR.
- **Assessment**: root cause, confidence, scope, remediation(s), reproduction, impact, severity/verdict, proposed size.
- **Verdict**: the test result (`verified`, `partial`, `failed`; final words per the spike).
- **Report author**: the issue author's association (`OWNER`, `MEMBER`, `COLLABORATOR` are trusted), or the user for a typed symptom; decides whether anything from the report may be run.
- **Gate**: a stop point, hard (user must decide) or soft (proceeds unless the user intervenes), per `/feat` semantics.
- **Shared harness reference**: the one file holding the rules both skills follow.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `/fix #N` on a real bug ends with a PR with `Fixes #N`, the trail committed and a `verified` verdict that holds after review fixes, with the user touching only gates.
- **SC-002**: A small, confident, reproduced fix with a clean review completes with zero hard gates when no issue is to be created (an existing issue, or no board tracking), the report author is trusted and the risk area does not include security.
- **SC-003**: A missing-feature report stops at assess in 100% of tries, creating zero issues and modifying none.
- **SC-004**: Zero PRs reach ship with a `partial` or `failed` verdict without an explicit user decision.
- **SC-005**: `/fix "<symptom>"` with board tracking creates exactly one `bug` issue, only after the assess gate, and it moves on the board.
- **SC-006**: `/fix resume` in a fresh session continues from the recorded phase without re-doing finished phases; after the PR is merged, `/fix resume` on the default branch finds nothing to resume.
- **SC-007**: `/feat` shows no change in phases, gates, state format or board moves after the extraction, shown by the text-diff check and one `/feat resume` on an existing state file.
- **SC-008**: `mise run lint` and `mise run test:apm` pass, the tracker tests cover issue creation, and the lint grep finds none of the `/feat`-only words in the harness.
- **SC-009**: No command, script or code from a report by an untrusted author, and no report command that reaches the network or outside the worktree, is run without the user's approval at a gate.
- **SC-010**: A security bug never gets an issue or a pushed PR without the user's explicit go-ahead at a hard gate, and its PR body has no reproduction steps.
- **SC-011**: A staged diff matching one of the secret patterns of FR-038 is never committed or pushed by the shipper.

## Assumptions

- The brief's Spec Kit names are provisional; the spike overrides them (see Naming note). A read-only check of the bundled bug extension (v1.0.1) is consistent with them but is not a substitute for the spike on the Claude integration's generated skill names.
- The orchestrator derives the slug at setup (from the issue or symptom) and passes it to the extension, so the interactive slug prompt never fires and the branch, directory and state agree.
- "Reproduced" for the soft assess gate means the assessor actually exercised the reproduction, not merely that the extension's verdict is "valid" (see Clarifications, Q1).
- "Confident" means high confidence in the root cause hypothesis as reported by the extension.
- `/fix`'s size table has the same rows-by-size shape as `/feat`'s, with its own agents and models; exact models and efforts are chosen at planning.
- State-file format and gate wording are reused from `/feat`; the location differs (`.specify/bugs/<slug>/`), and `/fix` adds the `done (shipping)` marker and logs every "back to N" (FR-017, FR-042); `/feat`'s own behaviour is unchanged.
- A report given as a non-GitHub URL has no author association to read, so it is treated as untrusted (FR-036).
- The extension's own URL trust policy and guardrails (no source edits during assess and test, never edit `assessment.md`) are kept and not restated.
- Out of scope: re-implementing assess/fix/test, Spec Kit spec/plan/tasks for bugs, refactors, features disguised as bugs, several bugs per run, backports, merging the PR.

## Clarifications

- **Q1**: How is "reproduced" established for the soft assess gate? The assessor reports an explicit reproduction status (`reproduced` / `not reproduced` / `not reproducible here`), `reproduced` only when it actually ran the reproduction; the soft assess gate requires `reproduced` (FR-007, FR-013).
- **Q2**: Does the single `failed` retry cover a `failed` re-test after review fixes? No. It covers the first test cycle only; a `failed` re-test after review fixes goes straight to a hard gate (FR-017).
- **Q3**: Which bug-extension versions are supported? The version tested in the spike is recorded (v1.0.1 observed). `install.sh check` and setup warn but do not block on differing skill names or sections; the assessor errors clearly if a required section is missing (FR-035).
