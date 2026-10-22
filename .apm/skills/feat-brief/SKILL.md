---
name: feat-brief
description: >
  First step of the feature workflow: interviews the user about a feature
  idea (interview-me), proposes its size, and saves a brief that /feat
  builds from; splits a huge initiative into a capability map instead. Use
  it whenever the user wants to build, add or implement a feature and has no
  brief yet, or as /feat-brief followed by the idea, or by a capability map
  path and a capability id.
  Not for bugfixes or pure refactors.
argument-hint: '"idea in one line" | map-path capability-id'
---

# /feat-brief: from an idea to a brief

The user's request: `$ARGUMENTS`

This is step one of two. It runs in its own context on purpose: the
interview, the code you read for it and the back-and-forth stay here, and
`/feat` starts from a clean context with only the brief. Every later call of
the build re-reads its context, so this split is the cheapest thing the
workflow does.

## 1. Interview

Read the project's `CLAUDE.md` / `AGENTS.md`, then the code the idea touches,
so your questions are about real choices, not things you could look up.

Invoke `interview-me` with the idea and follow its steps 1–5 (hypothesis,
one question at a time with your guess attached, want vs. should-want), with
two changes: its restate (step 4) is the brief below, and its confirmation
(step 5) is the gate of this skill, so the user confirms once. Skip its
step 6: don't offer to save the intent or hand off to other skills.

Cover at least: who uses it and why now, the observable behaviour, what is
out of scope, how we'll know it works, constraints from existing code.

From a capability map (`/feat-brief <map> <id>`): read the map, use the
capability's row and its dependencies as the idea, and keep the interview
short; most decisions were made when the map was approved.

## 2. Size

Propose one, with a one-line reason:

| Size | Rule of thumb |
|---|---|
| **small** | one package or project, no new external service, no new permissions or network exposure, no new dependency |
| **medium** | anything else that is not large |
| **large** | spans several packages/projects, or adds a service, or will likely produce more than ~25 tasks |
| **huge** | bundles capabilities that could ship and be verified independently: write a capability map (step 4) instead of a brief |

## 3. The brief

Write it to `specs/briefs/<short-name>.md`:

```markdown
# Brief: <feature, one line>
- Size: small | medium | large — <one-line reason>
- Short name: <2–4 word kebab-case, e.g. edit-stack-config>
- Map: <map path and capability id, if it came from one>

## Why
<the problem, for whom>

## Behaviour
- <what the user can observe>

## Out of scope
- <…>

## Acceptance
- <testable>

## Constraints / decisions already made
- <…>
```

**Gate**: show the brief and the size; the user confirms or edits. Then end
with exactly this, so the next step is one copy-paste:

```
Brief saved: specs/briefs/<short-name>.md
Start the build in a fresh context:
  /clear
  /feat specs/briefs/<short-name>.md
```

Installed as a Claude Code plugin, the command is `/feat-agents:feat`:
print that instead. Don't start `/feat` yourself: it would inherit this
whole interview.

## 4. Huge: the capability map

(Adapted from the scope check in addyosmani/agent-skills'
`spec-driven-development`, MIT.)

Most requests are one capability; this is the exception. Split when the
request bundles several independently testable capabilities:
- it names distinct capabilities with their own consumers or data (e.g.
  identity, billing, notifications, reporting);
- its acceptance criteria cluster into groups that could ship and be
  verified separately;
- one capability could be cut or replaced without rewriting the others'
  requirements.

Write a capability map to `specs/maps/<short-name>.md`, small enough to
review in a minute:

```markdown
# Capability map: <initiative>

| Id | Responsibility | Size | Depends on |
|---|---|---|---|
| identity | Accounts, sessions, SSO | medium | — |
| billing | Plans, invoices, payments | large | identity |
| notifications | Email and webhook fan-out | small | identity |

Build order: identity → billing, notifications
```

- **Stable ids**, kebab-case, chosen once and never renamed: each one is the
  short name of that capability's brief, branch and spec directory.
- **Dependencies point one way, no cycles.** If two capabilities each need
  the other, they are one capability.
- **Interfaces live at the boundary.** The map records that `billing`
  depends on `identity`; the contract between them goes in the providing
  capability's spec.
- **Each one ships something usable** in build order, so the initiative can
  stop after any of them.

**Gate** on the map: boundaries, dependency direction, sizes, build order.
Then write the brief for the first capability (step 3, short interview) and
end the same way. The map is the index of what remains: each capability
gets its own `/feat-brief <map> <id>` when the previous one has shipped.
