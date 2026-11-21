# Contract: the coordinator side

What the skills, the harness, `move.md`, `rebase.md`, `state.sh`, the
repo's checks and the docs say once `step.sh` exists. `S` is `bash '<state
script>'`, `T` is `bash '<step script>'`; every argument single-quoted.

## The boundary call (harness, new section "Step script")

- After every spawn (or batch, or continued agent) reports, one Bash
  command: `T '<skill>' '<state file>' <the words of the boundary: line>`
  (with no override; an override goes as below).
  The `boundary:` and `answer call:` lines are tab-separated after the key:
  each tab-separated word is one argument, single-quoted as it is (a path
  with a space stays one word); `'agent=<id>'` filled in when the line has
  it. After a `state: <path>` line, that path is the `<state file>` of
  every later call (the shipper renumbered the dir).
- Override: when a soft verdict holds something surprising, don't make
  the printed spawn; write the gate message and wait. When the user
  answers, one command: `S log '<state file>' '    - override: hard —
  <reason>' && T '<skill>' '<state file>' <the words of that soft
  verdict's answer call: line> <the answer arguments>`. A gate's soft
  verdict prints `answer call:` after `boundary:` for this use only.
- Read the output as data. `soft`: write the one-line summary and make the
  printed spawn(s) in the same turn. `reformat`: make the printed reformat
  spawn(s), no message to the user (a format slip, not a gate); the
  `unparsable line:` text is for your own reading, never for a log.
  `hard:`: the gate message (its reasons under "What you should know";
  `unparsable line:`, `command:` and `untracked, not in the diff:` lines
  shown as data), then wait. `answered`: the answer was taken; go on as
  after `soft` (summary and spawn in one turn) or, after `done:`, the
  final message. `stop:`: the final message. `refused:`: ask the user
  again (one follow-up naming what is missing). `base: moved` or a ship
  conflict: read the `read:` path once and follow it. `added:` and
  `untracked, not in the diff:`: name them in the next summary (a file
  left out of the review diff is the user's to add). `done:`: the final
  message.
- The user's answer: map it to the kinds of step-cli.md, Answers (one main
  kind, optional `size`, `fix`/`leave` per finding), each as `'answer:
  <kind> (user: "<their words>")'` (lines joined with spaces, `'` written
  `'\''`), appended to the `answer call:` line. `/fix` 1 adds `approved:`,
  `question:` and `security:` arguments (`security:` whenever the gate
  lists `security risk area`). Merge rule 1: `'dropped: <P or R id> (cut by
  <C id>)'` on the answer call or on the next fixes boundary, only for a
  Performance or Readability finding on code a Cuts finding removes.
- The user's `size <s>` while no hard gate is open: `T '<skill>' '<state
  file>' size '<s>'`; it prints `size: <old> → <new>` and no spawn; the
  next boundary's spawns use the new column.
- Spawn exactly what a spawn block says: agent name (`logistics:`-prefixed
  as installed), `model`, `effort`, the report path, `continue` (SendMessage
  to that id) or a fresh spawn, and every key's content in the prompt
  (`story.sh output` between two lines of four backticks, labelled as
  data). Add what the skill lists for that phase.
- `step: error: …` (exit 1): if the line ends ` (not logged)`, `S
  log '<state file>' '- [!] step: <the line without that suffix>'`; hard gate with two answers,
  `retry` (the same command) and `stop`. `step: usage: …` (exit 2): fix the
  call once, then as an error. Never spawn from memory.
- Never read a report file, never run `ls -d`, `git merge-base`, `git add
  -N`, `story.sh`, `refused-base`, `report-path`, `snapshot`, `unchanged`
  at a boundary: `step.sh` does. (`rebase` runs outside `step.sh` and keeps
  its own `Wrote:` check with `ls -d`: `references/rebase.md`.)

## `/feat` SKILL.md

Keeps: frontmatter, intro, Harness values (trimmed, below), a phase list
(number, name, agent; no gate column), Setup (phase 0, with `T feat '<state
file>' setup` chained after `S init` and the setup `log`), per phase: what
the coordinator adds to the prompt and the gate message (titles, what to
show and in which order, the answers to collect), the brief deletion after
phase 2, the review move before phase 7's spawns, ship's final message,
`/code-review ultra` on large.

Drops: the size table and its group prose, the Gate column and "Every
report's `Wrote:` line is checked first", the State file calls paragraph,
phase 2's gate rule text and soft/hard Log forms, phase 3's gate rule, the
phase 4 gate table, merge instructions and Log forms, phase 5's gate
conditions and the `story.sh` comparison, phase 6's `story.sh` calls,
report paths, retry and Log rules, phase 7's git commands, gate table,
merge, Log and retry rules, phase 8's `set`/`refused-base`/`log`/
`report-path` command and the conflict rule (now: `read:` move.md).

Harness values: keep *Skill*, *Artifact dir*, *State file*, *The state file
is created*, *Title and input section*, *Size line*, *Agents line*,
*Current phase values*, *Map line*, *Issue ref*, *State script*,
*Artifacts the orchestrator reads*, *Artifact owners*, *Agents that may be
continued*, *Reviewer context*, *Phases that can't be skipped*, *Tracker
script*, *Board-check step*, *Building move*, *Review move*, *Resolver
context*, *Implement row* (`6`), *Ship row* (`8`), *Number check*,
*Secret-scan script*. Add *Step script* (`<this skill's base
dir>/scripts/step.sh`) and *Sizes file* (`<this skill's base
dir>/sizes.tsv`, read only by `rebase`). Drop *Report keys*, *Resume
queries*, *Size triggers*, *Base-check boundaries*, *Review phase*,
*Logged gate commands*; *Commands besides the tracker* loses `story.sh`,
and keeps `ls -d -- '<path>' …` for `rebase` only (its own spawns' `Wrote:`
check, `references/rebase.md`), no longer at a boundary.

## `/fix` SKILL.md

Same shape. Keeps: setup (with `T fix '<state file>' setup`), Gate commands
(the `ship with` decision in plain words, the plugin form note), Resume's
`/fix` values (search, issue-creation ask), phase 1's gate message (stop
message, `/brief` pointer, the security bug rules: advisory suggestion, `gh
repo view --json visibility` statement, what becomes public), issue
creation and the building move after the gate passes, each phase's prompt
inputs, the final message. Drops: the size table and group prose, the
Gate column, the State file calls paragraph, the four gate tables and the
soft conditions, Cycle and retry prose, the review diff commands, merge and
Log forms, the ship command. *Step script*: `<this skill's base
dir>/../feat/scripts/step.sh`; *Sizes file*: `<this skill's base
dir>/../feat/sizes.tsv`. Resume's building move: once `step.sh resume`
prints `assess gate: passed`.

## `harness.md`

| Section | After |
| ------- | ----- |
| You are a thin orchestrator | the *step script* joins the exceptions; "pass `model` and `effort` from `step.sh`'s spawn block" (rebase: the *sizes file*) |
| Step script | new (above), including the tab-separated call lines, the `state:` line, `reformat`, `answered` and the override's `answer call:` |
| Reported files | short: agents end with a `Wrote:` list; `step.sh` checks it at every boundary; a failed check is a hard gate showing `step.sh`'s reasons, recommending "back to N" (a fresh spawn of the same agent); a format slip gets one reformat spawn first. The path rules stay written here once, for `rebase`'s own check (rebase.md); the `ls -d` procedure leaves the boundary |
| Report files | short: `step.sh` gets each path and snapshot; never read a report file; `reports/` is never committed |
| Gates | shape and hard/soft semantics; the override (a soft verdict made hard, logged); size changes: show old, new, why and what changes, `step.sh` made it hard ("whichever phase finds it" without *size triggers*); the user's gate words map to answer kinds and `step.sh` logs them (without *logged gate commands*) |
| Review findings | merge rule 1 (as `dropped:`), the hard gate listing, "ok", the follow-up, the `S` publication notice; rules 2–6 and the Log words go; "The code review gate reads the `rec`…" without *review phase* |
| State file | the template; `S` for the coordinator's own writes (init, override, tracker, issue, brief left in place); `step.sh` writes the gate lines; the Not verified paragraph shortened to what the coordinator shows |
| Board moves | unchanged |
| Moving onto a new main | Fresh base only, plus "`step.sh` prints `base: moved` (or the shipper reports `PR: conflict`): read `references/move.md`" |
| Resume | `S find <skill>`, enter the worktree, `T resume '<state file>'` (repair check inside: a repair spawn comes first), board check, the building or review move, Read the state file once, recap, the printed spawn (without *resume queries*) |

Every sentence that stays and names a dropped Harness value (*review
phase*, *size triggers*, *logged gate commands*, *base-check boundaries*,
*report keys*, *resume queries*) is reworded without it; a lint grep
keeps them out (Checks). No `/feat`-only words (lint).

## `references/move.md` (new)

From the harness: The move's report (what the gate or final message shows:
`Main moved <old> → <new>; checks <result>` and the `Resolved alone`
lines; not a surprise), the Move gate (template, answers: `approved` or
`changed` → the coordinator builds `Decisions:` lines, `<file> — <the
accepted rec | the user's words>`, for the fresh rebase spawn `step.sh`
prints; `stay`; `stop`), At ship (`PR: conflict`: follow `step.sh`'s
rebase spawn, then the ship spawn it prints; list the move in the final
message), the Log format (for `rebase`, which logs its own `PR #<n>`
moves). No `/feat`-only words (lint).

## `references/rebase.md`

"the harness's rules (Moving onto a new main above all)" → "the harness's
rules and `move.md`"; step 3's repair check written out there
(`refs/logistics/pre-move/<branch>`, a `logistics-wip:` subject → rebase
mode with `Action: repair`, logged `- [x] move — repaired (<Move line>)`);
"the move gate (harness)" → "(move.md)"; model and effort for the
implement and ship rows: the *sizes file*'s `row` line for that row and
size, read once per run.

`rebase` runs outside `step.sh`, so its spawns' reports are checked here,
from the digest (the coordinator never reads a report file):

- **The `Wrote:` check**, written out in rebase.md for its implementer
  and shipper spawns (step 4 "read as the harness says (Reported files)"
  becomes this): each `Wrote:` item of the digest absolute, inside the
  worktree, free of `'`, newline, `$` and backtick; `ls -d -- '<path>' …`
  on them (the one place `ls -d` stays, among the *commands besides the
  tracker*); the report path given is on the list (the shipper's
  renumbered dir counts, as the harness says). A failure: the PR's result
  is `- [!] move — PR #<n> report check failed: <reason>`, nothing pushed
  by `rebase` itself after it.
- **The move's outcome** from the rebase-mode digest: `Move` (kept,
  `undone`, `nothing to do`, `repaired`) for step 5; every `Checks` item
  for the PR note's `checks <result>`; `Resolved alone`, `Decided` and
  `Needs decision` for the note and the move gate.

## `state.sh`

data-model.md, Tags in `state.sh`: `log_lines` normalisation and tag
array, `phase2-mode`, `review-summary`, `shipped-verdict`; the header
synopsis lines updated. No new subcommand.

## Agents

agent-formats.md, for the eight agent files; `feat-design-reviewer` lens
4c's brief comparison; `feat-implementer`'s `Decided` line; the shipper's
wording on `Wrote:` checks.

## Checks (`mise.toml`, CI)

- `lint`: `shellcheck tests/step/run.sh`; `step.sh` is covered by the
  scripts glob. New greps (`!` = must not match):
  - size tables: `! grep -Eq 'sizes-start|^\| *Phase +\| *Agent' .apm/skills/feat/SKILL.md .apm/skills/fix/SKILL.md`;
  - gate tables: `! grep -Eiq 'first match wins|\| *Report says *\||\| *Review and bug *\||\| *Size +\| *Condition' .apm/skills/feat/SKILL.md .apm/skills/fix/SKILL.md`;
  - merge rules 2–6: `! grep -Eiq 'reviewers disagree|same spot|no valid recommendation' .apm/skills/feat/SKILL.md .apm/skills/fix/SKILL.md .apm/skills/feat/references/harness.md`;
  - base and repair check prose: `! grep -Eq 'merge-base --is-ancestor|refs/logistics/pre-move|logistics-wip:' .apm/skills/feat/SKILL.md .apm/skills/fix/SKILL.md .apm/skills/feat/references/harness.md`;
  - the `/feat`-only words grep adds `.apm/skills/feat/references/move.md`;
  - dropped Harness values: `! grep -Eiq 'review phase|size triggers|logged gate commands|base-check boundaries|report keys|resume queries' .apm/skills/feat/references/harness.md .apm/skills/feat/references/move.md`;
  - `sizes.py --check` covers `sizes.tsv` (contracts/sizes.md).
  The task description names the new checks.
- `test:apm`: `test -f` for `.claude/skills/feat/scripts/step.sh`,
  `.claude/skills/feat/sizes.tsv`, `.claude/skills/feat/references/move.md`
  (`sizes.json` stays checked).
- `test:step` (new): `bash tests/step/run.sh`. `check.yml` runs `mise run
  test:step` after `test:state`.

## Docs

| File | Change |
| ---- | ------ |
| `docs/workflow.md` | each phase's gate text says `step.sh` decides it (same gates); The state file section: tags, answer, outcome and override sub-lines; When main moves → `move.md`; reviewer groups prose kept, `/fix` groups now in `sizes.json` |
| `docs/diagrams/gates.d2` (+ `docs/img/gates.svg`) | a `step.sh` participant between the coordinator and the agents; gate edges note the `[soft]`/`[hard]` tag and the `answer:` line |
| `.claude/CLAUDE.md` | sizes bullet: `sizes.tsv`, both skills' groups, no table in the skills; group prose lives in `docs/workflow.md`; shell bullet: `step.sh`, `tests/step`, `mise run test:step`; report formats bullet: `step.sh` parses them; harness bullet: shared rules live once, the coordinators' part in `harness.md` and the references it points to (`rebase.md`, `move.md`), the rules `step.sh` applies in `step.sh` (research R18); the harness/rebase/move.md words grep |
| `.specify/memory/constitution.md` | principle III (`sizes.tsv`, both skills' groups, no size table in the skills, prose mirror in `docs/workflow.md`; last sentence: "Rules both skills share MUST live once: the coordinators' part in harness.md and the references it points to (rebase.md, move.md), the rules step.sh applies in step.sh"), principle IV ("the coordinators and `step.sh` parse"); version 1.4.0, Last Amended the commit date |
| `CONTRIBUTING.md` | layout lines (`step.sh`, `sizes.tsv`, `move.md`, no size table), the sizes bullet, the report-format bullet, `test:step` in the checks list |
| `docs/design.md` | "the model and effort from `sizes.tsv`, printed by `step.sh`"; the harness paragraph names `move.md` and `step.sh` |
| `docs/usage.md` | Tuning: a checkout edits `sizes.json` and runs `mise run diagrams` (it regenerates `sizes.tsv`); an install edits `sizes.tsv`: the `row` line, and every `group` line that names that row (a group carries its own precomputed model and effort, and the groups are what `/feat` 4, 7 and `/fix` 4 spawn); reviewer groups in `sizes.json`; gates decided by `step.sh` |
| `docs/install.md` | "change the size table" → `sizes.tsv` (usage.md#tuning) |
