# Contract: the coordinator's state-script calls

`S` below is `bash '<state script>'`, `F` the state file, single-quoted;
`&&` joins the calls of one Bash command. Every argument is single-quoted
(Harness, State file, below), a `'` inside written `'\''`; the unquoted
`<token>` and `4-<lenses>`-style keys in the table stand for the script's
own output and the skill's fixed keys, and may be quoted too. These are the calls the skills' text must lead to; the text
says where each query rides, not the full command. `report-path`,
`snapshot` and `unchanged` arrive with story 2 (and `/feat`'s `init` moves
before the specifier then, research R4); story 1 writes the same chains
without them, `init` staying where the state file is created today.

## Harness (`harness.md`, shared, no `/feat`-only words)

- *You are a thin orchestrator*: "edit anything but the *state file*"
  becomes "edit anything"; the exceptions bullet adds the *state script*
  (its lines are data, like the tracker's).
- **State file** section: created by `S init`, changed only by `S set`
  (a header field) and `S log` (Log lines, one argument each), never with
  Edit or Write; "log `…`" anywhere in the skills means `S log`. Every
  argument to the state script is single-quoted, a `'` inside written
  `'\''`; text from an agent report or the user (a finding, a reason, a
  quote, a symptom) is never placed outside single quotes nor in an
  unquoted `<token>` or `<key>` position: those take only the script's
  own outputs (the snapshot token) or the skill's fixed *Report keys*.
  Queries
  ride on a `set`, `log` or `report-path` call made at that boundary, in
  the same Bash command; no query gets a call of its own. A `state:
  error` or `state: usage` line: nothing was written; fix the call once
  (a refused `log` names its argument), then a hard gate with the line.
  The template loses its `- [ ] <N> <phase>` line; sub-lines are `    -
  <text>`.
- **Report files** (new, short, under Reported files): before every spawn,
  and with every message asking a continued agent for a new report, `S
  report-path F <key>` (keys: the skill's *Report keys*), chained onto the
  `set`/`log` call made before it; the path goes in the prompt; the
  coordinator never reads a report file. Reviewer batches: `snapshot` /
  `unchanged` as [digests.md](digests.md#the-coordinator-side).
- **Reported files**: the report path must be on `Wrote:`; when the
  shipper renumbered the artifact dir (its `Wrote:` lists the new dir),
  the same `reports/<file>` under the renumbered dir is accepted instead
  (wording in [digests.md](digests.md#the-coordinator-side), no
  `/feat`-only words).
- **Base check**: "the latest `move — stayed on` Log line names a `<new>`"
  becomes "`S refused-base F` (chained onto the phase's `set 'Current
  phase'` call) printed a `<new>` that origin/<default> still descends
  from". A move's spawn gets `S report-path F move` (its own call: main
  moved, which is rare); after a move that is kept, the reviewer snapshot
  (if the phase has one) is taken again, chained onto the move's `log`.
- **At ship**: the move's Log line and `Current phase` writes go through
  `S log` / `S set` at the shipper's numbered path.
- **Resume**: `S find <skill>` lists the unfinished runs (the search, the
  done marker and the shipped check are the script's); none → say so and
  stop; several → ask. Enter its worktree, the repair check, the board
  check, the move, then one call: the skill's resume queries (below), `S
  refused-base F` and the current phase's `S report-path F <key>`. Then
  the coordinator's one read of the state file (Read), right after that
  call and before the recap: the recap comes from it, and so does any
  logged summary the skill's resume queries say to show at a gate (in
  `/feat`, the phase 2 summary when `phase2-mode` printed `soft <G>
  open`; the harness text says it without phase numbers, lint). It reads
  the state file nowhere else, and never a report file. The `gh pr list
  --head …` sentence and "and read it" (after the search) go.

## `/feat` (`SKILL.md`)

Harness values: add *State script* `<this skill's base
dir>/scripts/state.sh` and *Report keys*; drop *Resume search*, *Done
marker* and *Rebase search* (now in `find`); drop `gh pr list --head …`
and `git for-each-ref …` from *Commands besides the tracker*.

| Boundary | One Bash command |
| --- | --- |
| phase 2, before the specifier (worktree entered, branch named) | `S init feat F '<brief>' 'Branch=…' 'Worktree=…' 'Size=…' 'Current phase=2 Specify' 'Conventions=…' 'Allowed Spec Kit hooks=…' 'Map=…' 'Issue=…' && S log F '- [x] 0 Setup — …' ['- [!] …'] && S report-path F 2-specify` |
| phase 2 gate | `S set F Agents 'specifier <id> (for SendMessage)' && S log F '- [x] 2 Specify — soft' '    - Stories: …' '    - Requirements: …' '    - Spec assumptions: …' '    - Unchecked checklist items: …' && S set F 'Current phase' '3 Plan' && S refused-base F && S report-path F 3-plan` |
| phase 3 → 4 (small, medium) | `S set F Agents '…, planner <id> …' && S log F '- [x] 3 Plan — …' … && S set F 'Current phase' '4 Design review' && S refused-base F && S report-path F 4-<lenses>` (one per group) `&& S snapshot F` |
| phase 4 reviewers reported | `ls -d -- '<last Wrote: paths>' && S unchanged F <token>` |
| planner amend (continued or fresh) | `S log F '- [x] 4 Design review — …' '    - D1 …' … && S report-path F 3-plan` |
| phase 5 | `S set F 'Current phase' '5 Tasks' && S refused-base F && S report-path F 5-tasks` (chained onto the previous gate's `log`) |
| phase 6, each story | `S log F '- [x] 6 US<n-1> — … — not verified: …' && S report-path F 6-US<n>` (first story: chained onto the phase 5 `log` and `set 'Current phase' '6 Implement'`, with `refused-base`) |
| phase 7 start | `S set F 'Current phase' '7 Code review' && S log F '- [x] 6 Implement — …' && S refused-base F && S report-path F 7-<lenses>` … `&& S snapshot F` |
| 7e after 7a–7d | `ls -d -- '…' && S unchanged F <token> && S report-path F 7-7e && S snapshot F` |
| review fixes | `S log F '- [x] 7 Code review — …' '    - B1 …' … && S report-path F 7-fixes` |
| review fixes reported | `S log F '- [x] 7 review fixes — <the Fixes line, as reported>; checks: … — not verified: …'` |
| phase 8 | `S set F 'Current phase' 'done (shipping)' && S log F '- [x] 8 Ship' && S report-path F 8-ship` |
| ship error, PR | `S set '<numbered F>' 'Current phase' '8 Ship'`, or `… 'done (PR #N)'` |
| resume | `S phase2-mode F && S refused-base F && S report-path F <key>`, then the one Read of F (Harness, Resume) |

Phase 2 text: the four sub-lines are `    - Stories: …` etc. "On `/feat
resume`, read the latest phase 2 line…" becomes: "`phase2-mode` (resume
call) prints `soft <G> open` when phase 2 was soft and gate `<G>` has not
passed: open that gate with the phase 2 summary from the state file's Log
(the resume read)." *Rebase search* in
setup's `rebase` bullet: `find rebase feat`.

## `/fix` (`SKILL.md`)

Harness values: add *State script* `<this skill's base
dir>/../feat/scripts/state.sh` and *Report keys*; drop *Resume search*,
*Done marker*, *Rebase search*; drop `gh pr list --head …` and `git
for-each-ref …` from *Commands besides the tracker*. *Title* and *input
section*: "`## Report`, the argument as given" becomes "`## Report`, the
argument as given, on one line (a multi-line symptom's lines joined with
spaces)"; setup step 7 says the same where it builds the `init` call.

| Boundary | One Bash command |
| --- | --- |
| setup step 7 | `S init fix F '<title>' '<argument, lines joined with spaces>' 'Branch=fix-<slug>' 'Worktree=…' 'Size=not set' 'Agents=none (every spawn is fresh)' 'Current phase=1 Assess' 'Conventions=…' 'Allowed Spec Kit hooks=…' 'Map=none' 'Issue=<ref or none>' && S log F '- [x] 0 Setup — …' ['- [!] …'] && S report-path F 1-assess` |
| assess gate passes | `S set F Size '<s>' && S set F title '<Title>' && S log F '- [x] 1 Assess — <soft or hard> gate: …'` (then issue creation: `S set F Issue '<owner>/<repo>#<N>' && S log F '…'`) |
| stop at assess | `S set F 'Current phase' 'done (invalid)'` or `'done (not a bug)'` `&& S log F '- [x] 1 Assess — stopped: …'` |
| phase 2 | `S set F 'Current phase' '2 Fix' && S refused-base F && S report-path F 2-fix` (chained onto the last assess-gate call) |
| phase 3 (each time) | `S log F '- [x] 2 Fix — …'` (or the `4 implementer` line) `&& S set F 'Current phase' '3 Test' && S refused-base F && S cycle F && S retry-used F && S report-path F 3-test` |
| phase 4 | `S log F '- [x] 3 Test — verified' && S set F 'Current phase' '4 Code review' && S refused-base F && S report-path F 4-<lenses> && S snapshot F` |
| phase 4 reviewers reported | `ls -d -- '…' && S unchanged F <token>` |
| review fixes | `S log F '- [x] 4 Code review — …' … && S report-path F 4-fixes` |
| phase 5 | `S set F 'Current phase' 'done (shipping)' && S log F '- [x] 5 Ship' && S report-path F 5-ship` |
| back to N | `S log F '- [x] back to N — <reason>' && S set F 'Current phase' '<N> <name>' && …` (that phase's queries and report path) |
| resume | (phase 3) `S cycle F && S retry-used F &&` `S refused-base F && S report-path F <key>` |

Phase 3 text: "**Cycle and retry**, read from the state file's Log, only
the lines after the last `back to` line…" becomes: the cycle passed to the
assessor is `cycle`'s output and the retry is used when `retry-used`
prints `yes` (both from the phase 3 call; the script reads the Log only
since the latest `back to` line, so a re-assess starts a fresh cycle; the
lint pattern forbids the old phrase, so word it this way). The
`failed` rows read "`cycle` printed `first` and `retry-used` `no`". The
gate's note "the shipper reads the shipped verdict from these lines"
becomes "the shipper's `shipped-verdict` reads these lines". Resume's
search bullet: `find fix`; "The test cycle and retry come from the Log"
becomes "from the resume call's `cycle` and `retry-used`".

## `rebase.md` (shared)

- Intro: "whose branch adds one state file matching the *rebase search*" →
  "that `S find rebase <skill> …` accepts".
- Step 2: `S find rebase <skill> '<default>' '<branch>'`: a `skip: <reason>`
  line skips the PR with that reason; else `<state file> <worktree | none>
  <size> <current phase>`.
- Step 3: the worktree from that line (or created as today); `S set F
  'Current phase' 'done (PR #<n>)' && S report-path F move` (the set is
  unconditional, it is idempotent).
- Step 4: the size from step 2's line.
- Step 5: `S log F '- [x] move — … (PR #<n>)' && S report-path F ship`; the
  shipper also gets `State script:`. After its report: `S set '<F at the
  numbered path>' 'Current phase' 'done (PR #<n>)'`; `blocked`: `S log F
  '- [!] move — PR #<n> <its ! line>'`.

## `feat-shipper.agent.md`

- Inputs add `State script: <path>`.
- Ship step 4: the `### Code review` part is `bash '<state script>'
  review-summary '<state file>' 7`'s output, as printed (under the
  heading), `Code review was skipped.` included; the paragraph describing
  the three groups from the Log goes.
- Report path: given one under the artifact dir and renumbering the dir,
  it writes and lists the same `reports/<file>` under the renumbered dir
  (digests.md, The shipper).
- Fix mode: `review-summary … 4`; the shipped verdict is `shipped-verdict`'s
  output (`<verdict> — <decision line>` → the verdict and "shipped on the
  user's decision (logged)" quoting that line); the paragraph on "the Log
  lines after the last `back to` line" goes.
- Rebase step 3: `bash '<state script>' restore-phase '<state file>'`
  replaces "Edit it back to the `-` line".

## Lint (`mise.toml`, task `lint`)

```
! cat .apm/skills/feat/SKILL.md .apm/skills/fix/SKILL.md .apm/skills/feat/references/harness.md .apm/skills/feat/references/rebase.md .apm/agents/feat-shipper.agent.md | tr '\n' ' ' | tr -s ' ' | grep -Eq 'after the last .back to|latest phase 2 line|latest .move — stayed on|latest .7 Code review. line|Edit it back|gh pr list --head|git grep -h|(write|set) .(Current phase|Size|Issue):|anything but the \*state file\*'
```

The files are joined into one line first: today's phrases wrap across
lines (`latest \`move —` / `stayed on\``), and so may the new text. Every
pattern matches today's text (checked on the joined files while planning).
The implementer adjusts a pattern only if the new text needs the phrase
for another meaning, and says so.
