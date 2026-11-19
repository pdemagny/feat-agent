# Quickstart: validating the size data feature

Run from the worktree root. Tools from `mise install` (`d2`, `apm`,
`shellcheck`); Python 3.11 or later on the PATH.

## 1. The D2 source is unchanged (SC-004), before `models.py` goes

```bash
python3 docs/diagrams/models.py > /tmp/models-old.d2
python3 -I docs/diagrams/sizes.py --d2 > /tmp/models-new.d2
cmp /tmp/models-old.d2 /tmp/models-new.d2
```

Expected: no output. Then, once `models.py` is removed:
`mise run diagrams` followed by `git diff --exit-code docs/img` exits 0.

## 2. First generation changes only labels and padding (US1-1, SC-003)

```bash
mise run diagrams
git diff --word-diff main -- .apm/skills docs/workflow.md
```

Expected: no `model · effort` value changes. The only word changes are the
FR-005 labels in `docs/workflow.md`'s `/feat` matrix ("Brief review
(`/brief`)", 4a–4c without "∥", "Tasks", "Implement") and `/fix` matrix
("Fix"), the added markers, the reflowed `/brief` sentence and the prose
edits listed in the plan. The two SKILL.md tables are unchanged apart from
the markers; the `/fix` matrix and the agents table change in padding.
A second `mise run diagrams` changes nothing.

## 3. One edit, one command (US1-2, SC-001)

In a scratch copy (or revert afterwards): change `feat` row `4b`'s
`medium` to `opus` · `high` in `.apm/skills/feat/sizes.json`, run
`mise run diagrams`, then `git diff --stat`.

Expected: `.apm/skills/feat/SKILL.md`, `docs/workflow.md` and
`docs/img/models.svg` change, and only on that value (the agents table's
cell stays: it shows small values). Do the same with row `1`'s `small`:
`.apm/skills/brief/SKILL.md`'s sentence and the agents table's
`feat-brief-reviewer` cell change too. Revert with `git checkout --`.

## 4. Lint fails on drift (US2, SC-002)

```bash
mise run lint                                    # passes
sed -i 's/| 8 Ship /| 8 Shop /' .apm/skills/feat/SKILL.md
mise run lint                                    # fails: names .apm/skills/feat/SKILL.md
git checkout -- .apm/skills/feat/SKILL.md
sed -i 's/<!-- sizes-end fix-matrix -->//' docs/workflow.md
python3 -I docs/diagrams/sizes.py --check; echo "exit $?"   # marker fix-matrix: unpaired, exit 2
python3 -I docs/diagrams/sizes.py; echo "exit $?"           # same error, nothing written
git checkout -- docs/workflow.md
```

## 5. Offline tests (FR-018, SC-005)

```bash
mise run test:sizes
```

Expected: every case passes: fresh copies match `tests/sizes/expected/`,
a second run writes nothing, check passes on fresh and fails (exit 1,
naming each file) on stale, hand-edited and data-changed copies; missing,
unpaired, duplicated and unknown markers fail in both modes (exit 2,
nothing written); an agents-table line without a row and a row agent
without a line fail; `--d2` matches `expected/models.d2`, whose small
code-review cell takes its model and its effort from different rows; the
agents table holds a one-value cell and a two-value cell.

## 6. The data file ships (US3, SC-006)

```bash
mise run test:apm                 # includes test -f .claude/skills/feat/sizes.json
jq -r '.feat.rows[] | select(.id == "3") | .large.model' .apm/skills/feat/sizes.json   # opus
python3 -c 'import json; print(len(json.load(open(".apm/skills/feat/sizes.json"))["fix"]["rows"]))'   # 8
node -e 'console.log(Object.keys(JSON.parse(require("fs").readFileSync(".apm/skills/feat/sizes.json"))))'  # [ 'feat', 'fix' ]
```

## 7. Rules follow the new source (US4)

Read `.claude/CLAUDE.md`'s first two bullets and constitution principle
III: they name `.apm/skills/feat/sizes.json`, say to run `mise run
diagrams`, forbid editing marked copies, and keep the group-prose rule.
`grep -rn models.py --exclude-dir=specs .` finds nothing.
