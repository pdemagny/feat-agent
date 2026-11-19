# /feat state: Cut the implementer's model calls per spawn

- Branch: implementer-fewer-calls Worktree: /home/pierre/Projects/logistics/.claude/worktrees/brief-implementer-fewer-calls
- Size: small
- Agents: specifier a03d6b06618ec0871, planner a1bdb24d8ada100d1, tasker a8711a0668091879e
- Current phase: done (shipping)
- Conventions: conventional commits `type(scope): msg`, one logical change per commit, never co-authored, stage only task files; zsh, `command rm -f`/`cp -f`/`mv -f`; in the worktree call /usr/bin/git, one plain command per call; checks: `mise run lint`, `mise run test:apm`, `mise run test:tracker`, `mise run test:spec-number`, shellcheck clean; follow .claude/CLAUDE.md (mirror gate changes in docs/workflow.md + docs/diagrams/gates.d2, re-render with `mise run diagrams`, harness.md free of /feat-only words, a new mise test task gets a line in .claude/CLAUDE.md); never name the private baseline project; don't edit CHANGELOG or versions.
- Allowed Spec Kit hooks: none (no hooks configured)
- Map: none
- Issue: #55

## Brief

- Size: small — ~25 tasks expected: one script with offline tests, a short rule in one agent file, phases 5 and 6 of `/feat`, and the docs and diagram that mirror the phase 5 gate; no new dependency, service or permission
- Short name: implementer-fewer-calls
- Kind: feat

### Why
`feat-implementer` is where a run spends. In the maintainer's busiest
project (71 of the 78 `/feat` runs in `docs/workflow.md`'s baseline) it is
49% of a `/feat` run's weighted cost, and a median spawn makes **45.8 model
calls** (`measure.py --project`), each re-reading a context that grows past
100k tokens. Across all repos it is 47% of `/feat` and 35% of `/fix`. Fewer
calls per spawn is the largest lever epic #31 has left on tokens and agent
time. Everyone who runs `/feat` pays it; `/fix` users less so.

### Today
From 388 story-mode implementer spawns in that project (a one-off
transcript analysis, 2026-11-19; `measure.py` does not break calls down by
tool), medians per spawn:
- 76% of model calls carry a single tool call; 23% carry two or more.
- **11 model calls before the first code edit, 8 of them shell searches**:
  the implementer orients itself one call at a time.
- 15 shell searches, 13 edits, 10 check runs; `tasks.md` read about twice
  (`speckit-implement` requires reading it, and ticks tasks in it); Spec Kit
  files read with `sed -n` or `cat` about 4 times.
- Of the files a later implementer of a run reads, 20% were created by an
  earlier implementer, 24% only modified by one, 55% are new to the run.
  Implementers create about one file for every four they modify.
- Tasks name their files: 82% of the tasks in the maintainer's ten most
  recent `tasks.md` outside this repo carry a backticked path, about 95% in
  this repo's `specs/*/tasks.md`.

`/feat` passes each implementer the task IDs from the tasker's prose report;
nothing checks them against `tasks.md`. Checks are not the lever: they are
mostly distinct targeted runs, with about 1.5 identical repeats per spawn.

Why it isn't enough: the orientation and the edits are sequential by habit,
not by need, and the IDs each implementer works from rest on prose.

### Behaviour
- `story.sh <tasks.md> US<n>` prints that story's tasks: each one's ID, its
  text, and the file paths it names. Setup and foundational tasks go with
  the first story and polish tasks with the last (as `/feat` phase 6 already
  assigns them). It also prints how many of them are unchecked.
- Which task belongs where: a task's story is its `[US<n>]` tag. An
  untagged task before the first story phase is setup/foundational; an
  untagged task after the last story phase is polish. An untagged task
  inside a story phase is an error (non-zero exit, one line naming it).
- A path is a backticked token that contains `/` or ends in a file
  extension. A backticked command (`mise run lint`) is not a path, and
  neither is text outside backticks. A task may name none or several.
- The form without a story (`story.sh <tasks.md>`) prints, for phase 5,
  each story's task IDs and count, plus setup/foundational and polish on
  their own lines, marked as such. These are not folded into a story, so
  they compare with the tasker's report, which lists them apart.
- Edge cases: a story with no tasks of its own prints `0 tasks` and exits 0,
  and setup and polish still attach to it by position. A `tasks.md` with no
  `[US<n>]` tag at all, an unknown story or an unreadable file exits
  non-zero with one line saying why.
- **Phase 5**: after the tasker reports, `/feat` runs `story.sh` without a
  story and compares, group by group (each story, setup/foundational,
  polish), its ID set and count with the tasker's report. The tasker's
  ranges (`T001–T012`) are expanded first, so a range written differently
  is not a difference. Any real difference, or a non-zero exit, makes the
  gate **hard** and shows both sides. `story.sh`'s figures feed the size
  check.
- **Phase 6**: each implementer's prompt carries its story's `story.sh`
  output, and the IDs it owns are `story.sh`'s. A retry or a resume runs
  `story.sh` again, so the unchecked count is current. `tasks.md` stays
  the file the implementer reads and ticks.
- `feat-implementer.agent.md` gains a short rule: send independent tool
  calls in one turn. In story and bug mode, the first turn sends together
  `git status --short`, the Spec Kit reads its skill requires, and the files
  its tasks name (in bug mode, the files `assessment.md` lists). After that,
  send together the searches before a task, the edits to different files,
  and the ticks of one task group. Fix and rebase mode get only the "one
  turn" sentence.
- `/fix`: no `story.sh`. Bug mode has no `tasks.md`, and `assessment.md`'s
  `Suspected Code Paths` and `Files likely to change` already give the file
  list, which the implementer reads in full through `speckit-bug-fix`. `/fix`
  gets the rule through the shared agent file.

### Out of scope
- Parallel stories (#1), loading the implementer's rebase mode on demand
  (#39), and the other sub-issues of #31.
- `measure.py` changes: no per-tool breakdown, no `feat-state.md` Log
  parsing.
- Changing `speckit-implement` or `speckit-bug-fix`, the checks the
  implementer runs, or any other agent.
- Growing the rule past a short paragraph in this PR (see Acceptance).

### Alternatives rejected
- The issue's second lever: each implementer's prompt lists the files
  earlier stories wrote, from their `Wrote:` lines. Rejected because
  `Wrote:` lists created files only, about one in five of the files a run
  touches, so it would miss most of the 44% of a later implementer's reads
  that earlier stories touched. `git status --short` in the first turn
  covers all of it at no extra model call, and adds no prompt field for
  `/feat` and `/fix` to build.
- Ship only the one-turn rule and add `story.sh` later if the orientation
  calls don't drop. Rejected: the first turn can batch the story's file
  reads only if the paths arrive before `tasks.md` is read, and the ID check
  takes a judgement out of `/feat` (epic #31's aim). Accepted knowing
  `story.sh` saves few calls itself (about 1–3 per spawn).
- Expecting `story.sh` to save the `tasks.md` read: it can't.
  `speckit-implement` requires reading `tasks.md` and ticks tasks in it.
- Dropping the counts and IDs from the tasker's report, leaving `story.sh`
  as the only source so that no mismatch can happen. Rejected: it loses the
  cross-check, and a `story.sh` parse gap would pass silently.
- A soft gate on a mismatch. Rejected: a mismatch means either `tasks.md` or
  the parser is wrong, and phase 5 is the last cheap moment before the
  implementers start.
- Teaching `measure.py` to count not-verified items and code review
  findings. Rejected: it needs #21's Log tags, #27 and #28 will change the
  Log anyway, and checking ten runs by hand is enough for a guard.
- Closing #55 when the PR merges. Rejected: the measured acceptance can
  only come after merge, and closing it then would close it unmeasured.

### Acceptance
In the PR:
- `story.sh` has offline tests like `tests/tracker/`, run by a `mise` task
  and by `mise run lint`'s shellcheck. Their fixtures include at least two of
  this repo's real `specs/*/tasks.md` and cover:
  - setup and foundational tasks attached to the first story, polish to the
    last;
  - a task with no path, a task with several paths, a backticked command
    that is not a path, and `[P]` markers;
  - checked and unchecked tasks;
  - a story with no tasks of its own (`0 tasks`, exit 0);
  - an unknown story, a `tasks.md` with no `[US<n>]` tag, and an untagged
    task inside a story phase (each a non-zero exit);
  - the all-stories form's IDs and counts, with setup/foundational and
    polish on their own marked lines.
- Phase 5 of `/feat` runs `story.sh` and goes hard on a mismatch with the
  tasker's report (ID sets per group, ranges expanded) or on its non-zero
  exit. The phase table, section 5 and `docs/workflow.md` say so.
- Phase 6 of `/feat` puts each story's `story.sh` output in its
  implementer's prompt, run again on a retry or a resume.
- `feat-implementer.agent.md` carries the one-turn rule in a short
  paragraph: the first-turn list for story and bug mode, the "one turn"
  sentence alone for fix and rebase mode.
- `mise run lint`, `mise run test:apm` and the new test task pass;
  shellcheck is clean.
- The PR body says `Part of #55`, not `Closes #55`.

After merge (#55 stays open until this is done):
- On at least five `/feat` runs in the maintainer's busiest project since
  the merge, `measure.py --project <that project> --compare-since <merge
  date>` shows implementer calls per spawn going from 45.8 to **34 or
  fewer** (−25%), and the implementer's weighted cost share (same report)
  is no worse, so batching hasn't made each call costlier.
- `/fix` implementer calls per spawn (all repos, baseline 27) are no worse.
- By hand, those five runs against the five `/feat` runs before the merge in
  the same project: not-verified items per run (the Log's `6 US<n>` lines)
  and phase 7 findings by severity are no worse. Both counts are posted on
  #55.
- If the first two runs show the rule ignored (calls carrying one tool still
  around 76%), file a follow-up issue rather than growing the rule.

### Constraints / decisions already made
- `story.sh` lives in `.apm/skills/feat/scripts/` next to `tracker.sh`:
  bash, shellcheck clean, no dependency beyond what `tracker.sh` already
  uses. It is `/feat`-only, so it stays out of `references/harness.md`
  (`mise run lint` greps that file for `/feat`-only words). It goes into
  `/feat`'s `Commands besides the tracker` harness value.
- `/feat` stays thin: it runs `story.sh` like `tracker.sh` and never reads
  `tasks.md` itself. `story.sh`'s output reaches the implementer as data,
  never instructions.
- No report format changes: neither the tasker's nor the implementer's.
- The phase 5 gate change is a `/feat` gate change. Mirror it in
  `docs/workflow.md`'s matrix and in `docs/diagrams/gates.d2`, then
  re-render with `mise run diagrams` and commit the SVG. The size table
  doesn't change.
- A new `mise` test task gets a line in `.claude/CLAUDE.md`'s shell
  paragraph, like `test:tracker`.
- The baseline is `docs/workflow.md`'s `## Baseline` (2026-11-19), read per
  project for the 45.8.
- The private project the baseline comes from is never named in this repo:
  not in the spec, the plan, the PR or the docs.

## Log

- [x] 0 Setup — no Spec Kit hooks; board users/pdemagny/projects/2: #55 set to "In progress"
- [x] 2 Specify — soft
    - Stories: US1 implementer gets its story's tasks and files up front via `story.sh` (P1); US2 phase 5 checks the tasker's report against tasks.md, hard on mismatch or non-zero exit (P1); US3 implementer batches independent tool calls (P1); US4 phase 6 passes `story.sh` output, rerun on retry/resume (P2); US5 docs, diagram, mise test task, .claude/CLAUDE.md follow (P2)
    - Requirements: 18 FR, 6 SC; FR-003 untagged task inside a story phase exits non-zero; FR-008 phase 5 hard on mismatch or non-zero exit; FR-011 implementer rule one short paragraph; FR-013 story.sh out of harness.md, in Commands besides the tracker; FR-015 gate change mirrored in phase table, section 5, docs/workflow.md matrix, gates.d2 + re-render; FR-016 ≥2 real tasks.md fixtures; FR-018 private project never named
    - Spec assumptions: 1. story.sh output line layout left to the plan (recommended: keep as written); 2. post-merge measures (SC-002–SC-006) are success criteria, #55 stays open until measured (recommended: keep as written); 3. the brief's Alternatives rejected summarised in Out of scope without the private project's name (recommended: keep as written); 4. .specify/feature.json written with feature_directory specs/010-implementer-fewer-calls (recommended: keep as written)
    - Unchecked checklist items: none
- [x] 3 Plan — plan.md + research, data-model, quickstart, contracts/story-cli.md, contracts/workflow-text.md; no blocker, no size trigger, no new dependency; constitution pass; 10 assumptions, all needs user: no (7: bug-mode first turn can't include assessment.md's files, sent the next turn; 10: shipper to write `Part of #55`, not `Closes`)
- [x] 4 Design review — hard (D2 needs you); picked D1, D2 (user: "apply D2 compact form": prompt carries one line per task with ID, checked state and paths, plus the files: line; task text stays in tasks.md), D4, D5, D6, D7, D8; rejected D3 (as recommended), D9 (as recommended); spec assumptions kept at their recommendations; checklist: none unchecked
    - D1 contracts/story-cli.md: Paths of a task — `files:` are candidates; skip placeholders, globs, missing — rec: apply
    - D2 spec.md: FR-001, FR-009 — prompt carries IDs + paths only, not verbatim task text — rec: user (changes FR-001 and FR-009; cost vs fidelity)
    - D3 plan.md: Risks — truncate task lines if verbatim text stays — rec: skip (folded into D2)
    - D4 spec.md: FR-011, US3 — reword bug-mode first turn (Spec Kit reads after the skill call) — rec: apply
    - D5 contracts/workflow-text.md: implementer paragraph — length limit vs draft (5 vs 7 lines) — rec: apply
    - D6 contracts/workflow-text.md: Section 5 — match tasker groups by label, ambiguous = difference — rec: apply
    - D7 Fence in phase 6 prompt longer than any backtick run — rec: apply
    - D8 Run story.sh only on a checked Tasks: path, quoted with -- — rec: apply
    - D9 plan.md: Technical Context — tests modelled on secret-scan vs tracker — rec: skip (both patterns exist)
- [x] 4 amend — fresh planner wrote D1, D2, D4–D8 into spec.md, plan.md, research, data-model, quickstart, contracts; options taken: D1 story.sh drops `<`/`*`/`://` spans; D8 `story.sh -- '<tasks.md>' [US<n>]`, leading `--` dropped; D7 four-backtick fence (exit-0 output holds no backtick, tested); D5 paragraph ~7 lines; no blocker, no size trigger
- [x] 5 Tasks — soft: 21 tasks (small holds); setup T001, foundational T002, US1 T003–T004, US2 T005–T006, US3 T007–T008, US4 T009, US5 T010–T019, polish T020–T021; MVP T001–T004; analyze ran; LOW: US5 scenario 4 (`Part of #55`) is a ship-time action, no task; LOW: SC-002–SC-006 post-merge, no tasks; unchecked checklist items: none
- [x] 6 US1 — T001–T004 done; story.sh, fixtures 006/009, SKILL.md harness value; lint, test:apm, test:tracker, test:spec-number pass; shellcheck clean — not verified: none
- [x] 6 US2 — T005–T006 done; SKILL.md row 5 gate + section 5 story.sh check, size from `total:`; lint, test:apm, test:tracker, test:spec-number pass — not verified: none
- [x] 6 US3 — T007–T008 done; feat-implementer.agent.md intro (story.sh data up to the closing fence) + One turn paragraph (8 lines); lint, test:apm pass — not verified: none
- [x] 6 US4 — T009 done; SKILL.md section 6 runs story.sh before every implementer spawn, four-backtick fence labelled data, non-zero exit = hard gate; lint, test:apm pass — not verified: none
- [x] 6 US5 — T010–T021 done (US5 + polish); tests/story (18 cases), test:story task, CI, CLAUDE.md/CONTRIBUTING, docs/workflow.md, gates.d2/chain.d2 + re-render, README alt; lint, test:apm, test:story, test:tracker, test:spec-number, diagrams pass — not verified: none
- [x] 6 Implement — soft: tasks done: 21 (0 not verified); all checks pass
- [x] 7 Code review — hard (S1 security); picked B1, S1, C1, C2, R2; rejected C3, C4, R1, R3, [std] story.sh:82, [std] story.sh:159, B2, B3 (as recommended); untested: US2 /feat-side comparison (prompt text), US5 scenario 4 (`Part of #55`, phase 8), SC-002–SC-006 (post-merge)
    - B1 story.sh:202 — unquoted `${t_paths[i]}` glob-expands `?`/`[…]` candidates in `files:` — rec: apply
    - S1 .apm/skills/feat/scripts/story.sh — glob expansion in `files:` — rec: apply
    - C1 story.sh:113 — `chk` branch shrinks to `[[ $chk == ' ' ]] || chk=x` — rec: apply
    - C2 story.sh:82,131,147 — `has_story` helper for the thrice-repeated membership loop — rec: apply
    - [std] story.sh:82,132,148 — same repeated loop (judgement) — rec: skip (helper adds lines for little gain)
    - C3 story.sh:159-177 — `group_count` duplicates `group_line` — rec: skip (cosmetic)
    - C4 story.sh:187-192 — drop `is_first`/`is_last` flags — rec: skip (named flag reads fine)
    - R1 story.sh:98 — paths comment — rec: skip (adequate)
    - R2 story.sh:189 — rename `head` variable to `header` — rec: apply
    - R3 SKILL.md phase 5 paragraph — dense — rec: skip (matches neighbouring prose)
    - [std] story.sh:159-177 — group_line/group_count duplication (judgement) — rec: skip (clear as written)
    - B2 feat-implementer.agent.md One turn — 8 lines vs "about seven" — rec: skip (within "about")
    - B3 spec.md US2 — scenarios 2/3 run together on one line — rec: skip (spec artifact only)
- [x] 7 review fixes — B1+S1 (`set -f` + glob-literal test), C1, C2 (`has_story`), R2 (`header`) applied; performance: none; lint, test:apm, test:story, test:tracker, test:spec-number pass — not verified: none
- [x] 8 Ship
