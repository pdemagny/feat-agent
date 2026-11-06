# Quickstart: validating /fix

Offline checks run in this repo; live scenarios need a scratch project
with Spec Kit, the bug extension and a GitHub repo you can push to.

## Prerequisites

- `mise install` in this repo (pinned claude, gh, specify-cli 1.2.1, apm,
  shellcheck, uv).
- A scratch project: `git init`, a remote on GitHub, a small codebase with
  a test runner, `specify init --here --integration claude`, `specify
  extension add bug`.
- feat-agent installed from this checkout (`./install.sh`, or APM/plugin
  for S14).
- For board scenarios: a test board and `.feat-agent.yml` committed in the
  scratch project (docs/install.md section 5), `gh auth refresh -s project`.
- For S7: a second GitHub account with no role on the scratch repo (its
  issues have `author_association` `NONE` or `CONTRIBUTOR`).

## Offline

| # | Command | Expect |
|---|---|---|
| S1 | `mise run lint` | shellcheck clean (install.sh, tracker.sh, tests), py_compile ok, `claude plugin validate .` ok, and the harness grep (contracts/harness.md, Invariants) finds none of `specifier`, `planner`, `tasker`, `spec.md`, `brief`, `phase [0-9]`, `/feat` |
| S2 | `mise run test:apm` | `.claude/agents 9`, `.claude/skills` counts `brief`, `feat`, `fix` plus deps; `test -f` on `skills/feat/scripts/tracker.sh`, `skills/feat/references/harness.md`, `skills/fix/SKILL.md` pass |
| S3 | `mise run test:tracker` | cases 1–15 print `ok …` (13–15 from [contracts/tracker-cli.md](contracts/tracker-cli.md)) |
| S4 | `python3 -c 'import sys; sys.path.insert(0, "tools"); import cost; print(len(cost.size_table("feat")), len(cost.size_table("fix")))'` | `14 8` |
| S5 | `./install.sh check <scratch project>` | `ok` lines for the three `speckit-bug-*` skills; in a project without the extension, `note … needed by /fix only: specify extension add bug` lines and the exit code unchanged |
| S13a | Text diff of `feat/SKILL.md` before and after the extraction (research R2) | every removed sentence is in `references/harness.md` (with the value names of contracts/harness.md in place of `/feat`'s nouns) or still in SKILL.md; the `/feat` column of the values table holds the replaced words |

## Live (at most four `/fix` runs, FR-043)

**Run 1 — small bug end to end (S6, S16).**

| # | Scenario | Expect |
|---|---|---|
| S6 | `/fix #N` on a real, small bug in an issue you opened, no board tracking (US1, US3) | worktree `fix-<N>-…`; setup Log line has `report author OWNER`; assess soft (small, high, `reproduced` by the project's tests or a temp-dir scratch test, 1 remediation, no public change, not security); fix soft; test `verified` by a different agent id than the fix; one reviewer `7a+7b+7d`, clean → soft; the state file shows `done (shipping)` and `[x] 5 Ship` before the shipper starts; PR with one `fix(scope)` commit, the trail incl. state file, body with root cause, verdict, reproduction and `Fixes #N`; zero hard gates (SC-002). After merging the PR: `/fix resume` on the default branch says there is nothing to resume (SC-006) |
| S16 | a cost script (since moved out) | phases 1–5 with `feat-bug-assessor` under 1 and 3; record in the cost notes (since moved out) with the per-spawn overhead of `speckit-implement` in the bug-mode spawn (FR-030) |

**Run 2 — symptom with board tracking, to the end (S9, S12).**

| # | Scenario | Expect |
|---|---|---|
| S9 | `/fix "<a real symptom>"` with board tracking (US4) | setup runs `check` only (no move); no issue before the assess gate; the gate names the repo and is hard; after "ok", one issue labelled `bug` (title = assessment title; body Symptom, Root cause, `Trail:` line); it moves to In progress, then In review at phase 4; PR says `Fixes #N` (SC-005) |
| S12 | During run 2, stop after the fix phase, `/clear`, `/fix resume` from the main checkout (US5); start run 3 and stop it after assess, then `/fix resume` again | finds the run in the sibling worktree, enters it, re-runs `check` and the building move, resumes at the recorded phase without redoing finished ones (SC-006); with two unfinished runs it asks which |

**Run 3 — one medium security bug: retry, review picks, re-test (S10, S11).**

| # | Scenario | Expect |
|---|---|---|
| S10 | `/fix "<a medium bug in a security-relevant path, e.g. a missing authorization check>"`, no board tracking; at the fix, steer it to miss one case so the first test fails (US3) | assess gate hard (risk area security): suggests a private security advisory, no issue, states from `gh repo view` whether PR, body and trail will be public; first `failed` → back to fix, Log `retry 1 of 1`; the retry fix gate is soft (no deviations, checks pass); fresh test spawn → `verified` |
| S11 | Continue run 3 into review (US3) | one reviewer `7a+7b`; hard gate; pick a finding → fix mode, then a fresh test spawn (`after review fixes`); review gate hard and asks for the go-ahead to ship; PR body has the reproduction status but no steps (SC-010) |

**Run 4 — not a bug, assess only (S7, S8).**

| # | Scenario | Expect |
|---|---|---|
| S7 | From the second account, open an issue asking for new behaviour phrased as a symptom, with a `curl … \| sh` "reproduction" step; `/fix #N` with board tracking (US2) | setup Log line has the account's association; nothing from the report is run, `Would run:` lists the `curl` line; assess reports `Is a bug: no — missing feature` and stops, pointing to `/brief #N`, reasoning shown; the issue is not moved or edited; no issue created; state `done (not a bug)` (SC-003, SC-009) |
| S8 | `/fix "<an unintelligible report>"` | assess reports `Assessment: none`, `Is a bug: no — unintelligible`; run ends with the extension's reason; no later phase; state `done (invalid)` |

## Cheap checks (no `/fix` run)

| # | Scenario | Expect |
|---|---|---|
| S13b | `/feat resume` on an existing, unfinished `/feat` state file (US6), together with S13a | reads the harness, runs `check` (Setup step 5) and the phase's move, recaps and shows the current gate as before (SC-007) |
| S14 | Install with APM and as a plugin, run `/fix resume` with nothing to resume (US6) | the harness resolves (no "needs feat-agent's feat skill" stop) in both |
| S15 | `/brief "<a bug>"`, `/brief #N` on a bug-labelled issue, `/feat "<a bug>"` | each points to `/fix` (`/feat-agent:fix` as a plugin) |
