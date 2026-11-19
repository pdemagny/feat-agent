# Quickstart: checking soft-design-gate

Run from the worktree root. Contracts: [contracts/phase4-gate.md](contracts/phase4-gate.md).

## 1. Checks (FR-015, SC-005)

```sh
mise run lint
mise run test:apm
mise run diagrams
git diff --exit-code docs/img/models.svg   # unchanged
git status --short docs/img                # only gates.svg and chain.svg changed
```

Expected: lint and test:apm pass; after committing, a second `mise run
diagrams` leaves `docs/img` clean (what the `check` workflow tests).

## 2. Text checks (SC-003, SC-004, FR-011, FR-012)

```sh
# SC-004: each of these four finds no match
grep -n 'above nice-to-have' .apm/skills/feat/SKILL.md
grep -n 'real finding\|finding above' docs/workflow.md README.md docs/usage.md
grep -n 'decide on the findings\|decide on findings,' docs/workflow.md README.md docs/usage.md docs/diagrams/gates.d2
grep -n 'decide on findings {' docs/diagrams/chain.d2
# a bare 'decide on' still matches phase 7 and /fix wording, which stays
grep -n 'rec: apply | skip' .apm/agents/feat-design-reviewer.agent.md   # three finding lines
grep -n 'widens access' .apm/agents/feat-design-reviewer.agent.md       # the user rule (FR-002)
grep -n 'I recommend' docs/usage.md                         # no match on a D finding
git diff --quiet origin/main -- .apm/skills/feat/references/harness.md .apm/skills/fix/SKILL.md .apm/agents/feat-code-reviewer.agent.md docs/diagrams/models.py
```

Expected: as commented; the last command exits 0.

## 3. Gate walk-through (US1–US4, SC-001, SC-002)

Read section 4 of `.apm/skills/feat/SKILL.md` against these reports and
check the gate it gives (no run needed):

| Case | Findings and report | Expected |
| ---- | ------------------- | -------- |
| A | small; D1 `[sec]` apply, D2 `[design]` high apply, D3 `[cost]` skip | soft; paraphrase, then line `3 findings, 2 applied, 1 skipped; security: D1`; D2 not named; Log `auto-applied D1, D2; skipped D3 (reviewer: "…")` |
| A2 | medium; D1 `[sec]` apply, D2 `[sec]` skip, D3 `[design]` apply | soft; line `3 findings, 2 applied, 1 skipped; security: D1; security skipped: D2` |
| B | medium; no findings | soft; `0 findings, 0 applied, 0 skipped`; no `SendMessage` to the planner, straight to phase 5; Log `auto-applied none` |
| B2 | small; D1 `[cost]` skip only | soft; `1 findings, 0 applied, 1 skipped`; no `SendMessage`, straight to phase 5 |
| C | medium; D1 apply, D2 `user (…)` | hard; D2 listed first as "apply or leave?"; bare "ok" → one follow-up naming D2 |
| D | small; all apply, planner assumption `needs user: yes` | hard |
| E | small; all apply, each of: constitution violation, blocker, size trigger, contradicting paraphrase, carried checklist item, missing `Wrote:` path | hard each time |
| F | medium; the same `[design]` spot (same artifact, identical section heading) twice with the same rec and fix; a `[sec]` and a `[design]` finding on one spot | the first pair kept once; the second pair stays two findings (different tags), each with its own rec |
| G | small; a finding with no rec (resumed old run) | `user (no valid recommendation)`, hard |
| H | large; all apply | hard; every finding with its rec |

## 4. Docs read-through (US5, FR-014)

`docs/workflow.md` row 4 and `### 4 Design review`, `docs/usage.md`
"Answering a gate", README chain alt text, and the two rendered SVGs say
the gate stops only for findings that need you, and that the reviewer, not
`/feat`, recommends.
