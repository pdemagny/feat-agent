---
name: feat
description: >
  Builds a feature from a brief (written by /brief) to a reviewed PR:
  specify and plan it with Spec Kit, review the design for security, cost
  and fit with the code, generate and analyze tasks, implement, review the code, then commit
  and open a PR on its own branch/worktree. Each phase runs in a dedicated
  feat-* subagent whose model and effort follow the feature's size; this
  session only coordinates and holds the gates where the user decides. Use
  it as /feat followed by a brief path, or /feat resume, when a brief exists. Without a
  brief, use /brief first. Not for bugfixes (use /fix) or pure refactors.
argument-hint: "specs/briefs/name.md | resume"
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
- *Current phase values*: `<N> <name>`; marked done in phase 8.
- *Map line*: `<map path and id, if any>`.
- *Issue ref*: the `Issue:` line (the brief's, then the state file's);
  in the state file, `<the brief's issue, if any>`.
- *Done marker*: marked done.
- *Artifacts the orchestrator reads*: the brief and the state file. Open
  spec.md or plan.md only to quote a line the user must decide on.
- *Commands besides the tracker*: git for the worktree and the diff;
  `ls -d -- '<path>' …` on a report's accepted `Wrote:` paths (harness,
  Reported files).
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
- *Resume search*: the most recent `specs/*/feat-state.md` not marked done;
  section 2 says how a soft phase 2 shows up on resume.

## Size table

The single source of truth for models and efforts: agent files carry none.
`Loads` is what the agent reads
for its job. Row 1 is spawned by `/brief`, which mirrors it.

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

Phase 4 runs one `feat-design-reviewer` per group of lenses. **small**: one
reviewer, lenses `4a+4b+4c`. **medium / large**: one per lens, in parallel.

Phase 7 runs one `feat-code-reviewer` per group of lenses. **small**: two
reviewers, lenses `7a+7b` and `7c+7d+7e`. **medium / large**: one per lens,
`7a`–`7d` in parallel, then `7e` with 7d's cuts. A group runs on the
strongest model and effort among its rows. Applying the picked fixes uses
the phase 6 row.

## Phases and gates

| # | Phase         | Runs in                                 | Gate                                                                                                                                   |
| - | ------------- | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| 0 | Setup         | you                                     | hard only if a Spec Kit hook would branch or commit                                                                                    |
| 2 | Specify       | `feat-specifier`                        | **hard** only on an open marker or blocker; else soft                                                                                  |
| 3 | Plan          | `feat-planner`                          | none for small and medium (merged with 4); **hard** for large                                                                          |
| 4 | Design review | `feat-design-reviewer` ×1 (small) or ×3 | small/medium: one gate for 3+4, hard on a finding, a user-call assumption, a blocker, size increase or checklist item; large: **hard** |
| 5 | Tasks         | `feat-tasker`                           | **hard** on CRITICAL/HIGH findings, a size increase or an unanswered checklist item, and always for large; else soft                   |
| 6 | Implement     | `feat-implementer`, one per user story  | soft unless checks fail; **hard after each story** for large                                                                           |
| 7 | Code review   | `feat-code-reviewer` ×2 (small) or ×5   | **hard**: user picks the fixes                                                                                                         |
| 8 | Ship          | `feat-shipper`                          | none: ends with the PR link                                                                                                            |

Phase 1 (the interview, the brief and its fresh-reader review) is
`/brief`, in its own context.

Every report's `Wrote:` line is checked first (harness, Reported files): a
failed check makes that phase's gate hard, even where the table says soft
or none.

---

## 0. Setup

0. This workflow needs Claude Code: subagents spawned by name with a
   `model` and `effort` per call, and `EnterWorktree`. If you can't do
   that here, stop: say `/feat` runs only in Claude Code, and that the
   brief can be built there. Don't run the phases inline instead.
1. `$ARGUMENTS` must be a brief file (or `resume`). If it is an idea instead,
   stop and point to `/brief "<idea>"`; if it is an issue (`#N` or its
   URL), to `/brief #N`; if it describes a bug, to `/fix "<symptom>"` (or
   `/fix #N`; `/feat-agent:fix` as a plugin). Read the brief; check it has
   size, short name, behaviour and acceptance. Huge isn't a size here.
   Older briefs and state files say "normal" or "big": read them as medium
   and large; older briefs may lack "Today" and "Alternatives rejected".
2. Read the project's `CLAUDE.md` / `AGENTS.md` and project memory. They
   override this file where they disagree. Keep the few lines agents need
   (commit style, branch rules, where checks live, docs to update).
3. Check `.specify/` exists (else stop: `specify init --here --integration
claude`) and the `feat-*` agents are installed (plain or
   `feat-agent:`-prefixed).
4. Read `.specify/extensions.yml`. Hooks that create branches or commit (the
   git extension's) clash with this workflow owning git: if any are enabled,
   **hard gate** before phase 2; unless the user says otherwise, agents skip
   them. The rest are allowed.
5. **Board check** (see Board moves): run `check`. Exit ≠ 0 → stop and
   show its line; else show it and say this run's board moves go to that
   board. Then the building move (phases 2–6; review from phase 7).

## 2. Specify

1. Create branch `<short-name>` and tell the specifier the feature dir is
   `specs/<short-name>/`: no `NNN` yet, because a worktree can't see the
   numbers other in-flight features take. The shipper numbers it in phase 8
   with the spec-number script (free on the fetched `origin/<default>` and
   in every open PR's files), checks it again before pushing, and leaves
   the branch name as is. Prefer a worktree
   (EnterWorktree). EnterWorktree picks its own
   branch name: check `git branch --show-current` and `git branch -m` it if
   needed. Enter it before spawning anything: agents start in your
   directory. If setup found `.feat-agent.yml` and the worktree has none,
   log `- [!] tracker: .feat-agent.yml is not in the worktree; commit and
   push it (board moves skipped)` and flag it at the first gate.
2. Spawn `feat-specifier` with the brief. It returns stories, requirements
   and open `[NEEDS CLARIFICATION]` markers with recommended answers.
3. Create the state file (move the brief into it; delete
   `specs/briefs/<short-name>.md`).

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
Next: phase 3 Plan`, and go on to phase 3. Log it as `2 Specify — soft`
followed by four indented lines: Stories (`US1 <title> (P1); …`),
Requirements (the count and a few notable ones), Spec assumptions
(numbered, each with "(recommended: keep as written)") and Unchecked
checklist items (file: item with a recommendation, or none). Copy them from
the specifier's report, never from spec.md. The next gate shows them, and
its Log line records what became of the spec assumptions and the checklist
answer.

Every phase 2 run, "back to 2" and reruns included, writes its own soft or
hard line, and the latest phase 2 line decides. A phase 2 line with neither
word counts as hard.

On `/feat resume`, read the latest phase 2 line. If it says `soft` and the
gate that carries the summary is not yet `[x]`, open that gate with the
summary from the Log. That gate is phase 4 on small and medium (the
`[x] 3 Plan` line does not close it) and phase 3 on large.

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
lenses. Give it the paths only, never the planner's report: lens 4c is a
fresh reader on purpose. Merge the findings into `D1…`, drop duplicates,
give each a recommendation.

Every gate of this phase starts with the 4c paraphrase, as reported: the user checks it against what they meant. If it
contradicts the brief, the gate is hard.

**Large**: hard gate, the user accepts or rejects each finding. **Small and
medium**: one gate for phases 3 and 4, headed "Plan and design review":
after a soft phase 2 the spec summary first (the `**The spec …**` block
read from the Log: stories, requirements, numbered spec assumptions each
with its recommendation, then the checklist question), then
the paraphrase, approach, what it touches, assumptions, any size increase
(asked first), the findings with their recommendations. It is hard if there
is a finding above nice-to-have, an assumption with `needs user: yes`, a
constitution violation, a blocker, a size increase or an unchecked checklist
item carried from a soft phase 2 (ask now; phase 5 would otherwise stop on
it); otherwise soft, and the recommendations are applied. "ok" accepts all
recommendations. After a soft phase 2, a soft gate's report still carries
the spec summary, and the spec assumptions are logged as kept at their
recommendations.

Accepted findings and the spec changes asked at this gate (an overturned
assumption, a reworded requirement) go to `feat-planner` in one amend pass
(continued after a soft gate, spawned fresh after a hard one), written into
spec.md and plan.md, quoting each change (the user's answer, or the new
wording). A change that rewrites stories is "back to 2". On large, when the
planner amended the plan after the phase 3 gate, say so under "What you
should know" (one line: what the amend changed).

## 5. Tasks

Spawn `feat-tasker`. It returns task counts per story, the MVP slice, the
stories' task IDs, open findings with proposed fixes, and unchecked
checklist items. **Hard gate** on a failed check (harness, Reported files;
the `Tasks:` path must be on `Wrote:`), on CRITICAL/HIGH findings (accepted fixes go
back to the tasker, which reruns analyze), on a size increase, on unchecked
checklist items that the answer already given (phase 2, or the spec
summary) doesn't cover (`speckit-implement` would otherwise stop to ask),
and always for large. Otherwise soft. Check the size against the task count
(small up to ~30, medium ~31–60, large over ~60); a new service,
permissions, exposure or dependency keeps it at least medium. A larger fit
is a size increase (hard gate, see Size changes); a smaller one is applied
and logged. Last cheap moment to change direction: raise any hesitation you
noticed.

## 6. Implement

One `feat-implementer` per user story, one after the other in tasks.md
order, each told its task IDs (setup and foundational tasks go with the
first story, polish with the last). Not in parallel: nothing is committed
before phase 8, so a separate worktree would miss the spec and earlier
stories. Pass the checklist answer from phase 5.

**Soft gate** after the last story (hard after each one for large): tasks
done, checks. Check each implementer's report (harness, Reported files)
before spawning the next one. Failing checks go back to the implementer
once with the failures; if they still fail, or the fix needs a design change, hard gate.
Never accept a weakened test or check.

## 7. Code review

First, the review move (see Board moves). The work is uncommitted, so
`git diff <default>...HEAD` is empty. Run (these are git, not code reading):
`git add -N` on the feature's new files, then
`BASE=$(git merge-base <default> HEAD)`; the diff command is
`git diff "$BASE"`. Check it is non-empty.

Spawn the reviewers per the size table, each with the diff command, its
lenses, the accepted `[sec]` design findings (for 7b) and the rejected
findings. Reviewers verify their own findings and list what they dismissed.
Merge into one list: `B…` bugs and spec mismatches, `S…` security, `P…`
performance, `C…` cuts, `R…` readability and `[std]` standards findings
(hard vs judgement call), one line each, bugs and security first. Drop
performance findings on code a cut removes. For large, suggest the user also
runs `/code-review ultra` before merging.

**Hard gate**: the user picks. Spawn `feat-implementer` in fix mode with the
picked findings, in order: bugs and security, cuts, performance (each
measured before and after, kept only if it beats the noise with tests
green), readability (one at a time, existing tests untouched). Log its
report, performance numbers included.

## 8. Ship

Spawn `feat-shipper` with the state file, the conventions, the worktree, the
default branch, the spec-number script (`<this skill's base
dir>/scripts/spec-number.sh`) and the issue, if any. It numbers the spec
dir, updates the docs the conventions call for, commits
(default: `docs(specs)` then `feat(scope)` with its docs; `perf` and `refactor` only when separable),
pushes and opens the PR, or returns `PR: blocked` with a single `!` line.
When that line is a command for the user to run (`! cd <worktree> && git
…`: git or gh blocked in the session), give it to the user as is and mark
the state file done. When it is an error, not a command (`! spec-number:
error: …` or another hard failure: nothing pushed), show it to the user as
an error, don't mark the state file done and leave `Current phase: 8 Ship`
so `/feat resume` finds the run. Otherwise mark the state file done. Never
merge.

Final message: the PR link, the branch/worktree, the two or three things
you'd look at first in review, and for a capability from a map, the next
capability with `/brief <map> <id>`.
