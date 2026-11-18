# Quickstart: validating the move onto a new main

Shapes are in [contracts/move.md](contracts/move.md), rules in
[data-model.md](data-model.md).

## Offline checks (every commit)

| # | Command | Expect |
| --- | --- | --- |
| Q1 | `mise run lint` | pass; its grep keeps the harness and `references/rebase.md` free of `/feat`-only words |
| Q2 | `mise run test:apm` | pass; agent and skill counts unchanged; `references/rebase.md` installed |
| Q3 | `mise run test:tracker`, `mise run test:spec-number` and `mise run test:secret-scan` | pass; `tracker.sh` and `spec-number.sh` untouched; the secret-scan `range` case passes (only the branch's added lines reported, main's own commit not; `range HEAD HEAD` clean; a missing argument or an unknown ref exits 2) |
| Q4 | `mise run diagrams`, twice | second run leaves `git status docs/img` clean; `models.svg` unchanged from main |
| Q5 | `git grep -n -e 'force-with-lease' -e '--force' -e 'push -f' -- .apm docs README.md` | every push hit is `--force-with-lease=<branch>:<lease>` in `feat-shipper.agent.md` rebase mode or the docs describing it (SC-009); `specify init … --force` is not a push |
| Q6 | `git grep -n 'stash' -- .apm` | only "never" / "off limits" wording (SC-005) |
| Q7 | `git grep -n 'merge-base <default>' -- .apm` | no hit: review diffs use `origin/<default>` (research R12) |
| Q8 | read the implementer and shipper report blocks against `/feat` §6–8, `/fix` §2–5, the harness section and `references/rebase.md` | every new line (`Move:`, `Resolved alone:`, `Needs decision:`, `Conflicts:`, `PR: conflict`) has a reader, and nothing reads a line no agent writes (principle IV); no `WIP: yes` field anywhere |
| Q9 | `git grep -n -e 'rebase' -- README.md docs/usage.md docs/install.md docs/workflow.md` | `/feat rebase`, `/fix rebase` and their plugin forms are documented |
| Q10 | `git grep -n -e '--author @me' -e '--limit 1000' -e 'check-ref-format' -e 'nameWithOwner' -e 'gh api user' -- .apm/skills/feat/references/rebase.md` | each present (FR-027, FR-028) |
| Q11 | `git grep -n -e 'logistics-wip' -e 'secret scan' -e 'secret-scan script' -e 'reset --keep' -- .apm/agents/feat-shipper.agent.md` | the WIP check before any push (both modes), the rebase mode's two scans (`staged` before the Log commit, `range origin/<default> HEAD` before the push) and the script among its inputs, the reset on a refused push or conflict |
| Q14 | `git grep -n -e 'secret-scan script' -- .apm/skills/feat/SKILL.md .apm/skills/fix/SKILL.md .apm/skills/feat/references/rebase.md` | each skill's *Secret-scan script* value, passed by `references/rebase.md` to the shipper's rebase mode (FR-030) |
| Q12 | `git grep -n -i -e 'after a conflict' -e 'done (shipping)' -- .apm/agents/feat-shipper.agent.md .apm/skills/feat/SKILL.md` | no "after a conflict" fixup path; `/feat` phase 8 unchanged (only Fix mode names `done (shipping)`) |
| Q13 | `git grep -n 'references/rebase.md' -- .apm/skills` | read from both skills' setup, `rebase` argument only |

## Git mechanics (manual, outside a worktree-isolated session)

M1. In a scratch repo with a bare remote: commit on `main`, branch `run`,
make a tracked change, an untracked file and an `add -N` file; push a
conflicting and a non-conflicting commit to the remote's `main`. Follow
contract §3 steps 4–9 by hand. Expect: after the kept move, `git status
--porcelain` shows the same `??` and ` A` entries as before; after an
undone move (`git reset --hard <ref>` + step 7), the branch is on the old
base, `git diff` and `git diff --cached` match the saved ones (an
untracked file created during the move may remain), and `git stash list`
is empty throughout; `git for-each-ref refs/logistics` is empty at the
end.

M2. Same repo, kill the sequence after `rebase` stops on the conflict;
run the repair commands of contract §3 (`Action: repair`). Expect the
state of M1's undone move. Again, stopping right after the WIP commit,
before `update-ref`: `git log -1 --format=%s` starts with
`logistics-wip:`, repair undoes it with no ref.

M3. Push `run` as a PR branch, push one more commit to it from elsewhere,
then `git push --force-with-lease=run:<old head> origin run` from a
rebased local `run`. Expect a refused push, remote untouched; after `git
reset --keep <old head>` the local branch is the old PR head and a
second move from it reports no branch item.

M4. Local `run` ahead of the PR head (one local commit on top of it), then
diverged (the PR also has a commit the local branch lacks): follow
contract §3 step 5. Expect a decision item and an untouched branch both
times; with the local commit subject `docs(specs): log rebase onto …`,
the rec is "reset to the PR head and redo the move", and `git rebase
--onto <lease> <tip>` keeps the WIP commit on top.

M5. In M1's repo, `git fetch origin -- main run` and `git worktree add --
<path> run` run as written (the `--` forms of `references/rebase.md`).

## Live scenarios (optional, in a test project)

| # | Scenario | Expect |
| --- | --- | --- |
| L1 | Start `/feat` after the remote main gained a commit not fetched locally | the worktree's base is the remote head (US3) |
| L2 | Main unmoved through a whole run | no rebase-mode spawn; gates as before (SC-003) |
| L3 | Merge an unrelated PR between phases 4 and 5 | one `Main moved …; checks pass` line at the phase 5 gate (or the next one shown); Log `move — … (before 5 Tasks)` |
| L4 | Main adds a row to a table the run also extends | resolved alone, listed one line per file, no stop |
| L5 | Main changes a line the run's code also changes, in a way that drops one side's behaviour | `Main moved … — needs your call` before the phase; worktree on the old base (`git merge-base HEAD origin/<default>` = old); "stay" logs `stayed on`, later boundaries stay silent until main moves again |
| L6 | Kill the session during a move; `/feat resume` | repair runs first; Log `move — repaired …` |
| L7 | Main moves with a conflicting change after the last boundary, before ship | shipper `PR: conflict`, nothing pushed; rebase mode; second shipper pushes; history is the shipper's usual commits, no fixup; the `at ship` Log line is in the local state file only and the final message lists the move |
| L8 | `/feat rebase <PR>` on a shipped run whose PR conflicts, worktree removed | worktree recreated under `.claude/worktrees/`, its state file `done (PR #<n>)` locally; PR rebased, checks green, pushed with the lease; a `docs(specs): log rebase onto …` commit whose diff is Log lines only; `### Rebases` line in the PR body; `/feat resume` does not pick the run; no command handed to the user (SC-001) |
| L9 | `/feat rebase` with two conflicting PRs, one needing a decision | the clean one pushed first; one gate at the end; then the second pushed (SC-007) |
| L10 | `/fix rebase` on a shipped fix | as L8, resolver context assessment.md and fix.md, no number check |
| L11 | `/feat rebase <PR>` on a PR from a fork, a PR URL of another repository, a hand-written PR, a branch name with a space or `;`, a state file with `Size: not set` | each skipped with its reason, before any spawn |
| L12 | `/feat rebase <PR>` on another author's PR | hard gate naming the author before any fetch; "stop" does nothing |
| L13 | Someone pushes to the PR branch during L8 | push refused, `! push refused: …`, nothing overwritten; the local branch is back on the PR head; a second `rebase` runs with no branch item |
| L14 | A resolution in L8 writes a line the secret scan matches (a key holding a literal value) | `PR: blocked`, `! secret scan: <file>:<line> matches <rule>`, never the value, nothing pushed |
| L18 | Main gained a commit adding a line the secret scan matches; `/feat rebase <PR>` on a run that doesn't touch it | the scan reads only what the PR brings onto the new main: pushed, no block |
| L15 | A `logistics-wip:` commit left on a shipped branch (hand-made) | the shipper blocks: `! WIP commit on <branch>; nothing pushed` |
| L16 | `/fix` run: main moves during phase 1, then the assess gate passes; later "back to 1" | no base check before phase 2; the first move is before phase 2; after "back to 1", none until phase 2 again |
| L17 | `/feat rebase` in a repo with more than 30 open PRs of yours, one conflicting past the 30th | found (no truncation) |
