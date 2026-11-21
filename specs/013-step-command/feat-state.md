# /feat state: Run each phase boundary of /feat and /fix with one command

- Branch: step-command Worktree: /home/pierre/Projects/logistics/.claude/worktrees/brief-step-command
- Size: large
- Agents: specifier a5e3e65997ed02c4b, planner ad23d9db4c29b0897, tasker a1ee02a4cbbade1e4 (for SendMessage)
- Current phase: done (shipping)
- Conventions: conventional commits type(scope): message, one logical change per commit, no co-author trailer; git as /usr/bin/git, one plain command per call (no $(), pipes, heredocs or globs); zsh, rm/cp/mv aliased to -i (use command rm -f etc.); checks: mise run lint, mise run test:apm, shellcheck, the offline mise run test:* tasks; sizes.json is the source, regenerate with mise run diagrams, never edit between sizes markers; agent frontmatter has no model/effort/tools/color; an agent report format and the orchestrator side change together; harness.md, rebase.md (and move.md) carry no /feat-only words; never edit versions, the release manifest or CHANGELOG.md; never name private projects from outside this repo; gh and mise calls may be refused after the rtk hook rewrites them: type the rtk form (rtk gh ...) in a call of its own
- Allowed Spec Kit hooks: none
- Map: none
- Issue: #28

## Brief

- Size: large — ~90 tasks expected (fresh reader: ~100): one bash command covering every gate of both skills and the boundaries inside phases, merge rules 2–6, the report, base and repair checks and the next spawn, plus #21's tags, the hand-back shrink across 8 agents, the skills' and harness' rewrite and the offline tests for each table row
- Short name: step-command
- Kind: feat
- Issue: #28

## Why
At each phase boundary the `/feat` and `/fix` coordinator applies rules a
script could apply exactly, one tool call and one model call at a time,
each re-reading about 110k tokens of context: check the report's `Wrote:`
paths, apply the gate table, merge review findings, run the base check,
look up the next agent's model and effort. The 2026-11-19 baseline
(`docs/workflow.md`, `## Baseline`) counts 62 coordinator calls per `/feat`
run (14 that spawn, 21 chores only, 26 text only) and 45 per `/fix` run (8,
21, 13); 167 `/feat` and 33 `/fix` coordinator Bash calls failed, most of
them command lines the worktree guard, a hook or the classifier refused. A
fixed command has neither cost. This is epic #31's main lever on the
coordinator; the users are the maintainer and anyone running `/feat` or
`/fix`.

## Today
- #27 (PR #68) moved the state file behind `state.sh`: each boundary's
  `set`, `log`, `refused-base` and `report-path` calls are chained into one
  Bash command, and agents write their full report to
  `<artifact dir>/reports/<key>.md` and hand back a digest.
- The coordinator still, by hand: runs `ls -d` on `Wrote:` paths; the base
  check (`git fetch`, then `git merge-base --is-ancestor`) as separate
  calls; the repair check on resume; applies the gate tables of
  `/feat` phases 2–7 and `/fix` phases 1–4, the routing inside them and the
  size triggers; merges review findings (harness, Review findings, rules
  1–6); reads the generated size tables in both SKILL.md files for each
  spawn's model, effort and reviewer groups.
- Only phase 2's Log line says whether its gate was soft or hard (`— soft`,
  `— hard (<why>)`, read by `state.sh phase2-mode`); no line says what the
  user answered in a fixed form (#21), so "how often does a soft gate turn
  hard" needs a model to read Logs.
- The digest still carries every field the gate rules read, because the
  coordinator applies them; `harness.md` carries the full "Moving onto a
  new main" section (move report, move gate, At ship) on every call,
  though moves are rare.

## Behaviour
- `step.sh` lives in `.apm/skills/feat/scripts/` (`/fix` reads it from
  `../feat`) and is the one Bash call at every boundary. Call forms:
  - `step.sh <skill> <state file> setup`: right after `state.sh init`;
    prints the first spawn (`/feat` phase 2, `/fix` phase 1);
  - `step.sh <skill> <state file> <phase> <report file>… [answer]`: after
    an agent or a batch of reviewers reported;
  - `step.sh <skill> <state file> size <s>`: the user's `size <s>` at a
    gate; logs it and prints the next spawn for the new size;
  - `step.sh resume <state file>`: the repair check, then the same output
    as the boundary call for the current phase.
- A boundary is also each step inside a phase: each `/feat` phase 6 story
  (hard after each one for large), the specifier and planner amends after a
  gate, 7e after 7a–7d, `7-fixes` and `4-fixes`, and `/fix`'s routing
  (phase 3 `failed` back to 2 once, 3 again after review fixes), which
  `step.sh` decides from `state.sh`'s `cycle` and `retry-used`.
- At each boundary `step.sh`:
  - checks each report's `Wrote:` paths (harness, Reported files, as #27
    left it, the shipper's renumbered dir included) and runs `unchanged`
    after a reviewer batch;
  - decides the verdict: `soft`, `hard:` with one reason per line (the
    size verdict where the phase checks it; a size increase is always
    hard), or `stop:` with its reason (`/fix` phase 1: not a bug);
  - for a review phase, applies merge rules 2–6 and prints the merged list
    with each finding's final `rec` and the counts the soft line needs;
  - writes the gate's Log line with its tag, `- [x] <N> <phase> [soft] — …`
    or `- [x] <N> <phase> [hard] — …`, and sets `Current phase:`, all
    through `state.sh`;
  - records the user's answer to the previous hard gate, passed
    single-quoted, as a sub-line under that gate's line: `    - answer:
    <kind> (user: "<words>")`, `<kind>` one of `approved`, `picked <ids>`,
    `changed`, `back to N`, `skip N`, `size <s>`, `stop`, `stay` (the move
    gate), `ship with <verdict>` (`/fix`), and per finding `fix <id>` or
    `leave <id>`, so a rejected finding keeps the user's words and is not
    proposed again, and logging the answer costs no call of its own;
  - runs the base check for the next phase and prints `same`, `refused`,
    `moved <old> <new>` (with "read `<path>/move.md`") or
    `fetch-failed: <first line>`;
  - gets the next report path and snapshot from `state.sh`, and prints the
    next spawn: agent, lenses, model and effort for the run's size, read
    from `sizes.tsv`.
- On a `soft` verdict the coordinator writes its short summary in the same
  turn as the next spawn, not in a turn of its own.
- A report `step.sh` cannot parse is always `hard`, with the line it stopped
  on. A `step: error` line from `step.sh` itself is logged as `- [!] step:
  <line>` and makes a hard gate whose only answers are `retry` (the same
  call) and `stop` (`/<skill> resume` later); nothing is spawned from
  memory.
- Every condition of a gate table maps to a fixed-value field of some
  agent's report (e.g. `Paraphrase: matches|contradicts`, `Risk area:
  security|none`). A condition no agent can report as a fixed value stays
  with the coordinator's override.
- The coordinator still writes the gate message, applies merge rule 1 (drop
  a Performance or Readability finding on code a cut removes), makes the
  board moves, and may make a soft gate hard when something is surprising:
  it then logs a `    - override: hard — <reason>` sub-line through
  `state.sh log`, chained onto a call it already makes.
- Every agent `step.sh` reads (`feat-specifier`, `feat-planner`,
  `feat-tasker`, `feat-implementer`, `feat-code-reviewer`,
  `feat-design-reviewer`, `feat-bug-assessor`, `feat-shipper`, and the
  rebase mode's `Move:` line) gets a report format `step.sh` parses safely
  (one field per line, fixed values) and a hand-back shrunk to what the
  coordinator needs beside `step.sh`'s output: the gate message inputs.
  Each agent's report format and its digest change together, once.
- `state.sh`'s queries (`phase2-mode`, `review-summary` and the others that
  read gate lines) read the tagged Log lines and the current untagged ones.
- The gate tables, merge rules 2–6 and the base and repair checks leave
  `/feat`'s and `/fix`'s SKILL.md and `harness.md`. The move report, the
  move gate, At ship and the move Log format move to
  `.apm/skills/feat/references/move.md`, read only when `step.sh` prints
  `moved` or the shipper reports `PR: conflict`.
- The generated size tables and the reviewer-group prose leave `/feat`'s
  and `/fix`'s SKILL.md. `sizes.json` stays the one source, and keeps
  shipping: `mise run diagrams` renders it into `sizes.tsv` (read by
  `step.sh`), `docs/workflow.md` and `models.svg` (for people), and
  `/brief`'s row-1 sentence.

## Out of scope
- Writing the gate message, merge rule 1 and the override: they stay with
  the coordinator.
- Board moves (`tracker.sh set-status`): two per run, they stay where they
  are.
- Scripting the ship (#57), setup and trail scripts (#29), configurable
  gates (#34, which builds on `step.sh`'s verdict output).
- Workflow scripts for medium and large fan-outs: measured after this lands
  (#56).
- `/tiny` (its `feat-code-reviewer` gets no report path) and `/brief`'s
  `feat-brief-reviewer`: unchanged.
- The "still waiting" text-only turns after background launches.

## Alternatives rejected
- One script per rule — the coordinator would still make one call per
  rule.
- A size lookup command — adds a call per spawn to replace a table read for
  free.
- A Workflow script (#56) — saved 2–3 coordinator calls per phase 7 stretch
  on small runs, has no file or git access, and is not available to every
  user.
- Re-basing the call targets on runs measured after #27 — there are not
  five runs of each skill to measure before #28; the targets are set
  against the 2026-11-19 baseline, #27's savings counting toward them.
- The epic's targets (`/feat` 35, `/fix` 25) — unreachable with spawns and
  text-only turns left in place (`/feat` 14 + 26 = 40 before any chore);
  replaced by targets derived from what this removes (Acceptance).
- The hand-back shrink as a follow-up issue — every agent's report contract
  would change twice (tightened now, shrunk later); both land here.
- Splitting the merge into its own PR — a review gate without the merged
  list leaves the coordinator re-deriving the counts its soft line needs.
- Splitting the `move.md` extraction into its own change (fresh reader,
  to pull the size back from the huge edge) — kept here: it is part of
  moving the base check out of the prose, and the user chose it in this
  brief.
- Dropping the "surprising makes it hard" override — kept, and logged, so
  #21's measurement tells rule-driven hard gates from judgment calls.
- Keeping the size tables in the SKILL.md files as a fallback — re-read on
  every call for nothing; a `step: error` is a hard gate instead.
- Keeping the move rules in `harness.md` — about 55 lines re-read on every
  call for a rare event; `step.sh`'s `moved` line points to `move.md`.
- `step.py` (Python 3.11) — would make Python a hard requirement of every
  `/feat` and `/fix` run, plugin installs included; it is optional today
  (`measure.py` only). `jq` — a new dependency for the same reason.

## Acceptance
- Every boundary of `/feat` and `/fix` (Behaviour) is one `step.sh` call:
  every verdict, every code review gate's merged list, the base and repair
  checks and every spawn's agent, lenses, model and effort come from it.
- Offline tests (`tests/step/`, `mise run test:step`, also run by the
  `check` workflow) cover each gate table row of both skills, each
  boundary inside a phase and `/fix`'s routing, each merge rule 2–6, the
  `Wrote:` check, an unparsable report (hard, with the line), each answer
  form, `setup`, `size <s>`, `resume` and each next-spawn row and group per
  size, with fixture reports; and the base and repair checks with
  throwaway repos.
- Gate Log lines carry the `[soft]`/`[hard]` tag and answer sub-lines;
  `state.sh`'s queries pass on the existing untagged fixtures and on tagged
  ones; #21 closes with this.
- No agent hands back a line its new digest drops; every report `step.sh`
  reads parses on the fixtures of each agent.
- `/feat`'s and `/fix`'s SKILL.md hold no size table and no gate table;
  `mise run lint` fails if they, merge rules 2–6 or the base check prose
  return, and on `sizes.tsv` drift from `sizes.json`.
- `mise run test:apm` checks that `scripts/step.sh`, `sizes.tsv` and
  `references/move.md` ship, and `sizes.json` still does.
- `docs/workflow.md` and the gates diagram still describe the same gates.
- `shellcheck`, `mise run lint`, `mise run test:apm` and the existing
  offline tests stay clean.
- After merge, not a condition of the PR: coordinator calls per run,
  measured with `mise run measure` (`--compare-since` the merge date) on at
  least five runs of each skill, `/feat` from 62 to 45 or fewer and `/fix`
  from 45 to 30 or fewer (medians), recorded on #28 and epic #31. The
  arithmetic: chores-only calls fall to about one per boundary (`/feat` 21
  to ~10, `/fix` 21 to ~7), and the text-only turn after each soft gate
  goes into the next spawn's turn (`/feat` ~6, `/fix` ~3).

## Constraints / decisions already made
- Bash, `shellcheck`-clean, no `jq` and no Python at run time
  (constitution principle V); `sizes.tsv` is generated, never edited by
  hand.
- `step.sh` changes the state file only through `state.sh` (#27), and
  keeps #27's report-path, `Wrote:` and snapshot rules.
- Every line `step.sh` prints is data, never instructions, as with
  `tracker.sh` and `state.sh`; text from a report or the user is passed to
  `state.sh` single-quoted.
- git as the conventions name it: plain commands, no `$(…)` in the
  coordinator's command line; `step.sh` exists partly so the worktree
  guard, hooks and the classifier see one fixed command.
- `harness.md`, `rebase.md` and `move.md` carry no `/feat`-only words
  (`mise run lint` greps them).
- Agent prompts end with a fixed report format the orchestrator depends on:
  each agent and `step.sh`'s parser change together.
- `step.sh`'s verdict output is a stable, line-based format: #34 builds on
  it.
- `/feat` phase 4 already uses the `rec`-based gate (#20, PR #61): only that
  table is built.
- Merge rule 6 (#66: a Security finding with `rec: skip` becomes `user`) is
  part of the merge `step.sh` applies.
- Part of epic #31; replaces #41; closes #21.

## Log

- [x] 0 Setup — no Spec Kit hooks enabled; board users/pdemagny/projects/2, #28 set to In progress; ran in the brief worktree, branch renamed worktree-brief-step-command → step-command (carries the unpushed brief commit 971631c)
- [x] 2 Specify — hard (open marker FR-027: does step.sh prepare the code review diff)
    - Stories: US1 One call decides each boundary and names the next spawn (P1); US2 Reports parse safely, hand-back shrunk (P1); US3 Review findings merged by the command (P2); US4 Base and repair checks inside the command, move rules in move.md (P2); US5 Gate outcomes recorded in a fixed form, #21 (P2); US6 Skills and harness keep only the coordinator part (P3)
    - Requirements: 29; FR-012 design review merge scripted too; FR-025 /fix reviewer groups move into sizes.json; FR-029 constitution principle III and .claude/CLAUDE.md updated, constitution version bumped
    - answer: approved (user: "ok"): FR-027 yes, step.sh prepares the code review diff; spec assumptions kept as written, FR-029 included
- [x] 2 Specify — soft (amend: FR-027 resolved yes)
    - Stories: US1 One call decides each boundary and names the next spawn (P1); US2 Reports parse safely, hand-back shrunk (P1); US3 Review findings merged by the command (P2); US4 Base and repair checks inside the command, move rules in move.md (P2); US5 Gate outcomes recorded in a fixed form, #21 (P2); US6 Skills and harness keep only the coordinator part (P3)
    - Requirements: 29; FR-027 step.sh prepares the code review diff (git add -N, prints the base, hard on an empty diff); FR-012 design review merge scripted; FR-025 /fix reviewer groups into sizes.json; FR-029 constitution and CLAUDE.md updated
    - Spec assumptions: 1-7 as shown at the phase 2 gate, kept by the user ("ok")
    - Unchecked checklist items: none
- [x] 3 Plan — approved (user: "ok"): exact task thresholds small <=30, medium 31-60, large >60; all planner assumptions kept as planned; no blocker, no size trigger, constitution pass (III and IV reworded, 1.4.0)
- [x] 4 Design review — picked D1-D12, D14-D28 (D18 option a; D23 shared-fixture test of both Log parsers); rejected D13 (user: "ok, as recommended": leave, follow-up issue under epic #31)
    - D1 contracts/agent-formats.md: Parsing rules — parser fails open on security fields
    - D2 data-model.md: Facts on gate lines — missing fact read as the safe value
    - D3 contracts/step-cli.md: Arguments — reports re-read without a hash check
    - D4 data-model.md: Diff preparation — add -N marks every untracked file
    - D5 contracts/gates.md: Every boundary step 5 — unparsable line text logged
    - D6 contracts/step-cli.md: Answers — dropped: accepts any id
    - D7 contracts/step-cli.md: Arguments — snapshot= not required
    - D8 contracts/gates.md: /fix 1 Assess — security answer optional
    - D9 research.md: R11 — Worktree line trusted as root
    - D10 research.md: R11 — default branch name unchecked
    - D11 contracts/gates.md: 8 Ship — shipper command prefix too loose
    - D12 spec.md: FR-008 — one reformat turn before an unparsable report goes hard — rec: user (brief says always hard)
    - D13 contracts/step-cli.md: Spawn block — list inputs to reports/<key>.in.md — rec: user (tokens not calls; changes every input contract)
    - D14 plan.md: Test harness — UPDATE=1 regenerates goldens — rec: apply
    - D15 contracts/agent-formats.md: Parsing rules — one-per-line fields read as empty — rec: apply
    - D16 contracts/coordinator.md: references/rebase.md — rebase loses its Wrote and Move checks — rec: apply
    - D17 contracts/step-cli.md: Output — no state: line after renumbering — rec: apply
    - D18 contracts/step-cli.md: Call forms — size form has no safe moment — rec: user (changes AC 1.10 and FR-002)
    - D19 data-model.md: The step function — phase 6 next story after a story gate — rec: apply
    - D20 contracts/step-cli.md: Output — answer call output undefined — rec: apply
    - D21 contracts/step-cli.md: Output — boundary line split on spaces — rec: apply
    - D22 data-model.md: Base check — Worktree none undefined — rec: apply
    - D23 research.md: R1, R6 — two Log parsers can drift — rec: user (adds a shipped file, reverses R1)
    - D24 contracts/sizes.md: sizes.tsv — install tuning misses group lines — rec: apply
    - D25 data-model.md: Facts on gate lines — assumption numbers lost — rec: apply
    - D26 research.md: R15 — merged 3 Plan line tagged as a gate — rec: apply
    - D27 contracts/step-cli.md: Answers — overridden soft gate answer args — rec: apply
    - D28 contracts/coordinator.md: harness.md — sentences name dropped values — rec: apply
- [x] follow-up: D13 filed as #69 (label feat); add it to the board and epic #31 by hand
- [x] 4 design amend — planner applied D1-D12, D14-D28 into spec, plan and contracts (new FR-030 to FR-034; FR-008/AC 1.6 one reformat turn per D12; FR-002/AC 1.10 size form per D18 a); step.sh ~1,700 lines; no blocker, no size trigger, constitution pass
- [x] 5 Tasks — hard (large; analyze CRITICAL: constitution III vs move.md and step.sh); 108 tasks (setup/foundational 33, US1 26, US2 9, US3 12, US4 9, US5 5, US6 7, polish 7); story.sh: match; size large kept
    - answer: approved (user: "ok"): widen the 1.4.0 amendment of principle III (R18, plan row III, FR-029, T103, T104); tasker reruns analyze and names its edits to contracts/step-cli.md and contracts/coordinator.md
- [x] 5 Tasks — hard (tasker contract edit changes the design); analyze rerun: none open; 108 tasks; story.sh: match
    - answer: approved (user: "ok"): keep the step: error " (not logged)" suffix in contracts/step-cli.md and contracts/coordinator.md
- [x] 6 US1 — not verified:
    - n/a → tests/step/run.sh under a real bash 3.2 → no bash 3.2 on this host (the construct grep passed)
- [x] 6 Implement — hard (large, after US1): 59/59 tasks, checks pass; Wrote: lists new files only (241 files changed)
    - answer: approved (user: "ok"): continue to US2
- [x] 6 US2 — not verified: none
- [x] 6 Implement — hard (large, after US2): 9/9 tasks, checks pass
    - answer: approved (user: "ok"): continue to US3
- [x] 6 US3 — not verified: none
- [x] 6 Implement — hard (large, after US3): 12/12 tasks, checks pass, /tiny unchanged
    - answer: approved (user: "ok"): continue to US4
- [x] 6 US4 — not verified: none
- [x] 6 Implement — hard (large, after US4): 9/9 tasks, checks pass; 39 earlier goldens regenerated
    - answer: approved (user: "ok"): continue to US5
- [x] 6 US5 — not verified: none
- [x] 6 Implement — hard (large, after US5): 5/5 tasks, checks pass; step.sh not on Wrote: (tags likely landed in US1-US3)
    - answer: approved (user: "ok"): continue to US6 with polish
- [x] 6 US6 — not verified:
    - T107 → quickstart step 7, scratch /feat small and /fix runs on a project installed with ./install.sh → needs interactive Claude Code sessions; step 8 ran only on the hand-run state file
    - n/a → SC-008, median coordinator calls after merge (mise run measure --compare-since) → after the merge, needs five runs of each skill
- [x] 6 Implement — hard (large, after US6, last story): tasks done: 108 (3 not verified); all checks pass
    - answer: approved (user: "ok"): go to phase 7 Code review
- [x] tracker: #28 set to "In review"
- [x] 7 review diff — base 78389e5, new files marked intent-to-add (feature files only), 518 files changed (+17277 -1496)
- [x] 7 Code review [hard] — picked B1, B2, B3, B4, B5, S1, S2, S3, [std]1, R1, R2, R3, R4, R6, R7; rejected [std]2 (as recommended), R5 (as recommended), R8 (as recommended), P1 (as recommended), P2 (as recommended), C1 (as recommended); criterion not met: US5-3 (fixed by B1)
    - answer: picked (user: "B3: a, and ok"): B3 option a, idempotent retry
    - B1 step.sh:512-528 — override not found after soft gate followed by untagged entry — rec: apply
    - B2 step.sh:3035-3049, 3260-3273 — wrote: sub-lines not logged without Not verified line — rec: apply
    - B3 step.sh:255-279, 2869-2876 — retry after partial write misroutes — rec: user (FR-008 names retry)
    - B4 spec US5 AC 3 / FR-016 — override after soft gates (as B1) — rec: apply
    - B5 spec FR-027 — wrote: paths unrecorded (as B2) — rec: apply
    - S1 step.sh — reviewer call report set not checked against the batch
    - S2 step.sh — sum= not required at 7e and reformat calls
    - S3 step.sh — directory on Wrote: widens git add -N
    - [std]1 step.sh:3035-3049, 3257-3273, 2659-2672 — one log_who helper — rec: apply
    - [std]2 step.sh:465, 489, 1177, 1270, 3651, 3673 — one table per skill — rec: skip (churn now; with #34)
    - R1 step.sh:1017-1045 — name check_report args — rec: apply
    - R2 step.sh:1017-1095 — split check_wrote, in_wrote — rec: apply
    - R3 step.sh:2934-3012 — split dec_feat_5, rename locals — rec: apply
    - R4 step.sh:2981 — 30/60 thresholds commented — rec: apply
    - R5 step.sh:3472-3555 — extract do_answer blocks — rec: skip ([std]2 reshapes the same lines)
    - R6 step.sh:309, 324, 1245 — name read columns — rec: apply
    - R7 step.sh:1929 — rename madd locals — rec: apply
    - R8 step.sh:3257-3273 — rename NVF — rec: skip (do it in the [std]1 merge)
    - P1 step.sh:268-270, 1137 — batch state.sh forks — rec: skip (tens of ms per boundary)
    - P2 tests/step/run.sh — parallel test:step — rec: skip (27 s offline is proportionate)
    - C1 step.sh:1782 — inline joined — rec: skip (4 lines, names a concept)
- [x] 7 review fixes — B1 applied (soft gate range runs to the next tagged line; 3 cases); B2 + [std]1 applied (log_who, wrote: under both who-lines); B3 applied (option a: repeat check skips trailing step: lines, commit undoes its field sets on error; 4 retry cases); S1 applied (batch_covered, answer ids equal logged ids); S2 applied (sum= required at 7e and reformat); S3 applied (only exact wrote: paths marked); R1, R2, R3, R4, R6, R7 applied; R8 done inside log_who (NV_SEEN); no existing test or golden changed, 18 new goldens; checks: lint, test:step, test:state, test:sizes, test:story, test:apm pass; not verified: none
- [x] 8 Ship
