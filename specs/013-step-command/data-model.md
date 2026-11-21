# Data model: step-command

## Entities

| Entity | Where it lives | Written by | Read by |
| ------ | -------------- | ---------- | ------- |
| State file | `<artifact dir>/feat-state.md` | `state.sh` (init by the coordinator; set/log by `step.sh` and the coordinator) | `step.sh`, `state.sh` queries, agents, the shipper |
| Report | `<artifact dir>/reports/<key>[-<n>].md` | the agent (full report) | `step.sh` only |
| Report hash | `sum=<file name>:<12 hex>` words on the call lines `step.sh` prints | `step.sh` (`git hash-object --no-filters`) | `step.sh`, on the call that passes the report again |
| Digest | the agent's hand-back | the agent | the coordinator (gate message inputs) |
| `sizes.tsv` | `.apm/skills/feat/sizes.tsv` | `docs/diagrams/sizes.py` from `sizes.json` | `step.sh` |
| Boundary | one `step.sh` call | the coordinator copies the `boundary:` / `answer call:` line | `step.sh` |
| Verdict | `step.sh`'s first output line | `step.sh` | the coordinator; later #34 |
| Gate line | a tagged Log entry | `step.sh` | `state.sh` queries, `step.sh`, #21 counts |
| Answer | `answer:` argument → `answer:` sub-line | coordinator (argument), `step.sh` (log) | `step.sh`, `state.sh` |
| Override | `override:` sub-line | coordinator via `state.sh log` | `step.sh`, `phase2-mode`, #21 counts |
| Merged list | `step.sh` output (`finding:` lines) and the gate's finding sub-lines | `step.sh` | coordinator, `review-summary`, later reviewers |
| Facts | segments of earlier gate lines, and `wrote:` sub-lines | `step.sh` | `step.sh` at later gates |

## State file fields `step.sh` reads

Header (`- <Key>: <value>`): `Branch` and `Worktree` (one line), `Size`,
`Agents`, `Current phase`, `Issue`. Title: `# /<skill> state: <title>`. Log:
the lines after `## Log`. `step.sh` parses them read-only itself (no
symlink follow: a symlinked state file is `step: error`); every write is a
`bash state.sh set|log` call.

**Top level.** `step.sh` never takes a root from the `Worktree:` value. It
derives the run's top level from the state file's own dir, as `state.sh`'s
`snap_setup` does: `git -C <state file dir> rev-parse --show-toplevel`,
then the physical path (`pwd -P`). `Worktree:` must be `none` or name the
same directory (its own physical path compared, so a symlinked `/tmp`
still matches), else `step: error: Worktree: <value> is not the state
file's top level <top>`. Every `git -C` target, the `Wrote:` containment
root and the ship command check use the top level; with `Worktree: none`
it is the repo the state file is in. A state file or report path holding a
tab is `step: error` (the call lines are tab-separated).

`Agents` (`/feat`): `<role> <id>, … (for SendMessage)`, roles `specifier`,
`planner`, `tasker`; `agent=<id>` replaces that role's entry.

## Log grammar

```
entry     = "- [x] " text | "- [!] " text | "- [ ] " text
gate line = "- [x] " head " [" tag "] — " rest          tag = soft | hard
sub-line  = "    - " text                                after an entry or sub-line
```

A gate's sub-lines are the sub-lines after its entry, up to the next
`- [x] ` or `- [ ] ` entry; `- [!] ` entries in between are skipped (an
answer logged after a `- [!] step: …` line still belongs to the gate). A
soft gate's sub-lines run on over untagged entries, up to the next gate
line: the call that logs a soft gate may log records after it (`/fix` 1's
`approved:` and `answer:` lines, a `<N> Ship` line), and the override,
then the answer it leads to, are appended after them.

Two readers parse this grammar: `state.sh`'s queries (`log_lines`,
`after_back_to`) and `step.sh`'s own reader (R1 keeps them in separate
processes). The test `log-readers-agree` (R6, R17) runs both on one shared
set of tagged and untagged fixtures and compares their answers, so the two
cannot drift unnoticed.

### Lines `step.sh` writes

| Line | When |
| ---- | ---- |
| `- [x] <N> <phase> [soft] — <rest>` | a gate passed by rule |
| `- [x] <N> <phase> [hard] — <reasons joined by "; ">[; <facts>]` | a gate stopped |
| `    - answer: <kind> (user: "<words>")` | under the open gate, one per answer argument |
| `    - outcome: picked <ids> \| none picked; rejected <id> (user: "<words>") \| <id> (as recommended), …[; untested: …]` | review gates, at the answer |
| `    - passed: <text>` | `/fix` 1 hard gate, at a passing answer |
| `    - dropped: <P or R id> (cut by <C id>)` | merge rule 1, from the coordinator's `dropped:` argument (Merged list) |
| `    - <id> <spot> — <title> — rec: <value>` | finding sub-lines of a review gate (`S` and `[sec]`: title only) |
| `    - Stories: …` and the three other phase 2 sub-lines | phase 2 |
| `    - spec assumptions: kept as recommended` | the gate that carries a soft phase 2's summary, passed soft |
| `- [x] 3 Plan — merged with 4; <facts>` | small and medium phase 3: a record, untagged (no gate there) |
| `- [x] <N> <who> — not verified: none` or `…not verified:` + `    - <task> → <check> → <why>` | every implementer report with a `Not verified:` line, whatever the verdict (`6 US<n>`, `2 implementer`) |
| `    - wrote: <path relative to the top level>` | under that who-line, or the `Not verified line missing` one (and under the `7 review fixes` and `4 implementer` lines), one per `Wrote:` path other than the report path |
| `- [x] <N> <who> — Not verified line missing` | a report without the line |
| `- [x] <N> <who> [soft] — checks failed (retry 1 of 1): <check>` | a retry (`6 US<n>`, `7 review fixes`) |
| `- [x] 3 Test [soft] — failed (retry 1 of 1): <Still failing>; retry fix` | `/fix` retry |
| `- [x] 7 review fixes — <Fixes value>; checks: <results>; not verified: …` / `- [x] 4 implementer — …` | fix-mode reports |
| `- [x] 3 Plan — amended[ (<ids>)]; <facts>` | a planner amend's report |
| `- [x] size <new> — was <old>: <why>` / `— was <old> (user)` | a decrease, the `size` form |
| `- [x] back to <N> — <words>` | `/fix` `back to N` (resets cycle and retry) |
| `- [x] 1 Assess — stopped: <reason>` | `/fix` stop |
| `- [x] 1 Assess — approved: <cmd>` / `— answer: <q> → <a>` / `— security: <choice> (user: "<words>")` | `/fix` 1 arguments |
| `- [x] 3 Test — unaccounted: <items> (user: "<words>")` | `/fix` 3, going on past them |
| `- [x] 4 Code review — ship go-ahead (user: "<words>")` | `/fix` 4 security, `approved` |
| `- [x] 8 Ship` / `- [x] 5 Ship` | before each shipper spawn |
| `- [x] move — …` (kept, stayed on, repaired), `- [x] move [hard] — undone (…)`, `- [!] move — git fetch failed (<line>)` | moves |
| `- [!] <N> <phase> — <reason>` | each report-check failure, `report changed since checked: <file name>` included |
| `- [!] <N> <phase> — unparsable: <file name>: line <n> (<Key>); reformat 1 of 1` | the first unparsable report of a spawn (Reformat turn); never the line's text |
| `- [!] step: <line>` | `step.sh`'s own error, when `state.sh` accepts it |

A who-line's not-verified items (for `not verified items:` and the
shipper) are its `    - <task> → <check> → <why>` sub-lines; its `    -
wrote:` sub-lines are facts, never items, and every reader of
not-verified items (`step.sh`, `review-summary`) skips them.

The coordinator writes, through `state.sh`: setup lines, `    - override:
hard — <reason>` (chained before its next call, the answer call of the
overridden gate: step-cli.md, Answers), board and issue lines, `brief left
in place`.

### Facts on gate lines

| Line | Facts (segments) | Read at |
| ---- | ---------------- | ------- |
| `3 Plan` (any) | `assumptions needing you: none \| <k>, <k>…` (the planner's assumption numbers), `constitution: pass \| <principles>`, `blockers: none \| yes`, `size trigger: none \| <kind>` | gate 4 (one reason per number), gate 5 (size floor) |
| `2 Specify` sub-line | `Unchecked checklist items: <…>` | gates 3 (large), 4, 5 |
| `1 Assess` pass text | `risk area <r>`, `performance bug <yes\|no>`, `size <s>` | `/fix` 4 groups and gate, 5 (`security bug`) |
| `4 Design review` sub-lines | accepted `[sec]` ids (`auto-applied`, `picked`) and their spot and title | lens 7b's `accepted sec:` |
| outcome segments, `leave` answers | skipped and rejected ids with words | every reviewer's `rejected:` |
| setup line | `report author <association>` | `/fix` 1 |
| `wrote:` sub-lines of implementer who-lines | the run's written paths | diff preparation |

The latest line of a kind wins. `/fix`'s queries ignore lines before the
latest `- [x] back to` entry, as today (`after_back_to`). A phase's
progress (stories done, fixes owed, retries used) is read from the Log
after the phase was last entered: after the latest `answer: back to <N>`
sub-line with N at or before that phase, else after the gate line that
entered it.

**A missing fact is never the permissive value** (FR-031). A run started
before this feature has none of the facts above but the phase 2 sub-lines.

| Fact missing | Read as |
| ------------ | ------- |
| `risk area` (`/fix` 4, 5) | names `security`, plus the hard reason `fact missing: risk area`; the shipper gets `security bug: yes`; `back to 1` re-assesses and logs it |
| `performance bug` (`/fix` 4) | `yes`: the `performance` groups (more review, no reason) |
| `report author` (`/fix` 1) | untrusted: hard reason `fact missing: report author` |
| a `3 Plan` fact (gates 4, 5) | hard reason `fact missing: <name>`, one per name (`assumptions needing you`, `constitution`, `blockers`, `size trigger`) |
| phase 2's `Unchecked checklist items` (gates 3 large, 4, 5) | hard reason `fact missing: unchecked checklist items` |
| `wrote:` sub-lines (diff preparation) | nothing marked; the untracked files are listed apart (`untracked, not in the diff:`); an empty diff is hard as usual |

## Tags in `state.sh`

`log_lines` reads a gate line as the same line without ` [soft]`/` [hard]`
(so `- [x] 3 Test [soft] — failed (retry 1 of 1): …` matches today's
`'- [x] 3 Test — failed (retry 1 of 1)'*`) and keeps the tag beside it.
The queries then:

| Query | Change |
| ----- | ------ |
| `phase2-mode` | the latest phase 2 line's tag decides: `hard` → `hard`; `soft` with an `override: hard` sub-line → `hard`; `soft` → as today; no tag → today's text rule. Gate G has passed when its line is soft (no override), or hard/overridden with an `answer:` sub-line whose kind is not `stop`, or untagged |
| `review-summary` | a tagged `<p> Code review` line whose head has no outcome segment takes its segments from its `outcome:` sub-line; finding sub-lines skip `answer:`, `outcome:`, `override:`, `passed:`, `dropped:`, `wrote:`; ids under `dropped:` are left out |
| `shipped-verdict` | also reads `    - answer: ship with <v> (user: "<words>")`, printed as today's `- [x] ship with …` line is |
| `cycle`, `retry-used`, `refused-base` | unchanged code; tagged lines match through the normalisation |

Old untagged state files read exactly as today (`tests/state` keeps its
fixtures and adds tagged copies; the shared set of `log-readers-agree`
includes both).

## Open gate

The most recent gate line, when it is `[hard]` or `[soft]` with an
`override:` sub-line, and has no `answer:` sub-line. A later gate line
closes an earlier one. An answer call's token must be the open gate's
token (not `Current phase`'s: an overridden soft gate has already moved
`Current phase` on). The overridden soft gate's answer call is the
`answer call:` line its soft verdict printed (step-cli.md, Output).
Answering an overridden soft gate first sets `Current phase` back to the
gate's phase (nothing when it already is), then applies the answer, so
`stop` leaves the run where today's override leaves it.

A `- [!] <N> <phase> — …` report-check line after the open gate's line
(a failed check, `report changed since checked: …`) narrows its answers
to `back to <N>` and `stop`, as for any gate a failed report check made
hard.

## Report hashes

When `step.sh` checks a report (gates.md, step 3) it takes `git -C <top>
hash-object --no-filters -- <report>`, cut to 12 hex. Every report the
next call passes again carries its hash on the printed call line as
`sum=<file name>:<hex>`: the earlier reports on the `7e` `boundary:`
line, the ship report on the `8`/`5` line after a conflict, the batch's
other reports on a reformat `boundary:` line, every report on an `answer
call:` line. The later call hashes each again before reading it:

- a report passed again without its `sum=` → `step: usage`;
- a different hash → a failed report check: reason `report changed since
  checked: <file name>`, logged `- [!] <N> <phase> — report changed since
  checked: <file name>`; on an answer call none of the answers is applied
  or logged, the verdict printed is `hard:` with that reason, and the open
  gate then takes only `back to <N>` or `stop`, which read no report and
  compare nothing.

## Reformat turn

A report that does not parse (agent-formats.md, Parsing rules) gets one
reformat turn per spawn. The key of a report is its file name without
`[-<n>].md` (`7-7b` for `7-7b-2.md`).

- First failure for the key: log `- [!] <N> <phase> — unparsable: <file
  name>: line <n> (<Key>); reformat 1 of 1` (or `…: no <Key>: line; …`),
  decide nothing else for the batch, and print for each failed report a
  spawn of the same row, `mode: reformat`, `from: <the unparsable report
  path>`, `unparsable: <file name>: line <n> (<Key>)`, `report:` a new
  path from `state.sh report-path` for the same key, `continue: <id>` when
  the skill's *agents that may be continued* has the role and the
  `Agents` line its id, else `fresh`. A reviewer's reformat spawn gets a
  new snapshot. The `boundary:` line repeats the token with the batch's
  reports in order, the reformatted ones replaced by their new paths, the
  others with their `sum=`.
- The reformat turn is used when the Log's latest entry naming the key is
  its `reformat 1 of 1` line. A report of that key that still does not
  parse is then a hard reason, `unparsable: <file name>: line <n>
  (<Key>)`.
- The text of the offending line is printed on stdout only, as
  `unparsable line: <file name>: <the line, cut to 80 characters>`, for
  the coordinator's message; it never reaches the Log.

A report-check failure (gates.md, step 3) is not a format slip: it makes
the gate hard at once, with no reformat turn.

## Expected boundary

| Skill | `Current phase` | Tokens accepted (besides `move`, `repair`) |
| ----- | --------------- | ------------------------------------------ |
| feat | `2 Specify` | `2` |
| feat | `3 Plan` | `3` |
| feat | `4 Design review` | `4`, `3` (an amend) |
| feat | `5 Tasks` | `5` |
| feat | `6 Implement` | `6` |
| feat | `7 Code review` | `7`, `7e`, `7-fixes` |
| feat | `8 Ship`, `done (shipping)` | `8` |
| fix | `1 Assess` | `1` |
| fix | `2 Fix` | `2` |
| fix | `3 Test` | `3` |
| fix | `4 Code review` | `4`, `4-fixes` |
| fix | `5 Ship`, `done (shipping)` | `5` |

Each new report's file name must be `<key>[-<n>].md` for a key the token
allows (`2` → `2-specify`, `4` → `4-<lenses>`, `6` → `6-US<n>`, `7e` →
`7-7e` first, `move`/`repair` → `move`, …), else `step: error`. A reformat
turn keeps the token and the key.

## The step function

`next(state)` is what a boundary prints after its verdict, and all that
`resume` prints (after the repair check): the work still owed at
`Current phase`, from the Log since that phase started.

| Skill | `Current phase` | Owed |
| ----- | --------------- | ---- |
| feat | 2 | specifier: `first`, or `amend` when a phase 2 line exists |
| feat | 3 | planner: `amend` when gate 3 was answered `changed` and no `3 Plan — amended` follows; else `first` |
| feat | 4 | planner `amend` when gate 4 has `apply` (soft) or picks or `changed` (answered) and no amend follows (continued only right after a soft gate, in the same call); else the design reviewer batch |
| feat | 5 | tasker: `amend` when gate 5 was answered `changed`; else `first` |
| feat | 6 | the first story, in `story.sh` order, that is not done (below); its retry when its latest `6 US<n>` line is the retry line |
| feat | 7 | when the gate 7 line passed with fixes owed and no `7 review fixes` line follows: the fix-mode implementer (its retry likewise); else the first review batch (a resume restarts 7a–7d) |
| feat | 8, `done (shipping)` | the shipper |
| fix | 1 | assessor, `assess` |
| fix | 2 | implementer, `bug` (with `test report`/`still failing` after a `3 Test — failed (retry …)` line) |
| fix | 3 | assessor, `test`, `cycle` |
| fix | 4 | as `/feat` 7 with `4 implementer` |
| fix | 5, `done (shipping)` | the shipper |
| any | `done (PR #N)`, `done (not a bug)`, `done (invalid)` | nothing: `done:` |

**A phase 6 story is done** when, since phase 6 was last entered, either
its latest `6 US<n>` line is the who-line (`6 US<n> — not verified:`) and
no later `6 Implement [hard]` line names `US<n>`, or the latest `6
Implement [hard]` line naming `US<n>` has an `answer:` sub-line whose kind
is not `changed`, `back to` or `stop`. The who-line is logged for every
report with a `Not verified:` line, whatever the verdict (gates.md, 6), so
a retry line or a hard story gate after it keeps the story open until
answered.

Entering a phase (soft verdict, passing answer, `back to N`, a resume):
`Current phase` set, then the base check when the phase is one of the
skill's base-check boundaries (`/feat` 3–8 and any phase rerun; `/fix` 2–5,
3 after review fixes, `back to N` with N ≥ 2), then the spawn. `skip N`:
when `next` would enter N, it enters N+1 instead (the answer sub-line is the
record).

## Base check

`git -C <top> fetch origin <default>`; fails → `base: fetch-failed:
<first line>`, `- [!] move — git fetch failed (<first line>)`, the phase
goes on. Then `git merge-base --is-ancestor origin/<default> HEAD`: 0 →
`base: same`; 1 → `state.sh refused-base` prints `<new>` (7–40 hex) and
`git merge-base --is-ancestor origin/<default> <new>` is 0 → `base:
refused`; else `base: moved <old> <new>` (`<old>` = `git merge-base HEAD
origin/<default>`, `<new>` = `git rev-parse origin/<default>`, both cut to
7), `read:` and the rebase-mode spawn (implement row, `action: move`,
`shipped: no`, key `move`) instead of the phase's spawn.

`<top>` is the top level (State file fields), with `Worktree: none` too.
`<default>`: `git symbolic-ref -q --short refs/remotes/origin/HEAD` without
`origin/`, else the `ref: refs/heads/<name>` line of `git ls-remote
--symref origin HEAD`. The name comes from the remote, so before any use
it must not start with `-` and `git check-ref-format --branch '<name>'`
must exit 0; else, or with no name, `step: error: no default branch`.

## Repair

`git -C <top> rev-parse -q --verify refs/logistics/pre-move/<branch>`
succeeds, or `git -C <top> log -1 --format=%s` starts with
`logistics-wip:` → a rebase-mode spawn, `action: repair`, key `move`,
boundary `repair`. Run by `resume` first and at a `move` boundary whose
report is missing.

## Diff preparation

At the call that prints a code review batch (`/feat` 7, `/fix` 4), in
`<top>`:

1. The run's paths: every `    - wrote: <path>` sub-line of the Log's
   implementer who-lines (all phases, the whole Log).
2. Of those, the ones still untracked and not ignored (`git ls-files -z
   --others --exclude-standard -- <those paths>`, keeping only the results
   equal to one of them, so a directory on `Wrote:` adds nothing under it)
   → `git add -N -- <them>` (none → skipped); each printed `added:
   <path>`.
3. Every other untracked, non-ignored file (`git ls-files -z --others
   --exclude-standard`, minus step 2's) is left alone: neither marked nor
   in the diff, printed `untracked, not in the diff: <path>` (at most 20,
   then `untracked, not in the diff: … <n> more`) for the coordinator's
   message.
4. `base` = `git merge-base origin/<default> HEAD`; `git diff --quiet
   <base>` exit 0 → hard `empty diff`, no spawn; else `diff: git diff
   <base>` and the spawns' `diff:` key.
5. Then the snapshot (after the index change).

## Merged list

**Code** (`/feat` 7, `/fix` 4). Each finding parsed from a reviewer report:
section (`Bugs`, `Spec`, `Standards`, `Security`, `Performance`, `Cuts`,
`Readability`), lens (the section's `(7x)`), reviewer (its report),
title, spot (`at: <file>[:<a>[-<b>]]`; no line = the whole file), `fix:`
text, `confidence:` (Bugs), the raw `rec`. Applied in order:

2. same spot (same file, overlapping lines) and same section, same `rec`
   and same `fix:` text → keep the first;
3. same spot and same section, from a different reviewer or lens, different
   `rec` or `fix:` text → both `user (reviewers disagree)`;
4. Bugs, `confidence: high`, `rec: skip (<why>)` → `user (<why>)`
   (`user (no valid recommendation)` without a why);
5. a `rec` not `apply`, `skip (<why>)` or `user (<why>)` →
   `user (no valid recommendation)`;
6. Security, `rec: skip (<why>)` → `user (<why>)`.

Ids by group, in report order (lens order, then line order): `B` (Bugs and
Spec), `S`, `P`, `C`, `R`, then `[std]` (Standards, numbered `[std]1`, …).
Printed in that order. Counts: findings, to apply (`apply`), skipped
(`skip`), `untested:` (Acceptance criteria `untested`).

**Rule 1 drops** (the coordinator's `dropped: <id> (cut by <C id>)`): a
drop is accepted only when `<id>` is a `P<n>` or `R<n>` of the merged list
and `<C id>` a `C<n>` of the same list; any other id or cut is `refused:
dropped: <id>: only a P or R finding cut by a C finding of this list`,
with nothing logged. A `B`, `S` or `[std]` finding therefore never leaves
the list without the user's answer.

**Design** (`/feat` 4). Spot = artifact + section or line, exactly as
written; section = the tag (`[sec]`, `[cost]`, `[design]`); rules 2, 3, 5 as
above; different tags on one spot stay separate. Ids `D1…` in report order
(4a, 4b, 4c). Counts: findings, applied, skipped, `security:` (`[sec]`
`apply` ids), `security skipped:` (`[sec]` `skip` ids).

**Answers to a review gate → outcome**: `fix <id>` and `picked` ids are
picked; `leave <id>` is rejected with the user's words; `approved` picks
every `apply` not left and rejects every `skip` not fixed `(as
recommended)`; `dropped:` ids are neither.

## `sizes.tsv`

See [contracts/sizes.md](contracts/sizes.md). `row` lines give `(skill,
row) → agent, lens, model and effort per size`; `group` lines give
`(skill, phase, size, variant) → ordered groups with their precomputed
model and effort`.
