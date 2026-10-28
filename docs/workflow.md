# The workflow in detail

What runs at each phase, on which model, for which size, and where it stops
for you. The size table in [`.apm/skills/feat/SKILL.md`](../.apm/skills/feat/SKILL.md)
is authoritative; this page mirrors it with explanations.

## Roles

- **`/feat-brief`**: phase 1, in its own context. Interviews you, proposes
  the size, writes the brief (or a capability map for huge ideas).
- **Coordinator**: the session running `/feat`, started from a clean
  context. It holds every gate and edits only `feat-state.md`; it never
  reads code, runs checks or edits artifacts. Every call it makes re-reads
  its whole context, so it stays thin on purpose.
- **Phase agents**: the `feat-*` subagents. Each does one job, can't talk to
  you, starts with no conversation history, and gets what it needs (paths,
  size, conventions, allowed hooks, rejected findings) in its prompt.
  Changes you ask for at a gate go back to the agent that owns the artifact.

## Phases at a glance

| #   | Phase         | Runs in                                                                                  | Skills used                                            | Produces                                      | Gate                                                            |
| --- | ------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------------------ | --------------------------------------------- | --------------------------------------------------------------- |
| 1   | Brief         | `/feat-brief` (your session)                                                             | `interview-me`                                         | `specs/briefs/<name>.md`, or a capability map | **hard** (confirm the brief)                                    |
| 0   | Setup         | coordinator                                                                              | —                                                      | conventions, hooks checked                    | hard only if a Spec Kit hook would branch or commit             |
| 2   | Specify       | `feat-specifier`                                                                         | `speckit-specify`                                      | branch/worktree, `spec.md`, `feat-state.md`   | **hard** (the only place questions are asked)  |
| 3   | Plan          | `feat-planner`                                                                           | `speckit-plan`                                         | `plan.md` and design docs                     | none (hard for large)  |
| 4   | Design review | `feat-sec-reviewer` ∥ `feat-cost-reviewer`, then `feat-planner` writes accepted findings | `security-and-hardening` (cost checklist in the agent) | findings D1…                                  | one gate with 3: hard only on a real finding, a user-call assumption, a blocker or a size increase (always hard for large) |
| 5   | Tasks         | `feat-tasker`                                                                            | `speckit-tasks`, `speckit-analyze`                     | `tasks.md`, analysis clean                    | hard on CRITICAL/HIGH, a size increase or an unanswered checklist item; always for large |
| 6   | Implement     | `feat-implementer` ×1 per user story, in turn                                            | `speckit-implement`                                    | the code, tasks ticked, checks green          | soft (hard per story for large; hard on a design problem)       |
| 7   | Code review   | `feat-code-reviewer` ×2 (small) or ×5, then `feat-implementer` applies picks             | `security-and-hardening`, `performance-optimization`   | findings B, S, P, C, R; picked fixes applied  | **hard**                                                        |
| 8   | Ship          | `feat-shipper`                                                                           | —                                                      | docs updated, commits, push, PR               | none                                                            |

**Hard gate**: Claude stops and waits for your answer. **Soft gate**: Claude
reports and continues; anything surprising turns it into a hard gate.

## Size × phase matrix

Each cell: model · effort, passed by `/feat` on every spawn.

| #   | Phase                        | Agent                | small           | medium          | large           | huge                         |
| --- | ---------------------------- | -------------------- | --------------- | --------------- | --------------- | ---------------------------- |
| 1   | Brief                        | your session         | session         | session         | session         | session, plus capability map |
| 2   | Specify                      | `feat-specifier`     | sonnet · medium | sonnet · medium | opus · high     | —                            |
| 3   | Plan                         | `feat-planner`       | opus · high     | opus · high     | opus · xhigh    | —                            |
| 4a  | Security design ∥            | `feat-sec-reviewer`  | sonnet · medium | opus · medium   | opus · high     | —                            |
| 4b  | Cost design ∥                | `feat-cost-reviewer` | sonnet · medium | sonnet · medium | opus · medium   | —                            |
| 5   | Tasks + analyze              | `feat-tasker`        | sonnet · medium | sonnet · medium | sonnet · high   | —                            |
| 6   | Implement (×1 per story)     | `feat-implementer`   | sonnet · medium | opus · medium   | opus · high     | —                            |
| 7a  | Correctness, spec, standards | `feat-code-reviewer` | sonnet · medium | opus · medium   | opus · medium   | —                            |
| 7b  | Security                     | `feat-code-reviewer` | sonnet · medium | opus · medium   | opus · high     | —                            |
| 7c  | Performance                  | `feat-code-reviewer` | sonnet · medium | sonnet · medium | opus · medium   | —                            |
| 7d  | Over-engineering             | `feat-code-reviewer` | sonnet · medium | sonnet · medium | sonnet · medium | —                            |
| 7e  | Readability                  | `feat-code-reviewer` | sonnet · medium | sonnet · medium | sonnet · medium | —                            |
| 8   | Ship                         | `feat-shipper`       | haiku · medium  | haiku · medium  | haiku · medium  | —                            |

**Phase 7 reviewers.** small: two reviewers, lenses 7a+7b and 7c+7d+7e. medium and large: one reviewer per lens, 7a–7d in parallel, then 7e
with 7d's cuts. A group runs on the strongest model among its lenses.
Applying the picked fixes uses the phase 6 row.

A huge idea never reaches `/feat` as one unit: each capability of its map
gets its own brief and size column.

### How the sizes differ beyond model and effort

|                    | small                                                                                        | medium                                           | large                                                       | huge                                       |
| ------------------ | -------------------------------------------------------------------------------------------- | ------------------------------------------------ | ----------------------------------------------------------- | ------------------------------------------ |
| **When**           | up to ~30 tasks; no new service, permissions, network exposure or dependency; docs-only work | ~31–60 tasks, or a small one adding any of those | more than ~60 tasks                                         | capabilities that could ship independently |
| **Hard gates**     | brief, 2, 7 (+4 on a real finding, +5 on CRITICAL/HIGH)                                      | brief, 2, 4, 7 (+5 on CRITICAL/HIGH)             | brief, 2, 3, 4, 5, each story in 6, 7                       | the map                                    |
| **Code reviewers** | 2                                                                                            | 5                                                | 5                                                           | per capability                             |
| **PRs**            | 1                                                                                            | 1                                                | 1                                                           | 1 per capability                           |
| **Extra review**   | —                                                                                            | —                                                | `/code-review ultra` suggested before merge (you launch it) | per capability                             |

### Why these choices

- **Plan is on Opus even for small.** Plan quality decides everything after
  it, and it is one agent run.
- **Effort before model.** Raising effort on the same model costs less than
  a bigger model, and pays off most in planning and review.
- **One implementer per story at every size.** Each starts fresh instead of
  carrying the earlier stories' reads; stories run one after the other
  because nothing is committed before phase 8.
- **Two reviewers for small.** Each agent start costs ~36k tokens before any
  work; a small diff doesn't need five separate contexts.
- **Ship on Haiku.** Commits, push and a PR body from the state file need
  little reasoning; it used to run at the coordinator's full context.
- **Huge is a scoping problem.** One spec with a dozen capabilities gives a
  shallow review and a PR nobody can read.

## Phase details

### 1 Brief (`/feat-brief`)
Reads the code the idea touches, interviews you one question at a time
(`interview-me` steps 1–5; its restate is the brief, its confirmation the
gate, its hand-off step skipped), proposes a size, writes
`specs/briefs/<name>.md` and tells you to `/clear` and run `/feat` on it.
**Huge:** writes a capability map to `specs/maps/<name>.md` (stable ids,
responsibility, size, one-way dependencies, a build order where each step
ships something usable), gates on it, then writes the first capability's
brief. Detection rules and map format adapted from the scope check in
[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)'
`spec-driven-development` (MIT).

### 0 Setup (coordinator)
Checks the argument is a brief, reads `CLAUDE.md`/`AGENTS.md` and project
memory (they override the skill), checks Spec Kit and the agents, and reads
`.specify/extensions.yml`: hooks that would create branches or commit are
put to you before anything runs.

### 2 Specify (`feat-specifier`)
The coordinator creates branch `<NNN>-<short-name>` (worktree when possible,
renamed if EnterWorktree picked another name) and enters it, so every agent
starts there. The specifier runs `speckit-specify` from the brief and
reports stories, requirements, open `[NEEDS CLARIFICATION]` markers with
recommended answers, assumptions and unchecked checklist items. The
coordinator moves the brief into `feat-state.md` and gates. This is the only
place questions are asked, the checklist question included; your answers and
edits go back to the same specifier, continued with `SendMessage` so it
keeps what it read.

### 3 Plan (`feat-planner`)
Runs `speckit-plan`, kept to what the spec requires; it never asks you
anything. It reports approach, what it touches, new dependencies or
services with reasons, constitution check, a size trigger (new service,
permissions, exposure or dependency), and the decisions the spec didn't
call for as assumptions with a recommendation and whether they need your
call. Only a blocker stops the run. Small and medium go straight to phase 4;
large stops here.

### 4 Design review (`feat-sec-reviewer` ∥ `feat-cost-reviewer`)
Both read spec and plan. Security translates the web-app checklist to the
project (exposure, identities, secrets, defaults, input, supply chain,
blast radius); cost looks for oversized resources, repeated work, unbounded
loops, extra calls, slow feedback loops, unused code, and may propose
dropping a requirement. Each `D…` gets a recommendation. Large: you accept or
reject each. Small and medium: one gate for phases 3 and 4 ("Plan and design
review"), hard only on a finding above nice-to-have, an assumption that needs
your call, a constitution violation, a blocker or a size increase; otherwise
the recommendations are applied, and "ok" accepts them all. The planner (the
same one, continued) writes the accepted ones into spec.md (as
requirements) and plan.md.

### 5 Tasks (`feat-tasker`)
Runs `speckit-tasks` then `speckit-analyze`, fixes MEDIUM/LOW findings that
don't change meaning, and reports CRITICAL/HIGH with proposed fixes, task
IDs per story, the MVP slice, and unchecked checklist items. The gate is
hard only on CRITICAL/HIGH findings, a size increase, or checklist items
your phase 2 answer doesn't cover (`speckit-implement` would stop on them).
Last cheap moment to change direction.

**Size changes** are checked at the plan (size trigger) and here (task
count). An increase is always a hard gate: it names the old and new size and
what changes. A decrease is applied, logged with its reason and mentioned at
the next gate; `size <s>` reverses it.

### 6 Implement (`feat-implementer` per story)
One implementer per user story, one after the other (setup tasks with the
first, polish with the last). Each runs `speckit-implement` over its tasks,
reads only what they need, runs build, tests and linters, never weakens a
check, never commits. Failing checks go back once; a needed design change is
a hard gate. **Large:** a gate after each story.

### 7 Code review (`feat-code-reviewer`)
The coordinator makes the uncommitted work reviewable (`git add -N` on new
files, `git diff <merge-base>`; a `...HEAD` diff would be empty) and spawns
the reviewers with their lenses:
- **7a Correctness, spec, standards**: three separate passes. Standards:
  the project's documented rules (hard) and a Fowler smell baseline
  (judgement calls). Spec: missing requirements, scope creep, wrong
  implementations, acceptance criteria. Bugs: edge cases, error handling,
  races. The first two are adapted from Matt Pocock's `code-review`
  ([mattpocock/skills](https://github.com/mattpocock/skills), MIT).
- **7b Security**: each accepted `[sec]` design finding is built, plus what
  the implementation introduced.
- **7c Performance**: `performance-optimization`'s measure and identify
  steps on what was built, with the project's own benchmarks or timings
  where cheap, the rest marked `unmeasured`.
- **7d Over-engineering**: what to delete (`delete`, `stdlib`, `native`,
  `reuse`, `yagni`, `shrink`), with the lines it would save; the checklist
  is in the agent, adapted from the pre-v5 `ponytail-review`
  ([dietrichgebert/ponytail](https://github.com/dietrichgebert/ponytail), MIT).
- **7e Readability**: nesting, long functions, dense expressions, flag
  parameters, names and comments, on the code as it will be after the cuts,
  never changing behaviour. Adapted from Addy Osmani's
  `code-simplification` ([addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), MIT).

Reviewers verify their findings and list what they dismissed. You get one
list (`B` bugs and spec mismatches, `S` security, `P` performance, `C` cuts,
`R` readability and `[std]` standards) and pick. `feat-implementer` in fix
mode applies the picks: bugs and security, then cuts, then performance
(each measured before and after, kept only if it beats the noise with tests
green, every attempt logged with its numbers), then readability one change
at a time with tests after each.

### 8 Ship (`feat-shipper`)
Updates the docs the project asks for, commits by the project's rules
(default: `docs(specs)` then `feat(scope)` with its docs; `perf` and `refactor`
only when separable),
stages only the feature's files, rebases, pushes, opens a non-draft PR with
the brief, accepted design changes, review results and numbers, and a link
to the state file. If git is blocked in the session, it returns one `!`
command for you to run. Never merges.

## The state file

`specs/<NNN-name>/feat-state.md` is the memory of the run: branch,
worktree, size, current phase, conventions, allowed hooks, the brief, and a
log of every gate with what you accepted and rejected (and why) and every
performance attempt with its numbers. Every agent reads it; `/feat resume`
starts from it; the PR links to it. It's updated at each gate.

## Agents

| Agent                | Phase(s)        | small size      | Denied tools                           | Loads                              | Writes                                               |
| -------------------- | --------------- | --------------- | -------------------------------------- | ---------------------------------- | ---------------------------------------------------- |
| `feat-specifier`     | 2               | sonnet · medium | NotebookEdit, Agent                    | `speckit-specify`                  | spec.md                                              |
| `feat-planner`       | 3, 4 (amend)    | opus · high     | NotebookEdit, Agent                    | `speckit-plan`                     | plan.md, design docs; accepted findings into spec.md |
| `feat-sec-reviewer`  | 4               | sonnet · medium | Edit, Write, NotebookEdit, Agent       | `security-and-hardening`           | nothing                                              |
| `feat-cost-reviewer` | 4               | sonnet · medium | Bash, Edit, Write, NotebookEdit, Agent | none (checklist in its prompt)     | nothing                                              |
| `feat-tasker`        | 5               | sonnet · medium | NotebookEdit, Agent                    | `speckit-tasks`, `speckit-analyze` | tasks.md, small artifact fixes                       |
| `feat-implementer`   | 6, 7 (fix mode) | sonnet · medium | Agent                                  | `speckit-implement`                | code, tasks.md                                       |
| `feat-code-reviewer` | 7               | sonnet · medium | Edit, Write, NotebookEdit, Agent       | per lens, on demand                | nothing                                              |
| `feat-shipper`       | 8               | haiku · medium  | NotebookEdit, Agent                    | —                                  | docs, commits, PR                                    |

Agent files carry no model or effort: `/feat` passes both on every spawn,
from the size table. Tool limits are deny lists (`disallowedTools`) rather
than allow lists, so a new tool is available to an agent unless denied. No agent but the shipper commits, and no agent spawns further agents.
