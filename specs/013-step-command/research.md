# Research: step-command

Decisions taken while planning, each with what was weighed. The brief's
rejected alternatives (no script per rule, no size lookup command, no
Workflow script, no `step.py`, no `jq`, no tables kept as a fallback, no
move rules in `harness.md`, no split PR) are not reopened. The design
review's accepted findings are folded in where they change a decision
(noted "design review").

## R1. One script, reading the state file itself, writing through `state.sh`

**Decision**: `step.sh` parses the state file read-only (title, header
fields, Log lines; about 40 lines of bash) and runs `bash state.sh` for
every write (`set`, `log`) and for the queries with side effects or shared
rules (`report-path`, `snapshot`, `unchanged`, `cycle`, `retry-used`,
`phase2-mode`, `refused-base`). Bash 3.2 constructs only, as `state.sh`
(`tests/step` greps for the bash 4 ones).

**Why**: FR-001 (writes only through `state.sh`) with process isolation:
a `state: error:` from a subprocess maps to one `step: error:` line;
sourcing `state.sh` would let its `die` end `step.sh` with the wrong prefix
and leak globals.

**Kept after the design review**: two readers of one Log grammar can
drift (constitution III). The user chose to keep them separate and add a
test that compares them (R6, R17), over a shared sourced read library.

**Rejected**: sourcing `state.sh` (above); a `state.sh get` subcommand (a
new subcommand for a two-line parse, and one process per field); a shared
sourced file of read helpers (a new shipped file, and it reverses the
process isolation above; the user's choice at the design review).

## R2. The boundary token and the call lines

**Decision**: each spawn block ends with a `boundary:` line holding the
exact arguments of the next call (token, report paths in order, the
`sum=` of each report passed again, the snapshot token, an `agent=<id>`
placeholder). A hard verdict prints an `answer call:` line instead (no
snapshot: `unchanged` is single use); a gate's soft verdict prints both,
`answer call:` for an override only. Both lines are tab-separated after
the key, each word one argument (design review: a path with a space must
stay one argument). `step.sh` checks the token against `Current phase`
(or the open gate) and each report's file name against the token's keys.

**Why**: the coordinator copies one line instead of deciding which phase,
key or path comes next, so a wrong boundary is a `step: error`, not a
silent misroute. Paths and tokens come from `state.sh`, so they are safe in
argument positions (harness rule). Tabs: `state.sh` allows spaces in paths
(`unsafe_path` refuses only newlines, `'`, `$` and backticks); a tab in a
path is `step: error`. The soft verdict's `answer call:` carries the
reports' `sum=` (R20), which the coordinator could not rebuild from the
soft call's own words.

**Rejected**: the coordinator naming the phase and paths (the judgment this
feature removes); `step.sh` finding the latest report per key itself (a
stale or half-written file from an earlier spawn would be read);
space-separated call lines (above); the override's answer call repeating
the soft call's words (no `sum=` there).

## R3. Answers ride on the repeated boundary call

**Decision**: the answer call repeats the gate's `answer call:` line plus
one `answer: <kind> (user: "<words>")` argument per answer. `step.sh`
validates the answers (refusals first, `/fix` 1's `security:` choice
required at a `security risk area` gate), compares each report with its
`sum=` (R20; not for `back to` and `stop`), re-reads the same reports (to
rebuild the merged list and the follow-up spawn), skips the checks, logs
the answers, prints `answered` and goes on. `stop` prints `answered`, then
`done: stopped (user)`, and leaves `Current phase` as it is. Kinds,
refusals and output: contracts/step-cli.md.

**Why**: FR-002's second form "after the user answered a hard gate" and
FR-015 "with no call of its own"; stateless: nothing but the state file and
the reports is needed, so a resumed run answers the same way. `answered`
gives #34 a first line for every outcome (design review).

**Rejected**: a fifth `answer` form (FR-002 fixes four); caching the merged
list in a file (more state to keep in step); `soft` as an answer call's
first line (it is not a gate verdict there).

## R4. Gate lines are written when decided; answers and outcomes are sub-lines

**Decision**: a hard gate's tagged line is logged at verdict time (AC 1.3),
with its finding sub-lines on review gates. The answer call appends
`answer:` sub-lines, then, on review gates, an `outcome:` sub-line with
today's `picked …; rejected …` text, and on `/fix` 1 a `passed:` sub-line.
The open gate is the latest gate line that is hard (or soft with an
`override:`) and has no `answer:` sub-line. Sub-lines after a `- [!]` line
still belong to the gate above it (data-model.md).

**Why**: resume and the answer call both need to see an unanswered hard
gate; `review-summary` keeps reading today's outcome words, only from a
different line.

**Rejected**: logging the gate line only at the answer (a crash before the
answer loses the hard verdict; AC 1.3 says it is logged by the boundary
call).

## R5. Facts later gates need are logged on earlier gate lines

**Decision**: the `3 Plan` line carries `assumptions needing you` (the
item numbers, `none | <k>, <k>…`), `constitution`, `blockers` and `size
trigger`; the `1 Assess` pass text carries `risk area` and `performance
bug`; phase 2's sub-lines carry the unchecked checklist items (already
today); each implementer who-line carries `wrote:` sub-lines (the run's
written paths, for the review diff, R11). Later gates read them from the
Log. A missing fact is never read as its permissive value (FR-031): a
missing `risk area` reads as `security` with the reason `fact missing:
risk area`, a missing `performance bug` as `yes`, a missing `report
author` as untrusted, any other missing fact is the reason `fact missing:
<name>` (data-model.md).

**Why**: `reports/` is never committed and may be gone on a resume
elsewhere; the Log is the record. It also leaves `step.sh` one parser per
format, used only at that format's boundary. Numbers, not a count: gate
4's reason `assumption <k> needs you` needs them (design review). Missing
facts: a run started before this feature has none, and reading one as
`none` would skip `/fix` 4's ship go-ahead and tell the shipper `security
bug: no` (design review).

**Rejected**: reading the latest earlier report by key (allowed by the
spec's assumption, but brittle as above); a missing fact as `none`.

## R6. Tags are read by normalising Log lines in `state.sh`

**Decision**: `log_lines` strips ` [soft]`/` [hard]` from a gate line's head
and keeps the tag in a parallel array. `cycle`, `retry-used` and
`refused-base` then match tagged lines unchanged; `phase2-mode`,
`review-summary` and `shipped-verdict` get the small changes of
data-model.md. Old untagged files read as today. The test
`log-readers-agree` runs `state.sh`'s gate-reading queries and `step.sh`'s
Log reader (sourced behind its main guard) on one shared set of tagged and
untagged fixtures and compares, per fixture, the answers both give to the
same questions: the latest phase 2 gate's tag, override and answer; each
review gate's picked, rejected and dropped ids; the latest `back to` cut;
the retry line used; the shipped verdict.

**Why**: FR-017 with the least change to tested code; each query's own
pattern stays the one source for its rule. The comparison test is the
user's answer to the design review's drift finding: two readers, one
fixture set, a failing test when they disagree.

**Rejected**: rewriting every pattern to allow an optional tag (more
diff, more places to drift).

## R7. `sizes.tsv`: row lines and group lines, strongest precomputed

**Decision**: tab-separated `row` and `group` lines (contracts/sizes.md);
`sizes.py` computes each group's strongest model and effort (its
`strongest()` already does for `models.svg`); `/fix` groups get a
`performance` variant; `/fix` reviewer rows carry their `lens`. The
generated header says how an install tunes it (the `row` line and every
`group` line naming it).

**Why**: `step.sh` reads it with `read` alone, no ranking of models in
bash, and the strongest-model rule lives once, in Python, at build time.

**Rejected**: `step.sh` parsing `sizes.json` (needs `jq` or a JSON parser in
bash); computing the strongest pair in bash (a second copy of the rule);
`/fix` groups as prose (FR-025).

## R8. Report formats: labelled segments, one item per line, fixed values, fail-closed

**Decision**: contracts/agent-formats.md. Finding lines name their parts
(`at:`, `fix:`) with `rec` last; every list field, `Wrote:` included, is
`<Key>: none` or `<Key>:` followed by `- ` items, one per line, never
wrapped; fields the gates read get fixed value sets (`Blocker`, `Size
remark`, `Paraphrase vs brief`, `Several bugs`, `Confidence`,
`Remediations`, `Reproduction`, `Status`, `Deviations`, `Decided`, `Risk
area`, `Performance bug`). The parser fails closed (FR-030): each section
of a reviewer's lenses is required (`none` when empty), a non-item line
inside a list is unparsable, a design finding must carry its tag.

**Why**: today's ` — ` and `→` separators also occur inside titles and
fixes, so the spot and the fix text (merge rules 2 and 3) cannot be cut out
reliably; FR-006 needs every condition as a fixed value. Fail-closed
(design review): with lines ignored and sections optional, a missing
`Security (7b):` section, an indented finding or `Risk area: Security
(token handling)` would drop an S finding or the security risk area
silently and turn the gate soft. Lists everywhere (design review): today's
`Wrote:` is bare paths on the lines after it, which a "list items start
`- `" rule would read as empty.

**Rejected**: parsing today's free text with heuristics (an unparsable
gate on every odd title); JSON reports (an agent writes them less reliably,
and bash can't read them without `jq`); ignoring unknown lines inside a
list (fails open).

## R9. Merge rule 1 comes back as `dropped:` arguments

**Decision**: the coordinator, applying rule 1 to `step.sh`'s list, passes
`dropped: <id> (cut by <C id>)` on its next call to `step.sh` (the answer
call at a hard gate, the fixes boundary after a soft one, or the fixes
boundary with no report when nothing is left). `step.sh` accepts it only
for a `P` or `R` id of the merged list cut by a `C` id of the same list,
logs it under the gate and leaves the id out of what it applies;
`review-summary` leaves it out of the PR body.

**Why**: FR-013 keeps rule 1 with the coordinator, and the record of the
drop must reach the Log without a call of its own. The id check (design
review) stops a mistaken or misled coordinator from dropping a `B` or `S`
finding without the user's answer, which would bypass rule 6.

**Rejected**: `step.sh` dropping by spot overlap (a cut removes more than
its line range; the spec keeps the rule out); a separate `state.sh log`
call (one more call per review).

## R10. Lens 4c compares its paraphrase with the brief

**Decision**: `feat-design-reviewer` lens 4c writes the paraphrase from the
spec and plan first, then reads the state file's brief and reports
`Paraphrase vs brief (4c): matches | contradicts (<what>)`.

**Why**: the brief's own example of a fixed value; it keeps "a paraphrase
that contradicts the brief" a rule in `step.sh` instead of an override.
Writing the paraphrase before reading the brief keeps lens 4c a fresh
reader.

**Rejected**: the coordinator comparing them (a judgment call left out of
`step.sh`, so it could only harden the gate as an override).

## R11. Git inside `step.sh`

**Decision**: `git -C <top>` from `PATH`, plain commands, where `<top>` is
the state file dir's git top level (physical path), never the `Worktree:`
value: `Worktree:` must be `none` or that path, else `step: error`.
Default branch from `git symbolic-ref -q --short
refs/remotes/origin/HEAD`, else `git ls-remote --symref origin HEAD` (as
`/tiny` resolves it); the name must not start with `-` and must pass `git
check-ref-format --branch`, else `step: error: no default branch`. Base
check, repair check and diff preparation as data-model.md; the diff
marks intent-to-add only the untracked paths of the run's implementer
`wrote:` facts, prints each as `added:`, and lists every other untracked
file as `untracked, not in the diff:`.

**Why**: hooks, the worktree guard and the classifier act on the
coordinator's command line; inside a script the conventions' git path rule
has nothing to protect, and one fixed command is the point (brief,
Constraints). Design review: an agent editing the state file outside
`state.sh` could point `Worktree:` at the user's main checkout, widening
the `Wrote:` root and every git target, so the root comes from where the
state file is (as `state.sh`'s `snap_setup` does), which also settles
`Worktree: none`; the default branch name comes from the remote and is a
git argument; marking every untracked file would put the user's own
files (a non-ignored `.env.local`, notes) into every reviewer's context
and into the index.

**Rejected**: reading a git path from the state file's conventions (free
text, and nothing needs it); trusting `Worktree:` as the root; `git add
-N` on every untracked file (today's prose said "the feature's new
files", FR-027 "the run's new files").

## R12. `rebase` keeps its own flow

**Decision**: `rebase.md` writes out the repair check (two git commands),
reads model and effort from the *sizes file*'s `row` line for the
implement and ship rows, once per run, and points to `move.md` for the
move gate and log format. It also keeps its own `Wrote:` check (path
rules and `ls -d`, the one place `ls -d` stays among the *commands besides
the tracker*), on the digests of its implementer and shipper spawns,
which carry what `rebase` reads (rebase-mode `Move`, every `Checks` item,
`Decided`, `Wrote`).

**Why**: `rebase` is outside `step.sh`'s four forms (FR-002) and the brief;
with the size tables gone from the skills it needs another source, and a
table read is free compared to a lookup command (brief, rejected). Design
review: the coordinator never reads a report file, so with the harness's
`ls -d` procedure gone and the digest shrunk, `rebase` could neither check
the move's report nor tell kept, undone and nothing-to-do apart, nor fill
its PR note's `checks <result>`.

**Rejected**: a fifth `step.sh` form for `rebase`; keeping a size table for
`rebase` (rejected in the brief); `rebase` reading report files (the
coordinator never does).

## R13. Resume is the step function

**Decision**: `step.sh resume` = repair check, then `next(state)`
(data-model.md): the current phase restarts with a fresh spawn as today,
except work already owed by an answered gate (an amend, review fixes) and
phase 6's finished stories, which are not redone. A story is done when its
latest `6 US<n>` line is the who-line with no later story gate naming it,
or the latest story gate naming it was answered with a kind other than
`changed`, `back to` or `stop`; the who-line is logged for every report
with a `Not verified:` line. It also prints `phase2-mode` (`/feat`) and
`assess gate: passed|open` (`/fix`), the values the skills' resume text
used to query.

**Why**: AC 1.11 ("the same output as the boundary call for the current
phase"), without redoing a review the user already answered. The done
rule (design review): a story stopped by `Not verified line missing`, a
design problem or checks failing after the retry got no who-line, so after
`approved` the same story would be picked again.

## R14. Fixed size thresholds

**Decision**: small ≤ 30 tasks, medium 31–60, large > 60, exact; a size
trigger keeps at least medium.

**Why**: today's "~30" and "~60" are judgment; FR-006 needs fixed values.
The user still decides: `approved` keeps the size at the gate.

## R15. What carries a tag

**Decision**: lines of a gate decision carry `[soft]` or `[hard]`: the
table gates, the retries decided by rule (`6 US<n>`, `7 review fixes`,
`/fix` `3 Test — failed (retry 1 of 1)`), the stop after review fixes, the
move gate. Records stay untagged: who-lines (`not verified`), fixes lines,
amend lines, `stopped:` lines, `ship with`, moves kept, `8 Ship`, and the
small and medium `3 Plan — merged with 4` line (no gate there). Internal
boundaries that go on (7a–7d → 7e, story → story on small and medium) log
no gate line; a reformat turn is a `- [!]` record, never a gate.

**Why**: #21 counts gates: `grep -c '^- \[x\] .* \[soft\] — '` and the
`[hard]` twin count gate decisions, `^    - override: hard — ` the
overrides, `^    - answer: <kind>` the answers (SC-003). A tagged merged
`3 Plan` line would count a gate that never exists (design review).

## R16. Ship and the renumbered dir

**Decision**: at the ship boundary `step.sh` finds a report the shipper
moved under a numbered dir (exactly one `NNN-<name>/reports/<file>`
sibling), from then on reads and writes the state file there, and prints
`state: <new absolute path>`, which the coordinator passes on every later
call; on `PR: <url>` it sets `done (PR #N)` in that local copy. A blocked
shipper's `!` line is a command for the user only when it starts exactly
`! cd <w> && `, `<w>` the `Worktree:` value or the top level, bare or
single-quoted (gates.md, 8 Ship); any other is the hard
reason `ship blocked`, its text printed under `command:`, never logged.

**Why**: #27's rule for `Wrote:` paths under a renumbered dir, applied by
the script that now reads the report. `step.sh` keeps no state between
calls, so without the `state:` line the coordinator's next call (the
move after `PR: conflict`) would name a file that no longer exists
(design review). The prefix check (design review): `! cd ` alone would
let a line send the user into another directory.

## R17. Tests

**Decision**: `tests/step/run.sh` copies `step.sh`, `state.sh`, `story.sh`, a
fixture `sizes.tsv` and a stub `move.md` into a scratch skill layout, so
spawn goldens do not change with `sizes.json`; fixture state files and
reports per gate row; golden stdout and golden Log tails; throwaway repos
(a bare `origin`, a clone, a worktree) for base, repair and diff cases,
one of them under a path holding a space; the bash 3.2 constructs grep on
`step.sh`. One more case checks the real `sizes.tsv` parses and names
every `sizes.json` row and group. `log-readers-agree` (R6) runs on
`tests/step/fixtures/logs/`, which holds the `tests/state` fixtures'
tagged and untagged Logs. `UPDATE=1 bash tests/step/run.sh` writes the
actual output over `tests/step/expected/` and exits non-zero, so it never
passes CI; the change is reviewed with `git diff tests/step/expected`.
Named cases from the design review: a shipper renumber followed by `PR:
conflict`; `Worktree: none`; a `Worktree:` naming another path; a remote
default branch starting with `-`; a report changed between calls; each
fail-closed parsing rule; an untagged pre-feature state file for each
missing fact; a `dropped:` naming a `B`, `S` or `C` id; a `/fix` 1
security gate answered without `security:`.

**Why**: SC-002 per row; goldens show a reviewer exactly what a change to
a gate does. About 150 cases compared to goldens, which #34 will change
again: regenerating them by hand would be the costliest part of every
format change (design review).

## R18. Constitution 1.4.0

**Decision**: principle III names `sizes.tsv`, both skills' groups and the
prose mirror's new home, and its last sentence becomes "Rules both
skills share MUST live once: the coordinators' part in harness.md and the
references it points to (rebase.md, move.md), the rules step.sh applies in
step.sh" (the move rules go to `move.md`, the gate tables, merge rules 2–6
and the base and repair checks to `step.sh`); principle IV says "the
coordinators and `step.sh`". MINOR bump (guidance materially expanded), with `.claude/CLAUDE.md`
in the same PR (governance).

## R19. One reformat turn before an unparsable report goes hard

**Decision**: the first unparsable report of a spawn is logged as a `- [!]
<N> <phase> — unparsable: <file name>: line <n> (<Key>); reformat 1 of 1`
record and gets a `reformat` spawn of the same row: continued when the
skill allows it and the `Agents` line has the id, else fresh; only the
agents whose reports failed are asked again; a reviewer's reformat gets
a new snapshot. A report of that key still unparsable after it is the hard
reason `unparsable: <file name>: line <n> (<Key>)`. A report-check
failure in the same call skips the turn (hard at once). The line's text
goes to stdout only (`unparsable line:`), never to the Log.

**Why**: the user's decision at the design review ("ok, as recommended"),
overriding the brief's "always hard": a format slip otherwise costs a
user round trip and, at phase 7, a rerun of the whole reviewer batch,
when the agent only has to rewrite one line. The one-retry shape and its
Log record follow FR-003's retry for failing checks. No text in the Log
(design review): the state file is committed and linked from the PR, and
a malformed `Risk area:` line or security finding would publish its text.

**Rejected**: always hard (the brief, overridden by the user); rerunning
the whole batch; more than one reformat turn.

## R20. A report read again is the report checked

**Decision**: when `step.sh` checks a report it takes its `git
hash-object --no-filters` (12 hex) and prints it as `sum=<file
name>:<hex>` on the call line of every later call that passes the report
again (the `7e` line, the ship line after a conflict, a reformat line,
every `answer call:`). That call compares before reading: a missing
`sum=` is `step: usage`, a different hash a failed report check, `report
changed since checked: <file name>`; on an answer call no answer is
applied, and the gate then takes only `back to <N>` or `stop`.

**Why**: design review: the 7e call reads 7a–7d again, the answer call
rebuilds the merged list from disk, and the snapshot leaves `reports/`
out, so a later agent editing an earlier report (removing an S finding,
flipping a `rec`) would make the user's "ok" apply a list they never saw.
Stateless, like the rest: the hash rides on the line the coordinator
copies.

**Rejected**: adding `reports/` to the snapshot (the reformat and fix
spawns write there by design); caching the merged list (R3).

## R21. The `size` form changes the column, not the running spawn

**Decision**: `step.sh <skill> <state file> size <s>`, for the user's
`size <s>` while no hard gate is open, sets `Size`, logs it and prints
`size: <old> → <new>` with no spawn; every spawn printed from the next
boundary on uses the new column (the harness's "later phases use the new
column"). At a hard gate the same request is the answer `size <s>`.

**Why**: the user's choice at the design review (option a). The form is
refused while a hard gate is open and a soft gate doesn't wait, so it can
only run while the next agent is already working; printing a spawn there
would start a second planner, reviewer batch or implementer.

**Rejected**: dropping the form and keeping only `answer: size <s>`
(option b: the user's mid-phase request would have no call).
