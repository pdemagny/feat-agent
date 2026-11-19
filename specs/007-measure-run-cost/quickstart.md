# Quickstart: validate `measure.py`

## Prerequisites

- A checkout of this repo with `mise install` done (shellcheck, git).
- `python3` 3.11 or later on `PATH`.

## Offline checks (what CI runs)

```sh
mise run lint            # shellcheck *.sh, run.sh and stubs; py_compile measure.py; its syntax against Python 3.11
mise run test:measure    # fixtures → golden outputs, exit codes, privacy, static checks
mise run test:apm        # measure.py lands in .claude/skills/feat/scripts/
```

Expected: `test:measure` prints one `ok <case>` per case and exits 0; a
failure prints `FAIL <case>: <why>` with the output.

## Scenarios the tests cover (spec → case)

| Spec | Case | Expect |
| --- | --- | --- |
| US1 1–4, FR-004 | default report in `app` | golden `report.txt`: call kinds, spawns, calls per spawn, shares, wall clock summing to the duration from the invocation, first-request lines and one `not recorded`; work before the invocation not counted; unfinished and resumed runs listed apart |
| US1 5, SC-004 | every case | no `SECRET-` in any output (the sentinel is in every free-text fixture field) |
| US2 | `--compare-since` on 2 + 2 runs; on a date with no run before | both counts and diffs; `no runs`, exit 0 |
| US3 | from `app`; `--project other` with `--since`/`--until`; `--all`; empty selection | worktree and deleted-worktree sessions counted, `app-old` not; runs outside the window not counted; one block per repo (the tab repo printed with `?`, `lib` with a `.git` file and no common dir as its own repo) and `all repos`; `no runs found …`, exit 0 |
| US4 | `--session <id>`; `--session` on a left-out id | golden `session.txt`; its `left out:` row, exit 0, then 1 with `--strict` |
| US5 | `--weights` without and with `prices`; unknown model; invalid files | units change; `USD` appears only with prices; `unweighted models:` line; `true`, `NaN`, `Infinity`, `1e400`, `-1` and the other errors exit 2 |
| US6 | runs without usage, without a timestamp, with a wrong-typed field, with an invalid agent id; unknown record type appended; `--strict` | listed under `left out:` with reason (`unexpected record shape` for the wrong-typed field) and version; output unchanged by the unknown record; exit 1 only with `--strict` |
| US7 | `install.sh check` with stub `python3` failing / passing; `mise run measure -- --help` | `note` line naming Python 3.11, same exit code both ways; the options |
| FR-003 | static check; fixtures read-only | stdlib imports only, no write mode, no network module; runs succeed on read-only files |

## By hand, on your own transcripts

```sh
cd ~/Projects/my-app
python3 ~/.claude/skills/feat/scripts/measure.py                 # this repo and its worktrees
python3 ~/.claude/skills/feat/scripts/measure.py --compare-since 2026-11-01
python3 ~/.claude/skills/feat/scripts/measure.py --all --strict
```

In a checkout of logistics: `mise run measure -- --help`, `mise run measure
-- --all`.

Before posting any output: it holds repo paths, your home directory and
session ids. Post only the all-repos block's figures, without the per-repo
blocks or the unfinished, resumed and left-out lists.

## Maintainer's steps (outside the tasks, need real transcripts)

1. `mise run measure -- --all` and fill `docs/workflow.md`'s Baseline section
   with the all-repos block's figures, its date and weights line.
2. Post those figures next to #31's table, explaining each difference.
