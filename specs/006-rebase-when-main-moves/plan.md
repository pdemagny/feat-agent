# Implementation Plan: /feat and /fix keep their run on the current main

**Branch**: `rebase-when-main-moves` | **Date**: 2026-11-18 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/006-rebase-when-main-moves/spec.md` (brief in [feat-state.md](feat-state.md), issue #13); amended with the design review's accepted findings D1–D21, then with the code review's S1 resolution (the secret-scan script's `range` mode, after main replaced the shipper's inline scan with `secret-scan.sh`).

## Summary

`feat-implementer` gains a rebase mode that moves a run onto
`origin/<default>`: uncommitted work rides a temporary `logistics-wip:`
commit (intent-to-add paths listed in its body, restored after), a
`refs/logistics/pre-move/<branch>` ref marks the move so it can be undone
or repaired, conflicts of the "keep both sides" kind are resolved and
listed, and anything that drops behaviour, drifts from the spec or plan
(read only from what main brought), fails the checks without a mechanical
fix, or (shipped) changes what reviewers saw becomes a decision item; with
any item, the agent undoes the whole move before reporting, so the hard
gate always finds the worktree on the old base. `feat-shipper` aborts on a
rebase conflict (`PR: conflict`, `Conflicts:`), never pushes a
`logistics-wip:` commit, and gains a rebase mode that commits the Log
lines alone as `docs(specs): log rebase onto <sha>`, rebases, scans what
the PR brings onto the new main for secrets (`secret-scan.sh range
origin/<default> HEAD`, a new mode of the existing script), pushes with
`--force-with-lease=<branch>:<PR head>` (a refused
push puts the branch back on the PR head) and notes the PR body. A new
harness section holds the rules every run uses (fresh base, git-only base
check, move gate, repair, ship conflict, Log line); a new
`references/rebase.md`, read only by `rebase`, holds the entry point that
finds the user's shipped runs (validated JSON first, D1–D3, D9) and
handles them one by one. `/feat` phase 8 is unchanged: a `/feat` run on
the user's open PR counts as shipped whatever its `Current phase:`
(research R7). Prompts, docs and two diagrams, two `mise.toml` lines, and
one mode added to the existing secret-scan script with its test case: no
new script, no new agent, no size-table cell.

## Technical Context

**Language/Version**: Markdown prompts (skills, agents, harness and rebase references), Markdown docs, D2 diagrams; git ≥ 2.44 and `gh` commands inside the prompts.

**Primary Dependencies**: none new. git (already ≥ 2.44 for the renumber's `rebase --autosquash`), gh (already used for `pr create`, `pr list`, `repo view`, `api`), d2 0.9.0 (pinned).

**Storage**: git state (a WIP commit and one ref per move in progress), the state file's `## Log` lines and local done mark ([data-model.md](data-model.md)), the PR body's `### Rebases` part.

**Testing**: `mise run lint` (its grep extended to `references/rebase.md`; shellcheck on `secret-scan.sh` and its test), `mise run test:apm` (its `test -f` too), `mise run test:tracker`, `mise run test:spec-number`, `mise run test:secret-scan` (a new `range` case), `mise run diagrams` (clean on a second run), the grep checks and manual git scenarios of [quickstart.md](quickstart.md); live runs optional.

**Target Platform**: Claude Code sessions, installed by APM, the plugin or `install.sh`.

**Project Type**: Claude Code skills/agents package.

**Performance Goals**: with main unmoved, two git commands per phase boundary and no spawn (SC-003); one implement-row spawn per move, one more per answered move gate; the shipper's push on the ship row (haiku).

**Constraints**: coordinators stay thin: git and gh only, no code read (FR-011, principle I); shared rules in `references/harness.md` and, for `rebase`, `references/rebase.md`, both lint-clean (FR-022); implementer and shipper report blocks change with both coordinators in one commit (FR-023, principle IV); no size-table row (brief); `--force-with-lease` is the only force-push, own branch, rebase mode (FR-021); no stash (brief); git commands plain and taken from the conventions (FR-026); PR-derived values validated before any git command, single-quoted, `--` before refs and paths (FR-027).

**Scale/Scope**: 17 files (one new) plus 2 rendered SVGs; ~35–45 tasks (medium).

## Constitution Check

*Constitution: `.specify/memory/constitution.md` v1.1.0.*

| Principle | Status |
| --- | --- |
| I. Thin coordinators | pass: the coordinator adds git and gh commands that compare bases and find runs: `git fetch`, `git merge-base` (`--is-ancestor`), the repair check (`git rev-parse -q --verify` of one ref, `git log -1 --format=%s`), `gh pr list` / `gh pr view` (JSON), `gh repo view --json nameWithOwner`, `gh api user --jq .login`, `git check-ref-format --branch`, `git worktree list` / `git worktree add`, `git diff --name-only` and one `git grep -h` printing two state-file lines (discovery). It reads no code and edits only the state file (Log lines, the local done mark); moving, resolving, checks and repair are the implementer's, pushing the shipper's. |
| II. The user decides at gates | pass: a resolution that changes behaviour, drifts from the spec, fails the checks or changes what reviewers saw stops at a hard gate; the user's refusal leaves the worktree untouched. A clean move is listed at the next gate. Another author's PR stops at a hard gate before anything runs. The lease push of a shipped run happens only on the user's `rebase` command and never merges. |
| III. One source of truth per fact | pass: the shared rules live once, in the harness section and `references/rebase.md`, with named values; the size tables gain one sentence each (no cell) mirrored in `docs/workflow.md` in the same commit; `models.svg` unchanged. |
| IV. Fixed report formats | pass: the implementer's three rebase-mode lines and the shipper's `PR: conflict` / `Conflicts:` change in the same commit as the harness section, `references/rebase.md` and both skills that read them. |
| V. Small and plain | pass: the harness section (~60 lines) is read on every run; the `rebase` entry point (~75 lines) is a separate reference read only on `rebase` (research R17). One new file, no new script: the lint and `test:apm` cover the reference; the one script change, a `range` mode reusing `secret-scan.sh`'s own diff reader, gets its case in the existing `tests/secret-scan/run.sh`. |

Post-design re-check: same result, no violation.

## Project Structure

### Documentation (this feature)

```text
specs/006-rebase-when-main-moves/
├── plan.md            # this file
├── research.md        # decisions R1–R19
├── data-model.md      # run, base, move, resolution, Log entry, batch states
├── quickstart.md      # offline checks Q1–Q14, git mechanics M1–M5, live L1–L18
├── contracts/move.md  # harness section, rebase.md, skill values, implementer and shipper text, report lines, gate messages
└── tasks.md           # phase 5
```

### Source Code (repository root)

```text
.apm/skills/feat/references/harness.md   # new "## Moving onto a new main"; thin-orchestrator exception; Resume order
.apm/skills/feat/references/rebase.md    # NEW: the `rebase` entry point, read only on `rebase`
.apm/agents/feat-implementer.agent.md    # description; "never commit" exception; Rebase mode section; 3 report lines
.apm/agents/feat-shipper.agent.md        # description; step 4 conflict and WIP check; step 6; Rebase mode; report PR: conflict + Conflicts:
.apm/skills/feat/SKILL.md                # frontmatter; Harness values; size-table sentence; phases table note; setup step 1; §2 fetch; §7 diff base; §8 conflict; final message
.apm/skills/fix/SKILL.md                 # frontmatter; Harness values; size-table sentence; phases table note; setup steps 2 and 7; Resume; §4 diff base; §5 conflict
.apm/skills/feat/scripts/secret-scan.sh  # new `range <from> <to>` mode (FR-030)
tests/secret-scan/run.sh                 # a `range` test case
mise.toml                                # lint grep and test:apm `test -f` cover rebase.md
.claude/CLAUDE.md                        # the harness bullet names rebase.md (lint greps both)
docs/workflow.md                         # roles, phases notes, matrices' sentences, phase 2/7/8 details, new "When main moves", /fix parts, agents table
docs/usage.md                            # "When main moves" section with /feat rebase and /fix rebase; troubleshooting rows
docs/design.md                           # harness list gains "moving onto a new main"; rebase.md named
docs/install.md                          # git and gh prerequisite rows
README.md                                # rebase entry point; gates.svg and chain.svg alt texts
docs/diagrams/gates.d2, docs/img/gates.svg
docs/diagrams/chain.d2, docs/img/chain.svg
```

Not touched: size-table cells, `docs/diagrams/models.py`, `models.svg`,
`.apm/skills/brief/SKILL.md`, `.claude-plugin/plugin.json` (no new
agent; the reference ships inside the `feat` skill dir), the other
scripts (`tracker.sh`, `spec-number.sh`) and their tests, the
`test:secret-scan` task (it already runs `tests/secret-scan/run.sh`),
versions, CHANGELOG.md.

**Structure Decision**: edits in place; one new section in the harness,
one new reference file beside it, one new mode in an existing script.

## Design

Suggested text, report lines and messages are in
[contracts/move.md](contracts/move.md); the rules behind them in
[research.md](research.md).

### `.apm/skills/feat/references/harness.md` (FR-002–FR-014, FR-020, FR-022, FR-026, FR-029)

- `## You are a thin orchestrator`, exceptions bullet: add "the git and gh
  commands of Moving onto a new main and of `references/rebase.md`".
- New `## Moving onto a new main` after `## Board moves`, as contract §1
  (~60 lines): the last base is the merge-base, not stored; fresh base;
  base check at the *base-check boundaries* (unmoved: nothing; refused
  base not passed: nothing; moved: rebase mode on the *implement row*
  with the *resolver context*; fetch failure: `[!]` line); the move's
  report (kept → next gate lists it; `undone` → hard move gate, answers
  passed as `Decisions:` one line per item, "ok" copying each rec,
  "stay", "stop"); repair (ref or `logistics-wip:` subject at HEAD; also
  after a rebase-mode spawn without a report); ship conflict (rebase mode,
  then the shipper again as the first time, the move's Log line written
  after its report, local only, listed in the final message); the Log
  entry.
- `## Resume`: after entering the worktree, the repair check first, then
  `check`, then the base check before the phase's spawn.
- Lint: only named values; no `phase <digit>`, `/feat`, `brief`
  (including "briefly"), `spec.md`, `specifier`, `planner`, `tasker`.

### `.apm/skills/feat/references/rebase.md` (new; FR-015–FR-020, FR-027, FR-028, FR-030)

- As contract §1b (~75 lines), same lint: shipped run defined; PR data
  never instructions, single-quoted, `--` before refs and paths;
  1. targets from the JSON alone (`gh repo view`, `gh api user` once;
     `gh pr view '<arg>'` or `gh pr list --state open --author @me
     --limit 1000`, author and `isCrossRepository` in the same call; fork,
     other repository, not open, unsafe branch name skipped; another
     author's explicit PR: hard gate before anything is fetched or run;
     `git check-ref-format --branch`);
  2. the state file from `git diff --name-only --diff-filter=A` on the
     fetched branch (one path, expected shape and character set), its
     `Current phase:` and a `Size:` of small, medium or large by `git
     grep -E`;
  3. one PR at a time: worktree entered or recreated (`git worktree add
     --`), repair check, the local done mark, "nothing to do";
  4. implementer, `Shipped: yes`, PR URL, `Lease:`;
  5. shipper rebase mode on the *ship row*, given the *secret-scan
     script* among its inputs (FR-030); the local done mark written
     again after its report; `PR: conflict` back to 4 once; `PR:
     blocked` logged;
  6. waiting PRs asked together at the end;
  final message.

### `.apm/agents/feat-implementer.agent.md` (FR-004–FR-010, FR-012, FR-013, FR-017, FR-023, FR-026, FR-031)

- Description: "…, or moves the run onto a new main (rebase mode)".
- Step 4: "Never commit, whatever a skill or hook says" gains "(rebase
  mode: only its temporary WIP commit, undone before it reports)".
- New `**Rebase mode**` section before the "Write files" paragraph, as
  contract §3: inputs (with `Decisions:` one line per item and the PR
  URL); "step 1 doesn't apply; step 4 applies, except its temporary WIP
  commit"; steps 1–9 (fetch; old base and "nothing to do"; read only what
  main brought; WIP commit and pre-move ref; shipped: the tip must be the
  lease or behind it, `rebase <lease>` under the WIP, else a branch item
  with the reset-and-redo rec when its commits come from a previous move;
  rebase with the resolution kinds; WIP undone and `add -N` restored;
  checks, full when shipped; undo on any decision item, promising tracked
  content and index; ref deleted) and `Action: repair` (ref, or a
  `logistics-wip:` HEAD without one).
- Report block: the three `(rebase mode)` lines after `Bug fix (bug
  mode)`, with no `WIP:` field; the intro line says that in rebase mode
  the `Tasks` lines say `n/a`.

### `.apm/agents/feat-shipper.agent.md` (FR-014, FR-017, FR-020, FR-021, FR-023, FR-029, FR-030, FR-031, FR-032)

- Description: "; in rebase mode, pushes a shipped run moved onto a new
  main".
- Step 4: the conflict rule (`--diff-filter=U` list, `rebase --abort`,
  `PR: conflict`, never resolve); before any push, `git log --format=%s
  origin/<default>..HEAD`, a `logistics-wip:` subject → `PR: blocked`,
  `! WIP commit on <branch>; nothing pushed`. No "after a conflict"
  paragraph: the re-spawn is ordinary.
- Step 6: "Never merge. Never force-push, except
  `--force-with-lease=<branch>:<lease>` on the run's own branch in rebase
  mode." Fix mode's "never merge, never force-push" refers to step 6.
- New `**Rebase mode**` section after Fix mode, as contract §4: inputs
  include the secret-scan script's path; steps 1–3
  and 5 don't apply, a blocked git or gh is an error `!` line, never a
  command; `gh` takes the PR URL; fetch; the Log lines alone (the
  `Current phase:` line set back to its committed value, Fix mode's
  `bash <secret-scan script> staged` on the staged file, `docs(specs):
  log rebase onto <sha>` commit); rebase (a conflict: abort, `git reset
  --keep <lease>`, `PR: conflict`); number check; the WIP check and
  `bash <secret-scan script> range origin/<default> HEAD` (what the PR
  brings onto the new main, conflict resolutions included, none of
  main's own commits; exit 1 → `PR: blocked`, `! secret scan:
  <file>:<line> matches <rule>` from its first output line, never the
  value; any exit but 0 and 1 → `PR: blocked`, `! secret scan: could not
  run (<first error line>)`; nothing pushed); lease push (refused: `git
  reset --keep <lease>`, `! push refused: …`); PR body note under `### Rebases`, state-file link
  updated on a renumber, the body file outside the tracked tree
  (`git rev-parse --absolute-git-dir` or a scratch dir), deleted after
  `gh pr edit`.
- Report: `PR: <url> | blocked | conflict`; new `Conflicts:` line after
  `Command for the user:`.

### `.apm/skills/feat/SKILL.md`

- Frontmatter: description adds "or /feat rebase to bring a shipped run's
  PR onto the current main"; `argument-hint: "specs/briefs/name.md |
  resume | rebase [PR]"`.
- `## Harness values`: *Base-check boundaries*, *Resolver context*,
  *Implement row*, *Ship row*, *Number check*, *Secret-scan script*
  (`<this skill's base dir>/scripts/secret-scan.sh`), *Rebase search*
  added (contract §2). *Current phase values*, *Done marker* and *Commands
  besides the tracker* unchanged.
- Under the size table, last sentence: "Applying the review fixes and
  moving onto a new main use the phase 6 row."
- Under the phases table: "From phase 3 on, each phase starts with the
  base check (harness, Moving onto a new main): silent when main has not
  moved; a move is listed at the next gate, or stops there when it needs
  your call."
- Setup step 1: `$ARGUMENTS` may be `rebase [<PR number, URL or
  branch>]`: run steps 0, 2, 3, 4 (not 5: no board moves), then read
  `references/rebase.md` and follow it.
- §2 step 1: "`git fetch origin <default>` (harness, Fresh base), then
  prefer a worktree (EnterWorktree)…".
- §7: `BASE=$(git merge-base origin/<default> HEAD)` (research R12).
- §8: `PR: conflict`: rebase mode (`Shipped: no`, harness, At ship), then
  the shipper again as the first time; the move's Log line written after
  its report, local only. The existing "mark the state file done"
  sentences stay.
- Final message: a kept move since the last gate, and an at-ship move,
  are listed (harness).

### `.apm/skills/fix/SKILL.md`

- Frontmatter: description adds "/fix rebase"; `argument-hint: '#N |
  issue-url | "symptom" | resume | rebase [PR]'`.
- `## Harness values`: the seven new values (contract §2), *Secret-scan
  script* being `<this skill's base dir>/../feat/scripts/secret-scan.sh`
  (the path §5 already gives Fix mode), *Base-check
  boundaries* from phase 2 on ("back to 1": no base check until the
  assess gate sets the size again). *Done marker* and *Resume search*
  unchanged.
- Under the size table: "Applying the review fixes and moving onto a new
  main use the phase 2 row."
- Under the phases table: "From phase 2 on (once the assess gate has set
  the size), each phase starts with the base check (harness, Moving onto
  a new main): silent when main has not moved; a move is listed at the
  next gate, or stops there when it needs your call."
- Setup step 2: the `rebase` argument (run steps 1, 3, 4, 5, then read
  `../feat/references/rebase.md` and follow it); the usage line gains
  `rebase [PR]`.
- Setup step 7: "`git fetch origin <default>` (harness, Fresh base), then
  EnterWorktree".
- `## Resume`: "the repair check first (harness)".
- §4 step 2: `BASE=$(git merge-base origin/<default> HEAD)`.
- §5: `PR: conflict` → rebase mode, then the shipper again as the first
  time; the move's Log line written after its report, local only; the
  state file stays `done (shipping)`.

### `.apm/skills/feat/scripts/secret-scan.sh` and `tests/secret-scan/run.sh` (FR-030)

- Header comment: a third line, `secret-scan.sh range <from> <to>   the
  lines git diff <from> <to> adds`; the usage error becomes `usage:
  secret-scan.sh staged | worktree <path>... | range <from> <to>`.
- `scan_main`: `range` takes exactly two arguments; it runs `git
  "${diff_opts[@]}" --end-of-options <from> <to> --` into `$tmp/diff`
  (a ref git can't resolve → `scan_die "git diff failed: …"`, exit 2)
  and feeds it to the existing `scan_diff`. No other change: same rules,
  same `<file>:<line>: <rule>` output, same exits (0 clean, 1 a match, 2
  could not run).
- `tests/secret-scan/run.sh`, a new case `range` before "self": a base
  commit adds a secret-looking line (main's own), a branch from it adds
  one in a new file and one in a modified file over two commits and
  removes another; `scan range <base> HEAD` → exit 1, only the branch's
  two lines, numbered in the new files, values hidden; `scan range HEAD
  HEAD` → exit 0, no output; `scan range <base>` and `scan range
  no-such-ref HEAD` → exit 2. Samples built by concatenation, as the
  other cases. The `test:secret-scan` task already runs the file.

### Tooling and project notes (FR-022)

- `mise.toml` line 27: `! grep -Eiq '…'
  .apm/skills/feat/references/harness.md
  .apm/skills/feat/references/rebase.md`; `test:apm` (line 48): add
  `test -f .claude/skills/feat/references/rebase.md`.
- `.claude/CLAUDE.md`, the harness bullet: the `rebase` entry point
  lives in `references/rebase.md`, under the same rule; `mise run lint`
  greps both.

### Docs (FR-025)

- `docs/workflow.md`:
  - Roles, coordinator: "it runs git only to compare bases and find
    runs"; phase agents unchanged.
  - Phases at a glance: a sentence under the table, as the skill's.
  - Matrix notes: "Applying the review fixes and moving onto a new main
    use the phase 6 row"; `/fix` matrix row 2 label "Fix (review fixes
    and moves)" and its note.
  - Phase 2 details: the fetch before the worktree. Phase 7: the diff base
    `origin/<default>`. Phase 8: the conflict stop and the second
    shipper; the WIP check before any push.
  - New `## When main moves` (after `## The state file`): fresh base; the
    check at each boundary; what is resolved alone and what stops; the WIP
    commit (never the stash, never pushed) and the pre-move ref; undo and
    repair; ship conflict; `/feat rebase` and `/fix rebase` (plugin
    forms), only your own PRs of this repo, the batch, the lease push and
    what a refused one leaves, the Log commit and PR note, the secret
    scan before the Log commit and before the push (what the PR brings
    onto the new main, none of main's own commits); that it uses
    the implement and ship rows.
  - `/fix` part: one line pointing to "When main moves" (boundaries from
    phase 2).
  - Agents table: implementer "6, 7 (fix mode), any boundary (rebase
    mode); `/fix` 2, 4"; shipper "8; `/fix` 5; `rebase` (rebase mode)";
    the "No agent but the shipper commits" sentence notes the
    implementer's temporary WIP commit.
- `docs/usage.md`: new `## When main moves` (what happens on its own, the
  move gate's answers "ok" / your resolution / "stay" / "stop", `/feat
  rebase [PR]` and `/fix rebase [PR]` with plugin forms, your own PRs
  only, what you get at the end); "When something goes wrong" rows: a PR
  conflicting after another merged → `/feat rebase <PR>`; `[!] move — git
  fetch failed` → check the network, the run went on; `! push refused: …`
  → someone pushed to the PR, the branch is back on it; rerun `rebase`
  after looking; `! secret scan: …` and `! WIP commit …` → nothing
  pushed, look at the file or branch.
- `docs/design.md`: the harness list "(thin orchestrator, gates, review
  findings, state file, board moves, moving onto a new main, resume)",
  and `references/rebase.md` for the `rebase` entry point.
- `docs/install.md`: git row "…; moves runs with `rebase`, phase 8
  renumbers with `rebase --autosquash`"; gh row "…; `rebase` lists your
  conflicting PRs and pushes with `--force-with-lease`".
- `README.md`: a `/feat rebase` / `/fix rebase` bullet in the command list
  (keeps a shipped run's PR on the current main, resolving conflicts and
  pushing it; only real decisions stop); gates.svg and chain.svg alt texts
  name the new step and stop.

### Diagrams (FR-025, research R18)

- `docs/diagrams/gates.d2`: after `cc -> agents: specify`, add `cc ->
  agents: before each phase: move onto main, if it moved` and `cc -> you:
  decide on a conflict that changes behaviour, if any {class: maybe}`;
  after the PR arrow, add `you -> cc: /feat rebase, when the PR
  conflicts`, `cc -> agents: rebase, resolve, checks, push`, `agents ->
  you: PR on the current main {class: back}`.
- `docs/diagrams/chain.d2`: `move: main moved?\nmove + checks {class:
  check}` and `gm: you decide on a conflict\nthat changes behaviour
  {class: maybe}`; `pr -> move: /feat rebase\nwhen it conflicts
  {style.stroke-dash: 3}`, `move -> gm`, `gm -> pr: pushed`. The first
  render is kept when no labels overlap; if it needs more than one tuning
  pass, drop this side path and keep the new step in `gates.d2` only (and
  the chain.svg alt text unchanged).
- `mise run diagrams`; commit both sources and SVGs.

## Order (FR-024)

1. **Post-PR first** (US1, US2, US5, US6 repair, US7): harness section
   (all of it but the base check and fresh base paragraphs),
   `references/rebase.md`, `mise.toml`, `.claude/CLAUDE.md`, implementer
   rebase mode and report lines, shipper step 4 conflict and WIP check,
   step 6, rebase mode and report lines, the secret-scan script's
   `range` mode and its test case, both skills' frontmatter,
   Harness values, size-table sentence, setup `rebase` argument, §8/§5
   `PR: conflict`, the Resume repair; docs and diagrams for these. One
   commit (principle IV), e.g. `feat(feat): rebase a shipped run's PR
   with /feat rebase and /fix rebase`.
2. **During the run** (US3, US4): fresh base and base check paragraphs,
   the phases-table sentences, §2/setup step 7 fetch, §7/§4 diff base;
   docs and diagrams for these. Second commit, e.g. `feat(feat): keep a
   run on the current main at every phase boundary`.
3. Quickstart Q1–Q14 after each; M1–M5 once.

## Complexity Tracking

None: no constitution violation.
