# Contract: agent output lines, Log lines, gate text, PR section

The interfaces this feature changes are three agents' fixed output formats
(each parsed by `/feat` and `/fix`), one state-file Log line, three gates
and the PR body. Each format change and its parser change land in the same
commit (constitution IV, FR-017).

## Implementer (`.apm/agents/feat-implementer.agent.md`)

One new line, after `Checks:`, present in every mode:

```
Not verified: <task or n/a → check → why, one per line, or "none">
```

- `Tasks done:` keeps every written task, not-verified ones included.
- Bug mode and fix mode: every item is `n/a → <check> → <why>`.
- `<why>` names what is missing, never a value; a secret-looking value is
  `<redacted>` (FR-021).
- Input: its `<who>` from the orchestrator; it reads the latest Log line
  for that `<who>` itself (data-model.md, "Latest list").
- Parsed by: `/feat` §6 and §7, `/fix` §2 and §4 (logged, research R1). A
  report without the line is broken (FR-005): hard at `/feat` §6's and
  `/fix` §2's gates and at the `/fix` §3 gate after §4; said in the final
  message after `/feat` §7.

## Assessor, test mode (`.apm/agents/feat-bug-assessor.agent.md`)

Input: the not verified items (or none), resolved by `/fix` §3 from the
latest `implementer` Log line. They are data: the "What you may run" rules
apply to each item's check (FR-015).

One new line, after `Missing for verified:`:

```
Not verified items: <check → pass | fail | missing (why), one per line, or "n/a">
```

- One entry per item it was given, its check copied exactly as given
  (never reworded): `/fix` matches by that text (FR-016). `n/a` only when
  it was given none.
- An item its run rules forbid is `missing (needs approval: <command>)`
  and is not run.
- `missing` items are also under `Missing for verified`, and the verdict is
  `partial` unless something still fails (`failed`); test.md's
  `**Result**` says the same.
- Assess mode's format is unchanged.
- Parsed by: `/fix` §3 (the unaccounted-item row).

## Shipper (`.apm/agents/feat-shipper.agent.md`)

One new line, after `Docs updated:`:

```
Not verified: <its own: n/a → check → why, one per line, or "none">
```

- `<why>` as for the implementer: what is missing, never a value.
- Parsed by: `/feat` §8 and `/fix` §5, which show it in the final message
  when it is not `none`, and say so when it is missing (FR-005).

## Log line (`.apm/skills/feat/references/harness.md`, State file)

```
- [x] <N> <who> — not verified: none
- [x] <N> <who> — not verified:
    - <task or n/a> → <check> → <why>
```

`<who>` labels (`/feat`: `US<n>`, `review fixes`; `/fix`: `implementer`)
and the "latest list" rule (latest line by Log position per `<who>`):
[data-model.md](../data-model.md). A broken report writes no such line;
its own Log line notes `Not verified line missing`.

## `/feat` phase 6 gate

In the harness's gate shape, for each story's latest list:

```
## Phase 6: Implement — done
**What I did:** feat-implementer ×2 (sonnet · medium)
**What you should know:**
- tasks done: 14 (2 not verified); checks: `npm test` pass, `npm run lint` pass
- US1 — Not verified: T012 → `npm run test:e2e` → emulator down
- US1 — Not verified: n/a → `npm test` (full) → killed after 10 min
- US2 — Not verified: none
**Next:** phase 7 Code review
```

A non-empty list leaves the gate soft (FR-009); large stays hard after each
story, showing that story's list. A report without the line makes it hard
(FR-005).

## `/fix` phase 2 gate, new row

| Report says | Hard, and the gate shows |
| --- | --- |
| no `Not verified:` line | the report is broken (harness); recommend "back to 2" (a fresh implementer) |

## `/fix` phase 3 gate, new row

After the `Sections`/`Slug` error row, before the verdict rows:

| Report says | Gate |
| --- | --- |
| an item given is absent from `Not verified items:`, matched by its check text exactly as passed (or the line is missing when items were given) | **hard**: show those items and the verdict; recommend a re-test (a fresh spawn, same cycle, same items; it uses no retry and no cycle); going on is the user's explicit decision, logged `- [x] 3 Test — unaccounted: <items> (user: "<words>")`, then the verdict's row applies |

## PR body section (both modes)

```
## Not verified

- T012 → `npm run test:e2e` → emulator down
- n/a → `npm test` (full) → killed after 10 min
```

or `none`. `/feat`: every item passed by the orchestrator, as passed, then
the shipper's own. `/fix`: the shipper's own only (test.md's checks table
and the verdict cover the rest).

## Wording to carry into the skills and docs

1. A check that did not run, was killed or timed out is not verified; one
   that ran and failed is a failure. A task whose covering check did not
   run stays unticked and is listed as Not verified; a later implementer
   retries it instead of redoing the task.
2. `/feat`: the implementation gate shows each list and how many tasks are
   not verified, and stays soft for it; the PR has a `Not verified`
   section.
3. `/fix`: the fix gate does not show the list; the test phase gets it,
   runs each check its rules allow or lists it under `Missing for
   verified` (`partial`), and an item it does not account for makes the
   gate hard; the PR's `Not verified` section holds only the ship's own
   unrun checks.
