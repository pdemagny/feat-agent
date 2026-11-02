---

description: "Task list for Board tracking"
---

# Tasks: Board tracking

**Input**: Design documents from `specs/001-board-tracking/` (spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md)

**Prerequisites**: plan.md, spec.md

**Tests**: Requested (FR-025, SC-007): the offline suite `tests/tracker/` with the twelve cases of plan.md "Tests" (ten at phase 6; read-issue and missing-scope added in the phase 7 fixes).

**Organization**: Grouped by user story. Implementers run one per story, sequentially, nothing committed until ship: Phases 1-2 go with US1, the Polish phase with US6 (last story).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: different files, no dependency on an incomplete task
- **MANUAL/USER**: cannot be done unattended (real board writes); the implementer skips it and reports it
- Paths are relative to the worktree root. Contract details (exit codes, output lines, error lines) are in `specs/001-board-tracking/contracts/tracker-cli.md` and `contracts/feat-agent-yml.md`. The GraphQL documents and `--jq` filters live only in `tracker.sh` (the contract points there since the phase 7 fixes).
- Conventions: bash 4+ with `#!/usr/bin/env bash`, `shellcheck` clean, no jq/yq/realpath/python in the shipped script; `/feat` SKILL.md gains at most 12 lines, `/brief` SKILL.md at most 10 (counted over the whole feature); the size table stays untouched.

---

## Phase 1: Setup (with US1)

- [X] T001 FIRST (plan D10): create placeholder `.apm/skills/feat/scripts/tracker.sh` (`#!/usr/bin/env bash`, `exit 0`); run `apm install <worktree path> -t claude` in a scratch dir (`git init` first) and confirm `.claude/skills/feat/scripts/tracker.sh` exists there; then add `test -f .claude/skills/feat/scripts/tracker.sh` to `test:apm` in `mise.toml`, inside the scratch dir after the install (FR-024). If APM drops the file, STOP and report: the Structure Decision fails.
- [X] T002 In `mise.toml`: pin `gh = "2.103.3"` (FR-035); extend `lint` with `shellcheck .apm/skills/feat/scripts/*`, `shellcheck tests/tracker/run.sh tests/tracker/bin/gh` and `python3 -m py_compile tests/tracker/fake_github.py`; add task `test:tracker` running `bash tests/tracker/run.sh` (FR-024, FR-025).
- [X] T003 [P] Create stub `tests/tracker/bin/gh` (executable, `#!/usr/bin/env bash`), stateless per plan: append argv to `$TRACKER_CASE/calls`; `api ...` -> `exec "$TRACKER_REAL_GH" "$@"`; `repo view ...` -> print `$TRACKER_CASE/repo`; `issue view ...` -> print `$TRACKER_CASE/issue.json`; `issue create ...` -> copy the `--body-file` file to `$TRACKER_CASE/body` and print `$TRACKER_CASE/issue-url`; anything else exit 1.
- [X] T004 [P] Create `tests/tracker/fake_github.py` (stdlib only, run as `python3 -I`): HTTP server on a unix socket given as argv[1], case dir argv[2]; for `POST /graphql` read the operation name from `query|mutation <Name>`, append `{"op","variables","query"}` as a JSON line to `<case>/requests`; if `<case>/<Op>.fail` exists remove it and answer 502; else answer `<case>/<Op>.json` with 200 plus `X-OAuth-Scopes` from `<case>/scopes` when present; no fixture -> a GraphQL `errors` body. Apply no mutation.
- [X] T005 [P] Create raw GraphQL response fixtures in `tests/tracker/fixtures/*.json` in the shape of the contract's "Raw response shape" section: board (Brief, In progress, In review, Done options), board with 12 Status options, item at target status, item not on the board, item at another status, `TrackerAdd`, `TrackerSet`.
- [X] T006 Create `tests/tracker/run.sh`: resolve the real gh with `command -v gh` before changing PATH (absent -> fail "install gh (mise install)"); a `run_case` helper that makes a temp dir with `git init` and a written `.feat-agent.yml`, a case dir, `ghcfg/config.yml` with `http_unix_socket: <case>/s`, starts `python3 -I tests/tracker/fake_github.py` in the background, waits for the socket, runs the script with `PATH=tests/tracker/bin:$PATH`, `TRACKER_REAL_GH`, `TRACKER_CASE`, `GH_CONFIG_DIR`, `GH_TOKEN=test`, `GH_NO_UPDATE_NOTIFIER=1`, `GH_PROMPT_DISABLED=1`, `TRACKER_RETRY_DELAY=0`, then stops the endpoint; assertion helpers; prints `ok <case>` per case; exits non-zero on the first failure. Cases are added by later tasks.

---

## Phase 2: Foundational (with US1)

**Purpose**: the shared body of `tracker.sh` every subcommand needs. Replace the T001 placeholder.

- [X] T007 Write the `.apm/skills/feat/scripts/tracker.sh` skeleton: `set -euo pipefail`; repo root = `git rev-parse --show-toplevel` falling back to `$PWD`; config path `<root>/.feat-agent.yml`; no config -> print `tracker: off (no .feat-agent.yml)`, exit 0 before any `gh` call (FR-001); subcommand dispatch for `check`, `read-issue`, `create-issue`, `set-status` (unknown subcommand or wrong argument count -> exit 2); `gh` missing -> `tracker: error: gh not found; install it (https://cli.github.com)`, exit 1; `clean()` (control characters -> `?`, cut to 60 characters); one-line `tracker: ` output helper, nothing on stderr.
- [X] T008 In `tracker.sh`, add the config parser per `contracts/feat-agent-yml.md`: `while IFS= read -r`, fixed grammar (exact keys, two-space indent, optional quotes, `#` comments), values stored in fixed variables `provider`, `project_url`, `status_brief`, `status_building`, `status_review`, never `eval`ed or `declare`d from config text (FR-019); URL matched with `[[ =~ ]]` against `https://github.com/(users|orgs)/<login>/projects/<number>`, login and number from `BASH_REMATCH`; digits-only check on the number; unknown/missing/duplicate keys, other indentation, tab, `provider` other than `github` -> exit 1 naming the line or key; no `gh` call on any parse or URL error (FR-002, FR-003).
- [X] T009 In `tracker.sh`, add the gh plumbing: the wrapper running `gh "$@" 2>"$err"` that on non-zero exit drops stdout and maps stderr's first line with the contract's 3-row table (else the line minus `gh: `/`GraphQL: `, cleaned); the current-repo helper (`gh repo view --json nameWithOwner --jq .nameWithOwner`, result must match `^[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9._-]{1,100}$`, no `{owner}`/`{repo}` placeholders; FR-029); the issue-ref validator (`^#[1-9][0-9]{0,9}$` or the `owner/repo#N` pattern; malformed -> exit 2); the ID check `^[A-Za-z0-9_=-]{1,200}$` for IDs read from responses (FR-020).
- [X] T010 In `tracker.sh`, add the four GraphQL documents and four `--jq` filters as quoted-heredoc constants `Q_BOARD`/`J_BOARD`, `Q_ITEM`/`J_ITEM`, `M_ADD`/`J_ADD`, `M_SET`/`J_SET` (probed live 2026-11-02; the only copy); strings pass with `-f`, integers with `-F` only after a digits-only check, IDs with `-f` after the ID check. The filters print tab-separated `B`/`O`/`I` lines read with `IFS=$'\t' read -r`.
- [X] T011 Add test case 1 `no config` to `tests/tracker/run.sh`: `check` and `set-status building #1` print `tracker: off ...`, exit 0, and no `calls` file exists (FR-001, SC-002). Run `bash tests/tracker/run.sh`.

**Checkpoint**: script skeleton, parser and plumbing ready; case 1 green.

---

## Phase 3: User Story 1 - A card follows the workflow without manual moves (Priority: P1) MVP

**Goal**: with a config, the issue's card moves to Brief, In progress, In review at the right moments; the board check line is shown at the start of `/brief` and `/feat`.

**Independent Test**: offline cases 5 and 6 pass; on a configured repo the skills run `check` then the moves (full run is T047, manual).

### Tests for User Story 1

- [X] T012 [US1] Add test case 5 `repeat` to `tests/tracker/run.sh`: item already at the target -> output `tracker: #N already "Brief"`, exit 0, `requests` holds only `TrackerItem` (FR-008, SC-006).
- [X] T013 [US1] Add test case 6 `item missing` to `tests/tracker/run.sh`: `requests` ops are `TrackerItem`, `TrackerAdd`, `TrackerSet` in order; `TrackerSet`'s `option` variable is the Brief option ID (proves the real `--jq` ran); output ends `(added to board)`.

### Implementation for User Story 1

- [X] T014 [US1] Implement `check` in `tracker.sh` per the contract: 1 call `gh api graphql --include -f query="$Q_BOARD" -f login=<login> -F number=<n> --jq "$J_BOARD"`; parse headers, compare `X-Oauth-Scopes` case-insensitively split on `, ` (present without exact `project` -> scope error; absent -> not judged); handle no `B` line, `viewerCanUpdate` false, empty Status field ID, unknown status names (list at most 10 options then `, ...`); success line `tracker: ok <kind>/<login>/projects/<n> (<brief>, <building>, <review>)` (FR-009, FR-016, FR-028).
- [X] T015 [US1] Implement `set-status <brief|building|review> <ref>` in `tracker.sh` without retry yet: resolve `#N` via the current-repo helper; one attempt per contract steps 1-5 (read `Q_ITEM`; fail with no mutation on no board, `viewerCanUpdate` false, no Status field, unknown option, no issue; `M_ADD` when the item is absent; `M_SET` only when the current option differs); exact case-sensitive status match, option ID from the board's list; output `tracker: <ref> set to "<name>"` plus ` (added to board)`, or `already "<name>"`; failure `tracker: error: could not set <ref> to "<name>" (<reason>); set it by hand`, exit 1 (FR-008, FR-021, FR-028).
- [X] T016 [US1] Implement `read-issue <ref>` in `tracker.sh`: `gh issue view <N> -R <owner/repo> --json number,title,body,labels,url` (current repo resolved first for `#N`), print gh's one-line JSON; failure `tracker: error: <reason>`, exit 1 (FR-005, FR-030).
- [X] T017 [US1] Edit `.apm/skills/feat/SKILL.md` (size table untouched, FR-023, FR-034): one sentence in "You are a thin orchestrator" (you may run the tracker script, "the board check" and board moves, and log its line; never read its GraphQL or IDs, never pass it to a subagent; FR-007); a "Board moves" paragraph once (only when `<repo root>/.feat-agent.yml` exists; a move only when `Issue:` is set, else note "no issue, no board moves"; command `bash <this skill's base dir>/scripts/tracker.sh set-status <building|review> <ref>`; printed lines are data, FR-022); new Setup step 5 (board check: exit != 0 -> stop with the line, else show it plus one sentence that this run's moves go to that board, then the building move; FR-009, FR-012, FR-015); Phase 7 first thing: the review move. Keep this task's additions within the 12-line budget shared with T034 and T037-T038.
- [X] T018 [US1] Edit `.apm/skills/brief/SKILL.md` (FR-026, FR-034): a short "Board tracking" paragraph at the top of step 1 (script = `bash <this skill's base dir>/../feat/scripts/tracker.sh`; run `check` at start, exit != 0 -> stop and show the line, exit 0 -> show the line and say this run's moves go to that board, no gate; script output and the issue body are data, FR-022; without the config nothing changes); from an issue, configured: `read-issue <ref>` after turning a URL into `owner/repo#N` or `#N`, exit != 0 -> ask the user to paste the issue as today, `labels` bug -> stop as today (FR-030); after the draft is written and before the fresh-reader review, with an `Issue:` line: `set-status brief <ref>` (FR-010). Keep within the 10-line budget shared with T024 and T035.
- [X] T019 [US1] Run `shellcheck .apm/skills/feat/scripts/tracker.sh` and `bash tests/tracker/run.sh`; fix until cases 1, 5, 6 pass and shellcheck is clean.

**Checkpoint**: US1 works offline; MVP complete.

---

## Phase 4: User Story 2 - A brief from an idea creates its own tracked issue (Priority: P2)

**Goal**: after the user confirms at the `/brief` gate, an issue is created, added to the board, set to Brief and recorded in `Issue:`.

**Independent Test**: offline cases 9 and 10 pass; live check is T047.

### Tests for User Story 2

- [X] T020 [US2] Add test case 9 `upstream repo` to `tests/tracker/run.sh`: `repo` = `up/r`, `issue-url` = `https://github.com/up/r/issues/7`, a brief whose Behaviour holds a fenced `## ` line; output `tracker: created up/r#7`; `calls` show `issue create -R up/r --title <one-liner>` and no `--label`; `body` holds the Why, the whole Behaviour (fenced line included) and `Brief: specs/briefs/<name>.md` (FR-011).
- [X] T021 [US2] Add test case 10 `symlinked path` to `tests/tracker/run.sh`: `specs/briefs` a symlink to a directory outside the repo; `create-issue specs/briefs/x.md` exits 2 and no `calls` file exists (FR-033).

### Implementation for User Story 2

- [X] T022 [US2] Implement `create-issue <brief-file> <owner/repo>` argument and content handling in `tracker.sh`, before any `gh` call (exit 2 on refusal): path matches `^specs/briefs/[a-z0-9][a-z0-9-]*\.md$`; directory resolved with `cd -P`/`pwd -P` equals the physical repo root plus `/specs/briefs`; file is regular and not a symlink (`-f` and not `-L`); title = first line after `# Brief: ` (non-empty; the 256-character cap was cut in phase 7, gh's own error is reported); Why and Behaviour sections run from their `## ` heading to the next `## ` line outside a ``` fence (toggle on lines starting with ```), both non-empty; body written to a `mktemp` file removed on exit, laid out as `## Why`, `## Behaviour`, blank line, `Brief: specs/briefs/<name>.md` (FR-011, FR-033).
- [X] T023 [US2] In `tracker.sh`, finish `create-issue` gh calls: current repo via the helper, then `gh issue create -R <owner/repo> --title <title> --body-file <tmp>` (no labels, no assignees, never retried); printed URL must match `^https://github\.com/([^/]+)/([^/]+)/issues/([1-9][0-9]{0,9})$` and owner/repo pass the ref rules; print `tracker: created <owner>/<repo>#<N>` from the URL; failure `tracker: error: could not create the issue (<reason>)`, exit 1.
- [X] T024 [US2] Edit `.apm/skills/brief/SKILL.md`: at the gate, configured and no `Issue:` line, say the issue will be created in `<owner/repo>` (from `gh repo view --json nameWithOwner --jq .nameWithOwner`); after the user confirms, in order: `create-issue specs/briefs/<name>.md` (exit != 0 -> show the line and stop before the final block, brief stays saved with no `Issue:` line), write the printed `owner/repo#N` into `Issue:`, `set-status brief <ref>`, print the `tracker:` lines above the final block, then the final block unchanged (FR-011, FR-031). Nothing is created before confirmation or for an abandoned, bug-stopped or rejected brief. Stay within the shared 10-line budget.
- [X] T025 [US2] Run `shellcheck .apm/skills/feat/scripts/tracker.sh` and `bash tests/tracker/run.sh`; cases 1, 5, 6, 9, 10 green.

**Checkpoint**: US1 and US2 both work offline.

---

## Phase 5: User Story 3 - Misconfiguration stops the run early with the exact fix (Priority: P2)

**Goal**: the check fails at the start with the exact fix for each configuration error.

**Independent Test**: offline cases 2, 3, 4, 7 pass.

### Tests for User Story 3

- [X] T026 [US3] Add test case 2 `malformed line` to `tests/tracker/run.sh`: configs with a 3-space indent, a tab, an unknown key, a duplicate key, a missing key, `provider: linear`; each exits 1, output names the line number or key, no `calls` file (FR-003).
- [X] T027 [US3] Add test case 3 `bad project URL` to `tests/tracker/run.sh`: repo URL, `http://`, other host, `/views/1`, trailing slash; each exits 1, no `calls` file (FR-019).
- [X] T028 [US3] Add test case 4 `unknown status` to `tests/tracker/run.sh`: `review: In Review` against the 12-option board fixture; exit 1, output names `"In Review"`, lists 10 options then `...` (FR-016).
- [X] T029 [US3] Add test case 7 `hostile value` to `tests/tracker/run.sh`: `brief: $(touch pwned)` in the config; no `pwned` file in any temp dir, `pwned` absent from `requests`, exit 1 with the value cleaned (FR-019, FR-020).

### Implementation for User Story 3

- [X] T030 [US3] Fix whatever T026-T029 expose in `tracker.sh`; verify the error table maps `gh auth login`, `INSUFFICIENT_SCOPES`/`required scopes` (exact fix `gh auth refresh -s project`) and `Could not resolve to a ProjectV2` per the contract, and that echoed values go through `clean()` in double quotes (SC-003).
- [X] T031 [US3] Run `shellcheck .apm/skills/feat/scripts/tracker.sh` and `bash tests/tracker/run.sh`; cases 1-7, 9, 10 green.

**Checkpoint**: US3 covered.

---

## Phase 6: User Story 4 - Tracking is off unless configured, and failures never block a build (Priority: P2)

**Goal**: failed moves are retried once, recorded and flagged while the build goes on; a missing script or worktree config is reported, never silent.

**Independent Test**: offline case 8 passes; skills text covers FR-017, FR-018, FR-032.

### Tests for User Story 4

- [X] T032 [US4] Add test case 8 `retry then success` to `tests/tracker/run.sh`: `TrackerItem.fail` present; `requests` holds `TrackerItem` twice then `TrackerSet`; exit 0 (FR-017).

### Implementation for User Story 4

- [X] T033 [US4] In `tracker.sh` `set-status`, wrap the read and mutations in one attempt function; on a `gh` failure sleep `${TRACKER_RETRY_DELAY:-2}` (digits only, else 2) and run the attempt once more; config, argument and result failures (`viewerCanUpdate` false, no Status field, unknown option) are never retried (FR-017, FR-028).
- [X] T034 [US4] Edit `.apm/skills/feat/SKILL.md`: in "Board moves", config present but script missing -> stop with the install hint (FR-018); a move with exit != 0 -> log `- [!] <the line>` in the state Log (before phase 2 creates the file: keep it and write it then), flag it under "What you should know" at the gate right after, go on; `[!]` lines never block resume (FR-017); Phase 2 step 1 after entering the worktree: if setup found the config and the worktree has none, log `- [!] tracker: .feat-agent.yml is not in the worktree; commit and push it (board moves skipped)` and flag it at the first gate (FR-032); State file Log example gains one `- [!] tracker: error: could not set #11 to "In review" (...); set it by hand` line, no new header line. Within the shared 12-line budget.
- [X] T035 [P] [US4] Edit `.apm/skills/brief/SKILL.md`: config present but script missing -> stop with the install hint (FR-018); a failed move is flagged at the gate (FR-017). Within the shared 10-line budget.
- [X] T036 [US4] Run `shellcheck .apm/skills/feat/scripts/tracker.sh` and `bash tests/tracker/run.sh`; all cases green (ten at the time).

**Checkpoint**: all FR-025 cases pass (ten at the time; twelve after phase 7).

---

## Phase 7: User Story 5 - Resume and send-back keep the card accurate (Priority: P3)

**Goal**: the card shows the status of the current phase after resume or a send-back.

**Independent Test**: read `.apm/skills/feat/SKILL.md`: resume in phases 2-6 sets building, 7-8 sets review; "back to N" (2-6) from phase 7 or 8 sets building. (Live run is T047.)

- [X] T037 [US5] Edit `.apm/skills/feat/SKILL.md`: `/feat resume` runs Setup step 5 before its gate, then the building move for phases 2-6 or the review move for phases 7-8 (FR-014, SC-005). Within the shared 12-line budget.
- [X] T038 [US5] Edit `.apm/skills/feat/SKILL.md`: at the gates, "back to N" with N in 2-6 from phase 7 or 8 -> the building move (FR-014).

**Checkpoint**: US5 covered.

---

## Phase 8: User Story 6 - Adopters understand setup, scope and risks from the docs (Priority: P3)

**Goal**: setup, scope, caveats and risks are findable in the docs.

**Independent Test**: `docs/install.md` and `docs/workflow.md` contain each item of FR-027.

- [X] T039 [US6] Edit `docs/install.md` (the only home for setup, FR-027): `gh` prerequisite row gains "board tracking also needs the `project` scope" (FR-035; "tested on 2.103.3" lives in section 5, no minimum version claimed); new section "5. Board tracking (optional)" with the `.feat-agent.yml` example (provider, project, statuses brief/building/review), commit and push it (worktrees branch from `origin/<default>`), `gh auth refresh -s project` and what the broad scope grants (read and write on every board you can reach), off unless configured, enable "Item closed" (else cards stop at In review and are moved to Done by hand), check what "Pull request linked to issue" sets (fires in phase 8, could undo the phase 7 move), and that a repo's `.feat-agent.yml` and `Issue:` lines can direct writes to any board you can edit and add any issue you can read, so check the board line at the start of each run on repos you didn't write.
- [X] T040 [P] [US6] Edit `docs/workflow.md`: a "Board tracking" subsection with the moments table (moment -> status: `/brief` draft -> Brief; `/feat` setup and resume in 2-6 and back-to-N -> In progress; phase 7 start and resume in 7-8 -> In review; Done from the board's "Item closed") linking to install.md for setup; one line each in the phase 0, 1 and 7 details. No matrix change (FR-026, FR-027).
- [X] T041 [P] [US6] Edit `docs/usage.md`: a short board-tracking paragraph in step 1 linking to `install.md` (FR-026).

**Checkpoint**: all six stories done.

---

## Phase 9: Polish & Cross-Cutting Concerns (with US6)

- [X] T042 [P] Edit `README.md`: Layout adds `.apm/skills/feat/scripts/` and `tests/`, `test:tracker` in the mise tasks line, and the docs table's `install.md` row mentions board tracking.
- [X] T043 [P] Add one entry under `## Unreleased` in `CHANGELOG.md` (board tracking: opt-in `.feat-agent.yml`, moves Brief / In progress / In review, issue creation from `/brief`, gh pin 2.103.3, `test:tracker`).
- [X] T044 [P] Edit `.claude/CLAUDE.md` Shell line: `shellcheck` also covers the tracker script and the bash tests (`mise run test:tracker` mentioned among the tasks).
- [X] T045 Verify budgets and invariants with `git diff` on the two SKILL.md files: `/feat` at most 12 added lines, `/brief` at most 10; the size table and its format unchanged; `apm.yml`, `.claude-plugin/plugin.json`, `install.sh` untouched; no `[!]` or tracker wording added to any agent file. Trim if over budget.
- [X] T046 Run `mise run lint`, `mise run test:apm`, `mise run test:tracker`; all exit 0, `test:tracker` prints one `ok` line per case (twelve after phase 7).
- [ ] T047 [MANUAL/USER] Live validation per `quickstart.md` "Live" steps 1-8 on a test board you own (real board writes; needs `gh auth refresh -s project`, a pushed `.feat-agent.yml`, "Item closed" enabled). The implementer skips this task and lists it as pending for the user before merging.

---

## Dependencies & Execution Order

- Phase 1 -> Phase 2 -> user stories in order US1 -> US2 -> US3 -> US4 -> US5 -> US6 -> Polish (one implementer per story, sequential).
- T001 first. T003, T004, T005 are parallel; T006 needs them in place to run. T007-T010 are sequential edits of one file.
- US1 tests (T012-T013) precede T014-T016; US2 tests (T020-T021) precede T022-T023; same for US3, US4.
- All `tests/tracker/run.sh` tasks and all `tracker.sh` tasks share a file: no [P] between them.
- `.apm/skills/feat/SKILL.md` edits (T017, T034, T037, T038) and `.apm/skills/brief/SKILL.md` edits (T018, T024, T035) share a line budget each; count at T045.
- US2 and US3 depend only on Phases 1-2 for the script, but US2's T024 edits the brief skill after T018.

### Parallel example

```text
T003 stub gh | T004 fake_github.py | T005 fixtures
T040 workflow.md | T041 usage.md
T042 README | T043 CHANGELOG | T044 CLAUDE.md
```

## Implementation Strategy

### MVP first (US1 only)

1. Phase 1 (T001 first) and Phase 2.
2. US1 (T012-T019): `check`, `set-status`, `read-issue`, skills wiring.
3. Stop and validate offline (cases 1, 5, 6). Remaining stories add issue creation, config-error tests, retry and failure flagging, resume, docs.

### MVP slice

T001-T019 (Setup, Foundational and US1).

### Allocation to implementers

- Implementer 1 (US1): T001-T019 (Setup, Foundational, US1)
- Implementer 2 (US2): T020-T025
- Implementer 3 (US3): T026-T031
- Implementer 4 (US4): T032-T036
- Implementer 5 (US5): T037-T038
- Implementer 6 (US6 + Polish): T039-T047
