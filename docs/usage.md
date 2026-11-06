# Using the workflow

Both commands run in Claude Code.

Two commands, in two contexts:

```
/brief "let users edit a stack's config from the CLI"
   … interview, brief, size …
/clear
/feat specs/briefs/edit-stack-config.md
   … gates …  → PR link
```

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

**Board tracking** (optional): with a `.feat-agent.yml` at the repo root,
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

State lives in `specs/<NNN-name>/feat-state.md`, next to the spec, plan and
tasks. The feature is built on branch `<NNN>-<name>`, in a worktree under
`.claude/worktrees/` when possible, so your checkout stays untouched.

## Answering a gate

```
## Phase 3–4: Plan and design review — needs your call
**What I did:** feat-design-reviewer ×3 on spec + plan: 4a (opus · high), 4b and 4c (opus · medium)
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
Installed as a plugin, it is `/feat-agent:fix`. A report that turns out to
be a missing feature stops at the first gate and points to `/brief #N`.

The gates you see:
- **Assess**: the root cause, its confidence, whether it was reproduced,
  the remediation and the proposed size. It stops for you unless all of
  it is plain and safe; it always stops when the report comes from someone
  without write access (nothing from it runs unless you approve it), for a
  security bug, and before it creates an issue for a `"<symptom>"` with
  board tracking.
- **Fix**: shown when the fix deviates from the assessment or a check
  fails.
- **Test**: `verified` goes on; `partial` asks for what is missing; a
  `failed` test goes back to the fix once, then asks you. A fix that is not
  `verified` ships only if you say so.
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
| large  | more than ~60 tasks                                                                  | higher effort on planning and reviews; a gate after each story                                           |
| huge   | capabilities that could ship on their own                                            | a capability map; one brief, `/feat` run and PR per capability                                           |

Full matrix in [workflow.md](workflow.md#size--phase-matrix).

## Tuning

The size table in [`.apm/skills/feat/SKILL.md`](../.apm/skills/feat/SKILL.md) is the
single source of truth: the coordinator passes `model` and `effort` from it
on every agent call. Edit it, mirror the change in
[workflow.md](workflow.md), and check the effect with
a cost script (since moved out).

Agent files carry no model or effort; outside the workflow an agent runs
on the session's model unless you name one.

| Setting         | Values                                                 | Effect                                                       |
| --------------- | ------------------------------------------------------ | ------------------------------------------------------------ |
| model           | `haiku`, `sonnet`, `opus`, `fable`, or a full model ID | capability vs. usage; Opus also has its own plan limit       |
| effort          | `low`, `medium`, `high`, `xhigh`, `max`                | thinking per step and number of tool calls on the same model |
| reviewer groups | phase 7 note under the size table                      | fewer reviewers = fewer cold starts                          |
| gates           | the Phases and gates table                             | more stops where mistakes cost more                          |

Suggested approach: run two or three real features, measure them with
a cost script (since moved out), note the phase where results were weakest, and raise
that phase's effort before its model.

## Using the agents on their own

They're ordinary Claude Code subagents: "have feat-code-reviewer review my
uncommitted diff with lenses 7b and 7d", "have feat-design-reviewer review
this plan with lens 4b". Installed as a plugin, they're `feat-agent:feat-code-reviewer` and
so on.
