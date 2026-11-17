---
title: Usage
weight: 20
---

# Using the workflow

Everything here runs in Claude Code. A feature takes two commands, in two
contexts:

```
/brief "let users edit a stack's config from the CLI"
   … interview, brief, size …
/clear
/feat specs/briefs/edit-stack-config.md
   … gates …  → PR link
```

A bug takes one: `/fix #42` ([below](#fixing-a-bug-fix)).

Words you'll meet:

- **Brief**: a one-page description of the feature (why, behaviour, scope,
  acceptance), written with you by `/brief`. `/feat` builds from it alone.
- **Size**: small, medium, large or huge. It picks the model and effort of
  every agent and how often the run stops for you ([Sizes](#sizes)).
- **Gate**: a point where the run reports to you. At a *hard* gate it waits
  for your answer; at a *soft* one it reports and goes on.
- **Phase agent**: a `feat-*` subagent that does one phase (plan, review,
  implement…) in its own fresh context, then reports back.
- **Lens**: one angle of a review (security, cost, performance…). Reviews
  are numbered by phase and lens: 4a is the design's security lens, 7d the
  code's over-engineering lens.
- **State file**: `feat-state.md`, the run's memory: size, phase, every
  decision you made. `/feat resume` and `/fix resume` start from it.

## 1. Brief: `/brief "<idea>"`

Claude reads the code the idea touches, then asks you questions one at a
time (`interview-me`), each with its guess attached. It proposes a size and
writes the brief to `specs/briefs/<short-name>.md`: why, how it's handled
today, behaviour, out of scope, alternatives rejected, acceptance,
constraints, size, short name. Expect pushback: before writing a decision
down, Claude gives its strongest counter-argument.

A fresh agent (`feat-brief-reviewer`) then reads the brief without the
interview, as the build will. You confirm the brief together with its
paraphrase of the feature, its own size estimate and its findings `F1…`,
each with a recommendation; "ok" accepts them all.

Claude may also start it on its own when you ask it to build a feature.
It's not for bugfixes (use [`/fix`](#fixing-a-bug-fix)) or pure refactors. You
can also write a brief by hand in the same format and skip this step.

From a GitHub issue, run `/brief #N` (or pass its URL): Claude reads it
with `gh`, its title and body are the idea and its unchecked checklist items
are questions the interview answers. The brief records the issue, and the PR
says `Closes #N`, so merging closes it.

**Board tracking** (optional): with a `.logistics.yml` at the repo root,
`/brief` and `/feat` move the issue across a GitHub Projects board (Brief,
In progress, In review; Done when the PR merges). Each run first prints the
board it will write to. A brief without an issue gets one created after you
confirm it at the gate. Setup: [install.md](install.md#5-board-tracking-optional).

**Huge** ideas (several capabilities that could ship on their own) get a
capability map in `specs/maps/<name>.md` instead: you approve the map, then
it writes the first capability's brief. Each later capability starts with
`/brief specs/maps/<name>.md <capability-id>`.

## 2. Fresh context: `/clear`

The brief step ends by telling you to run `/clear`. Do it: the build's
coordinator re-reads its whole context on every call, so starting it
without the interview in it is the single cheapest thing in the workflow.
A skill can't clear the context itself; that's why the workflow is split
into two commands at this point, where you are typing anyway. Opening a new
session works too.

Start that session on the model you want coordinating (Opus recommended):
the coordinator runs on the session's model.

## 3. Build: `/feat <brief>`

The session becomes a thin coordinator: it never reads code. Every phase runs
in a `feat-*` subagent and Claude stops only at gates; see
[workflow.md](workflow.md) for which phases stop and when. It ends with a PR
link and never merges.

A check an agent could not run (no credentials, a service down, a manual
step, a killed run) is never passed off as green: its task stays unticked,
the implementation gate lists it as Not verified, and the PR body repeats it
under `Not verified`. Run it and tick the task yourself.

State lives in `specs/<NNN-name>/feat-state.md`, next to the spec, plan and
tasks (`specs/<name>/` until the shipper numbers it). The feature is built
on branch `<name>`, in a worktree under
`.claude/worktrees/` when possible, so your checkout stays untouched.

## Answering a gate

```
## Phase 3–4: Plan and design review — needs your call
**What I did:** feat-design-reviewer ×3 on spec + plan: 4a (opus · medium), 4b (sonnet · medium), 4c (sonnet · high)
**How a fresh reader understood it:** … (check it against what you meant)
**What you should know:** …
**Your call:**
1. D1 [sec] … — I recommend accepting
2. D2 [cost] … — I recommend rejecting: …
3. D3 [design] plan says `config.Load` validates the file; it doesn't → validate in the new command — I recommend accepting
**Next:** phase 5 Tasks
```

On small and medium features, plan and design review share one gate, and
"ok" accepts every recommendation. A size increase is always asked on its
own; a decrease is applied and logged.

When the spec leaves no question open, phase 2 doesn't stop. The next gate
(phase 3 on large) opens with the spec, the specifier's assumptions and the
checklist question, and "ok" accepts those too. A spec change you ask for
there is written by the planner together with the findings; "back to 2" is
for a rewrite.

Answer in plain words ("accept D1, reject D2: behind the VPN"). Rejections
are logged with your reason and never proposed again. You can also say:

| Say                            | Effect                                                       |
| ------------------------------ | ------------------------------------------------------------ |
| `back to N`                    | rerun phase N with what you now know                         |
| `skip N`                       | skip phase N; the skip and your reason are logged            |
| `size large` (or small/medium) | change the size from now on; later phases use the new column |
| `stop`                         | pause; the state file keeps everything                       |

Silence or an ambiguous answer is not taken as approval.

**Answer within the hour when you can.** After an hour the prompt cache
expires and the next call re-processes the whole context. Back later? Prefer
`/clear` then `/feat resume`: it starts from the state file, which is
smaller than the conversation.

## Resuming

```
/feat resume
```

Finds the latest unfinished `feat-state.md` (asks if there are several),
recaps, and shows the gate you were at.

## Fixing a bug: `/fix`

```
/fix #42                      # a GitHub issue (or owner/repo#42, or its URL)
/fix "export drops the last row when the file has no trailing newline"
/fix resume
```

One command, no brief and no `/clear` step: `/fix` assesses the report
with Spec Kit's bug extension (install it once per project: `specify
extension add bug`), fixes it, has a different agent verify the fix,
reviews the code and opens a PR with `Fixes #N` when there is an issue.
Installed as a plugin, it is `/logistics:fix`. A report that turns out to
be a missing feature stops at the first gate and points to `/brief #N`.

The gates you see:
- **Assess**: the root cause, its confidence, whether it was reproduced,
  the remediation and the proposed size. It stops for you unless all of
  it is plain and safe; it always stops when the report comes from someone who
  is not an owner, member or collaborator of the repo (nothing from it runs
  unless you approve it), for a
  security bug, and before it creates an issue for a `"<symptom>"` with
  board tracking.
- **Fix**: shown when the fix deviates from the assessment or a check
  fails.
- **Test**: it also tries each check the fix could not run, and one it
  still can't run makes it `partial`, so the PR's `Not verified` section
  lists only checks the shipper could not run. `verified` goes on;
  `partial` asks for what is missing; a `failed` test goes back to the fix
  once, then asks you. A fix that is not `verified` ships only if you say
  so.
- **Code review**: you pick the fixes, unless the review is clean on a
  small, non-security fix.

The same answers work at every gate (`back to N`, `size <s>`, `stop`),
except that assess, fix and test can't be skipped. `/fix resume` finds the
unfinished run in this checkout or any of its worktrees (it asks when
there are several) and continues where it stopped. Phases, models and
board moves: [workflow.md](workflow.md#fix).

## Sizes

Proposed by `/brief`; you decide.

| Size   | When                                                                                 | What changes                                                                                             |
| ------ | ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| small  | up to ~30 tasks, no new service, permissions, exposure or dependency; docs-only work | Sonnet at medium effort for most phases, two code reviewers, fewest gates                                |
| medium | ~31–60 tasks, or a small one adding a service, permissions, exposure or dependency   | Opus for planning, design security, implementation, correctness and security review; five code reviewers |
| large  | more than ~60 tasks                                                                  | Opus for nearly every phase, higher effort on planning and reviews; gates at 3, 4, 5 and after each story |
| huge   | capabilities that could ship on their own                                            | a capability map; one brief, `/feat` run and PR per capability                                           |

Full matrix in [workflow.md](workflow.md#size--phase-matrix).

## Tuning

The size tables in [`.apm/skills/feat/SKILL.md`](https://github.com/pdemagny/logistics/blob/main/.apm/skills/feat/SKILL.md) and
[`.apm/skills/fix/SKILL.md`](https://github.com/pdemagny/logistics/blob/main/.apm/skills/fix/SKILL.md) are the single source
of truth: the coordinator passes `model` and `effort` from them on every
agent call. Edit them and mirror the change in [workflow.md](workflow.md).

Agent files carry no model or effort; outside the workflow an agent runs
on the session's model unless you name one.

| Setting         | Values                                                 | Effect                                                       |
| --------------- | ------------------------------------------------------ | ------------------------------------------------------------ |
| model           | `haiku`, `sonnet`, `opus`, `fable`, or a full model ID | capability vs. usage; Opus also has its own plan limit       |
| effort          | `low`, `medium`, `high`, `xhigh`, `max`                | thinking per step and number of tool calls on the same model |
| reviewer groups | phase 4 and 7 notes under the size tables              | fewer reviewers = fewer cold starts                          |
| gates           | the Phases and gates table                             | more stops where mistakes cost more                          |

Suggested approach: run two or three real features, note the phase where
results were weakest, and raise that phase's effort before its model.

## Using the agents on their own

They're ordinary Claude Code subagents: "have feat-code-reviewer review my
uncommitted diff with lenses 7b and 7d", "have feat-design-reviewer review
this plan with lens 4b". Installed as a plugin, they're `logistics:feat-code-reviewer` and
so on.

## When something goes wrong

| What you see | What to do |
| --- | --- |
| `apm` or `specify`: command not found after installing | `uv tool update-shell`, then open a new shell |
| `/brief`, `/feat` or `/fix` is not a known command | Restart Claude Code after installing. Installed as a plugin, they are `/logistics:brief` and so on. `install.sh check` lists what is missing ([install.md](install.md#4-check)) |
| `/fix` stops at setup and names `specify extension add bug` | Run it in the project, then `/fix` again |
| `tracker: error: …` at the start of a run | Check `.logistics.yml` is committed and pushed, and `gh auth refresh -s project` ([board tracking](install.md#5-board-tracking-optional)) |
| A `[!] tracker:` line at a gate | A board move failed; the run went on. Move the card by hand |
| The run ends with a line starting `! cd … && git …` | Git or `gh` was blocked in the session. Type that line as is: the `!` runs it in Claude Code |
| The run ends with `! spec-number: error: …` | Nothing was pushed. Fix the cause (usually `gh` auth or network), then `/feat resume` |
| The session closed, crashed or ran out of context mid-run | `/feat resume` (or `/fix resume`) continues from the state file |
| Your plan has no Opus (or no Sonnet) | Change the model in the size tables ([Tuning](#tuning)) |
