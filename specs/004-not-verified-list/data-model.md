# Data model: Not verified list

All of it is text: report lines, state-file Log lines, a PR body section.
Exact formats are in [contracts/formats.md](contracts/formats.md).

## Not-verified item

| Field | Value |
| --- | --- |
| task | a task ID of tasks.md, or `n/a` (a check covering no single task; every item in bug and fix mode; every shipper item) |
| check | the command, suite or manual step that did not run, as the agent ran or would have run it; downstream copies keep it verbatim |
| why | free text naming what is missing: no credentials, service down, too slow, manual step, killed, timed out, …; never a value (a secret-looking one is `<redacted>`, FR-021) |

Written `<task> → <check> → <why>`, one per line. Several tasks left
unproven by one check: one line each, same check.

Rules:
- A check that did not run, was killed or timed out → an item (FR-001).
- A check that ran and failed → a failing check, never an item (FR-020).
- A check covers a task when the project's conventions or the task's text
  tie it to that task (a test the task writes or names, a suite the
  conventions run for the files it changes). A task is an item when a
  check covering it, or one it names itself (a manual quickstart step),
  did not run; a task no check covers is not an item (FR-002).

## Lists

| Where | Line | Empty | Holds |
| --- | --- | --- | --- |
| implementer report (every mode) | `Not verified:` | `none` | its items |
| assessor report, test mode | `Not verified items:` | `n/a` (given none) | each item given → `pass`, `fail` or `missing (<why>)`, its check copied exactly as given; `missing (needs approval: <command>)` for one its run rules forbid (FR-015) |
| shipper report (both modes) | `Not verified:` | `none` | its own items only |
| PR body (both modes) | `## Not verified` section | `none` | `/feat`: every item of the latest list per `<who>` and the shipper's own; `/fix`: the shipper's own only |

An implementer or shipper report without its line is broken, not an empty
list (FR-005; see Gates touched).

## Log line (state file)

```
- [x] <N> <who> — not verified: none
- [x] <N> <who> — not verified:
    - <task or n/a> → <check> → <why>
```

One per implementer report, `none` included (research R1). A broken report
(no `Not verified:` line) writes none; its own Log line notes `Not verified
line missing`.

| Skill | `<N>` | `<who>` |
| --- | --- | --- |
| `/feat` | 6 | `US<n>` (one per story; its retry and a resume included) |
| `/feat` | 7 | `review fixes` |
| `/fix` | 2, 4 | `implementer` (every implementer of the run: the fix, its retry, the review fixes) |

The orchestrator tells each implementer its `<who>`.

**Latest list**: the latest line for a `<who>`, by Log position, is its
list; a later `none` clears earlier items (research R1, R3).
- `/feat` phase 6 gate: the latest list of each story.
- `/feat` phase 8: the latest list of each story and of `review fixes`,
  resolved by the orchestrator; their items go to the shipper (none if all
  say `none`).
- `/fix` phase 3: the latest `implementer` list, resolved by the
  orchestrator; its items go to the assessor (none if it says `none` or
  there is none).
- A re-spawned implementer: the latest line for its own `<who>`, read by
  itself (research R4).

## Task state in tasks.md

```
written, checks ran and passed (or no check covers it) → [x]
written, a covering check didn't run                   → [ ]  in Tasks done: and Not verified:
not written                                            → [ ]  in Tasks not done:
```

On an implementer whose `<who>` has a Log line (a retry after failing
checks, a resume, every `/fix` implementer after the first),
`speckit-implement` runs only over its tasks that line doesn't list. Each
listed task:
- the check now runs and passes → `[x]`, off the list;
- it still cannot run → stays `[ ]`, stays on the list;
- it runs and fails → a failing check (implementer step 2: fix it, rerun).

Each `n/a` item of that line: retried; listed again unless its check now
runs and passes (FR-006).

The user may run the check and tick the task by hand; nothing in the
workflow does it for them.

## Gates touched

| Gate | Change |
| --- | --- |
| `/feat` phase 6 | shows each story's latest list (`Not verified: none` when empty) and `tasks done: <n> (<k> not verified)`; a non-empty list leaves it as it was (not a surprise) |
| `/fix` phase 2 | does not show the list; an item is not a failing check |
| `/fix` phase 3 | new row after the error row: an item given but absent from `Not verified items:` (matched by its check text exactly as passed) → **hard**; its re-test uses no retry and no cycle |
| the gate after an implementer report without its `Not verified:` line (`/feat` 6, `/fix` 2, `/fix` 3 after phase 4's review fixes) | a surprise (harness soft-gate rule): **hard** |
| no gate follows (`/feat` phase 7 implementer, the shipper in both skills) | a missing line is said in the final message |
