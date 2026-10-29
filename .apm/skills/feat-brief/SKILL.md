---
name: feat-brief
description: >
  First step of the feature workflow: interviews the user about a feature
  idea (interview-me), proposes its size, has a fresh reader review the
  draft, and saves a brief that /feat builds from; splits a huge initiative
  into a capability map instead. Use
  it whenever the user wants to build, add or implement a feature and has no
  brief yet, or as /feat-brief followed by the idea, by an issue (#N or its
  URL), or by a capability map path and a capability id.
  Not for bugfixes or pure refactors.
argument-hint: '"idea in one line" | #N | issue-url | map-path capability-id'
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

Cover at least: who uses it and why now, how it's handled today and why
that isn't enough, the observable behaviour, what is out of scope, the
options considered and why the others lose, what is non-negotiable, how
we'll know it works, constraints from existing code.

Don't agree by default. Before you write a decision down, give its
strongest counter-argument (doing nothing, something the code or a library
already has, a smaller version) and let the user answer it. A rejected
option goes into the brief with its reason: nobody after you saw this
conversation, so an unwritten rejection gets proposed again.

From a capability map (`/feat-brief <map> <id>`): read the map, use the
capability's row and its dependencies as the idea, and keep the interview
short; most decisions were made when the map was approved.

From an issue (`/feat-brief #N` or an issue URL): read it with `gh issue
view <N or URL> --json number,title,body,labels,url` and use its title and
body as the idea. Its unchecked checklist items are questions the interview
must answer; what the body already decides needs no question, only its
counter-argument. An issue labelled as a bug is not for this workflow: say
so and stop. If `gh` can't read it, ask the user to paste the issue.

## 2. Size

Estimate how many tasks `speckit-tasks` will produce, then propose the
size from that number, with a one-line reason that states the estimate:

| Size | Expected tasks |
|---|---|
| **small** | up to ~30 |
| **medium** | ~31–60 |
| **large** | more than ~60 |
| **huge** | bundles capabilities that could ship and be verified independently: write a capability map (step 4) instead of a brief |

- Size on the amount of work, not its spread: touching several packages or
  many files doesn't make a feature bigger by itself.
- A new external service, new permissions, new network exposure or a new
  dependency raises small to medium. Nothing else raises a size.
- Docs-only or text-only changes are small.
- Between two sizes, pick the smaller: phase 5 of `/feat` checks the size
  against the real task count.

## 3. The brief

Write it to `specs/briefs/<short-name>.md`:

```markdown
# Brief: <feature, one line>
- Size: small | medium | large — <~N tasks expected, one-line reason>
- Short name: <2–4 word kebab-case, e.g. edit-stack-config>
- Map: <map path and capability id, if it came from one>
- Issue: <#N, or owner/repo#N for another repository, if it came from one>

## Why
<the problem, for whom>

## Today
<how it's handled now, and why that isn't enough>

## Behaviour
- <what the user can observe>

## Out of scope
- <…>

## Alternatives rejected
- <option> — <why not>

## Acceptance
- <testable>

## Constraints / decisions already made
- <…>
```

### Fresh-reader review

Every brief, every size: spawn `feat-brief-reviewer` (or
`feat-agents:feat-brief-reviewer` as a plugin) with the Agent tool, giving
it the brief's absolute path, the project root and, from a map, the map's
path. Nothing about the interview: it reads the brief as the specifier
will. Pass `model` and `effort` for the size you proposed (this mirrors row
1 of `/feat`'s size table): small and medium `sonnet` · `medium`, large
`opus` · `medium`. If the agent isn't installed, say so at the gate and
skip the review; don't review inline: the context that wrote the brief
can't read it fresh.

Number its findings `F1…` and give each a recommendation. You know the
interview, it doesn't: a finding the interview already answered is still a
gap in the brief, so recommend writing the answer in, not rejecting it.

**Gate**: the brief, the size, then the review: its paraphrase (the user
checks it against what they meant), its size estimate when it differs, and
the findings with your recommendations. The user confirms or edits; "ok"
accepts every recommendation. A size the reviewer puts higher is asked, not
applied. Write the accepted findings into the brief; a rejected `yagni`
finding goes under "Alternatives rejected" with the user's reason, so no
later reviewer proposes it again. Don't rerun the review unless the user
asks. Then end with exactly this, so the next step is one copy-paste:

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
