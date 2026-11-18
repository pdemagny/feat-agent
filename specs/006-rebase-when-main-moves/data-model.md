# Data model: moving a run onto a new main

No database: the "data" is git state, the state file's Log, and the
agents' report lines. Exact report and message shapes are in
[contracts/move.md](contracts/move.md).

## Run

| Field | Where it lives | Notes |
| --- | --- | --- |
| branch | `Branch:` line of the state file; `git branch --show-current` | `/feat`: `<short-name>`; `/fix`: `fix-<slug>` |
| worktree | `Worktree:` line; `git worktree list --porcelain` | recreated under `<repo root>/.claude/worktrees/<branch>` when gone (research R10) |
| state file | *state file* value | `/feat` `specs/[NNN-]<short-name>/feat-state.md`, `/fix` `.specify/bugs/<slug>/feat-state.md` |
| size | `Size:` line (`small`, `medium` or `large`, exactly) | picks the implement row's column for a move |
| shipped | an open PR of this repository (`isCrossRepository: false`, its URL's owner/repo = `gh repo view --json nameWithOwner`), opened by the user (`author.login` = `gh api user --jq .login`), whose branch adds exactly one state file matching the *rebase search*: `/feat` whatever its `Current phase:`, `/fix` with `Current phase:` starting with `done` (research R7, R9) | anything else is skipped by `rebase`, with the reason; another author's PR named explicitly stops at a hard gate first |
| local done mark | `Current phase: done (PR #<n>)` in the worktree's copy, never committed | written by `rebase` on entering a worktree whose copy is not marked done (a recreated one), and again after the shipper's report; set back to the committed value by the shipper before its Log commit |

Validation for a `rebase` target, in order, each failure a "skipped:
<why>" line and no spawn. From the JSON alone, before any other git
command: not a fork; same repository; open; branch name only
`[A-Za-z0-9._/-]`; author is the user (an explicit PR: hard gate, before
anything is fetched or run; the batch lists `--author @me` and drops the
rest); `git check-ref-format --branch` passes. Then, after `git fetch`:
exactly one added state-file path of the *rebase search* shape, slug
`[A-Za-z0-9._-]` (not `.` or `..`); a `Size:` of small, medium or large;
a `Current phase:` the *rebase search* accepts; the worktree can be
entered (R10). The local branch being the PR head or behind it is
checked by the agent (a decision item otherwise, R11).

## Base

- **Current (last) base**: `git merge-base HEAD origin/<default>` (before
  ship: HEAD itself). Not stored; each move's old and new base are on its
  Log line.
- **Moved**: `git merge-base --is-ancestor origin/<default> HEAD` exits 1.
- **Refused base**: the `<new7>` of the latest `move — stayed on …,
  refused <new7>` Log line; a check skips while `git merge-base
  --is-ancestor origin/<default> <new7>` exits 0.

## Move

| Element | Value |
| --- | --- |
| WIP commit | subject `logistics-wip: <branch>`; body `intent-to-add:` then one paragraph per path; made with `git add -A`, `--no-verify`, `-c commit.gpgsign=false`; only when `git status --porcelain` is not empty; never pushed (both shipper modes block it) |
| pre-move ref | `refs/logistics/pre-move/<branch>` → the WIP commit, or the branch tip when the tree was clean; set before anything moves the branch (the shipped fast-forward included); exists only while a move runs |
| lease | the PR's `headRefOid` when `rebase` picked it; the shipped branch must be it or behind it |
| old / new base | 7-char SHAs on the report's `Move:` line and the Log line |
| resolver context | *resolver context*: `/feat` spec.md and plan.md; `/fix` assessment.md and fix.md, those that exist |
| checks | `Shipped: no`: the implementer's step 2 checks; `Shipped: yes`: the full checks |
| decisions | `Decisions:` input, one line per item, `<file> — <the accepted rec | the user's words>`; "ok" copies each rec |

State transitions (the agent's, inside one spawn):

```
clean or dirty tree
  └─ dirty → WIP commit
  └─ pre-move ref set
      └─ shipped: tip is the lease or behind it → rebase <lease> (fast-forward under the WIP)
      │           tip ahead or diverged → decision item (reset decided → rebase --onto <lease> <tip>)
      └─ rebase onto origin/<default>
          ├─ conflict, keep-both kind → resolved alone (listed)
          ├─ conflict, behaviour kind → recommendation applied, decision item
          └─ decision given → applied as given
      └─ WIP undone (reset HEAD~1, add -N restored)
      └─ checks: pass | mechanical fix (listed) | decision item | not verified
  ├─ no decision item → kept;  ref deleted;  Move: <old> → <new>
  └─ decision item(s) → reset --hard <ref>, WIP undone;  ref deleted;  Move: undone (<old> → <new>)
crash at any point → ref set, or a logistics-wip: commit at HEAD → repair on resume:
  rebase --abort if one runs; reset --hard <ref> if set; WIP undone if HEAD is a WIP commit; ref deleted
```

Invariants (SC-005, SC-006):
- after any move, kept or undone: every path that was untracked is
  untracked, every intent-to-add path is intent-to-add; tracked content
  and the index are those before the move (undone, repaired) or the
  rebased ones (kept); untracked files a check created during the move may
  remain;
- the stash stack is never read or written;
- no ref under `refs/logistics/` survives a finished move;
- no `logistics-wip:` commit is ever pushed;
- fully staged changes (none before ship in either workflow) come back
  as unstaged changes with their content intact.

## Resolution

| Kind | Examples | Outcome |
| --- | --- | --- |
| keep both sides | both sides add entries to one list or table; adjacent-line edits; main renamed or moved what the run edits; formatting | resolved alone; `Resolved alone:` line `<file> — <how>` |
| generated file | `docs/img/*.svg` here (the conventions name the generator) | main's side taken, regenerated after the rebase with the conventions' command; never merged by hand; listed |
| mechanical check fix | a call site following main's rename, a regenerated file | applied; listed |
| behaviour | the resolution drops or changes what either side does | decision item |
| drift | main already implements part of the run, or contradicts a requirement of the resolver context (read only from what main brought since the old base) | decision item, even with no textual conflict |
| failing check, no mechanical fix | a semantic conflict | decision item |
| seen by reviewers (`Shipped: yes`) | the resolution changes lines of the PR's own diff a reviewer would want to see again | decision item |
| branch not on the PR head (`Shipped: yes`) | local commits the PR lacks (ahead, or diverged) | decision item, nothing changed; rec "reset to the PR head and redo the move" when they come from a previous move (`logistics-wip:` or `docs(specs): log rebase` subject, or patch-identical) |

Decision item: `<file> — run: <one line> — main: <one line> — rec: <one
line>`.

## Log entry (state file `## Log`)

Written by the coordinator from the report, after the move's outcome is
known. Labels: `move` for every move; where: `before <N> <phase>`, `at
ship`, or `PR #<n>`.

```
- [x] move — <old7> → <new7> (<where>): checks <pass | fail: …>; not verified: <none | items>
    - resolved: <file> — <how>
    - asked: <file> — <decision> (user: "<words>" | as recommended)
- [x] move — stayed on <old7>, refused <new7> (user: "<words>")
- [x] move — repaired (<the report's Move: line>)
- [!] move — git fetch failed (<first line>)
- [!] move — PR #<n> <the shipper's ! line>
```

Where each line goes:
- during a run: the local state file, committed with the run at ship, as
  every Log line is;
- `at ship` (after `PR: conflict`): written after the second shipper's
  report, in the local copy only, and listed in the final message;
- `PR #<n>` (`rebase` on a shipped run): written before the shipper's
  rebase mode, which commits the Log lines alone as `docs(specs): log
  rebase onto <new7>` (the `Current phase:` line set back to its
  committed value first) and pushes it with the rebase. A refused push
  or a shipper conflict resets the branch to the lease, taking that line
  with it; the coordinator then logs the `[!]` line locally.

The PR body gets, under a `### Rebases` heading (added at the end when
missing), one line per rebase, and its state-file link follows a
renumbered spec dir:

```
- Rebased onto <new7> (<YYYY-MM-DD>): resolved alone <files | none>; decided <file → answer | none>; checks <result>[; not verified: <items>]
```

## Rebase batch

| State | Meaning | Next |
| --- | --- | --- |
| dropped | a fork or another author's PR in the batch | not listed |
| skipped | not a shipped run of this skill (reason given: another repository, not open, unsafe branch name, no or several state files, no valid size, not shipped) | none |
| asked | an explicit PR by another author | hard gate before any fetch; "go on" continues as a target, "stop" ends |
| nothing to do | main not moved past the branch and not conflicting | none |
| pushed | moved, shipper pushed and noted | listed in the final message |
| waiting | the move reported decision items; worktree on the old base | asked at the end, with every other waiting PR, in one hard gate |
| refused | the user refused at that gate | left as is; `stayed on` Log line, uncommitted |
| failed | push refused (branch back on the lease), spec-number error, secret scan, WIP commit in range, blocked git or gh, a failed report | its `!` line in the final message; nothing overwritten |
