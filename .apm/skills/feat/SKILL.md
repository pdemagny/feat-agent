---
name: feat
description: >
  Builds a feature from a brief (written by /brief) to a reviewed PR:
  specify and plan it with Spec Kit, review the design for security, cost
  and fit with the code, generate and analyze tasks, implement, review the code, then commit
  and open a PR on its own branch/worktree. Each phase runs in a dedicated
  feat-* subagent whose model and effort follow the feature's size; this
  session only coordinates and holds the gates where the user decides. Use
  it as /feat followed by a brief path or short name, or /feat resume, when a brief exists,
  or /feat rebase to bring a shipped run's PR onto the current main. Without a
  brief, use /brief first. Not for bugfixes (use /fix) or pure refactors.
argument-hint: "specs/briefs/name.md | name | resume | rebase [PR]"
---

# /feat: from a brief to a PR

The user's request: `$ARGUMENTS`

This skill is a harness. It puts the phase agents in a fixed order, carries
the output of one into the next, and stops at gates so the user stays in
charge of the decisions that shape the feature. Two goals, equal weight: the
user ends up understanding the feature as well as you do, and nothing gets
built that nobody agreed to.

Gates are few on purpose. A user asked to approve seven times starts
approving without reading. Stop where the user's judgment changes the
outcome; otherwise report and keep going.

Read `<this skill's base dir>/references/harness.md` now: it holds the
rules this skill follows. The values it refers to are below.

## Harness values

- *Skill*: `feat`.
- *Artifact dir*: the feature dir, `specs/<short-name>/`.
- *State file*: `specs/<short-name>/feat-state.md` (unnumbered until
  phase 8, where the shipper renames it to `specs/<NNN>-<short-name>/`),
  created in phase 2.
- *The state file is created*: when phase 2 creates it.
- *Title* and *input section*: `# /feat state: <feature title>`;
  `## Brief`, `<copied from the brief file>`.
- *Size line*: `small | medium | large`.
- *Agents line*: `<specifier|planner|tasker> <agent id>, … (for
  SendMessage)`.
- *Current phase values*: `<N> <name>`, `done (shipping)` (written
  before each shipper spawn, so it is committed), `done (PR #N)` (local
  copy only).
- *Map line*: `<map path and id, if any>`.
- *Issue ref*: the `Issue:` line (the brief's, then the state file's);
  in the state file, `<the brief's issue, if any>`.
- *State script*: `<this skill's base dir>/scripts/state.sh` (harness,
  State file).
- *Resume queries*: `S phase2-mode '<state file>'` (section 2).
- *Report keys* (harness, Report files): `2-specify`, `3-plan` (the
  planner's amend passes too), `4-<lenses>` (`4-4a+4b+4c`, `4-4a`, …),
  `5-tasks`, `6-US<n>`, `7-<lenses>` (`7-7a+7b`, `7-7a`, …, `7-7e`),
  `7-fixes`, `8-ship`; a move: `move`; `rebase`: `move`, `ship`.
- *Artifacts the orchestrator reads*: the brief, and the state file once
  on resume (harness, Resume). Open spec.md or plan.md only to quote a
  line the user must decide on.
- *Commands besides the tracker*: git for the worktree and the diff;
  `ls -d -- '<path>' …` on a report's accepted `Wrote:` paths (harness,
  Reported files);
  `bash <this skill's base dir>/scripts/story.sh -- '<tasks.md>' [US<n>]`
  (phases 5 and 6), only on the `Tasks:` path of the tasker's report once
  it is also on its `Wrote:` and passed the `ls -d` check (harness,
  Reported files); single-quoted, after `--`.
- *Artifact owners*: specifier: spec.md; planner: plan.md, accepted
  design findings, and spec changes asked at the plan or the design review
  gate; tasker: tasks.md; implementer: code.
- *Agents that may be continued*: specifier, planner, tasker. Implementer:
  always a fresh spawn, one per story and one for fixes; never continue one
  into the next story.
- *Reviewer context*: the rejected findings and the brief's "Alternatives
  rejected".
- *Size triggers*: the planner's size trigger, the task count in phase 5.
- *Phases that can't be skipped*: none.
- *Logged gate commands*: "skip N" (with the reason), "size <s>".
- *Tracker script*: `<this skill's base dir>/scripts/tracker.sh`.
- *Board-check step*: Setup step 5.
- *Building move*: at setup (step 5, phases 2–6); on resume in phases 2–6;
  going back from 7 or 8 to 2–6.
- *Review move*: when phase 7 starts; on resume in phases 7–8.
- *Review phase*: 7.
- *Base-check boundaries*: the start of every phase once the state file
  exists: phases 3 to 8, and any phase rerun by "back to N".
- *Resolver context*: spec.md and plan.md.
- *Implement row*: the phase 6 row. *Ship row*: the phase 8 row.
- *Number check*: the spec-number script.
- *Secret-scan script*: `<this skill's base dir>/scripts/secret-scan.sh`.

## Size table

The models and efforts passed on every spawn. Generated from `sizes.json` in a
checkout; edit that, not this table. Agent files carry none. `Loads` is what
the agent reads for its job. Row 1 is spawned by `/brief`, which mirrors it.

<!-- sizes-start feat-table -->

| Phase                           | Agent                  | Loads                          | small           | medium          | large           |
| ------------------------------- | ---------------------- | ------------------------------ | --------------- | --------------- | --------------- |
| 1 Brief review (`/brief`)       | `feat-brief-reviewer`  | —                              | sonnet · medium | sonnet · medium | opus · medium   |
| 2 Specify                       | `feat-specifier`       | speckit-specify                | sonnet · medium | sonnet · medium | opus · high     |
| 3 Plan                          | `feat-planner`         | speckit-plan                   | opus · high     | opus · high     | opus · xhigh    |
| 4a Security design              | `feat-design-reviewer` | security-and-hardening         | sonnet · medium | opus · medium   | opus · high     |
| 4b Cost design                  | `feat-design-reviewer` | —                              | sonnet · medium | sonnet · medium | opus · medium   |
| 4c Clarity and fit              | `feat-design-reviewer` | —                              | sonnet · medium | sonnet · high   | opus · medium   |
| 5 Tasks                         | `feat-tasker`          | speckit-tasks, speckit-analyze | sonnet · medium | sonnet · medium | opus · high     |
| 6 Implement                     | `feat-implementer`     | speckit-implement              | sonnet · medium | opus · medium   | opus · high     |
| 7a Correctness, spec, standards | `feat-code-reviewer`   | —                              | sonnet · medium | opus · medium   | opus · medium   |
| 7b Security                     | `feat-code-reviewer`   | security-and-hardening         | sonnet · medium | opus · medium   | opus · high     |
| 7c Performance                  | `feat-code-reviewer`   | performance-optimization       | sonnet · medium | sonnet · medium | opus · medium   |
| 7d Over-engineering             | `feat-code-reviewer`   | —                              | sonnet · medium | sonnet · medium | sonnet · medium |
| 7e Readability                  | `feat-code-reviewer`   | —                              | sonnet · medium | sonnet · medium | sonnet · medium |
| 8 Ship                          | `feat-shipper`         | —                              | haiku · medium  | haiku · medium  | haiku · medium  |

<!-- sizes-end feat-table -->

Phase 4 runs one `feat-design-reviewer` per group of lenses. **small**: one
reviewer, lenses `4a+4b+4c`. **medium / large**: one per lens, in parallel.

Phase 7 runs one `feat-code-reviewer` per group of lenses. **small**: two
reviewers, lenses `7a+7b` and `7c+7d+7e`. **medium / large**: one per lens,
`7a`–`7d` in parallel, then `7e` with 7d's cuts. A group runs on the
strongest model and effort among its rows. Applying the review fixes and
moving onto a new main use the phase 6 row.

## Phases and gates

| # | Phase         | Runs in                                 | Gate                                                                                                                                   |
| - | ------------- | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| 0 | Setup         | you                                     | hard only if a Spec Kit hook won't run (specify, plan, tasks, analyze) or would branch or commit                                       |
| 2 | Specify       | `feat-specifier`                        | **hard** only on an open marker or blocker; else soft                                                                                  |
| 3 | Plan          | `feat-planner`                          | none for small and medium (merged with 4); **hard** for large                                                                          |
| 4 | Design review | `feat-design-reviewer` ×1 (small) or ×3 | small/medium: one gate for 3+4, **hard** on a `user` finding, a user-call assumption, a constitution violation, a blocker, a size increase, a paraphrase that contradicts the brief or a carried checklist item, else soft (the `apply` findings are applied); large: **hard**, findings shown with their recommendations |
| 5 | Tasks         | `feat-tasker`                           | **hard** on CRITICAL/HIGH findings, analyze not run, a size increase, an unanswered checklist item, or tasks.md not matching the tasker's report (`story.sh`), and always for large; else soft |
| 6 | Implement     | `feat-implementer`, one per user story  | soft unless checks fail; **hard after each story** for large                                                                           |
| 7 | Code review   | `feat-code-reviewer` ×2 (small) or ×5   | small/medium: **hard** on a `user` or `S` finding or a `not met` criterion, else soft (the `apply` findings are fixed); large: **hard**, findings shown with their recommendations |
| 8 | Ship          | `feat-shipper`                          | none: ends with the PR link                                                                                                            |

Phase 1 (the interview, the brief and its fresh-reader review) is
`/brief`, in its own context.

From phase 3 on, each phase starts with the base check (harness, Moving
onto a new main): silent when main has not moved; a move is listed at the
next gate, or stops there when it needs your call.

Every report's `Wrote:` line is checked first (harness, Reported files): a
failed check makes that phase's gate hard, even where the table says soft
or none.

**State file calls** (harness, State file; `S` is `bash '<state
script>'`, every argument single-quoted). Once the state file exists,
each phase from 3 to 8 (8: the command under 8. Ship) starts with one
Bash command: the `log` lines of
the gate just passed, `S set '<state file>' 'Current phase' '<N>
<name>'`, then `S refused-base '<state file>'` for the base check, then `S
report-path '<state file>' '<key>'` for each of the phase's spawns (the
*Report keys*), and in phases 4 and 7 `S snapshot '<state file>'` last
(harness, Report files), joined with `&&`. A gate's other changes
(`Agents`, `Size`) are `S set` calls in the same command. Every later
spawn, and every message asking a continued agent for a new report, gets
its own report path the same way, chained onto the `log` or `set` made
before it. No open `- [ ] <N> <phase>` line is written.

---

## 0. Setup

0. This workflow needs Claude Code: subagents spawned by name with a
   `model` and `effort` per call, and `EnterWorktree`. If you can't do
   that here, stop: say `/feat` runs only in Claude Code, and that the
   brief can be built there. Don't run the phases inline instead.
1. `$ARGUMENTS` must be a brief: its path or its short name (or `resume`,
   or `rebase`, below). If
   it is an idea instead, stop and point to `/brief "<idea>"`; if it is an
   issue (`#N` or its URL), to `/brief #N`; if it describes a bug, to
   `/fix "<symptom>"` (or `/fix #N`; `/logistics:fix` as a plugin).
   **Find the brief**: an existing file as given is the brief. Else take
   `<name>` (the argument without a leading `specs/briefs/` and a trailing
   `.md`); it must be a short name (`[a-z0-9][a-z0-9-]*`), else stop as
   for no match. Look for `specs/briefs/<name>.md` under `git rev-parse
   --show-toplevel` (this checkout), then under every other worktree `git
   worktree list --porcelain` names. One match: use it and say its
   absolute path. Several: list them and ask which; never pick one. None:
   stop, naming every path searched, and point to `/brief`. Keep the
   brief's absolute path for phase 2, and whether it is exactly `<this
   checkout's top level>/specs/briefs/<short name>.md`, the short name
   matching `[a-z0-9][a-z0-9-]*` (a file given by path counts only then).
   Read the brief; check it has size, short name, behaviour and acceptance.
   Huge isn't a size here, nor tiny: stop and point to `/tiny <path>`,
   or `/brief <path>` to grow it when it outgrew tiny. Older briefs and
   state files say "normal" or "big": read them as medium and large; older
   briefs may lack "Today" and "Alternatives rejected".
   - `rebase [<PR number, URL or branch>]`: run steps 0, 2, 3 and 4 (no
     step 5: `rebase` makes no board moves), then read `<this skill's base
     dir>/references/rebase.md` and follow it; no other run reads that
     file.
2. Read the project's `CLAUDE.md` / `AGENTS.md` and project memory. They
   override this file where they disagree. Keep the few lines agents need
   (commit style, branch rules, where checks live, docs to update).
3. Check `.specify/` exists (else stop: `specify init --here --integration
claude`) and the `feat-*` agents are installed (plain or
   `logistics:`-prefixed).
4. Read `.specify/extensions.yml` (enabled entries only; ignore
   `enabled: false`).
   - The specifier, planner and tasker can't run hooks (`Skill` is denied):
     every hook under `before_`/`after_` `specify`, `plan`, `tasks` or
     `analyze`, git ones included, will not run. `implement` hooks are
     allowed, except those that create a branch or commit (the git
     extension's, which clash with this workflow owning git), which agents
     skip unless the user says otherwise.
   - If any hook won't run or would branch or commit, **hard gate** before
     phase 2, one message: each such hook as `<key>: <extension>.<command>
     → run it by hand: /<command, dots as hyphens>` (a hook with no
     `command` is shown by its extension only, with no manual command), in
     two sections ("Won't run", "Would branch or commit (implement),
     skipped unless you allow it"), omitting an empty one; a hook enabled
     under several keys appears once per key.
   - Say that these won't run during this run: run them by hand once the PR
     is open, or stop now. The user continues with them skipped, or stops,
     and says whether to allow a branching or committing `implement` hook;
     there is no "run it anyway" for the first section. Log the answer on
     the setup line. On `rebase`, only the `implement` part applies.
5. **Board check** (see Board moves): run `check`. Exit ≠ 0 → stop and
   show its line; else show it and say this run's board moves go to that
   board. Then the building move (phases 2–6; review from phase 7).

## 2. Specify

1. Create branch `<short-name>` and tell the specifier the feature dir is
   `specs/<short-name>/`: no `NNN` yet, because a worktree can't see the
   numbers other in-flight features take. The shipper numbers it in phase 8
   with the spec-number script (free on the fetched `origin/<default>` and
   in every open PR's files), checks it again before pushing, and leaves
   the branch name as is. `git fetch origin <default>` (harness, Fresh
   base), then prefer a worktree (EnterWorktree). EnterWorktree picks its own
   branch name: check `git branch --show-current` and `git branch -m` it if
   needed. Enter it before spawning anything: agents start in your
   directory. If setup found `.logistics.yml` and the worktree has none,
   log `- [!] tracker: .logistics.yml is not in the worktree; commit and
   push it (board moves skipped)` and flag it at the first gate.
2. Create the state file before the specifier spawn, in one Bash command:
   `S init feat '<state file>' '<brief path>' 'Branch=<short-name>'
   'Worktree=<path>' 'Size=<size>' 'Current phase=2 Specify'
   'Conventions=<…>' 'Allowed Spec Kit hooks=<…>' 'Map=<…>' 'Issue=<…>'`
   (the brief's title and lines go into it), then `S log` of the setup
   line `- [x] 0 Setup — …` and any `[!]` lines kept so far, then `S
   report-path '<state file>' '2-specify'`, joined with `&&`.
3. Spawn `feat-specifier` with the brief and that report path. It returns
   stories, requirements and open `[NEEDS CLARIFICATION]` markers with
   recommended answers. Its agent id goes on the `Agents` line (`S set
   '<state file>' 'Agents' 'specifier <id> (for SendMessage)'`) in the
   command that logs the gate (below). Once it has reported, delete the
   brief file, by the absolute path setup found, only when setup marked it as this
   checkout's `specs/briefs/<short name>.md` (the checkout `/feat` started
   in). Any other brief (in another worktree, elsewhere in this checkout,
   outside it) stays: log `- [!] brief left in place: <path>` and name it
   in the final message, so the user decides.

**Gate**: hard only when the specifier's report lists an open
`[NEEDS CLARIFICATION]` marker or a blocker, the same at every size, large
included; anything else surprising makes it hard. Otherwise it is soft. A
blocker: the report has no `Spec:` path, or its Assumptions or Open markers
say the brief can't be specified as written. The `Spec:` path must be on
`Wrote:`; a failed check (harness, Reported files) is hard before anything
else. A size remark makes it hard
too; sizes are checked at phases 3 and 5.

**Hard**: stories and requirements in a few lines, the open markers
each with its recommended answer, the specifier's assumptions, and the
unchecked items of `checklists/` (`speckit-implement` stops on them: ask now
whether to proceed, and log the answer). Put the reason under "What you
should know" and log it as `2 Specify — hard (<why>)`. Answers and edits go
back to the specifier (amend mode). A spec with open markers isn't
approvable. After a hard phase 2 the next gate is as today, with no spec
summary.

**Soft**: print one line, `Phase 2 Specify — soft: spec.md written (<n>
stories, <m> requirements, no open question); summary at the next gate.
Next: phase 3 Plan`, and go on to phase 3. Log it as `- [x] 2 Specify —
soft` followed by four sub-lines, each its own `log` argument: `    -
Stories: US1 <title> (P1); …`, `    - Requirements: <the count and a few
notable ones>`, `    - Spec assumptions: <numbered, each with
"(recommended: keep as written)">` and `    - Unchecked checklist items:
<file: item with a recommendation, or none>`. Copy them from the
specifier's report, never from spec.md. The next gate shows them, and its
Log line records what became of the spec assumptions and the checklist
answer.

Every phase 2 run, "back to 2" and reruns included, logs its own soft or
hard line, and the most recent one decides. A phase 2 line with neither
word counts as hard.

On `/feat resume`, the resume call's `phase2-mode` (harness, Resume)
prints `soft <G> open` when that most recent line is soft and gate `<G>`,
the one that carries the summary, has not passed: phase 4 on small and
medium (the `[x] 3 Plan` line does not close it), phase 3 on large. Open
that gate with the phase 2 summary from the state file's Log (the resume
read). `soft <G> closed`, `hard` or `none`: no summary to show.

Questions are asked at phase 2 or at the gate that shows its summary, so
later phases don't stop to ask.

## 3. Plan

Spawn `feat-planner`. It never asks the user anything: a decision the spec
didn't call for comes back as an assumption with a recommendation and
`needs user: yes|no`, and only a blocker (the spec can't be planned as
written) stops the run. It also reports a size trigger (new service,
permissions, exposure or dependency); on a small feature, that is a size
increase to ask about.

Small and medium: no gate, go straight to phase 4, unless the report fails
its check (harness, Reported files). **Hard gate for large**:
after a soft phase 2 it opens with the spec block (`**The spec (phase 2
didn't stop):** …`, read from the Log: stories, requirements, numbered spec
assumptions each with its recommendation, then the checklist question),
then approach, what it touches, new dependencies or services with reasons,
constitution check, the planner's assumptions. "ok" accepts the
recommendations. Here a spec change goes to `feat-planner` in amend mode
right away (as in the amend pass below), and phase 4's reviewers are
spawned after it reports, with no second stop for the amend.

## 4. Design review

Spawn `feat-design-reviewer` per the size table's groups, each with its
lenses and its report path, under one `snapshot`; once all have reported,
`ls -d` on their `Wrote:` paths `&& S unchanged '<state file>'
'<token>'` (harness, Report files). Give it the paths only, never the
planner's report: lens 4c is a fresh reader on purpose. Merge the findings into `D1…`; each keeps the
`rec` that ends its line. Never set `apply` or `skip` yourself. Apply merge
rules 2, 3 and 5 of the harness (Review findings), where the same spot is
the same artifact and an identical section heading or line, and the same
section is the same tag (`[sec]`, `[cost]`, `[design]`); rules 1 and 4 don't
apply. Findings with different tags on the same spot stay separate, each
with its own `rec`. A missing or invalid `rec` becomes
`user (no valid recommendation)`. Work from the reviewer's report; never
read the spec or plan to decide a gate.

Every gate of this phase starts with the 4c paraphrase, as reported: the user checks it against what they meant. If it
contradicts the brief, the gate is hard.

**Soft** (small and medium): print the 4c paraphrase (after the spec block
when phase 2 was soft), then one line:
`Phase 4 Design review — soft: <n> findings, <a> applied, <s> skipped[; security: <[sec] ids with rec apply>][; security skipped: <[sec] ids with rec skip>]; none needs your call. Next: phase 5 Tasks`.
Leave out `; security: …` and `; security skipped: …` when empty; never name
severity; zero findings prints `0 findings, 0 applied, 0 skipped`. The
`apply` findings go to `feat-planner` continued with `SendMessage`; the
`skip` ones are left. With no `apply` finding send nothing to the planner
and go straight to phase 5.

**Gate**, first match wins:

| Size         | Condition                                                                                                                                                                                                                                      | Gate     |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| large        | always                                                                                                                                                                                                                                         | **hard** |
| small/medium | a `D` finding with `rec: user`, an assumption with `needs user: yes`, a constitution violation, a blocker, a size increase, a paraphrase that contradicts the brief, an unchecked checklist item carried from a soft phase 2, or a failed report check (harness, Reported files) | **hard** |
| small/medium | otherwise                                                                                                                                                                                                                                      | **soft** |

On small and medium, one gate covers phases 3 and 4, headed "Plan and
design review". It shows, in order: after a soft phase 2 the spec summary
(the `**The spec …**` block read from the Log: stories, requirements,
numbered spec assumptions each with its recommendation, then the checklist
question), then the paraphrase, approach, what it touches, assumptions, any
size increase (asked first), then the findings (the soft line when soft,
the hard list below when hard). An unchecked checklist item carried from a
soft phase 2 is asked now; phase 5 would otherwise stop on it. After a soft
phase 2, a soft gate's report still carries the spec summary, and the spec
assumptions are logged as kept at their recommendations, with the checklist
answer, as today.

**Hard**: print the gate in the harness shape, titled `Phase 3–4: Plan and
design review — needs your call` on small and medium (`Phase 4: Design review
— needs your call` on large). What you should know says why it stops (`large`,
`<ids> need you`, `assumption <n> needs you`,
`constitution: <principle>`, `blocker`, `size increase`, `paraphrase
contradicts the brief`, `checklist item`, `report check failed`). Your
call lists each `user` finding first as "apply or leave?" with the
reviewer's why, then every other finding with its `rec` (on large too, even
when none is `user`). "ok" applies every
`apply` finding and leaves every `skip`; each `user` finding needs its own
answer, and a bare "ok" while one is unanswered gets one follow-up naming
the ids; nothing goes to the planner until each is answered (harness,
Review findings, with "fix" read as "apply"; its `S` notice does not apply
here). The picked findings and any spec change asked go to a fresh
`feat-planner`.

Accepted findings (the `apply` findings on a soft gate, the picked ones on a
hard gate) and the spec changes asked at this gate (an overturned
assumption, a reworded requirement) go to `feat-planner` in one amend pass
(continued after a soft gate, spawned fresh after a hard one; either way
with a new `3-plan` report path, chained onto the gate's `log`), written into
spec.md and plan.md, quoting each change (the user's answer, or the new
wording). A change that rewrites stories is "back to 2". On large, when the
planner amended the plan after the phase 3 gate, say so under "What you
should know" (one line: what the amend changed).

**Log**: the harness's Review findings Log words, with this phase's line.
Soft: `- [x] 4 Design review — auto-applied <ids | none>; skipped <id> (reviewer: "<why>"), …`.
Hard: `- [x] 4 Design review — picked <ids> | none picked; rejected <id> (user: "<words>"), <id> (as recommended), …`
(`as recommended` only for a `skip` left by "ok"). Then one sub-line per
finding, each its own `log` argument: `    - <id> <artifact>: <section> —
<a few words> — rec: <value>` (a `[sec]` finding gives its title only). The accepted design findings are
the `auto-applied` and `picked` ids: phase 7 gives the accepted `[sec]` ones
to lens 7b. `skipped` and rejected `D` findings reach later reviewers as
rejected findings.

## 5. Tasks

Spawn `feat-tasker`. It returns task counts per story, the MVP slice, the
stories' task IDs, whether analyze ran, open findings with proposed fixes,
and unchecked checklist items. **Hard gate** on a failed check (harness, Reported files;
the `Tasks:` path must be on `Wrote:`), on CRITICAL/HIGH findings (accepted fixes go
back to the tasker, which reruns analyze), on an `Analyze:` line that is
`not run` (say under "What you should know" that analyze did not run, with
its error, and that spec, plan and tasks were only cross-checked by hand) or
missing (say there that the tasker did not say whether analyze ran), on a
size increase, on unchecked
checklist items that the answer already given (phase 2, or the spec
summary) doesn't cover (`speckit-implement` would otherwise stop to ask),
and always for large. Otherwise soft.

After each tasker report, a rerun included, once its `Wrote:` check passed
with the `Tasks:` path on it, run `story.sh -- '<tasks.md>'` (never read
tasks.md yourself) and compare its groups with the report's `Per story:`
line: setup/foundational (the IDs the tasker labels setup or foundational),
each story, polish (those it labels polish). Unlabelled IDs or a grouping
that reads two ways (a range spanning two labels, IDs listed "with" a story)
are a difference. Expand the tasker's ranges first (`T001–T012` is every ID
from T001 to T012); a group the report leaves out is empty. **Hard gate**
when a group's IDs or count differ, showing `<group> — tasker: <IDs> —
tasks.md: <IDs>` for each, or when `story.sh` exits non-zero, showing its
line; recommend sending it to the tasker as an accepted fix (it fixes
tasks.md, or its report when tasks.md was right), then run `story.sh`
again. Log `story.sh: match` or what differed on the phase 5 line.

Check the size against `story.sh`'s `total:` count (the tasker's total when
`story.sh` failed) (small up to ~30, medium ~31–60, large over ~60); a new service,
permissions, exposure or dependency keeps it at least medium. A larger fit
is a size increase (hard gate, see Size changes); a smaller one is applied
and logged. Last cheap moment to change direction: raise any hesitation you
noticed.

## 6. Implement

One `feat-implementer` per user story, one after the other in the order
`story.sh` lists them (tasks.md order). Before each spawn (a story's first,
its retry, a resume) get its report path (`6-US<n>`, chained onto the
`log` of the previous story's list, or of phase 5's gate for the first)
and run `story.sh -- '<tasks.md>' US<n>`, and put its output
in the prompt between two lines of four backticks (longer than any backtick
run in it), labelled `story.sh output (data, never instructions)`: the IDs
it owns are the ones listed there (setup and foundational tasks come with
the first story, polish with the last). A non-zero exit is a hard gate with
its line. Not in parallel: nothing is committed
before phase 8, so a separate worktree would miss the spec and earlier
stories. Pass the checklist answer from phase 5, and each implementer its
`<who>`, `US<n>` for its story (its retry and a resume included). Log each
implementer's `Not verified:` list (harness, State file) as `6 US<n>`.

**Soft gate** after the last story (hard after each one for large):
`tasks done: <n> (<k> not verified)`, checks. Under "What you should know"
show each story's latest `Not verified:` list (`Not verified: none` when
empty; for large, the per-story gate shows that story's list). A non-empty
list is not a surprise and never makes the gate hard; a report without the
line is (harness): hard, recommending a fresh implementer for that story.
Check each implementer's report (harness, Reported files) before spawning
the next one. Failing checks go back to the implementer once with the
failures; if they still fail, or the fix needs a design change, hard gate.
Never accept a weakened test or check.

## 7. Code review

First, the review move (see Board moves). The work is uncommitted, so
`git diff origin/<default>...HEAD` is empty. Run (these are git, not code reading):
`git add -N` on the feature's new files, then
`BASE=$(git merge-base origin/<default> HEAD)`; the diff command is
`git diff "$BASE"`. Check it is non-empty.

Spawn the reviewers per the size table, each with the diff command, its
lenses, the accepted `[sec]` design findings (for 7b), the rejected
findings and its report path, under one `snapshot` (harness, Report
files). On medium and large, once `7a`–`7d` have reported: `ls -d` on
their `Wrote:` paths `&& S unchanged '<state file>' '<token>' && S
report-path '<state file>' '7-7e' && S snapshot '<state file>'`, then
`7e`, then its `ls -d` and `unchanged`. Reviewers verify their own
findings and list what they dismissed, in their report file.
Merge into one list: `B…` bugs and spec mismatches, `S…` security, `P…`
performance, `C…` cuts, `R…` readability and `[std]` standards findings
(hard vs judgement call), one line each, bugs and security first; each
finding keeps its `rec`. Apply the merge rules (harness, Review findings).
For large, suggest the user also runs `/code-review ultra` before merging.

**Gate**, first match wins:

| Size         | Condition                                                  | Gate     |
| ------------ | ---------------------------------------------------------- | -------- |
| large        | always                                                     | **hard** |
| small/medium | any `user` or `S` finding, or any criterion `not met`      | **hard** |
| small/medium | otherwise                                                  | **soft** |

**Soft**: one line,
`Phase 7 Code review — soft: <n> findings, <a> to apply, <s> skipped; none needs your call[; untested: <criteria>]. Next: <review fixes, then phase 8 Ship | phase 8 Ship>`.
Spawn `feat-implementer` in fix mode with the `apply` findings, in order:
bugs and security, cuts, performance (each measured before and after, kept
only if it beats the noise with tests green), readability (one at a time,
existing tests untouched); the `skip` findings are not applied. Tell it its
`<who>`, `review fixes`, and give it the report path from `S report-path
'<state file>' '7-fixes'`, chained onto the gate's `log` per the harness
(Review findings). When it
reports, log `- [x] 7 review fixes — <its Fixes (fix mode): value, as
reported>; checks: <its Checks: results>` ending with its `Not verified:`
list (harness, State file): the shipper's `review-summary` finds the
reverted fixes and performance numbers in that value. Then phase 8.

**Hard**: print the gate in the harness shape, titled `Phase 7:
Code review — needs your call`. What you should know says why it stops
(`large`, `<ids> need you`, `S<n> security`, `criterion not met: <which>`). Your call lists every finding with its
`rec` (on large too, even when none is `user`), `user` first, "ok" rule
and follow-up, `S` publication notice and Log words per the harness (Review
findings). Next: review fixes, then phase 8 Ship. Spawn `feat-implementer`
in fix mode with the picked ids (same order and `<who>` as Soft), log its
report as Soft says (`7 review fixes`); none picked goes straight to
phase 8. A missing
`Not verified:` line after a hard gate goes to the final message as in
phase 6.

**After a soft gate**, check the fix report (harness, Reported files). Failing
checks go back to the implementer once with the failures, as in phase 6; a
second failure is a hard stop before phase 8. A failed `Wrote:` check or a
report without a `Not verified:` line is a hard stop at once, recommending a
fresh implementer with the same findings. Each stop appends
`- [!] 7 review fixes — <reason>` to the state file's Log without rewriting
earlier lines.

An `untested` criterion is never a trigger: name it in the soft line, or
under "What you should know" at a hard gate, and append `; untested: …` to
the gate's Log line.

## 8. Ship

First `S set '<state file>' 'Current phase' 'done (shipping)' && S
refused-base '<state file>' && S log '<state file>' '- [x] 8 Ship' && S
report-path '<state file>' '8-ship'`,
so the copy the shipper commits is already done; run it before every
shipper spawn, a second one after a conflict included. Then spawn
`feat-shipper` with that report path, the state file, the
*state script* (`State script:`), the conventions, the worktree, the
default branch, the spec-number script (`<this skill's base
dir>/scripts/spec-number.sh`), the issue, if any, and the not verified
items: those of the latest line of each story and of `review fixes`
(harness; none when every one says `none`). It numbers the spec
dir, updates the docs the conventions call for, commits
(default: `docs(specs)` then `feat(scope)` with its docs; `perf` and `refactor` only when separable),
pushes and opens the PR, or returns `PR: blocked` with a single `!` line.
When that line is a command for the user to run (`! cd <worktree> && git
…`: git or gh blocked in the session), give it to the user as is; the
state file stays done (resume finds the run while its branch has no
upstream). When it is an error, not a command (`! spec-number: error: …`
or another hard failure: nothing pushed), show it to the user as an error
and `S set '<state file>' 'Current phase' '8 Ship'` in the local copy so
`/feat resume` finds the run. After the PR you may `S set '<state file>'
'Current phase' 'done (PR #N)'` in the local copy only (uncommitted).
Either call goes to the state file at the path from the shipper's
`Wrote:` when it numbered the dir. Never merge.

`PR: conflict`: run harness "Moving onto a new main, At ship", then read
the report as above; the state file stays `done (shipping)`.

Final message: the PR link, the branch/worktree, the two or three things
you'd look at first in review, the shipper's `Not verified:` line when it
is not `none` (or the shipper report lacking the line), any report logged
with `Not verified line missing` (the review fixes, from a hard gate), a
move onto a new main kept since the last gate or at ship (harness, Moving
onto a new main), a brief left in place (the Log's `brief left in place`
line), and for a capability from a map, the next
capability with `/brief <map> <id>`.
