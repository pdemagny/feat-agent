# Research: /feat and /fix keep their run on the current main

Decisions the spec left to planning, each with what was weighed. Brief
decisions ("Constraints / decisions already made", "Alternatives
rejected" in [feat-state.md](feat-state.md)) are not reopened. The design
review's accepted findings (D1–D21, Log of feat-state.md) are folded in
where they apply.

## R1. Detecting that main moved: git, no stored base

- **Decision**: the coordinator runs `git fetch origin <default>` then
  `git merge-base --is-ancestor origin/<default> HEAD`. Exit 0: main has
  not moved past the branch's base. Exit 1: it has. The last base is
  `git merge-base HEAD origin/<default>`; every move's old and new base
  are written on its Log line (FR-020).
- **Rationale**: before ship nothing is committed, so HEAD *is* the base;
  after ship the merge-base is. Both are git facts, so no `Base:` field
  has to be added to the state file template, kept in sync, or trusted
  after a crash. Two plain commands, no `$(…)`, exit code only: the
  coordinator reads nothing (FR-002, FR-011). The spec's assumption reads
  the same way (D13: "the last base is the merge-base"); the check itself
  never reads the Log, except after a refusal (R13).
- **Alternatives**: a `- Base: <sha>` header line (one more value written
  at setup and every move, drifts if a move dies midway); comparing
  `git rev-parse` outputs (needs the coordinator to hold and compare SHAs).

## R2. Carrying uncommitted work: one WIP commit, intent-to-add listed in its body

- **Decision**: when `git status --porcelain` is not empty, the agent
  lists the intent-to-add files with `git diff --name-only
  --diff-filter=A` (an `add -N` entry shows in the worktree diff as a new
  file; untracked and fully staged files don't), then `git add -A` and
  `git -c commit.gpgsign=false commit --no-verify -m "logistics-wip:
  <branch>" -m "intent-to-add:" -m "<path>" …` (one `-m` per path). After
  the rebase: `git reset HEAD~1` (mixed: content kept, index back to the
  new base, so files that were untracked are untracked again), then
  `git add -N` each listed path.
- **Rationale**: FR-005/FR-006, no stash (brief). `git add -A` respects
  `.gitignore`, so ignored files never enter the commit and are never
  touched by the rebase. The list lives in the commit, so a repair after a
  crash (R3) can restore it without any other file. `--no-verify` and no
  signing: the commit is local, temporary, and never pushed (R19); a
  project's pre-commit hook would otherwise run its linters on half-done
  work and refuse it, and signing can prompt.
- **Alternatives**: `git stash` (rejected in the brief: shared stack);
  writing the lists to a file in the git dir (needs a shell redirect,
  refused by the worktree guard); restoring fully staged files too (no
  phase stages before ship except `add -N`; they come back as unstaged
  changes with their content intact; noted in data-model.md).

## R3. One ref marks a move in progress, and repair finds a lone WIP commit too

- **Decision**: right after the WIP commit (or at once when the tree was
  clean), the agent runs `git update-ref refs/logistics/pre-move/<branch>
  HEAD`. Undo is `git reset --hard <ref>`, then, when the ref's commit is
  a WIP commit, `git reset HEAD~1` and the `add -N` restore. The ref is
  deleted (`git update-ref -d`) when the move ends, kept or undone. The
  coordinator's repair check is two plain commands: `git rev-parse -q
  --verify refs/logistics/pre-move/<branch>` and `git log -1
  --format=%s`; the ref, or a `logistics-wip:` subject at HEAD without
  it (a crash between the WIP commit and `update-ref`, D4), sends the
  agent to `Action: repair`, which undoes the WIP commit the same way.
- **Promise** (D21): an undo or repair restores the tracked content and
  the index as they were; untracked files a check created during the move
  may remain (`reset --hard` leaves untracked files alone), and are never
  committed by the move.
- **Rationale**: one undo target whatever the state: mid-rebase, rebase
  finished but WIP not undone, checks half-run. Refs live in the common
  git dir, so the branch name keeps parallel runs apart; fetch and push
  never touch the `refs/logistics/` namespace. Repair is idempotent:
  running it twice lands on the same tree. Checking the subject closes
  the one window the ref leaves open (FR-013, FR-029).
- **Alternatives**: the reflog (ambiguous after several moves, needs
  reading); checking `rebase-merge` dirs (misses "rebase done, WIP not
  undone"); `git rerere` (records resolutions, does not undo; not adopted
  for now).

## R4. A move that needs the user is undone before the report

- **Decision**: the agent goes through the whole rebase, resolving the
  "keep both sides" conflicts alone and applying its own recommendation
  to every other conflict so it can go on, runs the checks, then, if any
  item needs a decision, undoes the whole move (R3) and reports every item
  at once. The coordinator's hard gate then sees a worktree on the old
  base. Any answer but a refusal or "stop" goes to a fresh rebase-mode
  spawn with `Decisions:`, one line per item, `<file> — <the accepted rec
  | the user's words>`; on "ok" the coordinator copies each item's rec
  (D11). On a refusal or "stop", nothing has to be undone.
- **Rationale**: FR-012 and SC-006 hold by construction; the worktree is
  never left mid-rebase while the user takes an hour to answer; the user
  sees every item of the move in one gate, with whether the checks pass
  with the recommendations. The cost is one more implement-row spawn per
  answered gate, on the rare move that needs one. A fixed `Decisions:`
  shape lets the agent match each answer to its item without guessing.
- **Alternatives**: leave the rebase stopped at the gate (a run "stop"ped
  there sits mid-rebase; an agent must abort it on refusal, breaking
  FR-011 if the coordinator does it); keep the tentative result and reset
  on refusal (needs a repair spawn on every refusal, and the user's
  "keep main's side" would need a second spawn anyway).

## R5. Who pushes a shipped run: the shipper, in a rebase mode

- **Decision**: `/<skill> rebase` runs `feat-implementer` (rebase mode,
  `Shipped: yes`: rebase, resolve, full checks) then `feat-shipper`
  (rebase mode). The shipper's order (D6): fetch; commit the state file's
  Log lines alone as `docs(specs): log rebase onto <short sha>` (its
  `Current phase:` line set back to the committed value first, so the
  local done mark is never committed); rebase onto the fetched main;
  spec-number check (`/feat`); the pre-push checks of R19; the lease
  push; the PR body note. A blocked git or gh in this mode is `PR:
  blocked` with an error `!` line, never a command for the user (it would
  be the force-push; D15).
- **Rationale**: FR-021 words the exception as the shipper's ("never
  force-push, except `--force-with-lease` on the run's own branch in
  rebase mode"); the shipper already holds the spec-number script, the
  push and the `gh` PR commands, and runs on the ship row (haiku), so the
  push costs no Opus tokens. Committing before the rebase means the
  rebase never starts on a dirty state file. The implementer still never
  commits for real and never pushes.
- **Alternatives**: the implementer pushes (a second agent gaining push
  and force-push; FR-021 would no longer be one rule in one file);
  committing after the rebase (the rebase would run with the state file
  dirty).

## R6. The lease names the PR head the run started from; a refused push puts it back

- **Decision**: `git push --force-with-lease=<branch>:<headRefOid> origin
  <branch>`, `<headRefOid>` read by the coordinator from `gh pr view` when
  it picked the target, and passed to both agents. Refused, or a rebase
  conflict in the shipper's rebase mode: `git reset --keep <lease>`, so
  the local branch is the PR head again and the next `rebase` starts
  clean (D7). The shipper's `gh pr view` and `gh pr edit` take the PR
  URL, never the bare number (D3).
- **Rationale**: a bare `--force-with-lease` compares with
  `origin/<branch>`, which any later `git fetch origin` (an agent's, an
  editor's) silently updates, making the lease protect nothing. An
  explicit expected SHA refuses the push if anyone pushed to the PR since
  the rebase started (edge case: nothing overwritten, reported). At that
  point everything local-only on the branch was made by this move (R11
  refuses a move from a branch ahead of the PR head), so the reset drops
  nothing else; `--keep` rather than `--hard` keeps any uncommitted change
  the user left in the worktree, and refuses instead of overwriting one.
- **Alternatives**: bare `--force-with-lease` (above);
  `--force-if-includes` (relies on the reflog of the remote-tracking ref;
  same failure mode after a fetch); leaving the rewritten branch in place
  (the next `rebase` would meet a diverged branch and ask the user).

## R7. A shipped `/feat` run is any `/feat` state file on the user's open PR

- **Decision** (D10, replacing the first plan's phase 8 reorder): no
  change to `/feat` phase 8, its *Current phase values* or its *done
  marker*. `/feat`'s *rebase search* accepts `specs/<slug>/feat-state.md`
  whatever its `Current phase:` on an open same-repo PR by the user: the
  shipper commits the state file before phase 8 marks it done, and only
  the shipper opens the PR. `/fix` keeps its committed `done (shipping)`
  and its search requires it. When `rebase` enters a worktree whose state
  file is not marked done (a recreated one), it writes `Current phase:
  done (PR #<n>)` in the local copy, as phase 8 does, so `resume` skips
  the run; the shipper sets that line back before its Log commit (R5),
  and the coordinator writes it again after the shipper's report.
- **Rationale**: no extra command or exception, no rollback on a failed
  ship; one place (the rebase search) knows how a `/feat` run looks once
  shipped. The local-only done mark matches today's `done (PR #N)` in both
  skills.
- **Alternatives**: phase 8 marks `done (shipping)` before spawning the
  shipper, with an upstream check in the done marker (an extra command,
  a rollback on an error line, and a widened FR-016 for older PRs);
  accepting only a done marker (no `/feat` PR would match).

## R8. The shipper's conflict report, and the second spawn

- **Decision** (D12): step 4's rebase conflict: list the files with `git
  diff --name-only --diff-filter=U`, `git rebase --abort`, push nothing,
  report `PR: conflict` and a new `Conflicts:` line. The coordinator runs
  the rebase mode (`Shipped: no`: the commits are local), then spawns the
  shipper again as the first time: the dir is numbered and the work
  committed, so steps 1 and 3 have nothing left to do. The move's Log
  line is written after that shipper's report, in the local state file
  only, and the final message lists the move. No fixup, no autosquash for
  it.
- **Rationale**: FR-014, FR-020, FR-023; a third `PR:` value keeps
  `blocked` meaning "the user has a line to read", and the new line is the
  only format change. Writing the Log line after the push keeps the
  shipper's input and history unchanged.
- **Alternatives**: folding the Log line into the `docs(specs)` commit
  with `--fixup` and `--autosquash` (a second path in the shipper for a
  rare case); a separate `docs(specs)` commit for it (noise in the PR);
  `PR: blocked` with a `! conflict: …` line (prose to parse).

## R9. Finding shipped runs: validated JSON first, then git on the fetched branch

- **Decision** (D1, D2, D3, D9): once, `gh repo view --json
  nameWithOwner` and `gh api user --jq .login`. Targets: `gh pr view
  '<arg>' --json number,url,state,author,headRefName,headRefOid,isCrossRepository,mergeable`
  or, with no argument, `gh pr list --state open --author @me --limit
  1000 --json …` with the same fields, kept to `CONFLICTING` (an
  `UNKNOWN` asked again once, else left out: spec assumption). Before any
  other git command, from the JSON alone: forks dropped; a URL whose
  owner/repo is not `nameWithOwner` skipped ("PR of another repository");
  a branch name with a character outside `[A-Za-z0-9._/-]` skipped; an
  explicit PR whose `author.login` is not the user stops at a hard gate
  naming the author; then `git check-ref-format --branch`. Survivors:
  `git fetch origin -- '<default>' '<branch>'`, the state file from `git
  diff --name-only --diff-filter=A 'origin/<default>...origin/<branch>' --
  '<rebase search glob>'` (exactly one path, of the expected shape and
  character set), then `git grep -h -E -e '^- Current phase: ' -e '^-
  Size: (small|medium|large)$' 'origin/<branch>' -- '<path>'` for the two
  lines the coordinator needs. Every PR-derived value single-quoted, `--`
  before refs and paths where the command takes it.
- **Rationale**: as `.apm/skills/feat/scripts/spec-number.sh` already
  reasons, `gh pr list` stops at 30 PRs by default and `gh pr view --json
  files` at 100 files, so neither may decide what is found: `--limit
  1000` and the diff of the fetched branch see everything. Filtering the
  JSON first means a fork's, a stranger's or a malformed branch name never
  reaches git, a worktree path or an agent prompt. The anchored `Size:`
  pattern skips the brief's own `- Size: medium — …` line and refuses a
  size that would pick no column.
- **Alternatives**: `gh pr view --json files` (capped at 100);
  `git show origin/<branch>:<path>` (the whole state file in the
  coordinator's context, per PR); scanning branches by name (branch names
  are free-form).

## R10. Entering or recreating the worktree

- **Decision**: the worktree whose `branch refs/heads/<branch>` line
  `git worktree list --porcelain` prints; else `git worktree add --
  '<repo root>/.claude/worktrees/<branch>' '<branch>'` (git creates the
  local branch tracking `origin/<branch>` when none exists), then
  `EnterWorktree` with `path`; then the local done mark (R7). A worktree
  outside `.claude/worktrees/` is entered the same way when the session
  starts outside a worktree; otherwise the coordinator says so and skips
  that PR (EnterWorktree refuses it).
- **Rationale**: brief constraint (EnterWorktree creates new branches
  only); the DWIM form needs no `-b`/`--track` variants; the branch name
  was validated (R9) before it becomes a path.

## R11. A shipped run's local branch must be the PR head, or behind it

- **Decision** (D7, D21): in `Shipped: yes`, the agent fetches the PR
  branch, makes its WIP commit and sets the pre-move ref first, then
  compares the branch tip (before the WIP commit) with the lease: an
  ancestor of it (equal or behind, e.g. a suggestion committed on GitHub)
  → `git rebase <lease>` brings the PR's commits under the WIP commit (a
  fast-forward of the branch); anything else (ahead or diverged) → a
  decision item, nothing changed. Its rec is "reset to the PR head and
  redo the move" when the local-only commits come from a previous move (a
  `logistics-wip:` or `docs(specs): log rebase` subject, or patch-identical
  by `git cherry`); with that answer the next spawn runs `git rebase
  --onto <lease> <tip>` (drops them, keeps the WIP commit) and goes on.
- **Rationale**: with a stale local branch, a lease equal to the PR head
  would still let the push drop the remote commits; bringing them in is
  the only move that keeps both. Setting the ref first means undo and
  repair also undo that fast-forward. Refusing a branch ahead of the PR
  head keeps R6's reset safe and never pushes commits the PR's reviewers
  have not seen without asking.
- **Alternatives**: `git merge --ff-only` before the WIP commit (not
  undone by the ref, and refused by a dirty tree); carrying local-only
  commits into the push (pushes unseen commits; a refused push's reset
  would drop them).

## R12. The review diff is taken against `origin/<default>`

- **Decision**: `/feat` phase 7 and `/fix` phase 4 compute `BASE` with
  `git merge-base origin/<default> HEAD` instead of the local
  `<default>`.
- **Rationale**: after a move, HEAD sits on `origin/<default>`, which the
  local `<default>` usually lags; the old merge-base would put main's new
  commits in the reviewers' diff.

## R13. A refused move: the run stays on the old base until main moves again

- **Decision**: a refusal (or "stay") at a move gate logs `- [x] move —
  stayed on <old7>, refused <new7> (user: "<words>")` and runs the phase
  on the old base. Later base checks first test `git merge-base
  --is-ancestor origin/<default> <new7>` against the latest such line:
  exit 0, main has not moved past what was refused, nothing happens. The
  shipper's own rebase will meet the same conflict and stop at ship, where
  it must be decided.
- **Rationale**: without it, every later boundary re-asks the same
  question; with it, the coordinator still only compares bases.

## R14. Which checks a move reruns

- **Decision**: during a run, the implementer's usual checks (its step
  2: fast tests when the conventions name them); on a shipped run, the
  full checks the shipper runs (FR-017). A check that could not run is a
  `Not verified:` item on the move's Log line and at the next gate; it is
  not passed to the shipper, whose full checks run after any move. On a
  shipped run it also goes into the PR note; the push still happens (the
  PR's CI runs).
- **Rationale**: spec assumption ("the checks" = what the project already
  runs); no new check is invented.

## R15. A failed fetch at a boundary

- **Decision**: log `- [!] move — git fetch failed (<first line>)`, flag
  it under "What you should know" at the next gate, and run the phase on
  the current base. The setup fetch failing stops setup, as any git
  failure there does.
- **Rationale**: like a failed board move: the shipper's own fetch and
  rebase still protect the push.

## R16. Rows, models and boundaries

- **Decision**: rebase mode on the implement row (`/feat` 6, `/fix` 2) of
  the run's size, as review fixes do; the shipper's rebase mode on the
  ship row (`/feat` 8, `/fix` 5). No size-table cell or row changes; one
  sentence under each table ("Applying the review fixes and moving onto a
  new main use the phase 6 row"), mirrored in `docs/workflow.md`.
  `models.svg` comes out unchanged. `/fix` checks from phase 2 on (D8):
  before the assess gate there is no size, so no implement row, and the
  setup fetch already covers phase 1; "back to 1" re-assesses with no
  check, and checks start again at phase 2.
- **Rationale**: the row has to exist before a move can be spawned on it.

## R17. Where the shared rules go, and the lint

- **Decision** (D14): `## Moving onto a new main` in
  `.apm/skills/feat/references/harness.md` holds what every run uses:
  fresh base, base check, the move's report and gate, repair, the ship
  conflict and the Log entry (about 60 lines). The `rebase` entry point
  (targets and their validation, one PR at a time, the batch, the final
  message; about 75 lines) goes in a new
  `.apm/skills/feat/references/rebase.md`, read by both skills only when
  their argument is `rebase`. Both are written with named values each
  skill's `## Harness values` fills: *base-check boundaries*, *resolver
  context*, *implement row*, *ship row*, *number check* and *rebase
  search*. `mise.toml`'s lint grep (`specifier|planner|tasker|spec\.md|brief|phase
  [0-9]|/feat`, case-insensitive: so no "briefly" either) and its
  `test:apm` `test -f` cover both files.
- **Rationale**: FR-022, principle III; principle V: every run would
  otherwise read ~75 lines most runs never use. One extra file, read on
  demand, beats ~140 lines read on every run.
- **Alternatives**: everything in the harness (the first plan's choice,
  costed at ~45 lines; the real figure was ~95, and growing with the
  target validation).

## R18. Diagrams

- **Decision**: `gates.d2` gains the move (an agent step and a dashed
  "decide on a conflict that changes behaviour, if any" stop) and the
  post-PR `rebase` exchange; `chain.d2` gains one check node and one
  dashed gate on a side path from the pull request back to it. Both
  re-rendered with `mise run diagrams`; README alt texts follow.
  `models.svg` unchanged. D16: `chain.d2`'s first render is kept when no
  labels overlap; if it needs more than one tuning pass, its side path is
  dropped and the new step appears in `gates.d2` only.
- **Rationale**: the ELK layout of `chain.d2` is easy to tangle; a
  bounded effort keeps the diagram readable.

## R19. What the shipper checks before any push

- **Decision**: both shipper modes, before pushing, run `git log
  --format=%s origin/<default>..HEAD`; a `logistics-wip:` subject → `PR:
  blocked`, `! WIP commit on <branch>; nothing pushed` (D4). The rebase
  mode also runs Fix mode's scan, `bash <secret-scan script> staged`, on
  the staged state file before its Log commit, and before the push `bash
  <secret-scan script> range origin/<default> HEAD`: the lines the PR
  brings onto the new main, conflict resolutions included, none of
  main's own commits (D5, then S1). `range <from> <to>` is a new mode of
  `.apm/skills/feat/scripts/secret-scan.sh`: `git diff -U0 <from> <to>`
  fed to the script's existing `scan_diff`, so the rules, the
  `<file>:<line>: <rule>` output and the exits are those of `staged`;
  one case in `tests/secret-scan/run.sh` covers it. Both block as Fix
  mode does: a match → `PR: blocked`, `! secret scan: <file>:<line>
  matches <rule>`, never the value; a scan that can't run (an exit other
  than 0 or 1) → `PR: blocked`, `! secret scan: could not run (<first
  error line>)`. The script's path is a rebase-mode input, passed by
  `references/rebase.md` from each skill's *secret-scan script* value
  (`/fix` already gives the same path to Fix mode). The
  PR body for `gh pr edit` is written with Write to a file outside the
  worktree's tracked tree (`git rev-parse --absolute-git-dir`, or a
  scratch dir), and deleted after the edit (D17); when the number check
  renumbered, the body's state-file link is updated with the note (D19).
- **Rationale**: a WIP commit carries everything the tree held, ignored
  only by `.gitignore`; it must never reach a remote, whatever crashed.
  The resolutions are new content nobody reviewed, pushed with force.
  After the rebase HEAD descends from `origin/<default>`, so the diff
  from it is exactly what the PR adds on the new main: main's own
  commits never show, and a run is never blocked by what another PR
  brought. The whole PR is scanned, not only the resolutions: a PR that
  already carries a matching line blocks until that line changes, a
  stop, never a leak. Reusing `scan_diff` keeps one set of rules for
  every scan.
- **Alternatives**: scanning only the Log commit (misses what the
  resolutions wrote); the range from the lease to the new head (holds
  main's own commits: any matching line main added blocks every rebase,
  code review S1); scanning only the resolutions (no single `git
  diff` shows them apart from the PR's own lines); a temp file in the worktree (a later `git add -A`
  could stage it).
