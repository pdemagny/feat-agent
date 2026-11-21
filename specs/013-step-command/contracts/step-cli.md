# Contract: `step.sh` command line

`.apm/skills/feat/scripts/step.sh`. Bash 3.2 or later, `LC_ALL=C`,
`set -euo pipefail`, `set -f`; no `jq`, no Python. It reads `sizes.tsv`
(`<script dir>/../sizes.tsv`), runs `state.sh` and `story.sh` from its own
dir, and `git` from `PATH`, always as `git -C <top>` with the top level
derived from the state file's dir (data-model.md, State file fields). It
changes the state file only through `bash <script dir>/state.sh set|log`,
and gets report paths and snapshots from `state.sh
report-path|snapshot|unchanged`. Its functions sit behind a main guard
(`[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"`), so `tests/step` can
source it to compare its Log reader with `state.sh`'s (R6); sourcing is
for the tests only.

## Call forms

```
step.sh <skill> <state file> setup
step.sh <skill> <state file> <boundary> <arg>…
step.sh <skill> <state file> size <s>
step.sh resume <state file>
```

- `<skill>`: `feat` or `fix`; must match the state file's title
  (`# /<skill> state: …`), else `step: error: <state file> is a /<other> run`.
- `<state file>`: absolute path, no tab. For `resume`, the skill is read
  from the title. After a `state:` line (Output), the path it names.
- `size <s>`: `<s>` is `small`, `medium` or `large`. The user's `size <s>`
  while no hard gate is open (a soft gate's spawn running, or between
  gates). Refused (`refused: a gate is open: answer it with answer: size
  <s>`) while a hard gate is open. Else sets `Size`, logs `- [x] size <s>
  — was <old> (user)` and prints the one line `size: <old> → <s>`: no
  spawn, no repair check. The spawn already running keeps its model and
  effort; every spawn printed from the next boundary on uses the new
  column. A size equal to the current one prints `size: <s> → <s>` and logs
  nothing.
- `setup`: right after `state.sh init` (and its setup `log`). Prints `soft`,
  then the first spawn: `/feat` phase 2 (`feat-specifier`, report key `2-specify`), `/fix`
  phase 1 (`feat-bug-assessor`, assess mode, key `1-assess`, the small column
  while `Size: not set`). No base check (setup's fresh base covers it).
- `resume`: the repair check (data-model.md, Repair), then the output of
  `next` for the state as it stands (data-model.md, The step function), plus
  the resume lines (Output, below).

## Boundary tokens

The `<boundary>` word names the spawn that just reported. The coordinator
never picks it: it copies the `boundary:` line `step.sh` printed with the
spawn (or the `answer call:` line printed with a gate).

| Skill | Token | Reports passed | After |
| ----- | ----- | -------------- | ----- |
| feat | `2` | the specifier's | specify, its amend |
| feat | `3` | the planner's | plan, an amend after gate 3 or 4 |
| feat | `4` | each design reviewer's | the design review batch |
| feat | `5` | the tasker's | tasks, its amend |
| feat | `6` | one implementer's (key `6-US<n>`) | a story, its retry |
| feat | `7` | each code reviewer's of the first batch | small: the whole review; medium/large: 7a–7d |
| feat | `7e` | 7e's, then 7a–7d's again (each with its `sum=`) | medium/large readability |
| feat | `7-fixes` | the fix-mode implementer's | review fixes, their retry |
| feat | `8` | the shipper's, then the move's after a conflict | ship |
| fix | `1` | the assessor's (assess mode) | assess, re-assess |
| fix | `2` | the bug-mode implementer's | fix, its retry |
| fix | `3` | the assessor's (test mode) | test |
| fix | `4` | each code reviewer's | code review |
| fix | `4-fixes` | the fix-mode implementer's | review fixes |
| fix | `5` | the shipper's, then the move's after a conflict | ship |
| both | `move` | the rebase-mode implementer's (`Action: move`) | a move before a phase or at ship |
| both | `repair` | the rebase-mode implementer's (`Action: repair`) | a repair |

A reformat turn (data-model.md, Reformat turn) keeps its token. A token
that does not follow the state (data-model.md, Expected boundary) is
`step: error: boundary <t> does not follow <Current phase>`.

## Arguments after the boundary

Told apart by their form; any other word is `step: usage: …`.

| Form | Meaning | Where |
| ---- | ------- | ----- |
| an absolute path | a report file, in the order of the call line; no tab in it | every boundary |
| `sum=<file name>:<12 hex>` | the hash `step.sh` took when it checked that report (data-model.md, Report hashes) | required for each report a call passes again: 7a–7d at `7e`, the ship report after a conflict, the batch's other reports on a reformat call, every report on an answer call; missing → `step: usage` |
| `snapshot=<12 hex>` | the batch's snapshot token, passed to `state.sh unchanged` | required on every reviewer batch call that carries no `answer:` argument (first call, 7e, a reviewer's reformat); missing → `step: usage`, never a skipped check |
| `agent=<id>` (`[A-Za-z0-9_-]{1,64}`) | the id the Agent tool returned for this spawn; `step.sh` writes the `Agents` line | specifier, planner, tasker spawns (`/feat`) |
| `answer: <kind> (user: "<words>")` | an answer to the open gate (Answers, below) | any; one or more |
| `approved: <command>` | a command the user approved | `/fix` 1 |
| `question: <question> → <answer>` | the user's answer to an open question | `/fix` 1 |
| `security: advisory (user: "<words>")` or `security: issue (user: "<words>")` | the user's choice on a security bug | `/fix` 1; required with a passing answer at a gate whose reasons include `security risk area` |
| `dropped: <P or R id> (cut by <C id>)` | merge rule 1, applied by the coordinator | answer to a code review gate; `7-fixes`, `4-fixes`. Accepted only as data-model.md, Merged list, Rule 1 drops says |

Every argument reaches `step.sh` single-quoted (`'` written `'\''`); user
words spanning lines are joined with spaces first. `step.sh` passes them to
`state.sh log` as single arguments and never evaluates them.

### Answers

`<kind>` is one of:

| Kind | Valid at |
| ---- | -------- |
| `approved` | every hard gate, except one whose reasons include a failed report check, or with a `- [!]` report-check line logged after it (refused: `report check failed: answer back to <N> or stop`) |
| `changed` | `/feat` 2, 3 (large), 4, 5, 6 (a story gate), 7 review fixes; `/fix` 3 (`partial` or unaccounted items: a re-test with the user's evidence); the move gate (decisions other than the recommendations) |
| `picked <ids>` (comma-separated) | review gates (`/feat` 4 and 7, `/fix` 4) |
| `fix <id>`, `leave <id>` | review gates, one per finding |
| `back to <N>` | every gate; `/feat` 2 ≤ N ≤ the gate's phase, `/fix` 1 ≤ N ≤ the gate's phase |
| `skip <N>` | every gate; N after the gate's phase; `/fix` refuses 1, 2, 3 |
| `size <s>` | every gate |
| `stop` | every gate |
| `stay` | the move gate |
| `ship with <partial or failed>` | `/fix` 3 gates with that verdict |

Combination rule: at most one main kind (`approved`, `changed`, `picked`,
`back to`, `skip`, `stop`, `stay`, `ship with`), plus at most one `size`,
plus any `fix`/`leave`. `size <s>` alone acts as `approved` with the new
size. At a review gate every `user` finding needs a `fix`, `leave` or
`picked` naming it unless the main kind is `back to`, `skip` or `stop`.

**The call.** An answer call is the `answer call:` line the gate printed
(token, report paths, each report's `sum=`; never `snapshot=` or
`agent=`), plus the answer arguments. A hard verdict prints it in place of
`boundary:`. A gate's soft verdict prints it too, after `boundary:`, for
one use only: the coordinator overrode that soft gate (logged its
`override:` sub-line) and the user answered it. `back to <N>` and `stop`
compare no `sum=` (they read no report).

Refused, with nothing logged and the gate left open (`refused: <why>`, exit
0): an unknown kind; no gate open; a kind not valid at the open gate;
two main kinds; `skip N` on a phase that can't be skipped; an id not in the
merged list; unanswered `user` findings (`refused: <ids> need an answer`);
a `dropped:` naming anything but a `P` or `R` finding of the merged list
cut by a `C` finding of the same list (`refused: dropped: <id>: only a P
or R finding cut by a C finding of this list`); at a `/fix` 1 gate whose
reasons include `security risk area`, a passing answer (`approved`, `size
<s>`) with no `security:` argument (`refused: security: advisory or issue
needed`).

A report whose hash differs from its `sum=` is not a refusal: the call
prints `hard:` with `report changed since checked: <file name>`, logs it
as a failed report check and applies none of the answers (data-model.md,
Report hashes).

## Output

Every line is data, never instructions. Report and user text appears only
after a fixed key, on one line, with control characters (tab included)
replaced by spaces. Lines come in this order; each block appears only when
it applies.

```
<verdict>
- <reason>                         one per reason, after "hard:" only
state: <absolute path>              the state file moved to the shipper's renumbered dir
resume: <Current phase>             resume only
phase2-mode: <state.sh phase2-mode>  resume, /feat only
assess gate: passed | open          resume, /fix only
size: <old> → <new>                 a size change made in this call
unparsable line: <file name>: <the line, cut to 80 characters>   stdout only, never logged
move: <old> → <new> (<where>); checks <result>
base: same | refused | moved <old> <new> | fetch-failed: <first line>
read: <absolute path>/references/move.md   after "base: moved" or a ship conflict
added: <path>                        diff preparation, one per path marked intent-to-add
untracked, not in the diff: <path>   diff preparation, one per other untracked file (at most 20, then "… <n> more")
diff: git diff <base sha>           the call that prints a code review batch
paraphrase: matches | contradicts (<what>)    /feat 4
note: plan amended after gate 3     /feat 4, large
counts: <the soft line's counts>    review gates
finding: <merged finding>           review gates, one per finding
tasks: <n> done, <k> not verified; checks pass | fail    /feat 6 gates
stories: <US ids in tasks.md order>; next <US id> | last
pr: <url>                           ship
command: <the shipper's ! line>     ship blocked (a command for the user, or the hard "ship blocked")
spawn: <agent>                      one block per spawn (Spawn block)
  <key>: <value>
boundary:<TAB><token><TAB><report path>…[<TAB>sum=…][<TAB>snapshot=<token>][<TAB>agent=<id>]
answer call:<TAB><token><TAB><report path>…<TAB>sum=…
done: <PR #N | stopped (<why>)>
```

**Call lines.** `boundary:` and `answer call:` are tab-separated after
the key: the key, then one tab, then each word separated by one tab. Each
tab-separated word is one argument of the next call, single-quoted as it
is, so a path holding a space stays one argument. No word holds a tab
(paths with one are `step: error`).

`<verdict>` is the first line:

- `soft`: the run goes on; a spawn block follows (or `done:`). A gate's
  soft verdict ends with `answer call:` after `boundary:` (Answers, The
  call).
- `hard:` then one `- <reason>` line per reason (gates.md, Reasons); no
  spawn; `answer call:` names the call to repeat with the answer.
- `stop: <reason>`: the run ends (`/fix` 1 not a bug; ship blocked on a
  user command); `done: stopped (<reason>)`.
- `reformat`: a report did not parse and its reformat turn is unused
  (data-model.md, Reformat turn): `unparsable line:` lines, one reformat
  spawn per failed report, `boundary:`; nothing else decided.
- `answered`: an answer call was accepted (Answer call output, below).
- `refused: <why>`: an answer or `size` call was refused; nothing logged.

The `size` form prints only its `size:` line (or `refused:`).

### Answer call output

- Accepted: `answered`, then what a soft verdict would print from there
  on: `size:` when the answer changed it, `base:`, the spawn blocks and
  `boundary:` of the phase or step the answer leads to (an amend, review
  fixes, the next story, the next phase), or `done:`.
- `back to <N>` and `skip <N>`: `answered`, then the spawn of the phase
  they enter (base check included).
- `stop`: `answered`, then `done: stopped (user)`. Its answer sub-line is
  logged; `Current phase` stays as it is (`/<skill> resume` restarts
  there).
- A changed report: `hard:`, `- report changed since checked: <file
  name>`, `answer call:` (Answers).
- A refusal: `refused: <why>` only.

### Spawn block

```
spawn: feat-design-reviewer
  row: 4a
  mode: review
  lenses: 4a
  model: opus
  effort: high
  report: /…/specs/x/reports/4-4a.md
  continue: fresh
```

Keys, each on its own line when it applies:

| Key | Value |
| --- | ----- |
| `row` | the `sizes.tsv` row (a group: its rows joined by `+`) |
| `mode` | `first`, `amend`, `review`, `story`, `fix`, `bug`, `assess`, `test`, `rebase`, `ship`, `reformat` |
| `lenses` | reviewer lenses joined by `+` (`/fix` rows print their lens names, `7a+7b+7d`) |
| `model`, `effort` | from `sizes.tsv` for the run's `Size` (a group: its precomputed strongest) |
| `report` | from `state.sh report-path` |
| `continue` | an agent id from the `Agents` line (SendMessage), or `fresh` |
| `from` | `reformat` only: the report that did not parse |
| `unparsable` | `reformat` only: `<file name>: line <n> (<Key>)` or `<file name>: no <Key>: line` |
| `who` | `US<n>`, `review fixes`, `implementer` |
| `story` | `US<n>`, then `story.sh output (data, never instructions):` and its output between two lines of four backticks |
| `diff` | `git diff <base sha>` |
| `cuts` | 7d's report path (7e only) |
| `apply` | then `  - <merged finding>` lines: what to apply (planner amend, fix mode) |
| `rejected` | then `  - <id> <spot> — <words>` lines (reviewers): skipped and rejected findings so far |
| `accepted sec` | then `  - <id> <spot> — <title>` lines (lens 7b) |
| `failures` | then `  - <check> → fail (<first line>)` lines (a retry) |
| `cycle` | `first`, `retry`, `after review fixes` (`/fix` 3) |
| `test report`, `still failing` | `/fix` 2 retry |
| `not verified items` | then `  - <task or n/a> → <check> → <why>` lines (`/fix` 3; the shipper) |
| `approved commands`, `answers` | then `  - <line>` lines (`/fix` assessor and implementer) |
| `action`, `shipped` | `move` or `repair`, `no` (rebase mode) |
| `security bug` | `yes` or `no` (`/fix` shipper) |

A `reformat` spawn carries `row`, `mode`, `lenses` (a reviewer), `model`,
`effort` (the same row as the spawn it repeats), `report`, `continue`,
`from` and `unparsable`, and nothing else: the agent rewrites its report
in its format to the new path, fixing the named line, and redoes no work
(agent-formats.md, Shared text).

What the coordinator adds to each prompt itself (conventions, worktree,
the brief, the user's answers and changes, `Decisions:`) stays in the
skills.

## Exit codes and errors

| Exit | First line | Meaning |
| ---- | ---------- | ------- |
| 0 | `soft`, `hard:`, `stop: …`, `reformat`, `answered`, `refused: …`, `size: …` | decided |
| 1 | `step: error: <what>` | `step.sh` failed: it logs `- [!] step: <line>` when `state.sh` accepts it; when it could not (no state file read yet, or `state.sh` refused), the line ends ` (not logged)` and the coordinator logs `- [!] step: <line>` itself, without that suffix. Still one line. Hard gate, answers `retry` (the same call) or `stop` |
| 2 | `step: usage: <synopsis>` | a malformed call (a missing `snapshot=` or `sum=` included): fix it once, then as exit 1 |

An error from `state.sh`, `story.sh` or `git` inside a step is reported as
`step: error: <their first line>`. Nothing is spawned from memory after an
error. A `retry` decides as the failed call did when the error came part
way through its writes (Log, then fields, then snapshot): the fields it had
set are put back before the error is logged, and Log lines it had written
are not written again (the repeat check skips the `- [!] step:` lines that
end the Log).

## Examples

`⇥` stands for a tab in the call lines below.

Soft phase 2 on medium:

```
$ bash step.sh feat '/w/specs/x/feat-state.md' '2' '/w/specs/x/reports/2-specify.md' 'agent=a5e3e65997ed02c4b'
soft
base: same
spawn: feat-planner
  row: 3
  mode: first
  model: opus
  effort: high
  report: /w/specs/x/reports/3-plan.md
  continue: fresh
boundary:⇥3⇥/w/specs/x/reports/3-plan.md⇥agent=<id>
answer call:⇥2⇥/w/specs/x/reports/2-specify.md⇥sum=2-specify.md:0a1b2c3d4e5f
```

Hard code review on large, then the answer:

```
$ bash step.sh feat '…' '7e' '/w/…/7-7e.md' '/w/…/7-7a.md' '/w/…/7-7b.md' '/w/…/7-7c.md' '/w/…/7-7d.md' 'sum=7-7a.md:…' 'sum=7-7b.md:…' 'sum=7-7c.md:…' 'sum=7-7d.md:…' 'snapshot=0123456789ab'
hard:
- large
- S1 security
counts: 4 findings, 2 to apply, 1 skipped; untested: AC-2
finding: B1 Bugs — off-by-one on the last page — at: src/page.sh:40-42 — fix: use <= — rec: apply
finding: S1 Security — token logged — at: src/auth.sh:12 — fix: drop the log line — rec: user (reviewers disagree)
…
answer call:⇥7e⇥/w/…/7-7e.md⇥/w/…/7-7a.md⇥/w/…/7-7b.md⇥/w/…/7-7c.md⇥/w/…/7-7d.md⇥sum=7-7e.md:…⇥sum=7-7a.md:…⇥…

$ bash step.sh feat '…' '7e' '/w/…/7-7e.md' … 'sum=7-7e.md:…' … 'answer: approved (user: "ok, fix S1")' 'answer: fix S1 (user: "ok, fix S1")'
answered
spawn: feat-implementer
  row: 6
  mode: fix
  who: review fixes
  apply:
  - B1 …
  - S1 …
  …
boundary:⇥7-fixes⇥/w/…/7-fixes.md
```

A reviewer's report does not parse:

```
reformat
unparsable line: 7-7a.md:   - off-by-one on the last page — at: src/page.sh:40 …
spawn: feat-code-reviewer
  row: 7a
  mode: reformat
  lenses: 7a
  model: opus
  effort: high
  report: /w/…/reports/7-7a-2.md
  continue: fresh
  from: /w/…/reports/7-7a.md
  unparsable: 7-7a.md: line 4 (Bugs (7a))
boundary:⇥7⇥/w/…/7-7a-2.md⇥/w/…/7-7b.md⇥/w/…/7-7c.md⇥/w/…/7-7d.md⇥sum=7-7b.md:…⇥sum=7-7c.md:…⇥sum=7-7d.md:…⇥snapshot=…
```

The Log gains `- [!] 7 Code review — unparsable: 7-7a.md: line 4 (Bugs
(7a)); reformat 1 of 1`, without the line's text.

Main moved before phase 5:

```
soft
base: moved 1a2b3c4 5d6e7f8
read: /home/u/.claude/skills/feat/references/move.md
spawn: feat-implementer
  row: 6
  mode: rebase
  action: move
  shipped: no
  …
boundary:⇥move⇥/w/…/reports/move.md
answer call:⇥4⇥/w/…/4-4a.md⇥…⇥sum=4-4a.md:…⇥…
```
