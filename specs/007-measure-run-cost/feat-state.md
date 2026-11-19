# /feat state: Measure what a /feat or /fix run costs, from the session transcripts

- Branch: measure-run-cost Worktree: ~/Projects/logistics/.claude/worktrees/brief-measure-run-cost
- Size: medium
- Agents: specifier a39f34cc2e24b9604, planner a292de0416bcb8cd2, tasker a92879dbaa248a66a (for SendMessage)
- Current phase: done (shipping)
- Conventions: conventional commits `type(scope): short message`, one logical change per commit, concise, user-facing `feat`/`fix` subjects (CHANGELOG is generated from them; never edit it or any version by hand); never co-author, the user is the only author; stage only this task's files; `Closes #N` goes in the PR body, never in a commit message. Git: `/usr/bin/git` directly, one plain command per call (`cd <worktree> && /usr/bin/git …`), no heredocs, pipes or globs; fetch and rebase before pushing; never push to main. Shell is zsh: quote variables; `command rm -f`, `command cp -f`, `command mv -f` (the bare forms prompt and hang); never `pkill -f` a pattern in your own command line. Checks: `mise run lint` and `mise run test:apm` before committing, `mise run test:tracker`, `mise run test:spec-number`; shellcheck stays clean on `install.sh`, the scripts and the bash tests. Repo rules are in `.claude/CLAUDE.md` (size tables mirrored in `docs/workflow.md`, D2 diagrams re-rendered, a new `docs/` page needs `title` and `weight`). Never name private projects from outside this repo; use "a private project" or `~/Projects/my-app`.
- Allowed Spec Kit hooks: none
- Map: none
- Issue: #53

## Brief

# Brief: Measure what a /feat or /fix run costs, from the session transcripts
- Size: medium — ~35 tasks expected: one script with two modes and its options, fixture tests, a docs page; Python 3 becomes a requirement for it
- Short name: measure-run-cost
- Kind: feat
- Issue: #53

## Why
Two readers, one need: numbers on what a run costs and where its time goes.

- The maintainer judges changes to the workflow. Epic #31 was first filed on a mechanism (rules re-read on every coordinator turn) that measures at under 1% of a run; each of its items now states a target in calls per run, context size or cost share, and nothing in the repo can check one.
- A user of logistics on their own repos wants to see what their runs cost with their setup (their tools, skills and models), what to trim, and whether a change they made helped.

## Today
The numbers in #31 came from analysis scripts written once, outside the repo: unreviewed, untested, and only their author can read their output. Nothing is shipped, so a user has no way to look at their own runs.

Claude Code keeps what is needed, on the user's machine. Under `~/.claude/projects/` there is one folder per directory a session ran in, holding `<session>.jsonl`, and for its subagents `<session>/subagents/agent-*.jsonl` with an `agent-*.meta.json` (agent type, model, effort). Records carry, per model call, the token usage by kind (input, cache write, cache read, output), the model, the tool calls and a timestamp; other records carry the user's messages and their origin, tool results and whether they failed, the session's working directory and the Claude Code version. Recent versions also record what an agent's first request was made of (system prompt and tool schemas). This format is not a documented contract.

## Behaviour
- A script shipped with the feat skill, next to `tracker.sh`: `scripts/measure.py`, Python 3 standard library only. It only reads transcripts and prints to the terminal. In this repo, `mise run measure` runs the same file and passes its arguments through.
- A run is one session in which `/feat` or `/fix` was invoked (plain or `logistics:`-prefixed) and at least one `feat-*` agent was spawned. A run counts as finished when a `feat-shipper` agent was spawned in it, for both skills; medians use finished runs, and unfinished ones are counted and listed apart. A run's date is the date of its first record.
- **How the numbers are defined**:
  - cost share is a share of that run's total cost units: the coordinator and all its agents add to 100% for one run; medians of shares over several runs need not;
  - wall clock is split along the coordinator's own timeline, each gap between two of its events going to what ends it: a model reply (coordinator thinking), a tool result (coordinator tools), an agent's report arriving (agents working), a message the user typed (waiting for the user). The four parts add up to the run's duration, so agents running in parallel are not counted twice;
  - an agent's time split uses the same rule on the agent's own transcript: a gap ended by a model reply is model time, by a tool result tool time.
- **Report** (the default), per skill, as medians over the selected runs, with the number of runs:
  - coordinator: model calls, split into calls that spawn an agent, calls that only do chores (tool calls, no agent) and calls with text only; its context at the first call, the median and the maximum; its share of the run's cost; its failed tool calls by tool;
  - each agent type: spawns per run, model calls per spawn, context at its first call, share of the run's cost, and its time split between the model and tools;
  - wall clock: agents working, waiting for the user, coordinator thinking, coordinator tools; and how many times the user answered during the run;
  - what each agent type's first request is made of (tool schemas by name, the skills listing, the agent's own prompt, the instruction files), when the transcript records it, else "not recorded";
  - tokens by kind, and one weighted figure in cost units.
- **One run in detail**: `--session <id>` prints the same numbers for that run, not medians.
- **Comparison**: `--compare-since <date>` prints the medians of the runs before that date next to those since it, with the difference and the number of runs on each side. It makes no statistical claim. A side with no run prints "no runs" and the command still exits 0.
- **Which runs**: with no option, the repo the command is run in, including the runs made in its worktrees. `--project <path>` picks another repo; `--all` takes every project on the machine, one block per repo and one for the total. `--since` and `--until` bound the dates. Every date option takes `YYYY-MM-DD`, read in the user's local time zone. A selection with no run prints "no runs found" with where it looked, and exits 0. A worktree's sessions are stored in another folder than the repo's: they are attributed to the repo from what each transcript records, never from the folder's name.
- **Cost**: cost units weight each kind of token and each model. Defaults: input 1, cache read 0.1, output 5, and for a cache write 2 on the 1-hour cache and 1.25 on the 5-minute cache, told apart by the usage record's cache-creation breakdown (1.25 when the record has none); haiku 1, sonnet 3, opus 5. A model it has no weight for is named in the report and weighted as the highest default. `--weights <file>` names a JSON file that overrides any weight. When that file also gives prices, the report adds a dollar column; without prices it never prints money.
- **Transcripts it can't read**: record types it does not use are ignored. A run missing what the numbers need (a model call without token usage, an event without a timestamp) is left out whole and listed at the end with the reason and its Claude Code version; the other runs are reported. Every report says how many runs it counted and how many it left out. `--strict` exits non-zero when any run was left out.
- **What it prints**: counts, tool names, agent types, models, session ids, dates and repo paths. Never the text of a prompt, a file or a command.
- **Docs**: a new page, `docs/measure.md`: the command for each way of installing logistics, each option, how to read each number, the weights and prices file, what "left out" means, the Claude Code versions it was tested with, and its limits. `docs/workflow.md` gets a baseline section with its date and weights; its numbers are the maintainer's (see Acceptance). `docs/install.md` lists Python 3.9 or later as needed for this script only. `install.sh check` reports whether Python 3.9 or later is there, as a note: it is not counted as missing, so a user who never measures sees no failing check.

## Out of scope
- Reading a run's state file (soft and hard gates, what the user answered): it waits for #21's Log tags.
- A `/measure` skill.
- A built-in price table.
- Joining a run resumed in a second session into one run: each session is its own run.
- Runs of `/brief` and `/tiny`.
- Charts, HTML or any output but terminal text.
- Tests of statistical significance.

## Alternatives rejected
- Keep the one-off scripts and rerun them on request — unreviewed, untested, readable by one person, and no use to other users.
- A `mise` task only, in this repo — a user who installed the plugin or the APM package has no checkout of this repo, so the tool would not exist for them.
- A `/measure` skill — a model would read the output on every use, the cost this work is meant to cut.
- bash with `jq` — aggregating thousands of JSON records in bash is hard to test, and `jq` would be a new requirement anyway.
- Always print dollars from a built-in price table — it goes stale with every model release, and it is fiction for users on a subscription plan; shares and before/after differences are the same in units.
- Stop at the first record it does not understand — one old or odd session in a user's history would make the tool useless, and they cannot repair a transcript. Leaving a whole run out, visibly, never mixes good and bad data in one number.
- Every project by default — repos differ more than changes do (test suite, file sizes), so mixing them hides or fakes an effect, and it would print every other project's name unasked.
- Report only, or comparison only — the report explains a number that looks odd; the comparison is what judges a change.
- Drop the dollar column and the prices in the weights file (brief review) — the user chose it: people think in money, and it costs nothing to those who give no prices.
- Drop `--all` and its per-repo blocks (brief review) — the user works on several repos, and judging a change to logistics itself needs the runs of all of them.
- Drop the breakdown of an agent's first request, or leave it to a follow-up (brief review) — it is the part that tells a user what to trim, and it is how #54 was found; "not recorded" on older transcripts is accepted.

## Acceptance
- `mise run test:measure` runs the script offline on fixture transcripts and checks exact numbers: the coordinator's three kinds of calls, each agent type's spawns and calls per spawn, cost shares with the default weights, and the wall-clock split.
- With fixtures holding two runs before a date and two since, `--compare-since` prints both medians, the difference and both counts.
- A fixture session whose recorded directory is a worktree of repo A is counted for A; a session of a repo whose folder name merely starts with A's is not. `--project` and `--all` select as described, `--all` with one block per repo and a total.
- An override file changes the cost units; with prices in it the dollar column appears, without them no money is printed.
- A fixture run with a model call lacking token usage is left out and listed with its reason, the other runs are reported, and `--strict` exits non-zero. A record of an unknown type changes nothing.
- A fixture run without a shipper is listed as unfinished and is not in the medians.
- The output for the fixtures contains none of the prompt, file or command text the fixtures hold.
- The script imports only the standard library, opens files read-only and makes no network call.
- A comparison with an empty side, and a selection with no run, print their "no runs" line and exit 0.
- `mise run measure --help` prints the options.
- `mise run lint` compiles the script and stays clean, `mise run test:apm` checks the script is installed, and `install.sh check` reports Python 3.9 or later as a note without failing when it is absent.
- `docs/measure.md` exists with `title` and `weight`, and `docs/workflow.md` has the baseline section.
- Maintainer's steps in the PR, outside the task list (they need real transcripts, which no agent has offline): fill the baseline section's numbers from an `--all` run, and put that report next to #31's table with each difference explained.

## Constraints / decisions already made
- It ships in `.apm/skills/feat/scripts/`, so its options and output are a public interface from the first release.
- Python 3.9 or later, standard library only; no other new requirement.
- Read-only and offline: it writes nothing but its output and sends nothing anywhere.
- Fixtures are synthetic, written for the tests: never copied from a real transcript, which holds private code and prompts.
- The transcript format is Claude Code's and can change in any version: the docs name the versions tested, and the left-out rule above is how a change shows.
- Transcripts only; no state file.
- Money only from prices the user supplies.
- The default set of runs is the current repo and its worktrees.
- `mise run lint` shellchecks `.apm/skills/feat/scripts/*` today, which would pick up the Python file: narrow that glob to `*.sh` and add `measure.py` to the `py_compile` line.
- The bash test runner follows `tests/tracker/` and stays shellcheck-clean; a new page in `docs/` needs `title` and `weight` front matter.

## Log

- [x] 0 Setup — board ok (users/pdemagny/projects/2); #53 set to "In progress"; no Spec Kit hooks enabled; reused the brief's worktree, branch renamed to measure-run-cost
- [x] 2 Specify — soft
    Stories: US1 see what my runs cost and where the time goes, default report (P1); US2 judge whether a change helped, --compare-since (P1); US3 choose which runs are counted, default repo + worktrees, --project, --all, --since/--until (P2); US4 one run in detail, --session (P2); US5 weights file and optional dollar column (P2); US6 trust the numbers on odd transcripts, left-out runs, --strict (P2); US7 docs, install.sh check note, mise run measure --help (P3)
    Requirements: 23 (FR-001..FR-023) and 8 success criteria; FR-004 run and finished definition (shipper spawned, both skills); FR-006/007 wall-clock split along the coordinator timeline, summing to the run's duration; FR-012 attribution from the recorded cwd, never the folder name; FR-014/015 default weights, unknown-model rule, money only from user-supplied prices; FR-016/017 whole-run left-out rule and --strict; FR-018 output never contains prompt, file or command text; FR-021 install.sh check reports Python 3.9+ as a note; FR-023 lint glob narrowed to *.sh, py_compile covers measure.py
    Spec assumptions: 1. skill invocation is identified from the user-message origin, `logistics:` prefix included, exact method left to planning (recommended: keep as written); 2. medians are taken per metric over finished runs (recommended: keep as written); 3. a cache write with no breakdown is weighted as 5-minute cache, 1.25 (recommended: keep as written); 4. local time zone is the system's (recommended: keep as written); 5. baseline numbers in docs/workflow.md and the report next to #31 are the maintainer's steps, not tasks (recommended: keep as written); 6. Out of scope and Alternatives rejected not reopened (recommended: keep as written); 7. the brief's file names and tooling (measure.py, mise tasks, Python 3.9) kept as binding constraints though implementation-level, noted in the checklist (recommended: keep as written)
    Unchecked checklist items: none
- [x] 2 note — speckit-specify created `.specify/feature.json` (new file); the shipper leaves it out of the commits unless told otherwise
- [x] 3 Plan — plan.md, research.md, data-model.md, quickstart.md, contracts/ written; no blocker; size trigger: Python 3.9+ at runtime for measure.py only (decided in the brief, stays medium); constitution: violation of V "Scripts MUST be bash" (justified in Complexity Tracking); assumptions A1–A13, A1 (`mise run measure -- --help`, reword FR-002 and US7) and A2 (amend constitution V to allow a Python stdlib script, 1.2.0) need the user; gate merged with phase 4
- [x] 4 Design review — hard (findings above nice-to-have; A1 and A2 need the user; constitution violation V); reviewers 4a opus · medium, 4b sonnet · medium, 4c sonnet · high; paraphrase matches the brief. User: "make it python 3.11+ only, then ok". Python floor 3.9 → 3.11 everywhere (user; overrides the brief's 3.9 constraint above); A1 accepted (`mise run measure -- --help`); A2 accepted (amend constitution V, 1.2.0, wording says Python 3.11+); accepted D1–D22 as recommended (D9 with `feature_version=(3, 11)`, D13 in part); rejected D23 (as recommended); spec assumptions 1–7 and plan assumptions A3–A13 kept at their recommendations; checklist: nothing unchecked. Findings:
    - D1 [sec] medium — an unexpected parse exception prints a traceback that can quote transcript text (FR-018) → catch per session, fixed reason `unexpected record shape`, test with a wrong-typed `SECRET-` field — rec: accept
    - D2 [sec] medium — the `SECRET-` sentinel misses fields the script reads (tool_use inputs, command args, api-request-shape texts, instruction-file paths and bodies) → put it in every free-text fixture field — rec: accept
    - D3 [sec] medium — an `--all` report posted on public #31 would publish repo paths, home dir and session ids → "Before sharing the output" paragraph in docs/measure.md and the baseline note: post only the all-repos figures; no new option — rec: accept
    - D4 [design] medium — FR-008 "context at its first call (median and maximum)" vs the plan's three figures → reword FR-008 and US1 to first call, median and maximum over the run's calls, then median over runs — rec: accept
    - D5 [design] medium — spec and plan disagree: unknown model ("highest default" vs "highest weight in effect"), "agent's own prompt" vs whole system prompt, left-out reasons missing from FR-016 → spec takes the plan's wording and the full reason list — rec: accept
    - D6 [design] medium — a run is the whole session, so work before the `/feat` or `/fix` invocation is counted → start timeline, coordinator calls, agent files and user answers at the invocation record — rec: accept (user call: changes what a run is)
    - D7 [design] medium — a `/feat resume` session that ships counts as a finished run with only the tail phases → classify sessions invoked with `resume` as "resumed (not in the medians)", listed apart — rec: accept (user call)
    - D8 [design] medium — `.git` file whose gitdir has no `commondir` (submodule, separate git dir) is undefined → the repo is the directory holding the `.git` file; one fixture — rec: accept
    - D9 [design][cost] medium — Python 3.9 floor is unchecked; 4c wants a gate, 4b says review convention and no 3.9 interpreter → `ast.parse(..., feature_version=(3, 9))` in `mise run lint`, no new interpreter — rec: accept the lint line
    - D10 [design] medium — `--session <id>` of a left-out run is undefined → print its left-out line; exit 1 only with `--strict` — rec: accept
    - D11 [design] medium — `--compare-since` with `--all`, diff format, a type on one side only, unfinished and left-out lists are open → same compare layout per block, `-` for a missing side, signed whole percentage points, lists printed once with dates — rec: accept
    - D12 [design] medium — failed tool calls by tool as a median is nearly always 0 → total over the finished runs, with the number of runs — rec: accept the total (user call: departs from "as medians")
    - D13 [cost] medium — test surface larger than the acceptance needs (~20 golden cases, six stub binaries, static scan) → keep the golden cases that map to acceptance lines and merge the rest, only the stubs `install.sh check` needs; keep the static import/open-mode scan in the test (4a relies on it) — rec: accept in part
    - D14 [sec] nice-to-have — weights file accepts `true`, `NaN`, `Infinity` → valid only if int or float, not bool, finite, ≥ 0; tests — rec: accept
    - D15 [sec] nice-to-have — agent ids from transcripts are joined into a path unchecked → accept only `[A-Za-z0-9_-]+`, else `agent transcript missing` — rec: accept
    - D16 [sec] nice-to-have — transcript and filesystem strings printed unescaped → control characters replaced by `?`; one fixture with a tab in its cwd — rec: accept
    - D17 [cost] nice-to-have — first-request breakdown parsed for every spawn → only the first spawn of each type per run — rec: accept
    - D18 [cost] nice-to-have — repo resolution repeated per session → cache per distinct cwd — rec: accept
    - D19 [design] nice-to-have — which record's usage counts when records of one message id differ → the last record's usage, the first record's timestamp — rec: accept
    - D20 [design] nice-to-have — a compact-summary or meta record with the tag and no origin would leave a run out → ignore `isCompactSummary` and `isMeta` records for that rule — rec: accept
    - D21 [design] nice-to-have — docs limits: duration is wall clock between first and last event, idle time included — rec: accept
    - D22 [design] nice-to-have — update the lint task's description; docs/measure.md says the dev install uses the APM user-level path — rec: accept
    - D23 [design] nice-to-have — default-weights line quoted unchecked in docs/workflow.md's baseline → rec: reject (the baseline records the weights of its date; it must not track later defaults)
    - A2 vs 4b: 4b recommends keeping the recorded violation and dropping the constitution edit; planner recommends amending principle V (1.2.0) — rec: amend
- [x] 4 amend — planner (fresh spawn, opus · high) wrote A (3.11), A1, A2 and D1–D22 into spec.md, plan.md, research.md, data-model.md, quickstart.md, contracts/ and the checklist note; D23 not written; constitution check now passes by amendment (principle V, 1.1.0 → 1.2.0, planned as a task); no blocker; stays medium. New assumptions, all `needs user: no`, kept: A14 "resumed" = first word of the command args is `resume`, `--session` on it prints under a `resumed` heading; A15 records before the invocation are not read; A16 a pre-filtered session that raises while parsed is listed as left out; A17 in a comparison failed tool calls show each side's total and runs with an empty diff, share diffs as `+3pp`; A18 the install.sh check test stubs only claude, gh and python3; weights-file errors name the section and key only; `--session` keeps its own golden file
- [x] 5 Tasks — soft: tasks.md, 52 tasks (fits medium). Setup T001–T004; Foundational T005–T009; US1 T010–T018; US2 T019–T022; US3 T023–T027; US4 T028–T030, T039; US5 T031–T034; US6 T035–T038, T040; US7 T041–T046; Polish T047–T052 (T049 amends constitution V to 1.2.0, T050 the Shell line in .claude/CLAUDE.md). MVP: T001–T018. Analyze: ran (passes applied by hand, no report table), 0 CRITICAL, 0 HIGH; fixed by the tasker: unknown-model run moved into T010, T028 reworded, dependency note T049/T004; open LOW left as is: T049 comes in Polish while T004 creates the Python script (nothing is committed before phase 8). Checklist: nothing unchecked, proceed. Implementers in order: US1 T001–T018; US2 T019–T022; US3 T023–T027; US4 T028–T030; US5 T031–T034; US6 T035–T040 (T039 is US4's task, placed after the left-out work); US7 T041–T052
- [x] 6 US1 — not verified: none
    T001–T018 done; lint, test:measure, test:apm, test:tracker, test:spec-number pass; `Wrote:` listed the 42 created files and tasks.md, not the edited mise.toml and .github/workflows/check.yml (confirmed modified by git status). Handed on: T002's lint line shellchecks only tests/measure/run.sh, the US7 implementer adds `tests/measure/bin/*` when T045 creates the stubs; the compare fixtures (T019) change expected/report.txt; fixture arithmetic is in comments in tests/measure/run.sh. `.specify/feature.json` is ignored by git: nothing to decide
- [x] 6 US2 — not verified: none
    T019–T022 done; lint, test:measure (report, compare, compare-empty), test:apm, test:tracker, test:spec-number pass; compare layout set by the golden files (columns before, since, diff; diffs on unrounded values; a zero diff prints unsigned); expected/report.txt updated by hand for the new sess-feat-6 run; a `no_statistics` check fails on "significan" or "confidence" in the output
- [x] 6 US3 — not verified: none
    T023–T027 done; lint, test:measure (report, compare, compare-empty, project, all, no-runs), test:apm, test:tracker, test:spec-number pass; `--project`, `--all` (one `## <repo>` block per repo, then `## all repos`, lists once), inclusive `--since`/`--until`, "no runs found" with where it looked; fixtures other, tab-repo, lib added; no existing golden file changed. Open point, untested: with one date bound only, the window text prints the missing side as `start` or `now` (the contract does not set it)
- [x] 6 US4 — not verified: none
    T028–T030 done, T039 left for US6; lint, test:measure (plus session and two session-not-found checks), test:apm, test:tracker, test:spec-number pass; `--session` searches every project folder, one block headed `== /<skill> run <id>, <date>, finished|unfinished|resumed ==`; a left-out run prints its row and exits 1 only with `--strict`; no existing golden file changed. To look at in review: the header reads `measure: /feat and /fix runs session <id>` (the contract's wording taken literally)
- [x] 6 US5 — not verified: none
    T031–T034 done; lint, test:measure (plus weights, weights-prices, 12 weights error cases, no_money on report and weights), test:apm, test:tracker, test:spec-number pass; `--weights` merges over the defaults, a bad file exits 2 naming only section and key; with prices a `prices:` header line, a `USD` row in Tokens and an `unpriced models:` line; USD = tokens × token weight × price / 1e6, no model weight; no existing golden file changed
- [x] 6 US6 — not verified: none
    T035–T040 done; lint, test:measure (plus left-out, left-out --strict, strict-clean, session-left-out, unknown-record, static, read-only fixtures), test:apm, test:tracker, test:spec-number pass; `left out:` list printed once, sorted by date, repo, session; `--strict` exits 1 for every command when any selected run was left out; bug fixed: a run whose only feat-* agent had the defect was neither counted nor listed (`parse_agent` now keeps the agent's type), tested by sess-odd-1; fixtures `odd` (six left-out runs, one per reason, and one counted) and `unknown-record` added; expected/all.txt updated by hand (14 counted, 12 finished, 6 left out)
- [x] 6 US7 — not verified:
    - n/a → help golden on Python 3.11–3.13 → only 3.14 and 3.15 are installed here; the `help` case leaves argparse's usage paragraph out of the comparison (it wraps differently on 3.12) and checks a `usage: measure.py ` line exists; options, description and weights line are compared byte for byte
    T041–T052 done, all 52 tasks ticked; lint, test:measure (plus window, help, docs, install-check), test:apm, test:tracker, test:spec-number, test:secret-scan, `mise run diagrams` (docs/img unchanged) and the hugo docs build pass; one-bound window text (`start` / `now`) now tested and documented; docs/workflow.md Baseline section has marked places for the maintainer's numbers, none invented; constitution V amended to 1.2.0; lint line now shellchecks tests/measure/bin/*
- [x] 6 Implement — soft: tasks done: 52 (1 not verified); checks pass
- [x] 7 review move — #53 set to "In review"; diff command `/usr/bin/git diff d62d37a175651ab52edc5ed70bb98698a8e163f7` (131 files, 3573 insertions); new code, tests and docs marked with `git add -N`, the spec dir left untracked
- [x] 7 Code review — hard (S1–S3 security; B2, R1, R2, R4, R7 need the user); reviewers 7a, 7b opus · medium, 7c, 7d, 7e sonnet · medium; every acceptance criterion met (the `mise run measure -- --help` pass-through checked by hand only; the suite's `help` case calls the script directly); 7c: no finding, 661 MB synthetic history in 1.23 s and 71 MB. User: "B2: fix R1: fix found R2: extract find_invocation R4: fix R7: fix"; the other findings taken at the reviewers' recommendations. picked B1, B2 (refuse a missing `--project` path with exit 2, as recommended), S1, S2, S3, C1, C3, R1 (`found`), R2 (`find_invocation` only), R4 (`… runs, session <id>`), R7 (`1 run`, `1 finished run`); not applied, as the reviewers recommended: B3, C2, C4, R3, R5, R6, R8, R9. Findings:
    - B1 measure.py:560-573, 673 — a tagged session that spawned no feat-* agent can be listed as left out — rec: apply
    - B2 measure.py:239-247, 1248 — `--project` on a path that does not exist reports the parent's repo — rec: user (it changes the public CLI: refuse with exit 2, or answer "no runs found")
    - B3 measure.py:209-213 — `$CLAUDE_CONFIG_DIR/projects` override beyond the spec's wording — rec: skip (the offline tests need it; documented in docs/measure.md)
    - S1 .apm/skills/feat/scripts/measure.py — a malformed recorded directory can end the report with a traceback
    - S2 .apm/skills/feat/scripts/measure.py — the printed-string filter misses lone surrogates
    - S3 tests/measure/run.sh — the read-only static test allows the whole `os` module
    - C1 measure.py:694-695 — drop the unread run keys `version`, `start`, `resumed` — rec: apply
    - C2 measure.py:693-697 — `shipped` and `status` stored separately — rec: skip (changes the resumed-table output; saves 1 line)
    - C3 measure.py:751 — unreachable `else 1` — rec: apply
    - C4 measure.py:1005 — `isinstance(v, dict)` guard in `pick` — rec: skip (a one-line defensive guard of the accepted shape-safety design)
    - R1 measure.py:1208-1212 — local `blocks` shadows the function `blocks(msg)` — rec: user (reviewers disagree: both say rename, to `found` or to `sections_for`)
    - R2 measure.py:541-698 — `_parse_session` is 155 lines with five jobs; extract `find_invocation` and the spawn-result helper — rec: user (the longest function, tested only through the golden files)
    - R3 measure.py:1010-1022 — `order` named twice in separate scopes — rec: skip (a rename would be churn)
    - R4 measure.py:1153, 1190 — `--session` header reads "runs session <id>" — rec: user (reviewers disagree: apply now since the wording freezes at release, or ask since it changes output and a golden file)
    - R5 measure.py:1245 — `repo = None` means both `--all` and `--session` — rec: skip (clear enough as written)
    - R6 [std] measure.py:910-919 vs 1038-1047 and two more — row labels written in both `render_block` and `render_compare` — rec: skip (the golden files catch any drift, and the layouts differ in columns)
    - R7 [std] measure.py:1137, 1144 — headings read `1 finished runs` and `1 runs` — rec: user (cosmetic, but the wording freezes at release)
    - R8 [std] tests/measure/run.sh:465-474 — the `help` case leaves the usage paragraph out of the golden comparison — rec: skip (argparse wraps it differently across Python versions)
    - R9 [std] measure.py:1122-1126 — one date bound prints `start` or `now` — rec: skip (documented and tested)
- [x] 7 review fixes — not verified: none
    applied B1, B2, S1, S2, S3, C1, C3, R1, R2, R4, R7; lint, test:measure, test:apm, test:tracker, test:spec-number pass; B1, S1, S2 proved failing first; no performance change tried. B1: a tagged session with a defect and no feat-* agent is neither counted nor listed (fixtures sess-odd-7/8/9). B2: `--project` on a missing directory exits 2 with `--project: no such directory`. S1: a session whose recorded cwd cannot be resolved is left out as `unexpected record shape` with repo `unknown`, selected only by `--all` and `--session` (documented). S2: lone surrogates replaced by `?`. S3: the static test is an `os` allowlist. R4 and R7 changed golden files by hand (session.txt, weights.txt; all.txt, compare.txt, compare-empty.txt, left-out.txt, project.txt, report.txt, weights-prices.txt); docs/measure.md and contracts/cli.md updated
- [x] 8 Ship
