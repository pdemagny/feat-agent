# Contract: phase 2 gate, the spec block, the planner's amend mode

The interfaces this feature changes are the gate messages the user reads
and the coordinator-to-planner amend message. Agent report formats do not
change (specifier and planner, FR-014, research R3).

## Phase 2 soft report (one line)

```
Phase 2 Specify — soft: spec.md written (<n> stories, <m> requirements, no open question); summary at the next gate. Next: phase 3 Plan
```

A link to spec.md is enough; nothing else is pasted. The summary goes into
the Log ([data-model.md](../data-model.md)).

## Phase 2 hard gate

As today (stories and requirements in a few lines, each open marker with
its recommended answer, the specifier's assumptions, the unchecked
checklist items with the proceed question), with "What you should know"
saying why it stopped (open markers, a blocker, or something surprising in
the report, such as a remark about size).

A blocker: the report has no `Spec:` path, or its Assumptions or Open
markers say the brief can't be specified as written.

## The spec block (first block of the summary-carrying gate)

Shown only after a soft phase 2, read from the Log, before anything else;
then the gate as today.

```
## Phase 3–4: Plan and design review — needs your call
**What I did:** …
**The spec (phase 2 didn't stop):** spec.md — US1 … (P1); US2 … (P2); <m> requirements, notably …
**How a fresh reader understood it:** …
**What you should know:** …
**Your call:**
1. Spec assumption: <assumption> — I recommend keeping it
2. Checklist: <file: item> unchecked — proceed? I recommend <proceed | fixing it first>
3. <size increase, if any>
4. D1 … — I recommend accepting
**Next:** phase 5 Tasks
```

On large, the same block opens `## Phase 3: Plan — needs your call`,
before approach, what it touches, dependencies, constitution check and the
planner's assumptions. When the planner amended the plan after that gate,
the phase 4 gate's **What you should know** says so (one line: what the
amend changed).

"ok" keeps every spec assumption and takes the checklist recommendation,
with the other recommendations of the gate. The gate's Log line records
what became of the spec assumptions and the checklist answer
([data-model.md](../data-model.md)).

When the gate is soft (small and medium only: no finding above
nice-to-have, no user-call assumption, no violation, no blocker, no size
increase, no contradicting paraphrase, no unchecked checklist item), the
soft report carries the same `**The spec …**` line and the spec
assumptions, and the Log says they were kept at their recommendations.

## Amend message to `feat-planner`

After a summary-carrying gate the user answered, `feat-planner` is spawned
fresh in amend mode (harness: after a hard gate) with, in one message:

- the accepted findings (small and medium), as today;
- each spec change the user asked for, quoted: an overturned assumption
  with the user's answer, a reworded requirement with its new wording.

On large, at the phase 3 gate, the same message carries the spec changes
only, and the design reviewers are spawned after it reports.

Planner prompt, amend mode (FR-014): after "apply edits as given;", one
clause is added and ends that sentence, exactly:

> a spec change (an assumption overturned, a requirement reworded) goes into spec.md, and into plan.md where it changes the how.

The amend-mode header is unchanged: it already names "the user's edits at
a gate", and naming spec changes there too would go past one phrase. Its
report stays `Report what changed, one line per finding`, a spec change
counting as one line; the fenced report block is unchanged.

## Wording to carry into the skill and the docs

The single statement every touched document must agree with (FR-017):

1. Phase 2 stops only when the spec has an open `[NEEDS CLARIFICATION]`
   marker or the specifier reports a blocker (or, as at any soft gate,
   something surprising); at every size. Otherwise it reports in one line
   and goes on.
2. After a soft phase 2, the next gate (plan and design review on small
   and medium, phase 3 on large) opens with the spec summary, the
   specifier's assumptions and the checklist question; "ok" accepts the
   recommendations.
3. After a soft phase 2, an unchecked checklist item makes the plan and
   design review gate hard.
4. A spec change asked at that gate goes to `feat-planner` (with the
   accepted findings, in one pass); one that rewrites stories is "back to 2".
