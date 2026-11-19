# Contract: phase 4 report line, merge, gate, soft line and Log

Both sides of the fixed report format (constitution IV): §1 is written into
`.apm/agents/feat-design-reviewer.agent.md`, §2–§6 into section 4 of
`.apm/skills/feat/SKILL.md`. Wording may be tightened; values, triggers and
formats may not change. `<…>` are placeholders.

## §1 Reviewer side (`feat-design-reviewer.agent.md`)

New section, after the severity paragraph and before `## Report, and nothing else`:

```markdown
## Recommendation

End every finding line with `— rec:`, one of three values, nice-to-have
included. `apply`: write it as proposed; on small and medium features the
planner writes it without asking the user, so recommend it only for what
you would change unasked. `skip (<why>)`: not worth the change; the why is
logged. `user (<why>)`: a call only the user can make. A finding that
removes or changes a story, a requirement or an acceptance criterion of the
spec, overturns one of its assumptions, or weakens a control the spec or
plan sets (relaxes validation, widens access), is `user`, never `apply`;
one that only adds a tightening requirement (input validation, error
handling, a secure default) may be `apply`. The paraphrase carries no rec.
```

Report format, finding lines (paraphrase, `Checked and fine:` and
`Wrote: none` unchanged):

```
- [sec] <risk> → <proposed change> (<artifact>: <section or line>) — severity: high | medium | nice-to-have — rec: apply | skip (<why>) | user (<why>)
- [cost] <cost or risk> → <proposed change> (<artifact>: <section or line>) — severity: high | medium | nice-to-have — rec: apply | skip (<why>) | user (<why>)
- [design] <gap> → <proposed change> (<artifact>: <section or line>) — kind: clarity | fit | simplicity | readiness — severity: high | medium | nice-to-have — rec: apply | skip (<why>) | user (<why>)
```

`[sec]` and `[cost]` gain `: <section or line>` so that "same spot" (§2) can
be compared on every line (research R2). Written into the agent beside the
format: `<section or line>` is the section heading as written in the
artifact, or a line number.

## §2 Merge (`/feat` section 4)

Replaces "Merge the findings into `D1…`, drop duplicates, give each a
recommendation":

> Merge the findings into `D1…`; each keeps the `rec` that ends its line.
> Never set `apply` or `skip` yourself. Apply merge rules 2, 3 and 5 of the
> harness (Review findings), where the same spot is the same artifact and
> an identical section heading or line, and the same section is the same
> tag (`[sec]`, `[cost]`, `[design]`); rules 1 and 4 don't apply. Findings
> with different tags on the same spot stay separate, each with its own
> `rec`.

The harness rules are referred to, not restated in section 4 (constitution
III); the outcomes below are for checking only (quickstart §3). Same spot,
same tag, same rec and fix → kept once; same spot, same tag, from different
reviewers or lenses, different rec or fix → each becomes `user (reviewers
disagree)`; same spot, different tags → kept separate, each with its rec;
rec missing, not one of the three values, or `skip`/`user` without its why
→ `user (no valid recommendation)` (this covers a run resumed from before
the change).

## §3 Gate (`/feat` section 4), first match wins

| Size         | Condition | Gate |
| ------------ | --------- | ---- |
| large        | always | **hard** |
| small/medium | a `D` finding with `rec: user`, an assumption with `needs user: yes`, a constitution violation, a blocker, a size increase, a paraphrase that contradicts the brief, an unchecked checklist item carried from a soft phase 2, or a failed report check (harness, Reported files) | **hard** |
| small/medium | otherwise | **soft** |

"Blocker" and "size increase" keep their meaning from section 3 (the
planner's blocker; its size trigger on a small feature). No row mentions
severity.

What the small/medium gate shows is today's list, unchanged in order:
after a soft phase 2 the spec block, then the paraphrase, approach, what it
touches, assumptions, any size increase (asked first), then the findings
(§5 on a hard gate, the soft line of §4 otherwise).

## §4 Soft gate

Prints the 4c paraphrase (every gate of this phase starts with it, as
today; research R1, decided at the phase 4 gate), after the spec block when
phase 2 was soft, then one line:

```
Phase 4 Design review — soft: <n> findings, <a> applied, <s> skipped[; security: <[sec] ids with rec apply>][; security skipped: <[sec] ids with rec skip>]; none needs your call. Next: phase 5 Tasks
```

e.g. `Phase 4 Design review — soft: 5 findings, 4 applied, 1 skipped; security: D2; security skipped: D5; none needs your call. Next: phase 5 Tasks`.

`; security: …` is left out when no `[sec]` finding is applied, and
`; security skipped: …` when none is skipped. Severity is never named. Zero
findings: `soft: 0 findings, 0 applied, 0 skipped`. The `apply` findings go
to `feat-planner` continued with `SendMessage` (the amend pass); the `skip`
ones are left. With no `apply` finding there is no `SendMessage` to the
planner: go straight to phase 5. After a soft phase 2 the spec assumptions
are logged as kept at their recommendations, as today.

## §5 Hard gate (small/medium and large)

Gate shape of the harness, titled `Phase 3–4: Plan and design review — needs
your call` on small/medium (`Phase 4: Design review — needs your call` on
large). What you should know says why it stops (`large`, `<ids> need you`,
`assumption <n> needs you`, `constitution: <principle>`, `blocker`, `size
increase`, `paraphrase contradicts the brief`, `checklist item`, `report
check failed`). Your call: each `user` finding first, with the reviewer's
why, as "apply or leave?"; then every other finding with its `rec` (on
large too, even when none is `user`). "ok" applies every `apply` and leaves
every `skip`; each `user` finding needs its own answer; a bare "ok" while
one is unanswered gets one follow-up naming the ids, and nothing goes to
the planner until each is answered (harness, Review findings, with "fix"
read as "apply"; its `S` notice doesn't apply here). The picked findings
and any spec change asked go to a fresh `feat-planner` (amend pass).

## §6 Log, on the `4 Design review` line

The harness's Review findings Log words, with this phase's line:

- soft: `- [x] 4 Design review — auto-applied <ids | none>; skipped <id> (reviewer: "<why>"), …`
- hard: `- [x] 4 Design review — picked <ids> | none picked; rejected <id> (user: "<words>"), <id> (as recommended), …`
  (`as recommended` only for a `skip` left by "ok")
- then one indented line per finding: `    - <id> <artifact>: <section> — <a few words> — rec: <value>`;
  a `[sec]` finding gives its title only, no exploit detail.
- after a soft phase 2, the spec assumptions and checklist answer as today.

The accepted design findings are the `auto-applied` and `picked` ids: phase
7 gives the accepted `[sec]` ones to lens 7b, and the shipper lists them in
the PR body. `skipped` and `rejected` `D` findings are rejected findings in
the reviewer context, so later reviewers don't propose them again.

## §7 `docs/usage.md` example gate

```
## Phase 3–4: Plan and design review — needs your call
**What I did:** feat-design-reviewer ×3 on spec + plan: 4a (opus · medium), 4b (sonnet · medium), 4c (sonnet · high)
**How a fresh reader understood it:** … (check it against what you meant)
**What you should know:** D2 needs you
**Your call:**
1. D2 [cost] … — apply or leave? reviewer: drops FR-004, which the brief asked for
2. D1 [sec] … — rec: apply
3. D3 [design] plan says `config.Load` validates the file; it doesn't → validate in the new command — rec: apply
**Next:** phase 5 Tasks
```
