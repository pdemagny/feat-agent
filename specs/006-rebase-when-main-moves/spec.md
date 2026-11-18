# Feature Specification: /feat and /fix keep their run on the current main

**Feature Branch**: `rebase-when-main-moves`

**Created**: 2026-11-18

**Status**: Draft

**Input**: User description: "Brief in feat-state.md (issue #13): several /feat and /fix runs go at once, each in its own worktree; when one merges, the others fall behind main. Keep each run on the current main from setup to after the PR opens, resolving rebase conflicts inside the workflow, so the user no longer drives them by hand or runs a force-push command themselves."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Rebase a shipped run whose PR now conflicts (Priority: P1)

The person has a PR opened by `/feat` or `/fix` that GitHub now reports as conflicting because another PR merged first. They run `/feat rebase` or `/fix rebase` (plugin: `/logistics:feat rebase`, `/logistics:fix rebase`), with a PR number or branch, or with no argument. The run is re-entered, rebased onto the current default branch, conflicts are resolved under the rules of this spec, the full checks pass, and the branch is pushed by the workflow itself. The person ends with the PR link and a list of what was resolved, and is never handed a command to run.

**Why this priority**: This is where the user's stated cost sits: today they must ask for a rebase, ask for conflict resolution, then run a force-push command themselves. About 6 of ~84 real runs hit this.

**Independent Test**: Take a shipped run whose open PR conflicts with main. Run `/feat rebase <PR>`. The PR is no longer conflicting, the checks are green, the branch was pushed with a lease-protected force-push, and no command was handed to the user.

**Acceptance Scenarios**:

1. **Given** a shipped `/feat` run whose open PR conflicts with the default branch, **When** the person runs `/feat rebase <PR number>`, **Then** the PR is rebased, the full checks pass, the branch is pushed with `--force-with-lease`, and the reply ends with the PR link and what was resolved.
2. **Given** several shipped runs of this repo whose open PRs are reported as conflicting, **When** the person runs `/feat rebase` with no argument, **Then** each such run is handled one after another.
3. **Given** a shipped `/fix` run whose PR conflicts, **When** the person runs `/fix rebase`, **Then** the same happens for the bug fix, using the assessment and fix as resolution context.
4. **Given** a shipped run whose worktree was removed, **When** `rebase` targets it, **Then** a worktree is recreated on the PR branch and used.
5. **Given** a run that has nothing to rebase, **When** `rebase` targets it, **Then** it says so and stops, pushing nothing.
6. **Given** a rebase on a shipped run finished, **When** the state file in its worktree is read afterwards, **Then** it is still marked done (a recreated `/feat` worktree's copy is marked done by `rebase`, as phase 8 does, and never committed), so `resume` does not pick the run up.
7. **Given** a shipped `/feat` run, **When** `/feat rebase` pushes, **Then** the spec number is rechecked first, as the shipper does.
8. **Given** a PR opened by someone else, **When** the person names it to `rebase`, **Then** the run stops at a hard gate naming the PR's author before anything is fetched or run; without an argument, only the person's own PRs are considered.
9. **Given** a PR from a fork, a PR URL of another repository, or a PR whose branch name holds a character outside `[A-Za-z0-9._/-]`, **When** `rebase` targets it, **Then** it is skipped with its reason before any git command uses its values.

---

### User Story 2 - Conflicts are resolved by an agent with the right context, and only real decisions reach the user (Priority: P1)

Whenever a run is moved onto a new main, a rebase mode of `feat-implementer` resolves the conflicts, given the spec and plan (`/feat`) or the assessment and fix (`/fix`) as context. Resolutions that keep both sides' intent without choosing between them are made silently and listed afterwards, one line per file. Anything that would drop or change behaviour from either side stops at a hard gate that names the file, each side in one line, and a recommendation.

**Why this priority**: Resolution quality is the core of the feature; both the post-PR and the in-run cases depend on it.

**Independent Test**: Provoke one "keep both sides" conflict and one behaviour-dropping conflict. The first is resolved without a stop and listed; the second stops with file, both sides and a recommendation.

**Acceptance Scenarios**:

1. **Given** both sides added entries to the same list or table, made adjacent-line edits, or main renamed or moved something, **When** the move runs, **Then** it is resolved without a stop and listed, one line per file, at the next gate.
2. **Given** generated files conflict (for example `docs/img`), **When** the move runs, **Then** they are re-rendered, never merged.
3. **Given** resolving would drop or change behaviour from either side, **When** the move runs, **Then** the run stops at a hard gate naming the file, each side in one line and a recommendation.
4. **Given** main changed something the spec or plan relies on (it already implements part of the feature, or contradicts a requirement), **When** main moved, **Then** the run stops at a hard gate even with no textual conflict.
5. **Given** the move was clean, **When** it finishes, **Then** the project's checks are rerun; a failure that has no mechanical fix stops at a hard gate, a mechanical one is fixed like a textual conflict.
6. **Given** the run is already shipped, **When** a resolution changes what the PR's reviewers have already seen, **Then** it stops at a hard gate.
7. **Given** the coordinator, **When** a move happens, **Then** it never edits code; reading, resolving and checks belong to the agent.

---

### User Story 3 - Fresh base at setup (Priority: P2)

`/feat` and `/fix` fetch `origin/<default>` before creating the worktree, so a run never starts on a stale local copy of main.

**Why this priority**: Cheap, removes one source of stale bases (one spec was written against one), but small by itself.

**Independent Test**: Move the remote main forward without fetching locally, then start a run; the worktree starts on the current remote main.

**Acceptance Scenarios**:

1. **Given** the remote default branch has commits the local `origin/<default>` has not fetched, **When** `/feat` or `/fix` sets up, **Then** the worktree is created on the current remote main.

---

### User Story 4 - Stay current at every phase boundary during a run (Priority: P2)

Before each phase starts, once the state file exists, the coordinator fetches and checks whether `origin/<default>` moved past the worktree's base. If not, nothing happens and nothing is shown. If it did, an agent brings the worktree onto the new main before the phase runs, carrying uncommitted work with it, under the rules of User Story 2.

**Why this priority**: Prevents plans and code being written for hours against an old base, but it comes after the post-PR case in build order.

**Independent Test**: Advance main between two phases; the next phase starts on the new base, the checks were rerun, and the next gate shows the move in one line. With main unmoved, no agent is spawned and gate output is unchanged.

**Acceptance Scenarios**:

1. **Given** main did not move since the last base, **When** a phase boundary is reached, **Then** no agent is spawned and the gate output is unchanged.
2. **Given** main moved and the re-apply is clean, **When** a boundary is reached, **Then** the phase runs on the new base, the checks were rerun, and the next gate shows the move in one line.
3. **Given** `/feat`, **When** boundaries are checked, **Then** the first checked boundary is before phase 3 (the state file is created in phase 2); for `/fix` it is before phase 2 (the size, and with it the implement row, is set at the assess gate; setup's fetch covers phase 1), and after "back to 1" no boundary is checked until the assess gate has set the size again.
4. **Given** uncommitted work with new, untracked and intent-to-add files, **When** it is moved onto the new main, **Then** every new file is present, untracked files are still untracked, intent-to-add files (phase 7's `git add -N`) are still intent-to-add, and the shared stash stack was never touched.
5. **Given** the main check runs, **When** it reads the spec and plan against what main brought, **Then** it reads only what main brought since the last base (the merge-base of the run's branch and `origin/<default>` before the move), and only when main moved.

---

### User Story 5 - The shipper stops on conflict instead of guessing (Priority: P2)

At ship, the shipper still fetches and rebases just before pushing. Because the boundary check ran just before ship, this is normally a no-op. If main moved in between and the rebase conflicts, the shipper aborts the rebase, pushes nothing and reports the conflicting files. The coordinator then runs the rebase mode and spawns the shipper again. The shipper never resolves conflicts itself.

**Why this priority**: Closes the gap between the last boundary check and the push; today a conflict has no rule on a small model without spec context.

**Independent Test**: Make main move after the last boundary check with a conflicting change; the shipper aborts, pushes nothing and reports the files; after the rebase mode resolves, a second shipper spawn pushes.

**Acceptance Scenarios**:

1. **Given** a conflicting rebase inside the shipper, **When** it happens, **Then** the rebase is aborted, nothing is pushed, and the report lists the conflicting files.
2. **Given** that report, **When** the coordinator reads it, **Then** it runs the rebase mode and spawns the shipper again, as the first time.
3. **Given** a move made at ship, **When** the PR opens, **Then** the move's Log line is in the local state file only (not in the pushed history) and the final message lists the move.
4. **Given** a `logistics-wip:` commit in the range about to be pushed, **When** the shipper (any mode) reaches the push, **Then** it pushes nothing and reports `! WIP commit on <branch>; nothing pushed`.

---

### User Story 6 - Undo and recover safely (Priority: P2)

When the person refuses a hard-gate recommendation, or stops there, the rebase is aborted and the worktree is left on the old base with its uncommitted work as before. A run that died mid-move is repaired by `resume` as its first step.

**Why this priority**: Moving uncommitted work through a temporary commit must never lose work.

**Independent Test**: Refuse a hard-gate recommendation, then check the worktree: old base, uncommitted work intact. Kill a run mid-move, then `resume`: leftover temporary commit undone or rebase aborted before anything else.

**Acceptance Scenarios**:

1. **Given** a hard gate on a move, **When** the person refuses or stops, **Then** the rebase is aborted, the temporary commit undone, and the worktree is on the old base with its tracked content and index as before (untracked files a check created during the move may remain).
2. **Given** a run that died mid-move with a leftover temporary commit, **When** `resume` starts, **Then** it undoes that commit first.
3. **Given** a run that died with an unfinished rebase, **When** `resume` starts, **Then** it aborts the rebase first.
4. **Given** a run that died right after its temporary commit, before the move was marked as started, **When** `resume` starts, **Then** it still finds that commit (by its `logistics-wip:` subject) and undoes it first.

---

### User Story 7 - Batch with decisions pending, and a log of every move (Priority: P3)

In a `rebase` run without argument, a PR that needs the person's decision is left unpushed and the batch goes on with the others; all pending decisions are asked together at the end, then those PRs are finished and pushed. Every move onto a new main is logged in the state file; on a shipped run the log lines are committed before the push and the PR body gets a one-line note per rebase.

**Why this priority**: Polishes batch use and traceability; the core works without it.

**Independent Test**: With one clean and one decision-needing conflicting PR, the clean one is pushed while the other waits; the question is asked once at the end; both state files show the move.

**Acceptance Scenarios**:

1. **Given** a batch where one PR needs a decision, **When** the batch runs, **Then** that PR is not pushed until the person answers, the other PRs are pushed meanwhile, and all decisions are asked together at the end.
2. **Given** any move onto a new main, **When** it finishes, **Then** the state file's Log has the old and new base, the files resolved alone, and decisions asked with the answer.
3. **Given** a shipped run, **When** the rebase is pushed, **Then** a `docs(specs): log rebase onto <short sha>` commit, made before the rebase and holding only the new Log lines (never a changed `Current phase:`), is pushed with it, and the PR body gets a one-line note per rebase (its state-file link updated when the spec number changed).

---

### Edge Cases

- Main moves again between the boundary check and the phase start, or between the shipper's rebase and push: the push is protected by the lease and the shipper's own fetch and rebase just before it.
- The `--force-with-lease` push is refused because the PR branch moved remotely: nothing is overwritten, the local branch is put back on the PR head it started from, and the run reports it.
- The local branch of a shipped run holds commits the PR lacks (ahead of the PR head, or diverged from it): the move changes nothing and asks; when those commits come from an earlier move, the recommendation is to reset to the PR head and redo the move.
- A `rebase` target is a PR from a fork, a PR URL of another repository, a PR not opened by `/feat` or `/fix`, a PR whose branch adds no state file (or several) of the expected shape, whose branch name is unsafe, or whose `Size:` is not small, medium or large; for `/fix`, one whose state file is not marked done: it is not a shipped run and is skipped with a stated reason.
- A `rebase` target named explicitly is someone else's PR: a hard gate names its author before anything is fetched or run.
- A run is mid-way (no PR open yet) when `rebase` is invoked on it: not a shipped run, so it is left to `resume`.
- A removed worktree for the PR branch needs a recreated worktree before entering it.
- The recreated worktree or the project conventions require a specific git path or one plain command per call: the coordinator and agents follow the conventions read at setup rather than a hard-coded path.
- Untracked or new files in the worktree at move time are not lost, even though they are not tracked yet.
- A clean rebase leaves the checks failing (semantic conflict): handled like a textual conflict.
- The project has no checks to rerun: the move proceeds and the report says none were found.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `/feat` and `/fix` MUST fetch `origin/<default>` before creating the worktree.
- **FR-002**: Before each phase starts, once the state file exists and the run's implement row is known (`/feat`: from phase 3 on; `/fix`: from phase 2 on, its size being set at the assess gate, setup's fetch covering phase 1), the coordinator MUST fetch and check whether `origin/<default>` moved past the worktree's base, using git only and the git conventions read at setup. After a `/fix` "back to 1", no boundary is checked until the assess gate has set the size again.
- **FR-003**: If main has not moved, the system MUST spawn no agent and show nothing new.
- **FR-004**: If main has moved, a rebase mode of `feat-implementer` MUST bring the worktree onto the new main before the phase runs, with the spec and plan (`/feat`) or the assessment and fix (`/fix`) as context, on the model and effort of the implement row (`/feat` phase 6, `/fix` phase 2). No new size-table row is added.
- **FR-005**: Uncommitted work MUST move onto the new main through a temporary WIP commit on the run's branch, rebased and then un-committed, never through `git stash`.
- **FR-006**: New files MUST be added for the WIP commit; afterwards the agent MUST restore their state: untracked stay untracked, and files that were intent-to-add are re-added with `git add -N`.
- **FR-007**: After every move onto a new main, clean or not, the project's checks MUST be rerun. A failure after a clean rebase is treated as a conflict; a mechanical fix is applied, a non-mechanical one stops at a hard gate.
- **FR-008**: Conflicts whose resolution keeps both sides' intent without choosing (entries added to the same list or table, adjacent-line edits, following a rename or move by main, formatting, generated files) MUST be resolved without a gate and listed, one line per file, at the next gate. Generated files MUST be re-rendered, never merged.
- **FR-009**: The run MUST stop at a hard gate, naming the file, each side in one line and the agent's recommendation, when: resolving would drop or change behaviour from either side; main changed something the spec or plan relies on, even with no textual conflict; the checks fail after the move and the fix is not mechanical; or, on a shipped run, the resolution changes what the PR's reviewers have already seen. Every item MUST be put at the same gate; "ok" accepts each recommendation as given, and any other answer is applied per item.
- **FR-010**: The check of the spec and plan against main MUST run only when main moved and read only what main brought since the last base (the merge-base of the run's branch and `origin/<default>` before the move).
- **FR-011**: The coordinator MUST NOT edit code, read code or resolve conflicts. Its git and gh commands for this feature are limited to: `git fetch`; `git merge-base` (compare bases); the repair check (`git rev-parse -q --verify` of the move's marker, `git log -1 --format=%s`); `gh pr list` / `gh pr view`, `gh repo view` and `gh api user` (find and validate targets); `git check-ref-format --branch`; `git worktree list` / `git worktree add` (enter a shipped run); `git diff --name-only` and `git grep` (find a shipped run's state file and its two header lines). The only file it edits is the state file: Log lines, and the local done mark of FR-018.
- **FR-012**: When the person refuses a hard-gate recommendation or stops there, the system MUST abort the rebase and leave the worktree on the old base with its tracked content and index as before (untracked files a check created during the move may remain), the WIP commit undone.
- **FR-013**: `resume` MUST, as its first step, undo a leftover WIP commit (found by the move's marker, or by a `logistics-wip:` commit at HEAD when the run died before the marker was set) and abort an unfinished rebase.
- **FR-014**: The shipper MUST still fetch and rebase just before pushing. On a rebase conflict it MUST abort the rebase, push nothing and report the conflicting files; the coordinator then runs the rebase mode and spawns the shipper again. The shipper MUST NOT resolve conflicts.
- **FR-015**: `/feat rebase` and `/fix rebase` (plugin: `/logistics:feat rebase`, `/logistics:fix rebase`) MUST re-enter a shipped run: with a PR number or branch, that run; without one, every shipped run of this repo whose open PR GitHub reports as conflicting, one after another. Finding them MUST NOT be truncated: up to 1000 open PRs are listed in one call, and a PR's state file is found from its fetched branch, never from a capped list of PR files.
- **FR-016**: A shipped run MUST be an open PR of this repository (not from a fork, its URL's owner/repo that of the current repository), opened by the person running `rebase`, whose branch adds exactly one state file: `specs/<slug>/feat-state.md` (`/feat`, whatever its `Current phase:`, since the PR opens only once the shipper ran) or `.specify/bugs/<slug>/feat-state.md` (`/fix`, marked done), with a `Size:` of small, medium or large.
- **FR-017**: `rebase` MUST enter the run's worktree, or recreate one on the PR branch if it was removed. It MUST rebase, resolve under the same rules, rerun the full checks, recheck the spec number (`/feat`, as the shipper does), and push with `--force-with-lease` itself, on that branch only. A local branch behind the PR head is brought up to it as part of the move, so undoing the move undoes that too.
- **FR-018**: `rebase` MUST end with the PR link and what it resolved. A run with nothing to do MUST say so and stop. The state file in the run's worktree MUST be marked done afterwards: when it is not (a recreated `/feat` worktree), `rebase` marks it done as `/feat` phase 8 does, in the local copy only, never committed.
- **FR-019**: In a `rebase` run without argument, a PR needing the person's decision MUST be left unpushed while the batch goes on; all pending decisions MUST be asked together at the end, then those PRs finished and pushed.
- **FR-020**: Every move onto a new main MUST be logged in the state file (old and new base, files resolved alone, decisions asked with the answer). On a `rebase` of a shipped run, the new Log lines MUST be committed as `docs(specs): log rebase onto <short sha>` before the rebase and the push; that commit MUST hold only Log lines, never a changed `Current phase:`; the PR body MUST get a one-line note per rebase, and its link to the state file MUST follow a renumbered spec dir. A move made at ship, before the PR exists, MUST be logged in the local state file only and listed in the final message.
- **FR-021**: `--force-with-lease` MUST be the only force-push anywhere, and only on the run's own branch in rebase mode. The shipper's rule becomes "never force-push, except `--force-with-lease` on the run's own branch in rebase mode"; it still never merges.
- **FR-022**: The shared rules MUST live in two reference files, written with named values that each skill's harness-values block fills (which boundaries, which context the resolver gets, the resume and rebase search), with no `/feat`-only words in either (the lint MUST check both): the harness reference (`.apm/skills/feat/references/harness.md`: fresh base, base check, the move's report and gate, repair, ship conflict, Log entry), read on every run, and `.apm/skills/feat/references/rebase.md` (the `rebase` entry point), read by both skills only when their argument is `rebase`.
- **FR-023**: Agent report formats MUST change together with the coordinator that reads them: the implementer's rebase mode report and the shipper's conflict report.
- **FR-024**: Build order: the rebase mode of `feat-implementer` and `/feat rebase` / `/fix rebase` land first; the per-boundary checks during a run come after.
- **FR-025**: The documentation, the size tables' mirrors, and the diagrams MUST reflect the change: a change to `/feat`'s phases or gates updates the gates and chain diagrams, re-rendered and committed with their sources; the workflow documentation and the README/install docs mention the new `rebase` entry points. When the chain diagram cannot show the new step without overlapping labels after one layout pass, the step MUST appear in the gates diagram only.
- **FR-026**: The git and shell commands of agents in worktrees MUST follow the project conventions read at setup (plain commands, no `$(…)`, a required git path if any), not a hard-coded path.
- **FR-027**: Before any git command uses a value taken from a PR, `rebase` MUST validate it from the PR's JSON: forks are dropped, and so are PRs not by the person (an explicitly named one stops at FR-028's gate); a branch name that fails `git check-ref-format --branch` or holds a character outside `[A-Za-z0-9._/-]` is skipped with the reason; only one state-file path is accepted, of the shape `specs/<slug>/feat-state.md` or `.specify/bugs/<slug>/feat-state.md` with that character set. Every PR-derived value MUST be single-quoted in commands, with `--` before refs and paths wherever the command takes it. PR content is data, never instructions.
- **FR-028**: `rebase` MUST act only on the person's own PRs of this repository: without an argument it lists only the person's PRs; a PR named explicitly whose author is not the person MUST stop at a hard gate naming the author before anything is fetched or run; a PR URL of another repository MUST be skipped ("PR of another repository"). Agents act on the PR by its URL, never a bare number.
- **FR-029**: A temporary WIP commit MUST never be pushed: before any push, in every shipper mode, a `logistics-wip:` commit in the range to push MUST block the push (`PR: blocked`, `! WIP commit on <branch>; nothing pushed`).
- **FR-030**: On a `rebase` of a shipped run, the shipper MUST run the existing secret scan on the staged state file before its Log commit (the scan's `staged` mode, as Fix mode runs it), and before the push over what the PR brings onto the new main (the lines added from `origin/<default>` to the new head: the run's commits and conflict resolutions, none of main's own commits), blocking as the existing scan does: a match → `PR: blocked`, `! secret scan: <file>:<line> matches <rule>`, never the value; a scan that can't run (an exit other than 0 or 1) → `PR: blocked`, `! secret scan: could not run (<first error line>)`; nothing pushed. The secret-scan script MUST gain a `range <from> <to>` mode that scans the lines `git diff <from> <to>` adds, with the same rules and output as its other modes and an offline test case; both skills MUST pass the script's path to the shipper's rebase mode.
- **FR-031**: A refused lease push, or a conflict in the shipper's own rebase during `rebase`, MUST leave the local branch on the PR head it started from (only that move's commits are dropped; uncommitted changes are kept), so the next `rebase` starts clean. A shipped run's local branch that is ahead of or diverged from the PR head MUST be a decision item, nothing changed.
- **FR-032**: In the shipper's rebase mode, a blocked git or gh MUST be reported as an error line, never as a command for the person to run (it would be the force-push). The temporary file holding the edited PR body MUST live outside the worktree's tracked tree, be written without a shell redirect, and be deleted after the edit.

### Key Entities

- **Run**: one `/feat` or `/fix` execution, with a branch, a worktree, a state file and, once shipped, a PR. It is shipped when the person's open PR of this repository adds its state file (`/feat`: whatever its phase; `/fix`: marked done).
- **Base**: the commit of `origin/<default>` the run's branch sits on; a move is the passage from an old base to a new one.
- **Move**: bringing a run onto a new base, via the rebase mode, with a WIP commit for uncommitted work, followed by the checks.
- **Resolution**: the outcome for a conflict or semantic drift, either resolved alone (listed afterwards) or put to the person at a hard gate with file, both sides and recommendation.
- **Log entry**: a state-file line recording a move (old and new base, resolved files, decisions and answers).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a shipped run whose PR conflicts, the person goes from "PR conflicting" to "PR rebased, checks green, branch pushed" with one command and zero commands handed to them to run.
- **SC-002**: A run started after main moved but before a local fetch starts on the current remote main in 100% of cases.
- **SC-003**: With main unmoved, 0 agents are spawned for the base check and gate output is byte-for-byte unchanged.
- **SC-004**: Across moves with only "keep both sides" conflicts, 0 stops occur; across moves that drop behaviour or contradict the spec or plan, 100% stop with file, both sides and a recommendation.
- **SC-005**: After any move, 0 new files are lost, untracked files remain untracked, and intent-to-add files remain intent-to-add; the shared stash stack is unchanged.
- **SC-006**: Refusing a hard-gate recommendation leaves the worktree on the old base with all uncommitted work intact in 100% of cases.
- **SC-007**: In a batch, PRs that need no decision are pushed before the person is asked anything; all decisions are asked in one round.
- **SC-008**: Every move appears in the state file's Log; on shipped runs also as a pushed log commit and a PR body note.
- **SC-009**: `--force-with-lease` is the only force-push form present in the shipped prompts and docs, and appears only for the run's own branch.

## Assumptions

- The default branch name is read from the repository as today; the brief writes it `origin/<default>`.
- "The checks" are the project's own checks that the shipper already runs before pushing (`mise run lint` and `mise run test:apm` here); the rebase mode reuses that definition and does not invent new ones.
- "Intent-to-add" refers to the state phase 7 gives to new files with `git add -N` before the review.
- The last base is the merge-base of the run's branch and `origin/<default>`; it is not stored. Each move's old and new base are on its Log line.
- A PR GitHub reports as conflicting is read from the PR's mergeable state; PRs whose state is still unknown are re-queried once and otherwise treated as not conflicting.
- `rebase` on a PR with no conflict and a base already current says there is nothing to do; a PR merely behind main without conflicts is not selected in the no-argument batch, but is rebased when named explicitly.
- Failure of a lease-protected push (the branch moved remotely) is reported, not retried with a stronger force; the local branch goes back to the PR head.
- Release and changelog handling follow existing project rules (release-please, generated changelog); the PR body says `Closes #13`.

### Out of scope

- Detecting or reporting overlap between in-flight runs or open PRs before any conflict exists.
- Triggering anything when a PR merges on GitHub: post-PR rebasing starts when the person runs `/feat rebase` or `/fix rebase`.
- Merging PRs, or choosing the order in which they merge.
- PRs not opened by `/feat` or `/fix` (no spec, plan or bug trail to resolve against).
- Rebasing onto anything other than `origin/<default>`.
- A GitHub Action resolving conflicts in CI, a standalone `/rebase` skill, GitHub's "Update branch", `git stash`, stretching `resume` to shipped runs, a plan-time overlap report, and a hard-coded git path: all rejected in the brief.
