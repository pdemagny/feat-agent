# Research: Not verified list

No `NEEDS CLARIFICATION` was left in the Technical Context. The decisions
below are the ones the spec left to the plan, amended after the design
review (D1–D11).

## R1. One Log line per implementer report, `none` included; latest per `<who>`

- **Decision**: every implementer report gets one Log line,
  `- [x] <N> <who> — not verified: none`, or the same line ending in
  `not verified:` with one indented item per line. The latest line for a
  `<who>`, by Log position, is that implementer's list: a later `none`
  clears earlier items. One rule, used by every reader (FR-007).
- **Rationale**: logging `none` too is what makes "the latest list"
  correct. Without it, a retry or a review-fix implementer that proves
  everything would leave an older list as the latest one, and `/fix` phase
  3 would ask the assessor to rerun checks that already passed. No special
  case for "a re-spawn that clears a list". It also lets resume show
  `Not verified: none` for each story at the phase 6 gate (FR-008).
- **Alternatives considered**: log non-empty lists only, plus a `none` line
  only when a re-spawn clears a logged list (two rules for the same thing);
  write the lists only at the gate (lost on a resume mid-phase, so US2 could
  not read them); scope `/fix`'s latest line to "after the last `back to`
  line" (a second rule that conflicts with the first: a "back to 3" re-test
  would get no items; dropped at the design review, D9).

## R2. The logging rule lives in `references/harness.md`

- **Decision**: one paragraph in the harness's State file section: the Log
  line format, "the latest line per `<who>` wins", who resolves the lists
  (the skill for the agents it passes them to, the implementer for its own
  `<who>`), and the broken report: no list logged, `Not verified line
  missing` noted in its own Log line, a surprise at the next gate, or said
  in the final message when no gate follows (FR-005). Each skill says what
  `<who>` is and when it reads the lists.
- **Rationale**: constitution III ("rules both skills share MUST live once,
  in harness.md"). The text is a state-file rule, not a report format
  (FR-019), and uses no word the lint grep refuses (`specifier`, `planner`,
  `tasker`, `spec.md`, `brief`, `phase <digit>`, `/feat`). A broken report
  logs no list so the latest list stays the last real one; the note in its
  own Log line lets resume still flag it.
- **Alternatives considered**: the same sentences in both skills (a shared
  rule written twice, which constitution III rules out); log a broken
  report as a list line (it would replace the earlier list of its `<who>`
  with nothing).

## R3. `<who>` labels

- **Decision**: the Log line is `<N> <who>`, `<N>` the phase, `<who>` the
  key the latest rule groups by. `/feat`: `US<n>` per story (phase 6, its
  retry and a resume included), `review fixes` (phase 7). `/fix`:
  `implementer` for every implementer of the run (phase 2's fix, its
  retry, phase 4's review fixes), so lines read `2 implementer` and
  `4 implementer`. The orchestrator tells each implementer its `<who>`.
- **Rationale**: in `/fix` each implementer works on the same fix and
  carries over the earlier one's items (FR-006), so one `<who>` makes the
  latest line the whole list (D9). In `/feat` stories are separate and the
  phase 7 review fixes are separate from them; the shipper gets the latest
  of each. Passing `<who>` costs one word per spawn and saves the
  implementer, a shared agent, from knowing either skill's labels.
  `4 implementer` does not contain `4 Code review`, which `/fix` uses to
  tell the first test cycle, and no label starts with a verdict word.

## R4. Who reads the lists

- **Decision**: the implementer reads the latest Log line for its own
  `<who>` (it already gets the state file path; US2). The orchestrator
  resolves the lists for the shipper (`/feat` §8: the latest line of each
  story and of `review fixes`) and the assessor (`/fix` §3: the latest
  `implementer` line) and passes the items in the spawn prompt (kept at
  the design review, D3).
- **Rationale**: the orchestrator writes the lines and knows the `<who>`
  labels, so it applies "latest per `<who>`"; the shipper and the assessor
  then take a plain list and carry no Log-reading rule, and the shipper in
  fix mode needs none at all. The passed list is the Log's resolved
  result, not a second record. The cost is the items' few lines in two
  spawn prompts.
- **Alternatives considered**: the shipper and the assessor read the Log
  themselves (a smaller orchestrator context, but each would need the
  latest rule and the labels; rejected at the design review, D3); the
  orchestrator also copies the implementer's line into its spawn prompt
  (the implementer already reads the Log; a second path for the same
  fact).

## R5. Covered tasks, ticking and the re-spawn

- **Decision**: a check covers a task when the project's conventions or
  the task's text tie it to that task (a test the task writes or names, a
  suite the conventions run for the files it changes); a task no check
  covers is not an item (D10, FR-002). A task is ticked once it is written
  and its checks ran and passed. `speckit-implement` ticks tasks as it
  writes them, so the implementer unticks a task whose covering check then
  could not run. An implementer whose `<who>` has a Log line runs
  `speckit-implement` only over its tasks that line doesn't list (none
  left: it skips the skill), retries each listed task's check, and retries
  every `n/a` item, listing it again unless it now runs and passes (D4,
  D5, FR-006).
- **Rationale**: FR-004, SC-002. Unticked is the honest state, and
  `speckit-converge` seeing the task open is intended (spec Assumptions).
  Without the skip, `speckit-implement` would pick up the unticked listed
  tasks as undone and rewrite them; without the `n/a` carry-over, a
  re-spawned implementer's `none` would clear an unrun suite it never
  retried.

## R6. The assessor feeds the items to `speckit-bug-test`, as data

- **Decision**: the items are data to the assessor: its "What you may run"
  rules (untrusted author, no network, no paths outside the worktree,
  approved commands only) apply to each item's check; an item needing
  anything else is `missing (needs approval: <command>)` and is not run
  (D1). It passes the items it may run to the stage as checks it must run
  and record in `## Checks Performed` (`not-run` with the reason when it
  still cannot), the others as `not-run` (needs approval). It then reports
  each on `Not verified items:`, its check copied exactly as given (D8); one
  still not run goes under `Missing for verified`, and the verdict, in the
  report and in test.md's `**Result**`, is `partial` unless something
  still fails (`failed`). One that runs and fails is a failing check, as
  the stage already treats it.
- **Rationale**: the check text reached the implementer partly from the
  report and assessment.md, so it gets the same trust rules as the report
  itself. The stage already calls an inconclusive check `partial` (its
  "Judge the outcome" step), so test.md's checks table records the items
  and agrees with the report. `failed` outranks `partial`, as in the
  stage. No verdict or gate rule changes (FR-016). A verbatim copy lets
  `/fix` match items by plain text, with no judgement in the orchestrator.
- **Alternatives considered**: the assessor runs the items outside the
  stage (test.md would not show them, and the shipper's PR body quotes
  test.md's checks table); match by a normalised check (a judgement the
  thin orchestrator should not make).

## R7. `/fix` phase 3: an unaccounted item

- **Decision**: a gate row right after the `Sections`/`Slug` error row:
  an item passed but absent from `Not verified items:` (matched by its
  check text exactly as passed), or the line itself missing when items
  were given → **hard**, showing those items and the verdict, recommending
  a re-test (fresh spawn, same cycle, same items). The re-test logs no
  `3 Test — failed` line, so it uses no retry and no cycle: no code changed
  (D8). Going on instead is the user's explicit decision, logged as
  `- [x] 3 Test — unaccounted: <items> (user: "<words>")`; then the
  verdict's row applies.
- **Rationale**: FR-016 asks only that the gate be hard. Treating it like
  the existing error row (a report the assessor got wrong) keeps the other
  rows untouched. The logged line does not start with a verdict word, so
  the shipper's "last `3 Test — <verdict>` line" still finds the verdict.

## R8. The shipper's own items

- **Decision**: a full or slow check the shipper should have run and could
  not, or that was killed or timed out, is `n/a → <check> → <why>` on its
  `Not verified:` line and in the PR's `Not verified` section, `<why>`
  naming what is missing, never a value (D2, FR-021; the implementer's
  items follow the same rule). A suite the conventions leave out of scope
  for this change is not listed. The report line holds its own items only
  (the orchestrator already has the logged ones). `/feat` and `/fix` show
  that line in their final message when it is not `none`, and say so when
  it is missing (FR-005).
- **Rationale**: FR-012; a suite out of scope did not need to run, so it
  proves nothing missing. The PR body is public once pushed, so a `why`
  must never carry a secret. Showing the line in the final message is what
  makes the orchestrator side of the new report line real (FR-017,
  constitution IV), at the cost of one clause per skill.

## R9. The phase 6 count

- **Decision**: "tasks done: <n> (<k> not verified)", `k` counting task
  items only; `n/a` items are shown in the lists but are not tasks.
- **Rationale**: FR-008 says "how many of them", them being tasks.

## R10. Where the docs say it

- **Decision**: `docs/workflow.md`: phase 6 details and its row in Phases
  at a glance, phase 8 details, the state file paragraph, and in `/fix`
  the roles (shipper), the phases row 3 and the Gates "Test" bullet.
  `docs/usage.md`: one paragraph in "3. Build" (the phase 6 gate and the
  PR body, since usage.md has no per-phase gate list for `/feat`) and the
  `/fix` "Test" bullet (test phase and its PR body).
- **Rationale**: FR-018 names the three places; usage.md describes `/feat`'s
  gates only in general, so the Build section is where a reader looks.
