# Quickstart: validating step-command

Run from the worktree root. Each step names the requirement it checks.

## 1. Offline checks (SC-002, SC-005, SC-006)

```sh
mise run lint
mise run test:step
mise run test:state
mise run test:sizes
mise run test:story
mise run test:apm
```

All pass, with no stderr from `tests/step`; `log-readers-agree` is among
the `tests/step` cases. `mise run diagrams` leaves `git status` clean
(`sizes.tsv`, `docs/workflow.md`, `docs/img/*` already rendered).

`UPDATE=1 bash tests/step/run.sh` exits non-zero and leaves `git diff
tests/step/expected` empty on a clean tree (FR-028).

## 2. The guards fail when they should (FR-026)

One at a time, then revert:

- paste the old size table back into `.apm/skills/feat/SKILL.md` → `mise
  run lint` fails;
- add a line `first match wins` to `.apm/skills/fix/SKILL.md` → fails;
- add `reviewers disagree` to `harness.md` → fails;
- add `git merge-base --is-ancestor` to `harness.md` → fails;
- add `*size triggers*` to `harness.md` → fails;
- add the word `planner` to `references/move.md` → fails;
- change one effort in `sizes.json` without `mise run diagrams` → fails on
  `sizes.tsv`;
- delete `references/move.md` → `mise run test:apm` fails.

## 3. One boundary by hand (US1)

```sh
mkdir -p /tmp/step-qs/specs/x
bash .apm/skills/feat/scripts/state.sh init feat /tmp/step-qs/specs/x/feat-state.md '<a brief path>' 'Branch=x' 'Worktree=/tmp/step-qs' 'Size=small' 'Current phase=2 Specify'
bash .apm/skills/feat/scripts/step.sh feat /tmp/step-qs/specs/x/feat-state.md setup
```

(`/tmp/step-qs` must be a git repo with an `origin` for the later base
checks: `git init /tmp/step-qs` and a bare clone as `origin` will do.)

Prints `soft`, one `spawn: feat-specifier` block with the small row's model
and effort and a `reports/2-specify.md` path, and a `boundary:` line whose
words are tab-separated (`cat -A` shows `^I`). Copy a fixture specifier
file from `tests/step/fixtures/agents/specifier/` to that path (fix its
`Wrote:` items), run the `boundary:` call, and read the Log: `- [x] 2
Specify [soft] — spec.md written` and four sub-lines.

Copy instead the fixture in today's layout (bare paths under `Wrote:`):
the call prints `reformat`, an `unparsable line:` line and a reformat
spawn of the specifier with a new report path; the Log gains `- [!] 2
Specify — unparsable: 2-specify.md: line <n> (Wrote); reformat 1 of 1`
and no text of the line. The same layout at the new path makes the next
call `hard:` with `- unparsable: 2-specify-2.md: line <n> (Wrote)`.

Edit the state file's `Worktree:` to another directory: the next call is
`step: error: Worktree: … is not the state file's top level …`.

## 4. A hard gate and its answer (US5)

With a fixture whose `Open markers:` is `1`: the call prints `hard:` and
`- open markers: 1`, an `answer call:` line (with the report's `sum=`),
and logs `- [x] 2 Specify [hard] — open markers: 1`. Repeat the call with
`'answer: approved (user: "ok")'`: the Log gains `    - answer: approved
(user: "ok")` and the output is `answered`, then the specifier amend
spawn. Repeat it once more: `refused: no hard gate open`, nothing logged.
Try `'answer: maybe (user: "x")'`: `refused`. Edit the report between the
hard call and the answer call: `hard:` with `- report changed since
checked: 2-specify.md`, no answer logged.

`size large` while no gate is open: `size: small → large` and nothing
else; the next boundary's spawn has the large row's model and effort.

## 5. Merge rules (US3)

`tests/step` cases `merge-rule-2` … `merge-rule-6` and `merge-zero`: each
prints the expected `finding:` lines, final `rec` and `counts:`. Inspect
one golden to see `user (reviewers disagree)` on both findings of rule 3.

## 6. Base and repair checks (US4)

`tests/step` repo cases: `base-same` prints `base: same` and logs nothing;
`base-moved` prints `base: moved <old> <new>`, `read: …/move.md` and a
rebase-mode spawn; `base-refused` prints `base: refused`; `base-fetch-failed`
logs `- [!] move — git fetch failed (…)`; `repair-ref` and `repair-wip`
make `resume` print `action: repair`; `diff-empty` is hard with `empty
diff`; `diff-new-files` marks intent-to-add only the untracked files of
the implementers' `wrote:` facts (`added: <path>`), leaves a user's
untracked `notes.txt` out of the index and the diff (`untracked, not in
the diff: notes.txt`) and prints `diff: git diff <sha>`;
`worktree-none` and `space-in-path` run the same checks in the repo the
state file is in and under a path with a space; `default-branch-dash`
is `step: error: no default branch`.

## 7. Scratch runs (SC-001)

On a scratch project with logistics installed from this checkout
(`./install.sh`):

- `/feat` on a small brief: every boundary's Bash call is one `step.sh`
  command (plus the override or the board move where one applies); no
  `$(…)`, no `ls -d`, no `git merge-base` in the coordinator's commands;
  each soft summary shares its turn with the next spawn.
- `/fix "<a symptom>"` with a failing first test (or a fixture forcing
  `failed`): phase 3 goes back to 2 once without stopping, then is hard.
- Stop at a hard gate, `/feat resume` in a fresh session: the same phase
  restarts; an answered gate's amend is not redone.

## 8. Counting gates (SC-003, #21)

On the state file of step 7:

```sh
grep -c '^- \[x\] .* \[soft\] — ' feat-state.md
grep -c '^- \[x\] .* \[hard\] — ' feat-state.md
grep -c '^    - override: hard — ' feat-state.md
grep -o '^    - answer: [a-z]*' feat-state.md | sort | uniq -c
```

Each number matches what happened in the run.

## 9. After merge (SC-008)

`mise run measure -- --compare-since <merge date>` on at least five runs of
each skill: median coordinator calls `/feat` ≤ 45, `/fix` ≤ 30; record on
#28 and epic #31.
