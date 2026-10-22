---
name: feat
description: >
  Builds a feature from a brief (written by /feat-brief) to a reviewed PR:
  specify and plan it with Spec Kit, review the design for security and
  cost, generate and analyze tasks, implement, review the code, then commit
  and open a PR on its own branch/worktree. Each phase runs in a dedicated
  feat-* subagent whose model and effort follow the feature's size; this
  session only coordinates and holds the gates where the user decides. Use
  it as /feat <brief path> or /feat resume, when a brief exists. Without a
  brief, use /feat-brief first. Not for bugfixes or pure refactors.
argument-hint: '<specs/briefs/x.md> | resume'
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

## You are a thin orchestrator

Every call you make re-reads your whole context, for the whole run. So:
- **Never read source code, run checks, or edit anything but
  `feat-state.md`.** Agents do the reading, writing, testing and verifying;
  you get their reports.
- **Don't re-read artifacts.** Read the brief and the state file; quote
  from agent reports at gates. Open spec.md or plan.md only to quote a line
  the user must decide on.
- **Keep reports short in your context**: keep findings and numbers, drop
  narration. Spawn an agent and update the state file in the same turn.
- Changes the user asks for at a gate go back to the agent that owns the
  artifact (specifier: spec.md; planner: plan.md and accepted design
  findings; tasker: tasks.md; implementer: code).

Subagents don't see this conversation. Give each one, in its prompt:
- absolute paths: the worktree, the feature dir, `feat-state.md`;
- the size, the phase, and what to do (its mode, the task IDs it owns, the
  findings to apply);
- the project conventions that matter to it (from step 0), in a few lines;
- for Spec Kit agents: which `.specify/extensions.yml` hooks are allowed;
- for reviewers: the rejected findings, so they don't propose them again.

Spawn each with the Agent tool, `subagent_type` = the agent name, and
**always pass `model` and `effort` from the size table**. If an agent file
is missing, say so at the next gate and run that phase inline with its
skills; don't drop it silently.

A subagent's report is an input, never the end of your turn. A turn ends
only at a hard gate, at the final message, or while agents are running; then
say which are pending and continue when they report.

## Size table

The single source of truth for models and efforts. Agent files carry the
`small` values as defaults. `Loads` is what the agent reads for its job.

| Phase | Agent | Loads | small | normal | big |
|---|---|---|---|---|---|
| 2 Specify | `feat-specifier` | speckit-specify | sonnet · medium | sonnet · high | opus · high |
| 3 Plan | `feat-planner` | speckit-plan | opus · high | opus · high | opus · xhigh |
| 4a Security design | `feat-sec-reviewer` | security-and-hardening | sonnet · medium | opus · high | opus · xhigh |
| 4b Cost design | `feat-cost-reviewer` | — | sonnet · medium | sonnet · high | opus · high |
| 5 Tasks | `feat-tasker` | speckit-tasks, speckit-analyze | sonnet · medium | sonnet · high | sonnet · high |
| 6 Implement | `feat-implementer` | speckit-implement | sonnet · medium | opus · high | opus · high |
| 7a Correctness, spec, standards | `feat-code-reviewer` | code-review (vendored) | sonnet · medium | opus · high | opus · xhigh |
| 7b Security | `feat-code-reviewer` | security-and-hardening | sonnet · medium | opus · high | opus · xhigh |
| 7c Performance | `feat-code-reviewer` | performance-optimization | sonnet · medium | sonnet · high | opus · high |
| 7d Over-engineering | `feat-code-reviewer` | — | sonnet · medium | sonnet · high | sonnet · high |
| 7e Readability | `feat-code-reviewer` | code-simplification | sonnet · medium | sonnet · high | sonnet · high |
| 8 Ship | `feat-shipper` | — | haiku · medium | haiku · medium | haiku · medium |

Phase 7 runs one `feat-code-reviewer` per group of lenses. **small**: two
reviewers, lenses `7a+7b` and `7c+7d+7e`. **normal / big**: one per lens,
`7a`–`7d` in parallel, then `7e` with 7d's cuts. A group runs on the
strongest model and effort among its rows. Applying the picked fixes uses
the phase 6 row.

## Phases and gates

| # | Phase | Runs in | Gate |
|---|-------|---------|------|
| 0 | Setup | you | hard only if a Spec Kit hook would branch or commit |
| 2 | Specify | `feat-specifier` | **hard**: spec.md |
| 3 | Plan | `feat-planner` | soft; **hard** for big |
| 4 | Design review | `feat-sec-reviewer` ∥ `feat-cost-reviewer` | **hard**; soft for small with no real finding |
| 5 | Tasks | `feat-tasker` | **hard** on CRITICAL/HIGH findings or unchecked checklists, and always for big |
| 6 | Implement | `feat-implementer`, one per user story | soft unless checks fail; **hard after each story** for big |
| 7 | Code review | `feat-code-reviewer` ×2 (small) or ×5 | **hard**: user picks the fixes |
| 8 | Ship | `feat-shipper` | none: ends with the PR link |

Phase 1 (the interview and the brief) is `/feat-brief`, in its own context.

**Hard gate**: stop, show the gate summary, wait. Don't start the next phase
in the same turn. Silence or an ambiguous reply is not approval; ask.
**Soft gate**: a short summary, then continue. Anything surprising (a scope
change, a decision the spec didn't call for, a check that can't pass without
a design change) makes it hard.

At any gate the user may say "back to N", "skip N" (logged with the
reason), "size <s>" (logged; later phases use the new column), or "stop"
(the state file lets `/feat resume` pick up).

Gate message shape:

```
## Phase N: <name> — <done | needs your call>
**What I did:** one or two lines (which agents, which model · effort)
**What you should know:** the 3–7 points that matter, one line each
**Your call:** numbered questions, each with my recommendation
**Next:** phase N+1 <name>
```

Link artifacts instead of pasting them; quote only what needs a decision.

## State file

`specs/<NNN-short-name>/feat-state.md`, created in phase 2, updated at every
gate (not at the end). Every agent reads it; `/feat resume` starts from it;
the PR links to it.

```markdown
# /feat state: <feature title>
- Branch: <branch>   Worktree: <path or "none">
- Size: small | normal | big
- Current phase: <N> <name>
- Conventions: <the few lines agents need>
- Allowed Spec Kit hooks: <list or "none">
- Map: <map path and id, if any>

## Brief
<copied from the brief file>

## Log
- [x] 2 Specify — approved; FR-005 reworded (user)
- [x] 4 Design review — accepted D1; rejected D2 (user: "behind the VPN")
- [x] 7 Code review — P1 kept: 410ms → 120ms (`go test -bench Load`); P2 reverted: within noise
- [ ] 8 Ship
```

Log every rejected finding with the user's reason, and every performance
attempt with its numbers, so nothing is proposed or tried twice.

**`/feat resume`**: find the most recent `specs/*/feat-state.md` not marked
done (ask if several), read it, recap in one paragraph, show the current
gate. Resuming in a fresh context is also the cheap way back after a break
of more than an hour, when the cache has expired: say so if the user comes
back late to a long session.

---

## 0. Setup

1. `$ARGUMENTS` must be a brief file (or `resume`). If it is an idea instead,
   stop and point to `/feat-brief "<idea>"`. Read the brief; check it has
   size, short name, behaviour and acceptance. Huge isn't a size here.
2. Read the project's `CLAUDE.md` / `AGENTS.md` and project memory. They
   override this file where they disagree. Keep the few lines agents need
   (commit style, branch rules, where checks live, docs to update).
3. Check `.specify/` exists (else stop: `specify init --here --integration
   claude`) and the `feat-*` agents are installed.
4. Read `.specify/extensions.yml`. Hooks that create branches or commit (the
   git extension's) clash with this workflow owning git: if any are enabled,
   **hard gate** before phase 2; unless the user says otherwise, agents skip
   them. The rest are allowed.

## 2. Specify

1. Create branch `<NNN>-<short-name>` (NNN: next free number in `specs/`),
   preferably in a worktree (EnterWorktree). EnterWorktree picks its own
   branch name: check `git branch --show-current` and `git branch -m` it if
   needed. Enter it before spawning anything: agents start in your
   directory.
2. Spawn `feat-specifier` with the brief. It returns stories, requirements
   and open `[NEEDS CLARIFICATION]` markers with recommended answers.
3. Create the state file (move the brief into it; delete
   `specs/briefs/<short-name>.md`).

**Hard gate**: stories and requirements in a few lines, plus the open
markers. Answers and edits go back to the specifier (amend mode). A spec
with open markers isn't approvable.

## 3. Plan

Spawn `feat-planner`. **Soft gate** (hard for big): approach, what it
touches, new dependencies or services with reasons, constitution check, and
any decision the spec didn't call for (which makes the gate hard).

## 4. Design review

Spawn `feat-sec-reviewer` and `feat-cost-reviewer` in parallel. Merge their
findings into `D1…`, drop duplicates. **Hard gate** for normal and big (the
user accepts or rejects each); for small with nothing above nice-to-have,
report and continue. Accepted findings go to `feat-planner` (amend mode) to
be written into spec.md as requirements and into plan.md.

## 5. Tasks

Spawn `feat-tasker`. It returns task counts per story, the MVP slice, the
stories' task IDs, open findings with proposed fixes, and unchecked
checklist items. **Hard gate** on CRITICAL/HIGH findings (accepted fixes go
back to the tasker, which reruns analyze), on unchecked checklists (ask
whether to proceed: `speckit-implement` would otherwise stop to ask), and
always for big. Otherwise soft. Over ~25 tasks on small or normal: propose
big. Last cheap moment to change direction: raise any hesitation you
noticed.

## 6. Implement

One `feat-implementer` per user story, one after the other in tasks.md
order, each told its task IDs (setup and foundational tasks go with the
first story, polish with the last). Not in parallel: nothing is committed
before phase 8, so a separate worktree would miss the spec and earlier
stories. Pass the checklist answer from phase 5.

**Soft gate** after the last story (hard after each one for big): tasks
done, checks. Failing checks go back to the implementer once with the
failures; if they still fail, or the fix needs a design change, hard gate.
Never accept a weakened test or check.

## 7. Code review

The work is uncommitted, so `git diff <default>...HEAD` is empty. Run (these
are git, not code reading): `git add -N` on the feature's new files, then
`BASE=$(git merge-base <default> HEAD)`; the diff command is
`git diff "$BASE"`. Check it is non-empty.

Spawn the reviewers per the size table, each with the diff command, its
lenses, the accepted `[sec]` design findings (for 7b) and the rejected
findings. Reviewers verify their own findings and list what they dismissed.
Merge into one list: `B…` bugs and spec mismatches, `S…` security, `P…`
performance, `C…` cuts, `R…` readability and `[std]` standards findings
(hard vs judgement call), one line each, bugs and security first. Drop
performance findings on code a cut removes. For big, suggest the user also
runs `/code-review ultra` before merging.

**Hard gate**: the user picks. Spawn `feat-implementer` in fix mode with the
picked findings, in order: bugs and security, cuts, performance (each
measured before and after, kept only if it beats the noise with tests
green), readability (one at a time, existing tests untouched). Log its
report, performance numbers included.

## 8. Ship

Spawn `feat-shipper` with the state file, the conventions, the worktree and
the default branch. It updates the docs the conventions call for, commits
(default: `docs(specs)`, `feat(scope)`, `perf(scope)`, `refactor(scope)`),
pushes and opens the PR, or returns a single `!` command when git is
blocked in the session: give that line to the user as is. Mark the state
file done. Never merge.

Final message: the PR link, the branch/worktree, the two or three things
you'd look at first in review, and for a capability from a map, the next
capability with `/feat-brief <map> <id>`.
