# Research: Report files and a state script

Every decision below is one the spec left open or that the code forced.
Alternatives the brief rejected (report.sh on stdin, coordinator-written
reports, a length cap, committed reports, tag enforcement, keeping hand
edits until #28, one call per query) are not reopened.

## R1. The snapshot token (spec assumption 2)

- **Decision**: `snapshot <state file>` prints 12 lowercase hex characters:
  the start of `git hash-object --stdin` over a manifest. The manifest has
  one record per path that `git status --porcelain=v1 -z
  --untracked-files=all --no-renames --ignore-submodules=all` lists (run at
  the worktree's top level), minus every path under `<artifact
  dir>/reports/`, sorted bytewise (`LC_ALL=C`), each record `<path> TAB
  <blob id of the worktree file | "deleted" | "link:" + its target>` and
  NUL-terminated. Blob ids come from one `git hash-object --no-filters
  --stdin-paths` call. `snapshot` also saves the manifest to `<git
  dir>/logistics/snapshots/<token>` (per worktree: `git rev-parse
  --git-dir`; outside the worktree, so `git status` never sees it).
  `unchanged <state file> <token>` recomputes it and prints `unchanged`,
  or `changed` followed by the paths whose record differs between the
  saved and the new manifest (`- <path>`, sorted, at most 10, then `-
  and <n> more`), exit 0 for both; it removes the saved manifest after.
  With no saved manifest it prints `changed` and a fixed "paths unknown;
  see git status" line.
- **Rationale**: `git status` already lists exactly "tracked and changed,
  plus untracked, minus ignored", so clean tracked files never need
  hashing (fast on large repos) and a reviewer that touches a clean file
  makes it appear in the list. Hashing the content of every listed path
  catches the case the spec calls out: a rewrite of a file that was
  already modified (every file at phase 7). A deleted file changes its
  record; a reverted file drops out of the list; both change the token.
  Index-only changes (`git add -N`) don't matter: the content is hashed,
  not the index. `--no-filters` keeps clean filters (LFS and the like)
  from running. Twelve hex characters are enough for an equality check
  within one run and stay short in the coordinator's context.
- **Alternatives considered**: hashing every tracked file (slow on large
  repos, no gain); `git stash create` (ignores untracked files, writes
  objects); a file list in the token (long, and printed on success too);
  no list at all (the user then has to work out from `git status` which
  of many already-modified files moved; the bounded list on failure only
  was the user's choice at the design review); `cksum` or `sha1sum` (not
  on every platform with the same name; git is already required).
- **Known limit**: a reviewer whose test or build run leaves an
  untracked, non-ignored file, or rewrites a tracked file (a golden or
  snapshot file, a lockfile), makes the token differ: a hard gate whose
  "What you should know" lists those paths, so the user sees at once
  whether they are build or test outputs. Build outputs are normally
  ignored; this is the cost of the spec's "untracked files" rule.

## R2. When snapshot and unchanged run

- **Decision**: one `snapshot` per batch of reviewers spawned together
  (phase 4's reviewers, phase 7's `7a`–`7d` or both small groups, `7e`
  alone, `/fix` phase 4's reviewers), taken right before the spawns and
  after the base check; `unchanged` once every reviewer of the batch has
  reported and passed its `ls -d` check, chained onto the last `ls -d`
  call, before any other state-file change. When the base check ran a
  move, the snapshot is taken again after the move (chained onto the
  move's `log` call). The state file is part of the snapshot: the
  coordinator writes nothing between the two calls.
- **Rationale**: per-reviewer checks can't tell which of several parallel
  reviewers wrote a file; a batch check can, by failing the batch, and the
  gate is hard anyway. Keeping the state file in the snapshot keeps the
  spec's "tracked and untracked files" literal and catches a reviewer that
  overwrites it.
- **Alternatives considered**: excluding the state file (a reviewer could
  rewrite it unseen); one snapshot per reviewer (parallel writes are
  indistinguishable).

## R3. Report paths: where the key comes from and what `report-path` needs

- **Decision**: `report-path <state file> <key>`; only the state file's
  directory is used (the artifact dir), and the state file need not exist
  yet. Keys match `^[A-Za-z0-9][A-Za-z0-9+_-]{0,63}$`. Each skill lists
  its keys as a harness value, *Report keys* (`/feat`: `2-specify`,
  `3-plan`, `4-<lenses>`, `5-tasks`, `6-US<n>`, `7-<lenses>`, `7-fixes`,
  `8-ship`; `/fix`: `1-assess`, `2-fix`, `3-test`, `4-<lenses>`,
  `4-fixes`, `5-ship`; both: `move`, `ship` in `rebase`), lenses joined by
  `+` (`7-7a+7b`). The path printed is absolute. A continued agent (a
  `SendMessage` asking for a new report) gets a fresh path too, from the
  same key (`3-plan-2.md`).
- **Rationale**: every other subcommand takes the state file first, so the
  coordinator never names the artifact dir separately; the harness can't
  hold phase numbers (lint), so keys live with each skill. A continued
  agent would otherwise rewrite its first report, which the spec forbids.

## R4. Creating the `/feat` state file before the specifier

- **Decision**: `/feat` phase 2 runs `init` (and the setup Log lines and
  the specifier's `report-path`) in one call before the specifier spawn,
  instead of after its report. The brief is still deleted only after the
  specifier reports, under today's rule. `speckit-specify` creates the
  feature dir with `mkdir -p`, so an existing `specs/<short-name>/`
  (holding `feat-state.md` and `reports/`) is no obstacle.
- **Rationale**: the specifier needs a report path and the state file is
  the only anchor `report-path` has; chaining it onto `init` costs no
  call. Side effect: a run that dies in phase 2 is now found by `resume`
  (phase `2 Specify`, a fresh specifier), where today it was lost.
- **Alternatives considered**: a separate `report-path` call before the
  spawn (one more call per run); an artifact-dir argument (a second
  calling form for one spawn).

## R5. Open `- [ ]` Log lines

- **Decision**: the coordinator no longer writes `- [ ] <N> <phase>`
  lines; the open phase is the header's `Current phase:`. `log` still
  accepts the `- [ ] ` prefix (FR-004) and never rewrites a line. The
  harness template drops its `- [ ] <N> <phase>` example.
- **Rationale**: today the open line is turned into `- [x] …` by an Edit;
  an append-only `log` can't, and no rule reads the open line (resume
  reads `Current phase:`, `phase2-mode` looks for a closing `[x]` line).
  Dropping it makes each phase end one `log` call, one for one with
  today's Edit. A state file of an older run keeps its stale `[ ]` line;
  every query skips it.
- **Alternatives considered**: `log` replacing a matching open line
  (a second write mode, in-place edits in the middle of the Log).

## R6. Header, input section and Log boundaries

- **Decision**: the header is every line before the first line starting
  `## `; `set` changes the first `- <Field>: ` line there and nothing else.
  The Log is every line after the last line equal to `## Log`. The input
  section (a brief copied with its own `## Why`, `- Size:` lines) lies in
  between and is never read by a query.
- **Rationale**: this very feature's state file has `- Size: medium — …`
  inside `## Brief`; a naive first-match would rewrite the brief. The Log
  is the last section by construction.

## R7. The template lives in `state.sh`, checked against the harness

- **Decision**: `state.sh` writes the header fields in the harness
  template's order (Branch/Worktree, Size, Agents, Current phase,
  Conventions, Allowed Spec Kit hooks, Map, Issue). The harness keeps its
  template block as the description every agent reads, and
  `tests/state/run.sh` fails when the field names of `init`'s output and of
  the harness block differ.
- **Rationale**: reading the template out of `harness.md` at run time would
  make the script parse prose; the test keeps one shape (principle III)
  the way `sizes.py --check` keeps the size tables.

## R8. `init`'s calling forms

- **Decision**: `init feat <state file> <brief file> [<Field>=<value>]…`
  (the title from the brief's `# Brief: ` line, the brief's other lines
  copied under `## Brief`) and `init fix <state file> <title> <report>
  [<Field>=<value>]…` (the report text under `## Report`). Branch, Size and
  Current phase are required; the other fields default to `none`. The
  parent dir is created; an existing state file is an error.
- **Rationale**: a brief is long and full of `'`; passing its path keeps the
  command plain. `/fix`'s input is the argument as given, short. Like every
  argument, `<report>` can't hold a newline, so the coordinator joins a
  multi-line symptom's lines with spaces before the call and `## Report`
  holds that one line (the `/fix` input-section value and setup step 7
  say so).

## R9. Output and exit conventions

- **Decision**: like `story.sh`: everything on stdout, nothing on stderr;
  exit 0 ok, 1 `state: error: …`, 2 `state: usage: …`. `init`, `set`,
  `log` and `restore-phase` print nothing on success, so a chain prints
  only its queries. Queries print bare values (a path, a token, a word);
  `refused-base` and `find feat|fix` print nothing when there is nothing.
  Writes go to a temp file in the same dir, then `mv -f`, so a failed call
  leaves the file as it was.

## R10. `find`'s searches

- **Decision**: `find feat|fix` reads `git worktree list --porcelain` from
  the current dir, globs `specs/*/feat-state.md` (feat) or
  `.specify/bugs/*/feat-state.md` (fix) in every listed worktree, and keeps
  a run unless: its `Current phase:` starts with `done` (except `done
  (shipping)` when `refs/heads/<branch>` exists and `git for-each-ref
  --format='%(upstream)'` prints an empty line), or `gh pr list --head
  <branch> --state all --json state --jq '.[].state'` prints `MERGED` or
  `CLOSED` and no `OPEN` (a `gh` error keeps the run). Lines are sorted
  most recent first (bash `-nt`, portable). `find rebase <skill> <default>
  <branch>` does `rebase.md` step 2 for one PR branch (fetch, the added
  state file, its shape, its size and phase) and prints `<state file>
  <worktree | none> <size> <current phase>` or `skip: <reason>` with
  today's reasons.
- **Rationale**: a branch ref that no longer exists (a merged run whose
  branch was deleted) is not "a branch with no upstream yet": today's rule
  says `for-each-ref` prints an empty line, which a missing ref doesn't. So
  committed `done (shipping)` copies in the main checkout are skipped
  without a `gh` call. The rebase search needs the size for the move's row
  and its skip reasons for the final message, so it prints both; the
  resume searches keep the spec's three fields.
- **Alternatives considered**: one `gh` call per state file found (slow
  on a repo with many shipped runs); dropping rebase's skip reasons
  (today's final message names them).

## R11. `review-summary` and the review-fixes Log line

- **Decision**: `review-summary <state file> <phase>` reads the latest
  `- [x] <phase> Code review — ` line holding an outcome (`auto-applied`,
  `picked`, `none picked`; a leading `soft gate: ` or `hard gate: ` is
  skipped), its sub-lines (finding text by id) and the `<phase> review
  fixes`, `<phase> Code review fixes` and `<phase> implementer` lines after
  it. From those it finds `<id> → reverted (<why>)` and `performance:
  <id>: <before> → <after> (<command>)`. To make them findable, the skills
  now say what the review-fixes Log line carries: the implementer's
  `Fixes (fix mode):` value as reported.
- **Rationale**: the gate line and its sub-lines already have a fixed
  grammar (harness, Review findings); the review-fixes line never had one
  ("log its report"), so reverted fixes can only be found when the line
  quotes the report's fixed `Fixes` format. Older free-form lines give no
  reverted fix: every applied id stays applied.

## R12. Malformed or hostile values read from a state file

- **Decision**: values read from a state file are matched against fixed
  patterns before use: `refused-base` prints only a 7–40 hex `<new>`
  (else nothing); `find` uses a `Branch:` only when it matches
  `^[A-Za-z0-9._/-]+$` and `git check-ref-format --branch` accepts it (else
  no git or gh call for it: the run is kept, a `done (shipping)` one
  skipped); paths holding a newline, `'`, `$` or a backtick are skipped by
  `find` and refused by `report-path`. Nothing read is evaluated.
  No write follows a symlink: `init`, `set`, `log` and `restore-phase`
  refuse a state file that is one, and `report-path` refuses a symlinked
  `reports/`, `.gitignore`, or candidate path, each with `state: error:
  <path> is a symlink` (`tracker.sh`'s leaf-symlink rule). In the
  coordinator's calls every argument is single-quoted, report and user
  text never outside quotes.
- **Rationale**: the coordinator pastes these values into later commands
  (`git merge-base --is-ancestor origin/<default> <new>`, EnterWorktree);
  the harness's path rule already refuses those characters. A symlink
  planted in the artifact dir would otherwise let a write land outside
  the worktree.

## R13. Old wording lint

- **Decision**: one line in `mise.toml`'s lint that joins both skills,
  `harness.md`, `rebase.md` and `feat-shipper.agent.md` into one line
  (`tr`, so a phrase wrapped across lines still matches) and fails when
  `grep -Eq` finds any of:
  `after the last .back to`, `latest phase 2 line`, `latest .move — stayed
  on`, `latest .7 Code review. line`, `Edit it back`, `gh pr list --head`,
  `git grep -h`, `(write|set) .(Current phase|Size|Issue):`, `anything but
  the \*state file\*`. Each is a phrase of today's prose rules or hand
  edits that the new text does not use.

## R14. SC-006 measurement

- **Decision**: no change to `measure.py`. After merge, three runs are
  measured with `mise run measure -- --since <merge date>` for calls per
  run; "no state-file Edit" is checked in the same runs' transcripts
  (quickstart step 9). The spec asks for the measurement, not for a new
  `measure.py` view.
