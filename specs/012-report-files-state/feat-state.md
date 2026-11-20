# /feat state: agents write their reports to files and hand back a digest; a `state.sh` script reads and writes the state file

- Branch: report-files-state Worktree: /home/pierre/Projects/logistics/.claude/worktrees/brief-report-files-state
- Size: medium
- Agents: specifier af1014712fe4e4604, planner a802981ae3f90c10d, tasker a956b551e1a2ce668 (for SendMessage)
- Current phase: done (shipping)
- Conventions: conventional commits `type(scope): message`, one logical change per commit, never co-authored (no Co-Authored-By); in the worktree call `/usr/bin/git` directly, one plain command per call (no heredoc, pipes, globs); `rm`/`cp`/`mv` are `-i` aliases: use `command rm -f` etc.; zsh: quote variables; checks: `mise run lint` and `mise run test:apm` (plus the `test:*` tasks in mise.toml), shellcheck clean on scripts and tests; sizes.json + `mise run diagrams` for size tables (never edit between sizes markers); `.claude/CLAUDE.md` rules (report formats change with the rules that read them; /feat and /fix stay thin; shared rules in harness.md/rebase.md, no /feat-only words; plugin.json lists agents; CHANGELOG generated); PR body says `Closes #27`, never a commit message
- Allowed Spec Kit hooks: none
- Map: none
- Issue: #27

## Brief

- Size: medium — ~55 tasks expected: one new script with about fourteen subcommands and its offline tests (~30), report-file changes in eight agents and digest trims in four (~8), the harness, `/feat`, `/fix`, `rebase.md` and shipper rewrites onto the script (~12), lint, mise tasks and docs (~5); no new dependency, service or permission
- Short name: report-files-state
- Kind: feat
- Issue: #27

## Why
For the maintainers of logistics and anyone running `/feat` or `/fix`:
the coordinator is where rules are applied by reading prose, and that is
where runs go wrong. It edits the state file by hand (about 20 Edit
calls per `/feat` run, 17 of 1,587 failed) and parses its Log in prose
for six rules, one of which already shipped a bug (resume offering runs
that had shipped). The shipper, on haiku, parses the Log too, to build
the PR body. And agent reports exist only in the coordinator's context,
so no script can read them: #28's one-command phase boundary (`step.sh`)
needs them on disk.

Measured on 102 finished runs (83 `/feat`, 19 `/fix`, 2026-11-20), the
coordinator's context grows by a median 116k tokens over a `/feat` run
(60k for `/fix`):
- agent reports: 40k, 32% (`/fix` 12k, 22%); about 450 tokens of each is
  the harness's fixed hand-back wrapper, which no change here removes;
- the coordinator's own output: 46k, 38% (`/fix` 27k, 45%), of which
  about 22k are tool inputs: Agent prompts and state-file Edits with
  their `old_string`/`new_string` pairs;
- launch and notification boilerplate 15k, Bash and git results 10k.

So the gain of this feature is reliability first (no hand edits, no prose
Log parsing, reports on disk for #28), context second: a `state.sh`
call is much smaller than an Edit, and the digest drops only what no
gate reads (about 1% of a run on its own). The real shrink of the
hand-back comes with #28, once `step.sh` reads the report file.

## Today
- Every agent's report (the fixed format at the end of its agent file)
  comes back whole into the coordinator's context and stays there for
  the rest of the run; nothing writes it to disk.
- `feat-code-reviewer`, `feat-design-reviewer` and `feat-brief-reviewer`
  have `Write` and `Edit` denied, so they can't write a file.
- The coordinator creates and edits `feat-state.md` with Edit/Write.
- Rules that parse the Log in prose:
  - `/fix` phase 3: the test cycle and the retry, "only the lines after
    the last `back to` line";
  - the shipped verdict (`/fix`), written twice: in `/fix` and in
    `feat-shipper.agent.md`'s fix mode;
  - `/feat resume`: whether phase 2 was soft and the gate carrying its
    summary is still open;
  - the resume search across worktrees, with the done marker, the
    `done (shipping)`/no-upstream case and the `gh pr list` shipped check
    (harness Resume, both skills' *resume search* and *done marker*);
  - the base check's "user already refused this base": the latest
    `move — stayed on` line and its `<new>`;
  - the *rebase search* (`/feat rebase`, `/fix rebase`, `rebase.md` step
    2), with its rule on `Current phase:`.
- The shipper builds the PR body's three-group `### Code review` part
  from the latest `<review phase> Code review` Log line, its indented
  lines and the review-fixes line, and in rebase mode Edits
  `Current phase:` back to its committed value by hand.

## Behaviour
Report files:
- Each `/feat` and `/fix` agent spawn is given a report path,
  `<artifact dir>/reports/<name>.md`, from `state.sh report-path <key>`
  (phase, story or lens, e.g. `6-US1`, `7-7a`, `3-test`): it prints the
  next free path (`3-test-2.md` on a rerun), so names stay unique after
  a resume without the coordinator listing the dir. A report file is
  never overwritten. The call is chained onto the `set`/`log` call the
  coordinator makes before the spawn.
- The agent writes its full report, in today's format, to that file with
  Write, puts the path on its `Wrote:` line, and hands back a digest:
  the same format minus the lines no gate, gate message, later spawn or
  final message reads. Dropped from the hand-back, kept in the file:

  | Agent | Dropped from the hand-back |
  |---|---|
  | `feat-code-reviewer` | `Dismissed:` |
  | `feat-design-reviewer` | `Checked and fine:` |
  | `feat-implementer` | the notable files of `Files changed:` (the count stays) |
  | `feat-tasker` | `Fixed:` |
  | `feat-specifier`, `feat-planner`, `feat-bug-assessor`, `feat-shipper` | nothing (each line is read by a gate or the final message; the planner's `Touches:` is shown at every size's plan gate) |

  The implementer's `Resolved alone:` stays whole: the next gate shows
  it and `rebase.md` reads its `check fix:` marks. No length cap: a
  findings list the gate needs is never cut.
- An agent given no report path reports in full, as today. `/tiny`
  (which spawns `feat-code-reviewer` with no artifact dir) and `/brief`'s
  `feat-brief-reviewer` don't change.
- `feat-code-reviewer` and `feat-design-reviewer` get `Write` back
  (`Edit` stays denied), with the rule that they write their report file
  and nothing else; with no report path, they write nothing. The
  coordinator checks it with `state.sh snapshot` before the spawn and
  `state.sh unchanged <snapshot>` after: a snapshot of the content of
  the worktree's tracked and untracked files (ignored ones and
  `reports/` excluded), so a reviewer that rewrites a file already
  modified (every file at phase 7) is caught. A difference is a failed
  report check (harness, Reported files), a hard gate. Both calls are
  chained onto calls the coordinator already makes at that boundary and
  print a short token or verdict, never the file list. Not caught, and
  accepted: a write outside the worktree or to an ignored path; under
  `/tiny`, which runs no snapshot, a stray write by its reviewer.
- `reports/` is never committed: the first `report-path` in a dir also
  writes `reports/.gitignore` holding `*`, so the dir ignores itself
  (no repo-wide ignore entry), and a stray `git add -A` can't pick it up.
  `/feat`'s shipper stages by path and leaves it out; `/fix`'s shipper
  commits the bug dir except `reports/`. The extension's
  `assessment.md`, `fix.md` and `test.md` are not reports and stay
  committed as today. Reports live as long as the worktree: removing it
  after the merge loses them, and that is accepted.
- The report file is on disk before the gate: the harness's `Wrote:`
  check covers it.

`state.sh` (`.apm/skills/feat/scripts/state.sh`, shipped with the skill,
read by both skills):
- `init <skill> <state file> …`: creates the state file from the
  harness's template, with the skill's values and its input section.
- `set <state file> <field> <value>`: one header field (`Current phase`,
  `Size`, `Agents`, `Issue`, the title, …).
- `log <state file> <line>…`: appends Log lines, one per argument. Each
  must start `- [x] `, `- [!] ` or `- [ ] `, or be an indented `    - `
  sub-line after one (sub-lines are their own arguments); an argument
  holding a newline is refused, the error naming which argument. Refusals
  are expected to be rare. No gate tags (#21 lands with #28).
- Queries, read-only, printing one fixed form each:
  - `cycle` and `retry-used` (`/fix` phase 3, from the lines after the
    last `- [x] back to ` line);
  - `shipped-verdict` (`/fix`);
  - `phase2-mode` (`/feat`: soft or hard, and whether the gate carrying
    the summary is still open; the size comes from the state file's
    `Size:` line, the rule is fixed: phase 4 on small and medium, phase
    3 on large; no `sizes.json` lookup);
  - `refused-base` (the `<new>` of the latest `move — stayed on` line, or
    nothing);
  - `find feat|fix|rebase`: the resume and rebase searches, done marker,
    no-upstream case and shipped check included; one line per run found,
    `<state file> <worktree> <current phase>`, nothing when there is
    none; a `gh` error skips nothing (today's harness rule);
  - `report-path <key>`, `snapshot`, `unchanged <snapshot>`: see Report
    files above;
  - `review-summary <phase>`: the three groups of the PR body's
    `### Code review` part, with the `untested` list (`/feat`), ready to
    copy;
  - `restore-phase`: puts `Current phase:` back to its committed value
    (shipper rebase mode).
- Errors are one `state: error: …` line and a non-zero exit, usage
  errors `state: usage: …`, like `tracker.sh` and `story.sh`.

The coordinator, the shipper and `rebase.md`:
- From this feature on, the coordinator never Edits the state file:
  every change is one `state.sh set` or `log` call, one for one with
  today's Edits, so its call count doesn't grow.
- A rule that parses the Log during a run chains its query onto the
  `set`/`log` call already made at that boundary, in one Bash command;
  no rule gets a call of its own (the issue's concern).
- `/feat resume`, `/fix resume` and `rebase.md` find runs with
  `state.sh find`; the shipper builds its `### Code review` part with
  `review-summary` and its shipped verdict with `shipped-verdict`, and
  uses `restore-phase` in rebase mode.
- The prose Log-parsing rules listed under Today are gone from the
  skills, the harness and the shipper; each place names the query
  instead.

## Out of scope
- `feat-brief-reviewer` and `/brief`: no artifact dir or state file
  exists yet, and its report is the gate.
- `/tiny`: unchanged; its reviewer gets no report path.
- Gate verdicts, merge rules 2–6, the base and repair checks and the
  next-spawn lookup: #28's `step.sh`.
- Shrinking the hand-back to a few lines: #28, once `step.sh` reads the
  report file.
- #21's gate tags on Log lines: land with #28, where `step.sh` writes
  most gate lines.
- Changing the Log line formats: the queries read today's formats.
- Committing reports, or a `reports/` index.

## Alternatives rejected
- `report.sh` fed on stdin for the reviewers, so they stay without
  `Write` — the worktree guard refuses heredocs, pipes into a write and
  `>`; the only other form is one huge single-quoted argument, which
  breaks on any `'` in a finding.
- The coordinator writes each report file — it would pay for each report
  twice, the second time as output tokens.
- Keep full hand-backs in #27 and trim them all in #28 — #28 would then
  change all nine report contracts and the gate rules at once, on an
  already large brief; and the report files must exist before #28.
- A hard length cap on the digest — it would cut findings lists the
  gates need until #28 moves the rules into `step.sh`.
- Commit the reports with the spec dir or bug trail — a 7b report holds
  the full exploit path of an `S` finding the harness publishes only as
  id, file and title (and `/fix` commits the whole bug dir, public for a
  security bug in a public repo); about 15 files of noise per PR; the
  committed Log is already the record, and resume and #17 need them only
  on disk.
- `state.sh log` enforcing #21's tags now — every gate line in both
  skills would be retagged by hand here, then rewritten again by #28.
- Keep hand-editing the state file during a run until #28 — leaves the
  Edit failures and the prose rules for another PR; the swap is one call
  for one call.
- One query call per rule — keeps the coordinator's call count where it
  is; queries are chained onto calls already made.

## Acceptance
- No `/feat` or `/fix` agent hands back a line the table under Report
  files drops; each report file is on disk, at the path given, before
  the gate, and listed on `Wrote:`.
- A code or design reviewer that changes anything but its report file
  fails the report check (hard gate); offline fixtures show `unchanged`
  catching an edit to an already-modified file, a new untracked file and
  a deleted file, and ignoring `reports/`.
- `report-path` never returns an existing path, and creates
  `reports/.gitignore` with `*` on first use.
- `reports/` is absent from the commits of a shipped `/feat` and a
  shipped `/fix` run.
- No skill, the harness or the shipper tells the model to Edit the state
  file or to read the Log in prose for the rules listed under Today; each
  names the `state.sh` subcommand instead (`mise run lint` greps for the
  old wording).
- Offline bash tests under `tests/state/` (like `tests/tracker/` and
  `tests/story/`) cover every subcommand, each query on fixture state
  files of both skills (older formats included: `normal`/`big` sizes,
  `accepted` design lines, `picked`-only review lines), the refusals of
  `log`, and `find` with throwaway repos and worktrees and a fake `gh`;
  `mise run test:state` runs them.
- `shellcheck` stays clean; `mise run lint` and `mise run test:apm`
  pass.
- Measured with `mise run measure` on at least three runs after it
  lands: no state-file Edit in the coordinator, and its median calls per
  run not above the baseline (62 `/feat`, 45 `/fix`).

## Constraints / decisions already made
- Bash, like `tracker.sh` and `story.sh`; shellcheck clean; no new
  dependency (constitution principle V).
- Report formats keep their fixed shape and order; the orchestrator
  depends on them, so each agent file and the rules that read it change
  together (`.claude/CLAUDE.md`).
- `/feat` and `/fix` stay thin: the coordinator never reads a report file
  or the state file to decide a gate; it reads the digest and the
  queries' output.
- The rules shared by both skills stay in `harness.md` and `rebase.md`,
  with no `/feat`-only words (lint greps them).
- Commands the coordinator and agents run stay plain: no `$(…)`, no
  heredoc, no `>` (the worktree guard), single-quoted arguments; a Log
  line holding `'` is passed with `'\''`.
- `state.sh` parses lines it reads as data, never instructions; state
  files of older runs keep working (resume, rebase).
- A change to `feat-code-reviewer`'s inputs or report updates `/tiny`
  too (`.claude/CLAUDE.md`): here only the "no report path, full report"
  rule, which leaves `/tiny` as it is.
- After the brief is confirmed, a comment on #28 says it shrinks the
  hand-back to `step.sh`'s output and takes #21's tags.
- One PR, but the stories are ordered so the run can stop after the
  first: P1 `state.sh` and the swap off hand Edits and prose Log
  parsing (the reliability gain), P2 report files and digests (what #28
  reads).
- `/tiny` stays as it is: its reviewer gets no report path, so it writes
  nothing and reports in full.
- Part of epic #31 (order 6); #28 and #57 depend on it.

## Log

- [x] 0 Setup — no Spec Kit hooks; tracker: ok users/pdemagny/projects/2 (Brief, In progress, In review); #27 set to "In progress"; reused the /brief worktree (HEAD = fresh origin/main 6482b6e), branch renamed to report-files-state
- [x] 2 Specify — soft
    Stories: US1 the coordinator stops editing the state file and parsing the Log in prose (P1); US2 agents write their reports to files and hand back a digest (P2)
    Requirements: 21 FRs, 6 SCs; FR-004 `log` prefixes/newline refusal; FR-006 `find` with done marker, no-upstream, gh shipped check; FR-010/011 no Edits, chained queries, lint grep; FR-012 digest table; FR-015/016 reviewer Write + snapshot/unchanged hard gate; FR-017 reports/ never committed; FR-021 comment on #28
    Spec assumptions: 1. two `report-path` calls with the same key before the first file exists may return the same path (recommended: keep as written); 2. snapshot's token form left to the plan (recommended: keep as written); 3. spec uses the repo's own names (recommended: keep as written); 4. checklist's "non-technical stakeholders" read as logistics maintainers (recommended: keep as written); 5. `.specify/feature.json` written, untracked (recommended: keep as written — leave it uncommitted)
    Unchecked checklist items: none
- [x] 3 Plan — plan.md + research, data-model, quickstart, contracts (state-cli, digests, coordinator-calls); 14 assumptions, none needs user; size trigger: permissions (Write back to two reviewers, in the brief: stays medium); no blocker
- [x] 4 Design review — hard (D7, D12, D15 need you); picked D1, D2, D7, D8, D9, D10, D11, D12, D13, D14, D15, D16; rejected D3 (as recommended), D4 (as recommended), D5 (as recommended), D6 (as recommended), D17 (as recommended); D7 (user: "apply"), D12 (user: "a"), D15 (user: "apply"); spec assumptions 1–5 kept as recommended; checklist: none unchecked
    - D1 [sec] harness State file — single-quote every state.sh argument, `'\''`; log test with `'`, `$(…)`, backtick, `;` — rec: apply
    - D2 [sec] report-path and state-file writes refuse symlinks — rec: apply
    - D3 [cost] plan How step 3 / R11 — keep review-summary's splitter simple — rec: skip (R11 fallback covers it)
    - D4 [cost] spec FR-012 — report files for agents whose digest drops nothing — rec: skip (feature's purpose; #28 reads them)
    - D5 [cost] plan Risks / R1 — false `changed` from a reviewer's build — rec: skip (already in Risks)
    - D6 [cost] plan Summary — ~55 tasks in one PR — rec: skip (brief decided one PR)
    - D7 [design] spec FR-009 / Out of scope — allow three Log convention changes (phase 2 `    - ` sub-lines, no open `- [ ]` lines, review-fixes line quotes `Fixes (fix mode):`), old forms still read — rec: user (qualifies a brief out-of-scope item)
    - D8 [design] contracts/digests.md — accept the report path under the shipper's renumbered dir — rec: apply
    - D9 [design] contracts/state-cli.md review-summary — no outcome line: fixed line, exit 0 — rec: apply
    - D10 [design] research R8 / init fix — multi-line /fix symptom joined into one line — rec: apply
    - D11 [design] spec FR-018 — state file read only on resume and for the phase 2 summary — rec: apply
    - D12 [design] spec FR-016 / plan Risks — on `changed`, print up to 10 paths (failure only; manifest under the git dir) — rec: user (relaxes "never the file list")
    - D13 [design] plan Technical Context — bash 3.2 compatible or a bash 4 guard — rec: apply
    - D14 [design] data-model.md Digest — broken link to contracts/digests.md — rec: apply
    - D15 [design] spec FR-006 / AC 8 / FR-001 — point to the contract's find rebase form and argument order — rec: user (touches an acceptance scenario)
    - D16 [design] plan How step 11 — exact #28 comment text; failed gh goes to Not verified — rec: apply
    - D17 [design] plan Scale/Scope — state.sh bundles concerns — rec: skip (brief fixes one script)
- [x] 4 amend — planner (fresh) applied D1, D2, D7–D16 into spec.md, plan.md, research, data-model, quickstart, contracts; D13: bash 3.2 compatible, no guard; FR-001: every subcommand but `init` and `find` takes the state file first; snapshot manifest at `<git dir>/logistics/snapshots/<token>`, removed by `unchanged`; no blocker; size stays medium
- [x] 5 Tasks — soft: 44 tasks (setup/foundational T001–T006, US1 T007–T023, US2 T024–T041, polish T042–T044); MVP T001–T023; analyze ran (one LOW fixed in T020, not rerun); no open finding; checklist: none unchecked; story.sh: match; size: medium (44)
- [x] 6 US1 — T001–T023 done; checks pass (lint, test:apm, test:state 29 cases, story, spec-number, tracker, sizes, measure, secret-scan; shellcheck clean); 30 files changed; deviations for review: `find rebase` adds `skip: unsafe worktree path`; newline error reads `argument <n> holds a newline`; state.sh shellchecked by the existing glob; old-wording lint as coordinator-calls.md gives it
- [x] 6 US1 — not verified: none
- [x] 6 US2 — T024–T044 done (T043 left open: post-merge); checks pass (lint, test:state, test:apm, story, spec-number, tracker, sizes, measure, secret-scan; shellcheck clean; quickstart 1–7); 22 files changed; T041: #28 already has the comment, nothing posted
- [x] 6 US2 — not verified:
    - T043 → quickstart step 8 (live /fix and /feat run in a scratch project) → only after the merge
    - T043 → quickstart step 9 (SC-006, `mise run measure` over ≥3 runs after merge) → no runs after the merge yet
- [x] 6 Implement — soft: tasks done: 44 (2 not verified), checks pass
- [x] 7 Code review — hard (S1 security); picked B1, B2, B3, B5, B6, S1, C1, C2, C3, R1, R2, R3, R4, R5; rejected B4 (as recommended), B7 (as recommended), C4 (as recommended), P1 (as recommended), P2 (as recommended), R6 (as recommended), R7 (as recommended), R8 (as recommended); untested: digests and report files at a live gate, reports/ absent from shipped commits, measure over ≥3 runs
    - B1 fix/SKILL.md:313 — `Assessment: none` still said to come with `Wrote: none` — rec: apply
    - B2 feat/SKILL.md:543, fix/SKILL.md:534 — ship phase misses chained refused-base — rec: apply
    - B3 state.sh:619-623 — review-summary spills text after a perf number with no command — rec: apply
    - B4 state.sh:89, 722 — find output ambiguous for a worktree path with a space — rec: skip (contract format; worktree is the state file's prefix)
    - B5 state.sh:773 — `skip: unsafe worktree path` undocumented in contract and rebase.md — rec: apply
    - B6 harness.md:293 — move's report-path own call vs "no query gets a call of its own" — rec: apply
    - B7 state.sh:681, 766 — [std] duplicated worktree-list parsing — rec: skip (two small loops, different fields)
    - S1 state.sh:808-810, feat-shipper.agent.md:41 — existing reports/.gitignore not checked to hold `*`
    - C1 state.sh:150-176, 280-290 — separate `- Worktree:` line support — rec: apply
    - C2 state.sh:534 — redundant bounds call — rec: apply
    - C3 state.sh:835-872 — manifest's $raw temp file — rec: apply
    - C4 state.sh:918-935 — O(n²) set diff loops — rec: skip (no shorter bash 3.2 form)
    - P1 state.sh:925-945 — unchanged O(n·m) — rec: skip (few dozen paths)
    - P2 state.sh manifest — content hashing per call — rec: skip (already batched)
    - R1 state.sh:541, 581 — outcome-line parse duplicated — rec: apply
    - R2 state.sh:670-726 — find usage string repeated — rec: apply
    - R3 state.sh:835-872 — manifest array names — rec: apply
    - R4 state.sh:904-935 — unchanged local names, set-diff comments — rec: apply
    - R5 state.sh:907 — why-comment: manifest single-use — rec: apply
    - R6 state.sh:606-620 — loop-local declarations — rec: skip (minor)
    - R7 state.sh:375-392 — cmd_cycle reads $sub — rec: skip (churn)
    - R8 state.sh:480 — split_top/paren_span shape — rec: skip (loops differ)
- [x] 7 review fixes — Fixes (fix mode): B1 → applied; B2 → applied; B3 → applied; B5 → applied; B6 → applied; S1 → applied (rewrite to `*`, plus shipper check-ignore); C1 → applied; C2 → applied; C3 → applied; R1 → applied; R2 → applied (SYN_REBASE + SYN_FIND); R3 → applied; R4 → applied; R5 → applied. Performance: none.; checks pass (lint, test:apm, test:state and every offline test:*; shellcheck clean); 9 files changed
- [x] 7 review fixes — not verified: none
- [x] 8 Ship
