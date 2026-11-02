# Feature Specification: Board tracking

**Feature Branch**: `board-tracking`

**Created**: 2026-11-02

**Status**: Draft

**Input**: User description: "/brief and /feat move the feature's issue across a GitHub Projects board" (brief: `specs/briefs/board-tracking.md`, issue #11)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A card follows the workflow without manual moves (Priority: P1)

An adopter who tracks features on a GitHub Projects board has opted in with a committed `.feat-agent.yml`. They run `/brief #N`, then `/feat`. The issue's card moves to Brief when the brief draft is written, to In progress when the build starts, and to In review when phase 7 starts. After merge, the board's own "Item closed" automation moves it to Done.

**Why this priority**: This is the whole point of the feature: cards stop sitting in Todo through the brief and the build.

**Independent Test**: On a test board with "Item closed" enabled and a configured repo, run `/brief #N` then `/feat` through phase 7 and merge. The card goes Todo, Brief, In progress, In review, Done with no manual move.

**Acceptance Scenarios**:

1. **Given** a configured repo and an issue already on the board, **When** `/brief #N` writes the brief draft (before the fresh-reader review), **Then** the card's status is Brief.
2. **Given** a brief with an `Issue:` line, **When** `/feat` finishes setup (before phase 2), **Then** the card's status is In progress.
3. **Given** the build is in progress, **When** phase 7 starts, **Then** the card's status is In review, before any PR exists.
4. **Given** the issue is not yet on the board, **When** `/brief #N` runs, **Then** it is added to the board and then set to Brief.
5. **Given** the PR carrying `Closes #N` is merged and the board has "Item closed" enabled, **When** the issue closes, **Then** the card reaches Done without any workflow action.

---

### User Story 2 - A brief from an idea creates its own tracked issue (Priority: P2)

An adopter runs `/brief "idea"` (or briefs a capability from a capability map). Once they confirm the brief at the `/brief` gate, an issue is created, added to the board, set to Brief, and the brief's `Issue:` line is filled in, so the rest of the workflow tracks it like any other issue.

**Why this priority**: Extends tracking to features that start without a ticket; the P1 flow works without it.

**Independent Test**: Run `/brief "idea"` on a configured repo, confirm at the gate, and check that an issue exists with the right title and body, sits in Brief on the board, and is referenced by the brief's `Issue:` line.

**Acceptance Scenarios**:

1. **Given** a configured repo and an interview in progress, **When** the user has not yet confirmed the brief, **Then** no issue exists.
2. **Given** the `/brief` gate for a brief without an issue, **When** it is shown, **Then** it names the repository (`owner/repo`) the issue will be created in.
3. **Given** the user confirms the brief at the gate, **When** the workflow continues, **Then** an issue is created in that repository with the brief's one-liner as title, a body of the confirmed Why, Behaviour and `Brief: specs/briefs/<name>.md`, and no labels.
4. **Given** the issue is created, **When** creation succeeds, **Then** it is added to the board, set to Brief, the brief's `Issue:` line holds its full reference `owner/repo#N`, and the `tracker:` lines are printed above the unchanged final block.
5. **Given** the interview is abandoned, stopped as a bug, or the brief is rejected at the gate, **When** the run ends, **Then** no issue was created.
6. **Given** issue creation fails, **When** it fails, **Then** `/brief` stops with the reason before the final block, and the brief file stays saved without an `Issue:` line.
7. **Given** the current repository is a fork whose gh default is the upstream, **When** the issue is created, **Then** the printed and recorded reference names the repository gh created it in (the upstream), not the fork.
8. **Given** the repository gh resolves at creation differs from the one the `/brief` gate named (e.g. `gh repo set-default` changed in between), **When** create issue runs, **Then** no issue is created and `/brief` stops with the reason before the final block.

---

### User Story 3 - Misconfiguration stops the run early with the exact fix (Priority: P2)

At the start of `/brief` and `/feat`, a read-only check verifies access and the `project` token scope, the board, and that each configured status exists on the board. A failure stops the run with the exact fix.

**Why this priority**: Prevents runs that silently fail to track; the fix text makes setup self-service.

**Independent Test**: Configure a missing scope, a nonexistent board, and an unknown status in turn; each stops the run at the start with a specific fix, and an unknown status lists the board's real options.

**Acceptance Scenarios**:

1. **Given** the token lacks the `project` scope, **When** the check runs, **Then** the run stops and names the fix (`gh auth refresh -s project`).
2. **Given** a configured status name not among the board's options, **When** the check runs, **Then** the run stops and lists the unknown name next to the board's real options (at most 10 of them).
3. **Given** a malformed config line, an unsupported `provider`, or a project URL that does not match the accepted form, **When** the check runs, **Then** it fails and names the offending line.
4. **Given** a valid config and board, **When** the check runs, **Then** it prints `tracker: ok <kind>/<login>/projects/<n> (<brief>, <building>, <review>)`, the skill shows that line to the user with one sentence saying moves go to that board, and the run continues without a gate.

---

### User Story 4 - Tracking is off unless configured, and failures never block a build (Priority: P2)

A repo without `.feat-agent.yml` behaves exactly as today and makes no tracker calls. In a configured repo, a failed move mid-run is retried once, recorded, and flagged at the next gate, while the build continues.

**Why this priority**: Protects existing users and keeps tracking from becoming a point of failure.

**Independent Test**: Run the script in a repo with no config and observe zero network calls; simulate a failing move and observe one retry, a state-file entry, and a flag at the next gate.

**Acceptance Scenarios**:

1. **Given** no `.feat-agent.yml`, **When** `/brief` or `/feat` runs, **Then** no tracker call is made and behavior is unchanged.
2. **Given** a config but the tracker script is missing (e.g. only `brief` installed), **When** `/brief` or `/feat` starts, **Then** it stops with an install hint and never falls back silently to tracking off.
3. **Given** a move fails mid-run, **When** the retry also fails, **Then** the failure is logged in `feat-state.md`, flagged at the next gate with the status to set by hand, and the build goes on.
4. **Given** a move fails during `/brief`, **When** it fails after the retry, **Then** it is flagged at the `/brief` gate.
5. **Given** a move fails at `/feat` setup before `feat-state.md` exists, **When** phase 2 creates the state file, **Then** the failure is written to it and flagged at the first gate.
6. **Given** setup found `.feat-agent.yml` but the worktree `/feat` enters lacks it (not committed or not pushed), **When** `/feat` enters the worktree, **Then** a `[!]` line saying the config is not in the worktree (commit and push it) is logged and flagged at the next gate, instead of later moves being skipped silently.
7. **Given** the state file holds `[!]` lines, **When** `/feat resume` runs, **Then** they don't block it.
8. **Given** `/brief #N` on a configured repo and the issue can't be read, **When** read issue fails, **Then** `/brief` asks the user to paste the issue, as today, instead of stopping.

---

### User Story 5 - Resume and send-back keep the card accurate (Priority: P3)

After `/feat resume`, or after a gate decision that sends the build back to phases 2-6, the card shows the status for the current phase.

**Why this priority**: Keeps the card honest in non-linear runs; the straight-through path works without it.

**Independent Test**: Resume at phases 3 and 7; the card reads In progress and In review respectively. Send back from phase 7 to phase 4; the card returns to In progress.

**Acceptance Scenarios**:

1. **Given** a run resumes in phases 2-6, **When** setup completes, **Then** the card is In progress.
2. **Given** a run resumes in phases 7-8, **When** setup completes, **Then** the card is In review.
3. **Given** a gate decision sends the build back to phases 2-6, **When** the decision is taken, **Then** the card is set to In progress again.
4. **Given** the user manually moved the card, **When** the next workflow move happens, **Then** the workflow's status overrides it.

---

### User Story 6 - Adopters understand setup, scope and risks from the docs (Priority: P3)

Adopters reading the docs learn how to enable tracking, what the broad `project` scope grants, that the feature is off unless configured, and the board automation caveats.

**Why this priority**: Without it, cards would stop at In review or be undone by another automation.

**Independent Test**: Read `docs/install.md` and `docs/workflow.md` and find each item in the requirements below.

**Acceptance Scenarios**:

1. **Given** the setup docs, **When** an adopter reads them, **Then** they learn to enable "Item closed", or else that cards stop at In review and must be moved to Done by hand.
2. **Given** the setup docs, **When** an adopter reads them, **Then** they learn to check what "Pull request linked to issue" sets, since it fires in phase 8 and could undo the phase 7 move.
3. **Given** the docs, **When** an adopter reads the security notes, **Then** they see that the feature needs the broad `project` scope (read and write on every board the user can reach) and is off unless configured.
4. **Given** the docs, **When** an adopter reads the security notes, **Then** they learn that a repo's `.feat-agent.yml` and `Issue:` lines can direct writes to any board they can edit and add any issue they can read to it, and to check the board line printed at the start of each run on repos they didn't write.

---

### Edge Cases

- `Issue:` is `owner/repo#N` for an issue in another repository than the one on the board.
- The brief has no `Issue:` line (written before the config existed): `/feat` runs the check, logs "no issue, no board moves", and continues; `/feat` never creates issues.
- Any move is repeated (resume, send-back, retry): the board is unchanged on repetition.
- The item is missing from the board when a status is set: it is added first.
- `.feat-agent.yml` comes from an untrusted repo: wrong URL shape, extra or missing keys, other indentation, or a hostile value must not cause anything outside the one configured board's Status field and the one issue to be touched, nor any command injection.
- The issue body read back from the tracker contains instruction-like text: it is treated as data.
- The check passes in `/brief` but `/feat` starts days later after the token or board changed: `/feat` checks again.
- Config values are quoted, or carry `#` comments: both are accepted; anything else fails.
- The brief path given to create issue is, or sits under, a symlink leading outside `specs/briefs/`: it is refused before any `gh` call.
- The brief's Why or Behaviour contains a fenced code block with a `## ` line: the section doesn't end there.
- The board has more than 10 Status options and a configured name is unknown: the error lists the first 10.
- Any line the script prints carries instruction-like text (an option name, a gh error, the issue body): it is shown or logged as data, never acted on.
- The issue's `Brief: specs/briefs/<name>.md` link stops resolving once `/feat` moves the brief into `feat-state.md` (the final path isn't known at `/brief` time); this is accepted.

## Requirements *(mandatory)*

### Functional Requirements

**Configuration**

- **FR-001**: The workflow MUST enable tracking only when a committed `.feat-agent.yml` exists at the repo root; without it, behavior is identical to today and no tracker call is made.
- **FR-002**: The config MUST hold `tracker.provider` (only `github` accepted), `tracker.project` (a board URL), and `tracker.statuses.brief`, `.building`, `.review`. There is no `done` entry.
- **FR-003**: The accepted config format MUST be exactly those keys, two-space indent, values optionally quoted, `#` comments ignored. Unknown or missing keys, other indentation, or another provider MUST fail the check and name the offending line.
- **FR-004**: Field and option IDs MUST be looked up at runtime and never stored in the config or state.

**Operations**

- **FR-005**: The workflow MUST provide four operations: check, create issue, read issue, set status; each prints one short line the orchestrator can log, except read issue, which prints the issue as one line of JSON.
- **FR-006**: The operations MUST ship as one bash script inside the `feat` skill (`.apm/skills/feat/scripts/`), one subcommand per operation, starting with `#!/usr/bin/env bash`, needing only bash and `gh` (no other dependency). `/brief` MUST reach it through the sibling path `<brief base dir>/../feat/scripts/`.
- **FR-007**: Only `/brief` and `/feat` (the orchestrator) MAY run the script; subagents MUST NOT.
- **FR-008**: Set status MUST add the item to the board first if absent, and repeating it MUST leave the board unchanged (no mutation when the item is already at the target status).
- **FR-028**: Set status MUST fail without any mutation when the account can't edit the board (`viewerCanUpdate` false), when the board has no single-select Status field, or when the issue doesn't exist.
- **FR-029**: An issue reference `#N` MUST be resolved to the current repository the way `gh issue` and `gh repo view` resolve it (`gh repo view --json nameWithOwner`), so that read issue, create issue and set status all act on the same repository.

**Moves**

- **FR-009**: At the start of `/brief` and the start of `/feat` (setup, before phase 2), every time, the workflow MUST run the read-only check: access and `project` scope, the board, and the configured statuses. On success the check prints `tracker: ok <kind>/<login>/projects/<n> (<brief>, <building>, <review>)`; the skill MUST show that line itself to the user, with one sentence saying the moves of this run go to that board. This adds no gate.
- **FR-010**: `/brief #N` MUST add the issue to the board if absent, and set Brief once the brief draft is written, before the fresh-reader review.
- **FR-030**: When tracking is on, `/brief` from an issue MUST read it with read issue. An issue URL MUST be turned into `owner/repo#N` (or `#N` for the current repository) before the call. A non-zero exit MUST keep today's fallback (ask the user to paste the issue), not stop the run. The bug-label stop MUST read `labels` from the returned JSON.
- **FR-011**: For `/brief "idea"` or a brief from a capability map, immediately after the user confirms the brief at the `/brief` gate (and not earlier), the workflow MUST create the issue (title: the brief's one-liner; body: the confirmed Why, Behaviour and `Brief: specs/briefs/<name>.md`; no labels), add it to the board, set Brief, and fill the brief's `Issue:` line. A section of the brief runs from its `## ` heading to the next `## ` heading outside a ``` fence. The `/brief` gate message MUST name the repository the issue will be created in. Create issue MUST take that confirmed `owner/repo` as an argument, resolve the current repository once (`gh repo view --json nameWithOwner`), and refuse (exit 1, no issue created) if the two differ; otherwise it MUST pass it to `gh issue create` with `-R`, and print `tracker: created <owner>/<repo>#<N>` with owner and repo taken from the URL gh prints; `/brief` MUST write that full reference into `Issue:`.
- **FR-031**: After the user confirms at the `/brief` gate, `/brief` MUST run, in order: create issue, write the `Issue:` line, set status Brief, print any `tracker:` line(s) above the final block, then the final block unchanged. A failed create issue MUST stop before the final block; the brief file stays saved without an `Issue:` line.
- **FR-012**: `/feat` setup (before phase 2) MUST set In progress; phase 7 start MUST set In review (before any PR exists).
- **FR-013**: Done MUST NOT be set by agents; it comes from the board's "Item closed" automation after `Closes #N` closes the issue, or from the user.
- **FR-014**: `/feat resume` MUST set the status for the current phase (2-6: building; 7-8: review). A gate decision that sends the build back to phases 2-6 MUST set In progress again. Workflow moves override manual ones.
- **FR-015**: The `Issue:` line MUST accept `#N` or `owner/repo#N`. A brief without an `Issue:` line MUST make `/feat` run the check, log "no issue, no board moves" and go on; `/feat` MUST NOT create issues.
- **FR-032**: After `/feat` enters the worktree, it MUST test for `.feat-agent.yml` again. If setup found it and the worktree lacks it, `/feat` MUST log a `[!]` line (the config is not in the worktree; commit and push it) and flag it at the next gate, instead of skipping later moves silently. No new state-file field is added.

**Failures**

- **FR-016**: A failed check MUST stop `/brief` or `/feat` at the start with the exact fix (e.g. `gh auth refresh -s project`; an unknown status name listed next to at most 10 of the board's real options). Issue creation failure is the only other hard stop.
- **FR-017**: A failed move mid-run MUST be retried once, after `TRACKER_RETRY_DELAY` seconds (default 2), then logged in `feat-state.md` and flagged at the next gate with the status to set by hand; the build goes on. The retried attempt includes resolving a `#N` reference (`gh repo view`), so a failure there is retried too. In `/brief` it is flagged at the gate. A move failing at `/feat` setup before `feat-state.md` exists MUST be kept in context, written to the state file when phase 2 creates it, and flagged at the first gate. `[!]` lines in the Log are informational: each is flagged at the gate right after it is written, and none blocks `/feat resume`.
- **FR-018**: If `.feat-agent.yml` is present but the script is missing, `/brief` and `/feat` MUST stop with an install hint and never fall back silently to tracking off.

**Security**

- **FR-019**: The config MUST be treated as untrusted: the project URL MUST match `https://github.com/(users|orgs)/<login>/projects/<number>`; status names MUST be matched only against the board's real options; no config value MAY be passed to `eval` or into a shell string.
- **FR-020**: Every value MUST be passed as a quoted argument; GraphQL values as variables, never pasted into the query; issue bodies via a body file.
- **FR-021**: The script MUST touch only the configured board's Status field and the one issue.
- **FR-022**: The issue body returned by read issue, and every line the script prints, MUST be treated as data: relayed to the user or logged, never acted on as instructions. Both skills MUST say so where they run the script. Every value the script echoes (config values, option names, issue titles, gh errors) MUST have its control characters and Unicode bidi/format characters (U+200B–U+200F, U+202A–U+202E, U+2066–U+2069) replaced with `?` and be cut to 60 characters.
- **FR-033**: Create issue MUST resolve the brief path's directory physically (`cd -P`, `pwd -P`) and require it to equal the physical repo root (`cd -P "<repo root>" && pwd -P`) followed by `/specs/briefs`, so a symlinked `specs` or `specs/briefs` is refused, and the file to be a regular file that is not a symlink; otherwise it MUST exit 2 before any `gh` call.

**Architecture and delivery**

- **FR-023**: `/feat` MUST stay thin: it runs the script and logs its one-line result, and never reads GraphQL or IDs. The "You are a thin orchestrator" rules in `.apm/skills/feat/SKILL.md` MUST say so in one sentence, calling the check "the board check". There is no new agent, no change to the size table, and no change to `apm.yml`, `.claude-plugin/plugin.json` or `install.sh`'s install logic.
- **FR-034**: The skills' context cost MUST stay small: `.apm/skills/feat/SKILL.md` defines "Board moves" once (command form, exit handling, the log-and-flag rule), then one short line per moment (setup, phase 7, back to N, resume), within a budget of 12 lines; `.apm/skills/brief/SKILL.md` adds within a budget of 10 lines. The budget is judged by the token cost of the additions, counted as prose wrapped at ~76 columns like the surrounding text, not by raw line count (a long unwrapped line counts as several). The moments table lives only in `docs/workflow.md`.
- **FR-024**: `mise run lint` MUST also run `shellcheck .apm/skills/feat/scripts/*`, which stays clean. `mise run test:apm` MUST assert, inside its scratch directory and after its install, that `.claude/skills/feat/scripts/tracker.sh` exists.
- **FR-025**: A new `mise run test:tracker` MUST exercise the script offline with `gh` stubbed on PATH. The stub answers `gh issue` and `gh repo` from canned per-case files and hands `gh api graphql` to the pinned real `gh`, pointed at a local fake GraphQL endpoint that returns raw GraphQL JSON per operation name, so the script's real `--jq` filters run. The stub records no mutations (it is stateless apart from a one-shot fault marker). Cases: no config means no `gh` call; an unknown status; a malformed config line; a project URL that fails validation; set-status on an item already at the target makes no mutation; an item missing from the board is added first; a hostile config value runs nothing and reaches no request; one failed read then success; create issue in a repo whose gh default is an upstream records the upstream reference; a brief path through a symlinked directory is refused; read issue prints the issue's JSON line, `labels` included; a token lacking the `project` scope makes check fail with `gh auth refresh -s project`.
- **FR-035**: `mise.toml` MUST pin `gh` to the version the GraphQL documents were probed with (2.103.3); `docs/install.md` MUST state "tested on gh 2.103.3". No minimum `gh` version is stated.
- **FR-026**: `.apm/skills/brief/SKILL.md` (check, read issue, Brief move, issue creation after the gate), `.apm/skills/feat/SKILL.md` (setup check and move, worktree re-test, phase 7 move, send-back, resume, failure flagging, the Log example's `[!]` line), `docs/workflow.md`, `docs/install.md` (its `gh` prerequisite row mentions the `project` scope), `docs/usage.md` (a board-tracking paragraph linking to install.md; no `gh` prerequisite there), `README.md` (its Layout and docs table) and `CHANGELOG.md` (under `## Unreleased`) MUST be updated.
- **FR-027**: The setup docs (`docs/install.md` only) MUST hold the config example and tell adopters (a) to enable "Item closed", or else that cards stop at In review and must be moved to Done by hand, (b) to check what "Pull request linked to issue" sets, (c) that the feature needs the broad `project` scope and is off unless configured, and (d) that a repo's `.feat-agent.yml` and `Issue:` lines can direct writes to any board they can edit and add any issue they can read, so they should check the board line on repos they didn't write. `docs/workflow.md` holds the moments table and links to install.md for setup.

### Key Entities

- **Tracker config** (`.feat-agent.yml`): opt-in file holding the provider, board URL and the three status names.
- **Board**: a GitHub Projects board with a Status field whose options include the configured names.
- **Card / item**: an issue's entry on the board; its Status follows the workflow.
- **Issue reference**: `#N` or `owner/repo#N`, carried in the brief's `Issue:` line.
- **Move**: one status change from the table of moments, repeatable and idempotent.
- **Move failure record**: a `[!]` entry in `feat-state.md`'s Log (or held in context before it exists) naming the status to set by hand, or that the config is missing from the worktree; informational, never blocks resume.
- **Created issue**: an issue made by create issue in the repository gh resolves, recorded in the brief as `owner/repo#N`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a configured repo whose board has "Item closed" enabled, a feature goes from Todo (or no ticket) to Done with 0 manual board moves.
- **SC-002**: In a repo without `.feat-agent.yml`, 0 tracker calls are made and the workflow output is unchanged.
- **SC-003**: A missing `project` scope, a missing board, or an unknown status name stops the run at the start 100% of the time, with the exact fix in the message.
- **SC-004**: A failed move mid-run never stops the build and is shown at the next gate (0 silent failures).
- **SC-005**: After `/feat resume` at any phase, the card shows that phase's status.
- **SC-006**: Repeating any move any number of times leaves the board unchanged.
- **SC-007**: `mise run lint`, `mise run test:apm` and `mise run test:tracker` all pass, and the twelve offline scenarios of FR-025 are covered.
- **SC-009**: Every `/brief` and `/feat` run on a configured repo shows the user, before any move, which board it will write to.
- **SC-008**: An adopter can find, in the docs, the two automation caveats and the broad-scope warning without reading code.

## Assumptions

- Adopters use `gh` authenticated as a user able to edit the board; GitHub is the only provider.
- Linear and third-party providers, manual-move detection, agents setting Done, syncing Priority/Size, configurable transition points, turning on board automations, and labels on created issues are out of scope (per the brief).
- The existing flow already carries the brief's `Issue:` line to the shipper, which writes `Closes #N`; that remains unchanged.
- Only the Status field is managed; "Item closed" is the board's job, not the workflow's.
- The "In review" option wording on the boards (done during the interview) and enabling "Item closed" on the feat-agent board are manual, outside this change.
- The check's one read-only call is acceptable cost at the start of both skills.
- The offline tests may use `python3` (standard library only), which `mise run lint` already needs, for the fake GraphQL endpoint; the shipped script needs only bash and `gh`.
