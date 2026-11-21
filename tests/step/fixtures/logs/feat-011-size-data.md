# /feat state: generate the size tables and every copy of them from one JSON data file

- Branch: size-data Worktree: /home/pierre/Projects/logistics/.claude/worktrees/brief-size-data
- Size: small
- Agents: specifier a07d34b037d22099d, planner a8cd750774f6207ec, tasker aaf5b35b08b9f10e6 (for SendMessage)
- Current phase: done (shipping)
- Conventions: conventional commits `type(scope): message`, one logical change per commit, never co-author (the user is the only author); zsh, `rm`/`cp`/`mv` aliased to -i (use `command rm -f`); call `/usr/bin/git` directly, one plain command per call; `gh`/`mise` may be rewritten by the rtk hook and refused — type `rtk gh …` / `rtk mise …` yourself, one such call per response; `mise run lint` and `mise run test:apm` before committing; `.claude/CLAUDE.md` holds the mirroring, diagrams (`mise run diagrams`, commit `docs/img`), lint and docs rules; CHANGELOG is generated, never edited; a PR says `Closes #N` in its body, never in a commit message.
- Allowed Spec Kit hooks: none
- Map: none
- Issue: #30

## Brief

# Brief: generate the size tables and every copy of them from one JSON data file, and fail lint on drift
- Size: small — ~20–28 tasks expected: one data file, one Python generator with a check mode (absorbing `models.py`), markers in four files, offline tests, lint and rule updates; no new dependency
- Short name: size-data
- Kind: feat
- Issue: #30

## Why
Maintainers of logistics change a model or an effort by hand in up to six
places, and nothing fails when one is missed. The data also needs a form
that #28's boundary command can read later to print the next spawn's
model and effort, whatever language #28 ends up in (bash with jq, Python
or a Workflow script in JS, pending spike #56).

## Today
Models and efforts are written by hand in:
- `.apm/skills/feat/SKILL.md`, `## Size table` (with a `Loads` column;
  the phase number inside the label cell, e.g. "1 Brief review
  (`/brief`)");
- `.apm/skills/fix/SKILL.md`, `## Size table` (same shape);
- `docs/workflow.md`, `## Size × phase matrix`: the same rows with a
  separate `#` column, other labels ("Brief review", "Tasks + analyze",
  "Implement (×1 per story)", "∥" on parallel lenses), no `Loads`, plus a
  "1 Brief / your session" row and a `huge` column;
- `docs/workflow.md`, `/fix`'s `### Size matrix` (no `Loads`; row 2 is
  "Fix (review fixes and moves)"; one row overflows its column);
- `docs/workflow.md`, `## Agents`: its "small size" column, not
  column-padded (the bug assessor's cell holds both modes: "opus · medium
  (assess), sonnet · medium (test)");
- `.apm/skills/brief/SKILL.md`: row 1 written out as prose ("small and
  medium `sonnet` · `medium`, large `opus` · `medium`").

The reviewer groups are prose under each size table and, for `/feat`,
again as Python lists in `docs/diagrams/models.py`, which parses `/feat`'s
markdown table to draw `docs/img/models.svg`. `.claude/CLAUDE.md` and
constitution principle III ask for every copy to change in the same
commit; only the SVG is checked (CI renders and diffs `docs/img`).

## Behaviour
- `.apm/skills/feat/sizes.json` (shipped with the skill, so #28's command
  can read it in an install; the path is a contract for #28) holds, per
  skill (`feat`, `fix`): each row's `id` (e.g. `1`, `4a`), `label`
  (without the id), agent, `Loads` and model · effort per size (small,
  medium, large); and `/feat`'s reviewer groups per size (the lists
  `models.py` holds today).
- One label per row, used by every copy. The generator joins id and label
  for the skills ("1 Brief review (`/brief`)") and puts the id in the
  docs' `#` column. The docs' wording changes, and only these labels:
  - `/feat` 1 "Brief review" → "Brief review (`/brief`)";
  - `/feat` 4a–4c lose "∥";
  - `/feat` 5 "Tasks + analyze" → "Tasks";
  - `/feat` 6 "Implement (×1 per story)" → "Implement";
  - `/fix` 2 "Fix (review fixes and moves)" → "Fix".
  What the dropped words said stays in the prose under each table (one
  implementer per story; review fixes and moves use the phase 6 / phase
  2 row).
- A Python generator replaces `docs/diagrams/models.py` (kept in
  `docs/diagrams/`, renamed, e.g. `sizes.py`) and, from the JSON:
  - rewrites the text between HTML comment markers in
    `.apm/skills/feat/SKILL.md`, `.apm/skills/fix/SKILL.md`,
    `.apm/skills/brief/SKILL.md` (an inline pair around row 1's sentence)
    and `docs/workflow.md` (both matrices and the agents table). Table
    markers wrap the whole table, header included;
  - adds the docs-only parts as fixed template text: the "your session"
    row, the `huge` column ("first capability's size" on row 1, "—"
    elsewhere), no `Loads` column in the docs;
  - in the agents table, replaces only the "small size" cells, in place;
    its other columns (phases, denied tools, loads, writes) stay
    hand-written. A cell is the agent's distinct small values across both
    skills' rows: one value is printed as is; several are each printed
    with their row's label in lowercase, which gives the bug assessor's
    "opus · medium (assess), sonnet · medium (test)";
  - prints the D2 source of `models.svg`, as `models.py` does today, with
    `/feat`'s groups read from the JSON.
- A missing, unpaired or duplicated marker is an error in both modes,
  naming the file and marker: a lost marker never makes the check pass.
- Padding is normalised to the widest cell of each column, so the `/fix`
  docs matrix and the agents table get a whitespace-only change once.
- The coordinator reads the same values in the same markdown table it
  reads today: nothing changes at run time.
- A check mode (e.g. `--check`) exits non-zero and names each file whose
  marked text differs from a fresh generation; `mise run lint` runs it.
- A mise task (or `mise run diagrams`) regenerates everything: changing a
  model or effort is one edit to the JSON plus one command.
- The reviewer-group prose under each table stays hand-written: it holds
  conditions ("7e with 7d's cuts", "for a performance bug") that a
  generated sentence can't carry. The check does not cover drift between
  `/feat`'s group lists in the JSON and that prose; the mirroring rule
  for it stays in `.claude/CLAUDE.md`.
- `.claude/CLAUDE.md`'s mirroring rules and constitution principle III
  are rewritten: the JSON is the source of truth for models, efforts and
  loads; the marked copies are generated, never edited by hand.

## Out of scope
- A runtime lookup command printing a spawn's model and effort: #28's
  boundary command does that, from this JSON.
- Removing the tables from the SKILL.md files: decided in #28's brief,
  once its command prints the next spawn (a question added to #28).
- `/fix`'s reviewer groups in the JSON: no consumer reads them yet, and
  they depend on conditions ("for a performance bug"); #28 adds them with
  those conditions when it needs them.
- Generating the reviewer-group prose, or the agents table's other
  columns (e.g. denied tools from the agents' `disallowedTools`).
- Changing any model, effort or group: the JSON starts with today's
  values.

## Alternatives rejected
- The SKILL.md markdown tables as the generator's input (no new file, no
  constitution change) — splitting cells on ` · ` is a fragile input for
  #28's command in bash or JS, and the reviewer groups can't live in a
  markdown table.
- TOML or YAML — YAML needs a dependency in Python; TOML is read-only in
  Python's standard library and unreadable by jq or JS without one. JSON
  is read by all three.
- A bash and jq generator (constitution V prefers bash) — building padded
  markdown tables, the strongest-of-a-group rule and in-place marker
  rewrites in four files is the JSON aggregation where principle V allows
  Python.
- A second label per copy (`doc_label`) to keep the docs' wording — a
  second label is one more field that drifts unnoticed.
- An agent-to-rows mapping in the JSON for the agents table — the rows'
  `agent` field already gives it.
- Dropping the agents table's "small size" column and pointing to the
  matrices — the user wants it kept and generated.
- Removing the tables from the SKILL.md files now — until #28 prints the
  spawn, the coordinator would need a tool call to read the JSON (the
  issue's reason against a lookup command), and the saving is well under
  1% of a run per the measured baseline.
- Shipping the generator in `.apm/skills/feat/scripts/` — it only serves
  this repo's sources, never an install.
- A permanent fixture of today's values — the PR's one-time diff against
  `main` proves the first generation; the tests pin the generator's logic.

## Acceptance
- Changing one model or effort is one edit to the JSON plus one
  generate command; after it, every copy (both skills, `/brief`, both
  docs matrices, the agents table's cell, `models.svg`) shows the new
  value.
- `mise run lint` fails, naming the file, when any marked copy is edited
  by hand, a JSON change is not regenerated, or a marker is missing,
  unpaired or duplicated; it passes on a fresh generation.
- The PR's diff of the generated copies against `main` changes no
  model · effort anywhere: only the labels listed under Behaviour and
  whitespace padding change.
- `mise run diagrams` produces a `models.svg` identical to today's.
- Offline tests under `tests/` cover generate and check with a fixture
  JSON: a drifted copy fails, a fresh one passes, a missing or duplicated
  marker fails, the strongest-of-a-group cell, and an agents-table cell
  with one value and with several.
- `mise run lint` stays clean (the generator compiled and syntax-checked
  against Python 3.11, like `measure.py`); `mise run test:apm` checks
  `.claude/skills/feat/sizes.json` lands in an install.
- `.claude/CLAUDE.md`'s mirroring paragraph shrinks to "edit the JSON,
  run the generator" (plus the group-prose rule); constitution principle
  III names the JSON.

## Constraints / decisions already made
- Python 3.11 or later, standard library only (constitution V), run with
  `python3 -I`.
- Markers are HTML comments (as release-please's in `docs/install.md`);
  the website renders raw HTML (`hugo.toml`: `unsafe = true`), so they
  stay invisible there.
- `measure.py` stays the only script in the shipped `scripts/`; the JSON
  ships, the generator does not.
- Every place naming `models.py` or "read from the size table" follows
  the rename and the new source: `mise.toml`'s `py_compile` list (lint),
  its `diagrams` task and description, and `docs/workflow.md`'s "drawn
  from the size table by `mise run diagrams`".
- The CI step that renders and diffs `docs/img` stays.
- #28 reads this JSON; its path and format are a contract for #28's
  brief.

## Log

- [x] 0 Setup — no Spec Kit hooks; board users/pdemagny/projects/2 ok; #30 set to "In progress"; branch renamed worktree-brief-size-data → size-data (worktree already on origin/main + the brief commit)
- [x] 2 Specify — soft
    - Stories: US1 Change a model or effort in one place (P1); US2 Lint fails on drift or a bad marker (P1); US3 The data file ships and is readable from jq, Python or JS (P2); US4 Rules, constitution III, mise.toml and docs follow the new source; models.svg unchanged (P2)
    - Requirements: 19 FRs, 6 SCs; FR-001 sizes.json at .apm/skills/feat/sizes.json with today's values; FR-005 only the listed labels change; FR-007 agents-table cell rule; FR-008 bad marker is an error in both modes; FR-011 --check names each differing file, lint runs it; FR-013 models.svg identical; FR-018 offline tests with a fixture JSON
    - Spec assumptions: 1. generator named sizes.py; flag, mise task, marker text and JSON field names left to the plan (the field names become #28's contract) (recommended: keep as written); 2. huge column is fixed template text, no huge values in the JSON (recommended: keep as written); 3. today's copies already agree, so the first generation changes only labels and padding (recommended: keep as written); 4. added edge case, not in the brief: an agents-table agent with no JSON row, or the reverse, fails the generator (recommended: keep as written); 5. no .specify/feature.json, the shipper numbers the dir (recommended: keep as written)
    - Unchecked checklist items: none
- [x] brief moved into this file; specs/briefs/size-data.md deleted
- [x] 3 Plan — plan.md, research.md, data-model.md, quickstart.md, contracts/sizes-json.md, contracts/sizes-cli.md; no size trigger, no blocker, no new dependency; constitution pass (III amended, 1.2.0 → 1.3.0)
    - Planner assumptions (all needs user: no, recommended: keep): 1. one command is `mise run diagrams` (writes copies, then renders); 2. one marker pair wraps the whole agents table, only `small size` cells replaced and table re-padded; 3. JSON shape `{"feat":{"rows":[…],"groups":{"4":{size:[[ids]]},"7":{…}}},"fix":{"rows":[…]}}`, row `{id,label,agent,loads:[…],small|medium|large:{model,effort}}`, no version field, unknown keys fail; 4. diagram column titles fixed in the generator, fail if `/feat` phases differ; 5. only haiku/sonnet/opus and low…max accepted; 6. wording updates beyond FR-016 (SKILL.md source-of-truth sentences, docs/usage.md Tuning, CONTRIBUTING.md, check.yml comment, CLAUDE.md Python bullet); 7. exit 0 clean / 1 drift / 2 error, generate writes nothing on error; 8. constitution 1.3.0 (MINOR); 9. note for #28: installed sizes.json can disagree with hand-tuned tables
    - Markers: `<!-- sizes-start NAME -->` / `<!-- sizes-end NAME -->`, NAME in feat-table, fix-table, brief-review (inline), feat-matrix, fix-matrix, agents-table; CLI `sizes.py [--root DIR] [--check | --d2]`
- [x] 4 Design review — auto-applied D1, D2, D3; skipped D4 (reviewer: "R4 already records this as accepted; the same command fixes it"), D5 (reviewer: "decided in the brief"); spec assumptions 1–5 kept at their recommendations; checklist: none; paraphrase matches the brief
    - D1 data-model.md: Row table — schema forbids only `|` in label; tighten label/agent/loads, reject unknown top and skill keys — rec: apply
    - D2 plan.md: Text changes — SKILL.md source sentence read by the coordinator; word it for the prompt, no path in /fix — rec: apply
    - D3 plan.md: Text changes — sweep remaining "size table" authority prose (design.md, install.md, workflow.md:522, usage.md:308) — rec: apply
    - D4 contracts/sizes-cli.md: Messages — padding drift in agents table looks like JSON drift — rec: skip (R4 already records this as accepted; the same command fixes it)
    - D5 [cost] sizes.json ships unread until #28 — rec: skip (decided in the brief)
- [x] 5 Tasks — soft: 26 tasks (US1 T006–T012, US2 T013–T018, US3 T019, US4 T020–T025; setup T001, foundational T002–T005, polish T026); size small confirmed; analyze ran, 0 open findings (LOW fixed: T001 saves old D2 output before the rename, now in T003); checklist: none
- [x] 6 US1 — T001–T012 done; checks: --d2 byte-identical to old models.py, mise run diagrams pass (models.svg unchanged, rerun idempotent), mise run lint pass; lint ast check now loops over all args — not verified: none
- [x] 6 US2 — T013–T018 done; checks: test:sizes pass (28 cases), mise run lint pass (incl. sizes.py --check, shellcheck tests/sizes/run.sh), quickstart 4 by hand pass — not verified: none
- [!] 6 US3 — tasks.md not on Wrote: (reported "Wrote: none (modified only: mise.toml, tasks.md)"); T019 done; checks: test:apm pass (sizes.json in install), mise run lint pass, quickstart 6 jq/python/node pass — not verified: none
- [x] 6 US3 — accepted as is (user: "ok, accept US3 and continue"); files verified on disk — not verified: none
- [x] 6 US4 — T020–T026 done; checks: lint, test:sizes, test:apm, diagrams + git diff --exit-code docs/img, test:tracker, test:spec-number, test:story, test:measure all pass; sweep kept design.md:32,:181 and install.md:31 (true for installs), reworded workflow.md:522,:529; models.py left only in frozen tests/story fixtures — not verified: none
- [x] 6 Implement — soft: tasks done: 26 (0 not verified)
- [x] 7 Code review — picked B1, S1, B2, C1 (user: "apply, argparse is pretty standard and clear to humans and machine alike, and there are already other changes to apply, so if it cuts, let's go"), R1, R2, R5, R6; rejected S2 (as recommended), C2 (as recommended), R3 (as recommended), R4 (as recommended); criteria SC-001–SC-006 met
    - B1 sizes.py:30-31,66,73,78 — trailing \n bypasses NAME_RE/ID_RE (re.match + $) → fullmatch + test — rec: apply
    - S1 docs/diagrams/sizes.py — D1 validation only partly built (trailing-newline bypass)
    - B2 sizes.py:105-108 — non-list group entry crashes, exit 1 reads as drift — rec: apply
    - S2 docs/diagrams/sizes.py — label holding a sizes marker passes validation
    - C1 sizes.py:314-339 — hand-rolled arg parsing → argparse (~-15 lines) — rec: user (changes usage-error text the contract implies but does not pin)
    - C2 sizes.py d2() — style template .format indirection — rec: skip (churn)
    - R1 sizes.py brief_sentence — nested conditional lambda → def join_sizes — rec: apply
    - R2 sizes.py agents_table — next(iter(distinct)) one-liner → explicit branches — rec: apply
    - R3 sizes.py — assigned lambdas (E731) — rec: skip (harmless, matches the file's style)
    - R4 sizes.py render() — implicit fallback return — rec: skip (unreachable branch)
    - R5 sizes.py:1-12 — rewrap docstring and lines over 110 chars — rec: apply
    - R6 sizes.py agents_table/d2 — single-letter names → agent_col, small_col — rec: apply
- [x] 7 review fixes — applied B1+S1 (fullmatch), B2 (isinstance list), C1 (argparse; sizes-cli.md had no usage-error text), R1, R2, R5, R6; 3 new tests; checks: test:sizes, lint, diagrams + docs/img diff, --check all pass; performance: none — not verified: none
- [x] 7 review fixes (after ship) — S2 applied (user: "are we really gonna leave a security bug unfixed ? i don't think so"): label allowlist `[A-Za-z0-9 ,()`/-]+` (fullmatch) replaces the denylist; FR-020, data-model.md, contracts updated; new test for a marker in a label; checks: test:sizes, lint, diagrams + docs/img diff, --check pass — not verified: none
- [x] 8 Ship
