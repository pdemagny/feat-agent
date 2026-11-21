# Contract: what `step.sh` decides at each boundary

Today's gate tables of `/feat` phases 2–8 and `/fix` phases 1–5, as
`step.sh` applies them. Field names are those of
[agent-formats.md](agent-formats.md); Log forms are those of
[../data-model.md](../data-model.md). "Facts" are values an earlier boundary
logged so a later one reads them from the Log, never from an old report.

## Every boundary, in this order

0. **Top level** (data-model.md, State file fields): derived from the
   state file's dir; `Worktree:` neither `none` nor that path is `step:
   error`.
1. **Expected boundary**: the token must follow the state
   (data-model.md), else `step: error`.
2. **Answer call?** When answers are passed: the open gate must exist
   (data-model.md, Open gate); validate the answers (step-cli.md,
   Answers), refusals first; unless the main kind is `back to` or `stop`,
   compare each report's `sum=` (data-model.md, Report hashes): a mismatch
   is a failed report check, logged, `hard:` printed, no answer applied;
   else log the answer sub-lines (and, at a review gate, the `outcome:`
   sub-line; extra `/fix` 1 lines; `dropped:` sub-lines); skip steps 3–6;
   print `answered` and go to 7.
3. **Report check** of each new report: the file exists and is non-empty
   (else `report missing`); its `Wrote:` field parses as a list
   (agent-formats.md; a layout slip such as bare paths under `Wrote:` is
   an unparsable report, step 5, not a failed check); each path absolute,
   inside the top level, free of `'`, newline, tab, `$`, backtick and of a
   `..` segment, and on disk; `Wrote: none` with a note beside it is
   refused like a path (as today); the report path itself and each
   artifact path the report names (`Spec:`, `Plan:`, `Tasks:`,
   `Assessment:`, `Test report:`, `Fix report:`) are on `Wrote:`. Each
   report passed again (not new) is compared with its `sum=` instead
   (data-model.md, Report hashes): a mismatch is the failure `report
   changed since checked: <file name>`. The shipper's renumbered dir: when
   the given report path is missing and exactly one
   `<parent>/[0-9][0-9][0-9]-<name>/reports/<file>` exists, that is the
   report; the state file is read and written at the same renumbered path
   from then on, and `state: <new absolute path>` is printed (step-cli.md,
   Output) so the coordinator passes that path on every later call. Each
   failure: `- [!] <N> <phase> — <reason>` and a reason. Each new report
   found on disk is hashed for the call line printed next.
4. **Snapshot**: a reviewer batch's call (no `answer:` argument) must carry
   `snapshot=`, else `step: usage`; `state.sh unchanged '<state file>'
   '<token>'`; `changed` adds the reason `files changed outside the
   reports` and one `changed: <path>` reason per path it printed (or its
   "see git status" line).
5. **Parse** each report (agent-formats.md, Parsing rules: fail-closed).
   A missing required field, a value outside its set, or a non-item line
   inside a list field makes the report unparsable. When no report failed
   steps 3–4 and every unparsable report of the call has its reformat turn
   unused (data-model.md, Reformat turn): log `- [!] <N> <phase> —
   unparsable: <file name>: line <n> (<Key>); reformat 1 of 1` per failed
   report, print `reformat`, `unparsable line:` and the reformat spawns,
   decide nothing else, stop. Otherwise (a turn used, or a report check
   failed in the same call) each unparsable report's reason is
   `unparsable: <file name>: line <n> (<Key>)` or `unparsable: <file name>:
   no <Key>: line`, never the line's text; the text goes to stdout only,
   under `unparsable line:`.
6. **Verdict** from the tables below, after the missing-fact rule
   (data-model.md, Facts on gate lines: a missing fact is never the
   permissive value). Any reason from 3–5 makes it hard before any row,
   even where the row says soft or none. Log the gate line.
7. **Next** (data-model.md, The step function): set `Current phase`, run
   the base check when the next phase starts at a base-check boundary,
   prepare the diff before a code review batch, get report paths and the
   snapshot, print the spawn blocks and `boundary:` (a gate's soft verdict
   also `answer call:`, for an override).

Size increase: always hard, reason `size increase: <old> → <new> (<why>)`;
`size <s>` accepts it, any other main kind keeps the size. Size decrease:
soft, `Size` set, `- [x] size <new> — was <old>: <why>` logged, `size:` line
printed. Two triggers: the earlier phase's is shown first (its gate stops
first).

## `/feat`

### 2 Specify (token `2`)

| Condition | Reason |
| --------- | ------ |
| `Spec: none` | `no spec` |
| `Open markers:` not `none` | `open markers: <n>` |
| `Blocker:` not `none` | `blocker` |
| `Size remark:` not `none` | `size remark` |
| otherwise | soft |

Log: `- [x] 2 Specify [soft] — spec.md written` or `- [x] 2 Specify [hard] —
<reasons>`, then four sub-lines copied from the report: `    - Stories:
<Stories>`, `    - Requirements: <Requirements>`, `    - Spec assumptions:
<Assumptions>`, `    - Unchecked checklist items: <Unchecked checklist
items>`. Every phase 2 report, amends included, logs its own line.

Next: soft → phase 3 (base check, planner, `first`). Answers:

| Answer | Next |
| ------ | ---- |
| `approved` with no open marker and no blocker | phase 3 |
| `approved` with open markers (their recommended answers), `changed` | specifier, `amend`, fresh, key `2-specify` |
| `back to 2` | specifier, `amend`, fresh |

### 3 Plan (token `3`)

Facts logged on every phase 3 line: `assumptions needing you: none | <k>,
<k>…` (the numbers of the planner's `Assumptions` items ending `needs
user: yes`, in report order from 1), `constitution: pass | <principles>`,
`blockers: none | yes`, `size trigger: none | <kind>`.

| Size | Condition | Gate |
| ---- | --------- | ---- |
| small, medium | report check passed | no gate: `- [x] 3 Plan — merged with 4; <facts>`, an untagged record (as `8 Ship`), so #21's counts see no gate that never exists → phase 4 |
| large | always | hard: `- [x] 3 Plan [hard] — large[; <other reasons>]; <facts>` |

Large reasons besides `large`: `assumption <k> needs you` (one per
number), `constitution: <principle>`, `blocker`, `size increase` (never on
large), `checklist item` (a soft phase 2 left unchecked items), `fact
missing: unchecked checklist items` (no phase 2 sub-line to read). After a soft phase 2 whose gate is 3
(phase2-mode `soft 3 open`), a soft-passing answer adds `    - spec
assumptions: kept as recommended`.

Size trigger on small: no gate here; gate 4 gets `size increase: small →
medium (<kind>)`.

Answers (large): `approved` → phase 4; `changed` → planner, `amend`, fresh,
key `3-plan`; its report (token `3`, gate 3 answered `changed`) logs `- [x]
3 Plan — amended; <facts>` (untagged, no stop unless its report check
fails) → phase 4.

### 4 Design review (token `4`)

Merge (data-model.md, Merged list, design): rules 2, 3 and 5; `D1…`.

| Size | Condition | Reason |
| ---- | --------- | ------ |
| large | always | `large` |
| small, medium | a finding with final `rec: user` | `<ids> need you` |
| small, medium | the 3 Plan facts: assumptions needing you not `none` | `assumption <k> needs you`, one per number |
| small, medium | constitution not `pass` | `constitution: <principle>` |
| small, medium | blockers `yes` | `blocker` |
| small, medium | size trigger on small | `size increase: small → medium (<kind>)` |
| small, medium | a 3 Plan fact missing (a run started before this feature) | `fact missing: <name>`, one per name |
| small, medium | `Paraphrase vs brief: contradicts` | `paraphrase contradicts the brief` |
| small, medium | the latest phase 2 line is soft and its `Unchecked checklist items` sub-line is not `none` | `checklist item` |
| small, medium | that sub-line missing | `fact missing: unchecked checklist items` |
| small, medium | otherwise | soft |

Printed: `paraphrase:`, `counts: <n> findings, <a> applied, <s>
skipped[; security: <[sec] ids with apply>][; security skipped: <[sec] ids
with skip>]`, one `finding:` per merged finding.

Log soft: `- [x] 4 Design review [soft] — auto-applied <ids | none>; skipped
<id> (reviewer: "<why>"), …`, then one `    - <id> <artifact>: <section> —
<title> — rec: <value>` per finding (`[sec]`: title only), then `    - spec
assumptions: kept as recommended` when phase2-mode was `soft 4 open`.
Log hard: `- [x] 4 Design review [hard] — <reasons>`, the same finding
sub-lines; at the answer, answer sub-lines and `    - outcome: picked <ids>
| none picked; rejected <id> (user: "<words>") | <id> (as recommended), …`.

Next soft: `apply` findings → planner `amend`, continued (its id) with
`apply:` lines, key `3-plan`, boundary `3`; none → phase 5. Answers:
picked findings or `changed` → planner `amend`, fresh, `apply:` the picked;
nothing picked and no change → phase 5. The amend's report (token `3`,
`Current phase: 4`) logs `- [x] 3 Plan — amended (<ids>); <facts>` → phase
5. On large, when a `3 Plan — amended` line follows the gate 3 line, the
gate 4 output carries `note: plan amended after gate 3` (not a reason).

### 5 Tasks (token `5`)

`step.sh` runs `story.sh -- '<Tasks path>'` once the report check passed,
and compares each group (setup/foundational, each `US<n>`, polish) with
`Per story:`, ranges expanded (`T001–T012`, `T001-T012`); a group the report
leaves out is empty.

| Condition | Reason |
| --------- | ------ |
| a CRITICAL or HIGH line under `Open findings:` | `<n> CRITICAL/HIGH findings` |
| `Analyze: not run (…)` | `analyze not run` |
| no `Analyze:` line | `analyze: not said` (not an unparsable report) |
| `story.sh` exits non-zero | `story.sh: <its line>` |
| a group's IDs differ | `story.sh: <group> — tasker: <IDs> — tasks.md: <IDs>` (one per group) |
| `Total tasks` differs from `story.sh`'s `total:` | `story.sh: total — tasker: <n> — tasks.md: <t>` |
| `Unchecked checklist items: open: …` and no answered gate since the latest phase 2 line had the reason `checklist item` (nor was that line hard and answered) | `unanswered checklist items` |
| the total fits a larger size | `size increase: <old> → <new> (<t> tasks)` |
| no `size trigger` fact on any 3 Plan line, or no phase 2 `Unchecked checklist items` sub-line | `fact missing: <name>` |
| Size large | `large` |
| otherwise | soft |

Size from the total (`story.sh`'s `total:`, the report's `Total tasks:`
when `story.sh` failed): small ≤ 30, medium 31–60, large > 60; a size
trigger other than `none` on the latest 3 Plan line keeps it at least
medium. Smaller: decrease (soft, logged).

Log: `- [x] 5 Tasks [soft] — <t> tasks; story.sh: match; analyze ran` or
`[hard] — <reasons>`. Next: phase 6, first story. Answers: `approved` →
phase 6; `changed` (accepted fixes) → tasker `amend`, fresh, key `5-tasks`.

### 6 Implement (token `6`)

Story order: `story.sh -- '<tasks.md>'` (all stories, tasks.md order).
Each spawn: `story.sh -- '<tasks.md>' US<n>` printed under `story`; a
non-zero exit is hard with `story.sh: <its line>`.

Per story report, the who-line first: every report with a `Not verified:`
line logs `- [x] 6 US<n> — not verified: none` (or the list), a report
without it `- [x] 6 US<n> — Not verified line missing`; either way its
`    - wrote: <path>` sub-lines follow, whatever the verdict. Then the
first matching row:

| Condition | Result |
| --------- | ------ |
| no `Not verified:` line | hard: `- [x] 6 Implement [hard] — US<n>: Not verified line missing` |
| a `Checks:` line `fail` and no retry for this story since the last answer or back to | `- [x] 6 US<n> [soft] — checks failed (retry 1 of 1): <check>`; fresh implementer, same story, `failures:` |
| a `Checks:` line `fail` after the retry | hard: `- [x] 6 Implement [hard] — US<n>: checks fail after retry: <check>` |
| `Design problems:` not `none` | hard: `- [x] 6 Implement [hard] — US<n>: design problem` |
| Size large | hard: `- [x] 6 Implement [hard] — US<n>: large` |
| more stories | next story (no gate line) |
| last story | `- [x] 6 Implement [soft] — tasks done: <n> (<k> not verified); checks pass` → phase 7 |

Which stories are done (so the next one is picked, on an answer or a
resume) is data-model.md, The step function. `tasks:` and `stories:` lines
printed. Answers at a story gate: `approved` → next story or phase 7 (the
story counts as done); `changed` → that story again, fresh, with the
user's changes; `back to 6` → phase 6 from its first story.

### 7 Code review (tokens `7`, `7e`)

Into phase 7 (the call that prints the first batch): data-model.md, Diff
preparation: `git add -N` only on the untracked paths of the Log's
`wrote:` sub-lines (`added:` printed per path), every other untracked file
listed `untracked, not in the diff:` and left alone, `git merge-base
origin/<default> HEAD`, `git diff --quiet <base>`; exit 0 (empty) → hard
`empty diff` before any spawn.
Spawns: `sizes.tsv` groups for phase 7. Medium/large: the groups before the
lone `7e` group run first (token `7`); their call checks reports and the
snapshot, then prints 7e with `cuts:` (7d's report) under a new snapshot
(token `7e`); the gate comes after 7e.

Merge: rules 2–6 (data-model.md, Merged list, code).

| Size | Condition | Reason |
| ---- | --------- | ------ |
| large | always | `large` |
| small, medium | a final `rec: user` | `<ids> need you` |
| small, medium | an `S` finding | `S<n> security` (one each) |
| small, medium | an `Acceptance criteria` line `not met` | `criterion not met: <criterion>` |
| small, medium | otherwise | soft |

`untested` criteria: never a reason; in `counts:` and `; untested: <…>` on
the Log line (soft) or the `outcome:` sub-line (hard).

Printed: `counts: <n> findings, <a> to apply, <s> skipped[; untested:
<criteria>]`, the `finding:` lines. Log as phase 4 with `7 Code review`.
Next soft: `apply` findings → implementer `fix`, fresh, `who: review
fixes`, `apply:` in order (bugs and security, cuts, performance,
readability), key `7-fixes`; none → phase 8. Hard: picked → the same; none
picked → phase 8.

### 7 review fixes (token `7-fixes`)

`dropped:` arguments: accepted only as data-model.md, Merged list, Rule
1 drops says (else `refused:`, nothing logged); sub-lines under the gate
line, written first; ids removed from `apply`; nothing left to apply and
no report → phase 8.

The fix-mode report's `- [x] 7 review fixes — …` line (or `— Not
verified line missing`) carries its `wrote:` sub-lines.

| Condition | Result |
| --------- | ------ |
| report check failed, or no `Not verified:` line | `- [x] 7 review fixes [hard] — <reason>` |
| a check fails, no retry yet | `- [x] 7 review fixes [soft] — checks failed (retry 1 of 1): <check>`; fresh implementer, same findings, `failures:` |
| a check fails after the retry | `- [x] 7 review fixes [hard] — checks fail after retry: <check>` |
| otherwise | `- [x] 7 review fixes — <Fixes (fix mode) value>; checks: <results>; not verified: …` → phase 8 |

Answers at a review-fixes stop: `changed` → a fresh fix-mode implementer
with the same findings and the user's instructions; `approved` → phase 8
as it is (the user's explicit decision); `back to N`; `stop`.

### 8 Ship (token `8`)

Into phase 8: `Current phase: done (shipping)`, base check, `- [x] 8 Ship`,
key `8-ship`, shipper spawn with `not verified items:` (the latest list of
each story and of review fixes). The report:

| `PR:` | Result |
| ----- | ------ |
| `<url>` | `soft`, `pr:`, `Current phase: done (PR #N)` (local copy), `done: PR #N` |
| `blocked`, `Command for the user:` starts exactly `! cd <w> && ` or `! cd '<w>' && `, `<w>` being the state file's `Worktree:` value as written or the top level (data-model.md; with `Worktree: none`, the top level only) | `stop: ship blocked on a command for you`, `command:` |
| `blocked`, any other `!` line (another dir, no `&& `, a prefix of the top level) | hard `ship blocked`; the line is printed under `command:` for the gate message, never logged; `Current phase: 8 Ship` (local copy); `approved` → ship again |
| `conflict` | `soft`, `read:`, rebase-mode spawn (`shipped: no`, key `move`), boundary `move`; the move's report (Current phase `done (shipping)`) → ship again with `boundary: 8 <ship report> <move report>` (the ship report with its `sum=`); that call logs the move (`at ship`) after reading the ship report, at the renumbered path |

When the shipper renumbered the dir (step 3), every one of these outputs
starts, after the verdict, with `state: <new absolute path>`; a test case
covers a renumber followed by `PR: conflict` and the move's call at the
new path.

## `/fix`

### 1 Assess (token `1`)

Stop first (checked before any other row):

| Condition | `Current phase` | Log |
| --------- | --------------- | --- |
| `Assessment: none (…)` | `done (invalid)` | `- [x] 1 Assess — stopped: <the reason>` |
| `Verdict: invalid` | `done (invalid)` | the same, with `invalid` |
| `Is a bug: no — refactor` or `no — backport` | `done (not a bug)` | `- [x] 1 Assess — stopped: out of scope (<refactor or backport>)` |
| `Is a bug: no — …` (other) | `done (not a bug)` | `- [x] 1 Assess — stopped: <the Is a bug value>` |

Output `stop: <the logged reason>`, `done: stopped (…)`.

Soft only when all hold: `Proposed size: small`, `Confidence: high`,
`Reproduction: reproduced`, `Remediations: 1`, `Public behaviour change:
no`, `Verdict: valid`, `Is a bug: yes`, `Several bugs: no`, `Open questions:
none`, the setup line's `report author` is `OWNER`, `MEMBER`,
`COLLABORATOR` or `user`, `Risk area` does not name `security`, `Sections:
ok`, `Slug: ok`, and no issue is to be created (board tracking, i.e.
`.logistics.yml` at the worktree's top level, with `Issue: none`, and not a
security bug). Else hard, every reason that applies:

| Condition | Reason |
| --------- | ------ |
| `Sections: error …` | `sections: <error>` |
| `Slug: mismatch (…)` | `slug mismatch: <slug>` |
| report author untrusted | `report author <association>` |
| no `report author` on the setup line | `fact missing: report author` (untrusted) |
| `Reproduction: needs approval` | `needs approval` |
| `Risk area` names `security` | `security risk area` |
| an issue is to be created | `issue to create` |
| `Verdict: likely valid, needs reproduction` | `needs reproduction` |
| `Open questions:` not `none` | `open questions: <n>` |
| `Several bugs: yes` | `several bugs` |
| `Proposed size` not small | `proposed size <s>` |
| `Confidence` not high | `confidence <c>` |
| `Reproduction` not `reproduced` (other than needs approval) | `<the value>` |
| `Remediations` not 1 | `remediations: <N>` |
| `Public behaviour change: yes` | `public behaviour change` |

On pass (soft, or an `approved`/`size <s>` answer): `Size` set (proposed,
or the answer's), `title` set (`Title:`), logged `- [x] 1 Assess [soft] —
gate: <verdict>, <confidence> confidence, <reproduction>, <N>
remediation(s); size <s>; risk area <r>; performance bug <yes|no>`, or under
the hard line the sub-line `    - passed: <the same text>`. Then the
`approved:`, `question:` and `security:` arguments as `- [x] 1 Assess —
approved: <command>`, `- [x] 1 Assess — answer: <q> → <a>`, `- [x] 1
Assess — security: <choice> (user: "<words>")`. At a gate whose reasons
include `security risk area`, a passing answer (`approved`, `size <s>`)
without a `security:` argument is refused, `refused: security: advisory or
issue needed`, nothing logged: the user's choice comes before any issue
is created. Next: phase 2 (base check).
Issue creation and the building move stay with the coordinator, before the
phase 2 spawn. `back to 1` → assessor `assess`, fresh, with the user's
evidence (the coordinator's), size column as set.

### 2 Fix (token `2`)

| Condition | Reason |
| --------- | ------ |
| `Slug: mismatch (…)` | `slug mismatch: <slug>` |
| `Deviations:` not `none` | `size increase: <old> → <one step up> (deviations)` (large stays large: reason `deviations`) |
| a `Checks:` line `fail` | `check fails: <check>` |
| `Status:` not `applied` | `status <value>` |
| no `Not verified:` line | `Not verified line missing` |
| otherwise | soft |

Log: `- [x] 2 implementer — not verified: …` (who-line with its `wrote:`
sub-lines, or `— Not verified line missing`), then `- [x] 2 Fix [soft] — [retry: ]applied; no deviations;
checks pass` (`retry: ` when `retry-used` says `yes`) or `- [x] 2 Fix [hard]
— <reasons>`. Next: phase 3 (base check). Answers: `approved` (going on
past the reasons; with deviations, `size <s>` is "go on with size <s>"),
`back to 1`, `back to 2`.

### 3 Test (token `3`)

Spawn inputs: `cycle` (`state.sh cycle`), `not verified items` (the latest
`implementer` list), `approved commands`.

First match wins:

| Condition | Result |
| --------- | ------ |
| report check failed | hard, no verdict logged |
| `Sections: error` or `Slug: mismatch` | hard `sections: …` / `slug mismatch: …` |
| the latest `4 implementer` line notes `Not verified line missing` | hard `review fixes report lacked Not verified line` |
| an item given is missing from `Not verified items:` (matched on `<check>`), or the line is `n/a` while items were given | hard: `- [x] 3 Test [hard] — unaccounted items: <items>; verdict: <v>`; `approved` logs `- [x] 3 Test — unaccounted: <items> (user: "<words>")` and applies the verdict's row; `changed` → re-test, same cycle, same items |
| `Verdict: verified` | `- [x] 3 Test [soft] — verified` → phase 4, or phase 5 when `cycle` is `after review fixes` |
| `Verdict: partial` | `- [x] 3 Test [hard] — partial: <Missing for verified>`; `changed` → re-test with the user's evidence; `ship with partial` → phase 4 (first cycle) or 5 |
| `Verdict: failed`, `cycle` `first`, `retry-used` `no` | `- [x] 3 Test [soft] — failed (retry 1 of 1): <Still failing>; retry fix` → phase 2, fresh implementer, `test report`, `still failing` |
| `Verdict: failed` otherwise | `- [x] 3 Test [hard] — failed: <Still failing>`; `back to 1` recommended; `ship with failed` → 4 or 5 |

`back to N` also logs `- [x] back to N — <the user's words>` (resets cycle
and retry). `ship with <v>` logs only its answer sub-line
(`shipped-verdict` reads it).

### 4 Code review (tokens `4`, `4-fixes`)

Into phase 4: the diff as `/feat` 7. Groups: `sizes.tsv` phase 4 for the
size, the `performance` variant when the 1 Assess facts say `performance
bug yes` or lack `performance bug`. Merge rules 2–6.

| Condition | Reason |
| --------- | ------ |
| the 1 Assess facts name `security` | `security risk area` (the gate shows the go-ahead) |
| the 1 Assess facts lack `risk area` (a run started before this feature) | `fact missing: risk area` and `security risk area`: read as a security bug; `back to 1` re-assesses and logs the fact |
| Size large | `large` |
| a final `rec: user` | `<ids> need you` |
| an `S` finding | `S<n> security` |
| otherwise | soft |

`approved` at a gate with `security risk area` also logs `- [x] 4 Code
review — ship go-ahead (user: "<words>")`. Next as `/feat` 7, key
`4-fixes`, `who: implementer`. The `4-fixes` report logs `- [x] 4
implementer — <Fixes value>; checks: <results>; not verified: …` with its
`wrote:` sub-lines (or `— Not verified line missing`) → phase 3, cycle
`after review fixes`. `dropped:` as `/feat` 7 review fixes. No
retry here. Nothing to apply → phase 5. `skip 4` answered at an earlier
gate on a security bug: phase 4 becomes the hard gate `- [x] 4 Code review
[hard] — skipped; security risk area`, whose `approved` logs the go-ahead
and goes to 5.

### 5 Ship (token `5`)

As `/feat` 8 with `5 Ship`, key `5-ship`, `security bug:` from the facts:
`yes` when `risk area` names `security` or is missing, else `no`. A
missing `risk area` is also the hard reason `fact missing: risk area` at
the boundary into 5, unless a phase 4 gate carrying that reason was
answered since the latest `back to` (the user has answered it once:
`approved` ships it as a security bug, `back to 1` re-assesses).

## Moves (tokens `move`, `repair`)

The rebase-mode report's `Move (rebase mode):` line:

| Value | Result |
| ----- | ------ |
| `<old> → <new>` | `- [x] move — <old> → <new> (before <N> <name>): checks <result>; not verified: <none or items>`, `    - resolved: <file> — <how>` per `Resolved alone` line, `    - asked: <file> — <decision>` per `Decided` line; `move:` printed; the phase's spawn (new snapshot) |
| `undone (<old> → <new>)` | hard: `- [x] move [hard] — undone (<old> → <new>)`, reason `move undone (<old> → <new>)`; `approved`/`changed` → fresh rebase spawn (the coordinator adds `Decisions:`); `stay` → `- [x] move — stayed on <old>, refused <new> (user: "<words>")`, the phase on `<old>` |
| `nothing to do` | nothing logged; the phase's spawn |
| `repaired` (token `repair`) | `- [x] move — repaired (<the Move line>)`; then `next` |

`<result>`: `pass` when every `Checks:` line passes, else `fail: <first
failing check>`. Report missing at `move`: the repair check; it applies →
repair spawn (`action: repair`); else hard `report missing`.

## Reasons

The reason strings above are fixed text (with their values filled in); #34
and the Log readers match on their first words. Reasons that carry report
text carry only ids, paths, file names, line numbers, keys, counts, check
commands or one-word values, never a finding's text, an unparsable line's
text or a shipper's `!` line: those are printed on stdout only, under
their own keys (`unparsable line:`, `command:`), for the gate message.
`fact missing: <name>` names the fact, never a value.
