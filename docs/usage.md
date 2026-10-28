# Using the workflow

Both commands run in Claude Code.

Two commands, in two contexts:

```
/feat-brief "let users edit a stack's config from the CLI"
   … interview, brief, size …
/clear
/feat specs/briefs/edit-stack-config.md
   … gates …  → PR link
```

## 1. Brief: `/feat-brief "<idea>"`

Claude reads the code the idea touches, then asks you questions one at a
time (`interview-me`), each with its guess attached. It proposes a size and
writes the brief to `specs/briefs/<short-name>.md`: why, behaviour, out of
scope, acceptance, constraints, size, short name. You confirm or edit it.

Claude may also start it on its own when you ask it to build a feature.
It's not for bugfixes (use Spec Kit's bug commands) or pure refactors. You
can also write a brief by hand in the same format and skip this step.

**Huge** ideas (several capabilities that could ship on their own) get a
capability map in `specs/maps/<name>.md` instead: you approve the map, then
it writes the first capability's brief. Each later capability starts with
`/feat-brief specs/maps/<name>.md <capability-id>`.

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
## Phase 4: Design review — needs your call
**What I did:** feat-sec-reviewer (opus · high) and feat-cost-reviewer (sonnet · high) on spec + plan
**What you should know:** …
**Your call:**
1. D1 [sec] … — I recommend accepting
2. D2 [cost] … — I recommend rejecting: …
**Next:** phase 5 Tasks
```

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

## Sizes

Proposed by `/feat-brief`; you decide.

| Size   | When                                                                                 | What changes                                                                                             |
| ------ | ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| small  | up to ~25 tasks, no new service, permissions, exposure or dependency; docs-only work | Sonnet at medium effort for most phases, two code reviewers, fewest gates                                |
| medium | ~26–50 tasks, or a small one adding a service, permissions, exposure or dependency   | Opus for planning, design security, implementation, correctness and security review; five code reviewers |
| large  | more than ~50 tasks                                                                  | higher effort on planning and reviews; a gate after each story                                           |
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
uncommitted diff with lenses 7b and 7d", "ask feat-cost-reviewer about this
plan". Installed as a plugin, they're `feat-agents:feat-code-reviewer` and
so on.
