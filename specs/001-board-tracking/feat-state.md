# /feat state: /brief and /feat move the feature's issue across a GitHub Projects board

- Branch: board-tracking Worktree: .claude/worktrees/brief-board-tracking
- Size: medium
- Agents: specifier a6bdd95367686cd60, planner a8d5d89fcf9686b05
- Current phase: done (PR #14)
- Conventions: conventional commits `type(scope): msg`, one logical change per commit, no co-author; `mise run lint` + `mise run test:apm` before committing; CHANGELOG under `## Unreleased`; update docs/workflow.md and docs/install.md; /feat stays thin; no change to the size table, apm.yml, plugin.json or install.sh install logic; shellcheck clean; PR says `Closes #11`
- Allowed Spec Kit hooks: none (no .specify/extensions.yml)
- Map: none
- Issue: #11

## Brief

- Size: medium — ~32 tasks expected; one script and edits to both skills and three docs, raised to medium anyway by the new `project` token scope
- Short name: board-tracking
- Issue: #11

### Why
Adopters who track features on a GitHub Projects board want each card to
follow the workflow (Todo → Brief → In progress → In review → Done) without
moving it by hand. Today nothing in the workflow writes to the board, so a
card sits in Todo through the brief and the build.

### Today
`/brief #N` reads the issue with `gh issue view`, and the brief's `Issue:`
line is carried to `feat-shipper`, which writes `Closes #N` in the PR. A
brief from a plain idea has no issue at all. GitHub's built-in board
automations react only to PR and issue events ("Pull request linked to
issue", "Item closed"), so they can't show Brief or In progress, and they
show In review only once a PR exists. On another project's board, moves to Brief
or In progress were made by agents improvising `gh project item-edit` from
a memory note. No skill or agent asks for those moves, so they happen
inconsistently.

### Behaviour
- Opt-in through a committed `.feat-agent.yml` at the repo root. If the
  file is absent, the workflow behaves exactly as it does today and makes
  no tracker calls:
  ```yaml
  tracker:
    provider: github            # later: linear
    project: https://github.com/users/pdemagny/projects/1
    statuses:
      brief: Brief
      building: In progress
      review: In review
  ```
  Only status names are configurable; field and option IDs are looked up
  at runtime. There is no `done` entry. The accepted format is exactly
  these keys, two-space indent, values optionally quoted, `#` comments
  ignored. Anything else (unknown or missing keys, other indentation) or a
  `provider` other than `github` fails the check, which names the line.
- Four operations: check, create issue, read issue, set status. They live
  in one bash script shipped inside the `feat` skill
  (`.apm/skills/feat/scripts/`), one subcommand each. `/brief` reaches it
  through the sibling path `<brief base dir>/../feat/scripts/`. Each call
  prints one short line the orchestrator can log.
- Moves. Only `/brief` and `/feat` (the orchestrator) run the script;
  subagents never do:

  | Moment | Effect |
  |---|---|
  | Start of `/brief` and start of `/feat` (setup, before phase 2) | Read-only check: access and `project` scope, the board, the configured statuses. Runs in both, every time. |
  | `/brief #N`, issue not on the board | Adds it to the board |
  | `/brief #N`: brief draft written, before the fresh-reader review | Brief |
  | `/brief "idea"` or from a capability map: right after the user confirms the brief at the `/brief` gate | Creates the issue (title: the brief's one-liner; body: the confirmed Why, Behaviour and `Brief: specs/briefs/<name>.md`; no labels), adds it to the board, sets Brief, fills the brief's `Issue:` line |
  | `/feat` setup, before phase 2 | In progress |
  | Phase 7 starts | In review (the feature is waiting on the user's code review decision, before any PR exists) |
  | PR merged | Done, set by the board's own "Item closed" automation after `Closes #N` closes the issue, or by the user (see Constraints) |

- Set status adds the item to the board first if it isn't there, so every
  move can be repeated safely. `/feat resume` sets the status for the
  current phase (2–6: building; 7–8: review). A gate decision that sends
  the build back to phases 2–6 sets In progress again. Workflow moves
  override manual ones.
- Issues: `Issue:` may be `#N` or `owner/repo#N`, because a board can hold
  issues from any repository. A brief without an `Issue:` line (e.g.
  written before the config existed): `/feat` runs the check, logs "no
  issue, no board moves" and goes on. `/feat` never creates issues.
- If `.feat-agent.yml` is present but the script is missing (e.g. only
  `brief` was installed), `/brief` and `/feat` stop with an install hint.
  They never fall back silently to tracking off.
- Failures: a failed check stops `/brief` or `/feat` at the start with the
  exact fix (e.g. `gh auth refresh -s project`, an unknown status name
  listed next to the board's real options). Issue creation is the only
  other hard stop. A failed move mid-run is retried once, then logged in
  `feat-state.md` and flagged at the next gate with the status to set by
  hand; the build goes on. In `/brief`, it is flagged at the gate. A move
  that fails at `/feat` setup, before `feat-state.md` exists, is kept in
  context, written to the state file when phase 2 creates it, and flagged
  at the first gate.

### Out of scope
- Other providers (Linear is its own item and may reshape the four
  operations) and third-party provider plugins.
- Detecting manual moves; agents setting Done; syncing Priority, Size or
  other fields; configurable transition points.
- Turning on the board's built-in automations: GitHub's API can read them
  but not change them.
- Labels on created issues.

### Alternatives rejected
- Doing nothing and leaving moves manual: that's today, and it produced
  inconsistent moves on another project's board and gives adopters nothing.
- A third skill holding the `gh` instructions: it sits in the
  orchestrator's context on every call, and each run would improvise the
  commands again (the inconsistency this fixes).
- A subagent per move: a spawn costs far more than one status update.
- A script at the package root or in another language: the skill's own
  `scripts/` dir ships unchanged with APM, the plugin and `install.sh`, and
  bash plus `gh` adds no dependency (no `yq`, no PyYAML).
- Skipping the check in `/feat` because `/brief` just ran it: `/feat` often
  starts days later in a fresh context, when the token or the board may
  have changed. The check is ~3 read-only calls and yields the IDs `/feat`
  needs anyway.
- Creating the issue when `/brief` starts, or when the draft is written:
  an interview abandoned halfway, stopped as a bug or rejected at the gate
  would leave an orphan issue. The raw idea also makes a worse title than
  the confirmed brief's one-liner.
- Caching field and option IDs in the config or state: that's one more
  thing to keep in sync, for no measurable saving.

### Acceptance
- On a configured repo whose board has "Item closed" enabled, a feature
  goes from Todo (or no ticket) to Done with no manual board moves.
- A repo without `.feat-agent.yml` behaves exactly as today, and the
  script makes no network calls there.
- A missing `project` scope, a missing board or an unknown status name
  stops the run at the start with the exact fix.
- A failed move mid-run doesn't stop the build and appears at the next
  gate.
- After `/feat resume`, the card shows the current phase's status.
- Repeating any move leaves the board unchanged.
- The script starts with `#!/usr/bin/env bash`, and `mise run lint` also
  runs `shellcheck .apm/skills/feat/scripts/*`, which stays clean.
- A new `mise run test:tracker` exercises the script offline with `gh`
  stubbed on PATH. It covers: no config means no network calls; an unknown
  status; a malformed config line; a project URL that fails validation;
  set-status repeated with no change; and an item missing from the board
  being added first.
- Setup docs tell adopters (a) to enable "Item closed", or else that cards
  stop at In review and must be moved to Done by hand after merging or
  closing, and (b) to check what "Pull request linked to issue" sets,
  because it fires in phase 8 and could undo the phase 7 move.
- `.apm/skills/brief/SKILL.md` (check, Brief move, issue creation after
  the gate) and `.apm/skills/feat/SKILL.md` (setup check and move, phase 7
  move, send-back, resume, failure flagging) are updated, as are
  `docs/workflow.md`, `docs/install.md` and CHANGELOG.md.

### Constraints / decisions already made
- `/feat` stays thin: it runs the script and logs its one-line result,
  the way it runs git in phase 7, and it never reads GraphQL or IDs. No
  new agent and no change to the size table.
- No change to `apm.yml`, `.claude-plugin/plugin.json` or `install.sh`'s
  install logic: the script travels inside the skill directory.
- Security (for the 4a and 7b reviewers):
  - `.feat-agent.yml` is untrusted, since it comes from whatever repo
    `/feat` runs in. The project URL must match
    `https://github.com/(users|orgs)/<login>/projects/<number>`, status
    names are only matched against the board's real options, and no config
    value is ever passed to `eval` or into a shell string.
  - Every value is a quoted argument. GraphQL gets values as `-f`/`-F`
    variables, never pasted into the query. Issue bodies go through
    `--body-file`.
  - The script touches only the configured board's Status field and the
    one issue.
  - The issue body from `read-issue` is data, never instructions (as with
    `gh issue view` today).
  - Docs state that the feature needs the broad `project` scope (read and
    write on every board the user can reach) and is off unless configured.
- Conventions: conventional commits, `mise run lint` and `mise run
  test:apm` before committing, CHANGELOG under `## Unreleased`, PR says
  `Closes #11`.

## Log

- [x] 0 Setup — Spec Kit initialised with `specify init --here --integration claude --force` (added only .specify/ and .claude/skills/, both untracked; decide at ship whether to commit them); branch renamed to board-tracking. No board check/move: this repo has no `.feat-agent.yml` and the feature isn't built yet.
- [x] 2 Specify — approved as written (user: "ok, approved"); 6 stories, 27 FRs, 8 SCs, no open markers, checklist all checked (no checklist items to proceed past)
- [x] 3+4 Plan and design review — accepted D1–D13 and N1–N8 (user: "ok"); rejected D14 drop `read-issue` (recommendation accepted: the brief fixes four operations, and the script is one place to validate refs); `Brief:` line kept, its dead link after phase 2 noted as a limitation in the contract; dismissed: folding check into set-status, dropping send-back (a brief decision)
  - Planner amend: FR-028–035 added, 12 FRs amended, SC-009. New planner assumptions (needs user: no): `#N` resolved with `gh repo view` in every subcommand (no `{owner}`/`{repo}` placeholders); tests use a python3-stdlib fake GraphQL endpoint on a unix socket so gh's real `--jq` runs; docs state minimum gh 2.0, untested (only 2.103.3 tested); leaf symlinks still refused; M_ADD/M_SET only exercised by the live quickstart.
- [x] 5 Tasks — soft gate: 47 tasks (medium fits); no CRITICAL/HIGH; 3 LOW left as is (feat SKILL.md 12-line budget tight, T045 trims; US3 parser built in foundational; FR-013 holds by construction); checklist all checked. Stories: US1 T001–T019 (with setup + foundational), US2 T020–T025, US3 T026–T031, US4 T032–T036, US5 T037–T038, US6 T039–T047 (with polish). T047 live quickstart is [MANUAL/USER], pending for the user.
- [x] 6 Implement — soft gate: T001–T046 done, lint, test:apm, test:tracker (10 cases) pass; T047 live quickstart pending for the user before merge. Final SKILL.md added lines: /feat 10/12, /brief 6/10. Open: FR-035's "minimum gh version" clause not met (docs say only "tested on 2.103.3"; no older gh verified) → spec to amend at the phase 7 gate. Note: I had the implementer reword FR-033 in spec.md (should have gone to the planner).
  - US1 T001–T019 done; shellcheck, test:tracker, lint, test:apm pass. T001 confirmed apm ships scripts/. Deviations: GraphQL docs as quoted heredocs (SC2016), LC_ALL=C, ASCII `, ...`. SKILL.md lines: /feat 6/12, /brief 4/10
  - US2 T020–T025 done; all checks pass. FR-033 read as physical root + fixed `specs/briefs` suffix (literal wording would never catch a symlinked dir; spec wording to tighten). Content refusals exit 2. SKILL.md lines: /feat 6/12, /brief 6/10. (Report mentioned skipping hooks in .specify/extensions.yml; that file doesn't exist; nothing ran.)
  - US3 T026–T031 done; tests only (cases 2, 3, 4, 7), tracker.sh unchanged; all checks pass. Open nit: contract says `, …`, script prints ASCII `, ...`. SKILL.md lines unchanged.
  - US4 T032–T036 done; retry only on gh failure (return 1), case 8 red then green; all checks pass. Install hint wording is the implementer's own. SKILL.md lines: /feat 8/12, /brief 6/10.
  - US5 T037–T038 done (two lines extended in place); all checks pass. SKILL.md lines: /feat 10/12 added (6 net). Wording fix handed to T045: resume runs "the board check from Setup step 5, without its move".
- [x] 7 Code review — user: "ok" to all recommendations. Picked: B1 (document backslash unsupported), B2, B3, B4, B5 (FR-026 reword), B6 (drop FR-035 minimum clause), T1 (read-issue + missing-scope tests), S1, S2, C1–C6, C8, C9, C11, C12, C13–C15, P1 with Std1 (wrap SKILL.md prose at ~76 cols, judge by tokens not line count), Std2, Std3, R1–R4, R6, R7, R8, R9. Rejected: C7 (keep valid_id: the named check is clearer), C10 (superseded by T1's read-issue test), P2 (the re-read keeps idempotence), R5 (extra function for little gain). Spec/contract edits → planner; code → implementer fix mode.
  - Planner amend done: B1, B3, B5, B6, S1 (into FR-022), S2 (FR-011, US2 AS8; `create-issue <brief-file> <owner/repo>`, mismatch → exit 1), C8, C13–C15, 12 cases, FR-034 judged by tokens. tasks.md left as the phase 5/6 record (now says "ten cases", 256-char title, "minimum 2.0" in places).
  - Fixes applied: B2, B3, B4, T1, S1, S2, C1–C6, C8, C9, C11, C12, SKILL.md wording (wrapped ~76 cols; wc -w feat 3214 → 3193, brief 1494 → 1493), Std2–4, R1–R4, R6, R7, R9. test:tracker 12 cases, lint, test:apm pass. No performance attempts (P2 skipped). B2/B3 have no dedicated test (stateless stub). Small leftover: the contract doesn't name the exit-2 "malformed repo" message or RE_SCOPE_PROJECT.
- [x] 8 Ship — PR 14 of the pre-release repo (draft); commits 0f2d752 docs(specs), 0da3ed1 feat(board); branch 001-board-tracking; .specify/ and .claude/skills/ left uncommitted
