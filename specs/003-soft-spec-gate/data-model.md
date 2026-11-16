# Data model: soft spec gate

Everything lives in the state file's `## Log` (`specs/<short-name>/feat-state.md`),
written only by the coordinator, from agent reports.

## Phase 2 gate mode

Decided by the coordinator from the specifier's report, the same at every
size:

| Condition (any one)                                                                                                         | Mode |
| --------------------------------------------------------------------------------------------------------------------------- | ---- |
| `Open markers` lists at least one `[NEEDS CLARIFICATION]`                                                                   | hard |
| A blocker: the report has no `Spec:` path, or its Assumptions or Open markers say the brief can't be specified as written (research R3) | hard |
| Anything else surprising in the report, a remark about size included (harness, "Gates")                                    | hard |
| None of the above                                                                                                           | soft |

No size-increase row: phase 2 has no size trigger (the *size triggers* are
the planner's trigger and the phase 5 task count, and the specifier's
report has no size field). A size increase is caught at phase 3 or 5.

## Phase 2 Log line

Hard (as today, with the mode and why):

```markdown
- [x] 2 Specify — hard (2 open markers); approved; FR-005 reworded; checklist: proceed (user)
```

Soft (the summary under it, from the specifier's report):

```markdown
- [x] 2 Specify — soft; spec summary for the next gate:
  - Stories: US1 <title> (P1); US2 <title> (P2); …
  - Requirements: <count>; <notable ones, a few words each>
  - Spec assumptions: 1. <assumption>; 2. <assumption> (recommended: keep as written)
  - Unchecked checklist items: <checklists/ file: item> (recommended: <proceed | fix first>) | none
```

Read as hard: a phase 2 line with neither `soft` nor `hard` right after the
dash (older state files). No summary is shown for it.

Several phase 2 lines ("back to 2", reruns): every phase 2 run, reruns
included, writes its own soft or hard line, and the latest one decides. A
hard rerun after a soft one shows no summary; a soft rerun shows its own.

## Summary-carrying gate

The first gate after a soft phase 2: `3–4 Plan and design review` on small
and medium, `3 Plan` on large. It is open while no `[x]` line for that gate
follows the latest phase 2 line: on small and medium the phase 4 line
(`3–4 Plan and design review`; a `[x] 3 Plan` progress line doesn't close
it), on large the phase 3 line.

The wording the skill carries verbatim (section 4, and section 3 for
large): "The gate's Log line records what became of the spec assumptions
and the checklist answer." So a later resume doesn't show the summary
again:

```markdown
- [x] 3–4 Plan and design review — spec assumptions kept (user: "ok"); checklist: proceed (user); accepted D1, D3; rejected D2 (user: "…")
- [x] 3–4 Plan and design review — soft; spec assumptions kept at recommendations; checklist: none unchecked; applied D1
- [x] 3 Plan — spec assumption 2 overturned: "<user's words>" → planner amend; checklist: proceed (user); approved
```

## State transitions

```text
phase 2 report
  ├─ hard ─► gate (user answers) ─► specifier amend ─► phase 3 ─► next gate as today
  └─ soft ─► one-line report + Log summary ─► phase 3
              ├─ large: phase 3 gate (hard) opens with summary
              │     └─ spec change? ─► planner amend (fresh) ─► phase 4
              │           (phase 4 gate: "What you should know" says the plan was amended)
              └─ small/medium: phase 4 ─► 3–4 gate opens with summary
                    ├─ hard (a finding, a user-call assumption, a violation, a blocker,
                    │        a size increase, a contradicting paraphrase, or an
                    │        unchecked checklist item) ─► user answers ─► planner amend:
                    │        accepted findings + spec changes, one pass
                    └─ soft ─► report carries the summary; spec assumptions logged
                               as kept; planner applies the recommendations
```

On `/feat resume`: when the latest phase 2 line says `soft` and no `[x]`
line for the summary-carrying gate follows it, that gate opens with the
summary read from the Log.

A change that rewrites stories is "back to 2" at any gate: the specifier
reruns, the phase 2 rule applies again to its new report, and the rerun
writes its own phase 2 line.
