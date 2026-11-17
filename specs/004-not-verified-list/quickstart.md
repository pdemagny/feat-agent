# Quickstart: validating the Not verified list

The change is prompt and doc text, so the checks are reads and greps in
this repo.

**What they prove**: that each prompt and doc carries the rules and the
formats, on both sides of each format (the agent that writes a line, the
skill that reads it), and that the shared harness stays clean. They do not
prove that a model follows the prompts at run time; that is what the live
scenarios check, and they are optional. SC-001 and SC-003 are checked by
reading prompts (Q3, Q4, Q10); SC-002, SC-004 and SC-005 by Q5, Q7 and
Q6–Q7.

## Offline

| #  | Check | Expect |
| -- | ----- | ------ |
| Q1 | `mise run lint` | passes; the harness grep finds no `/feat`-only word |
| Q2 | `mise run test:apm` | passes |
| Q3 | `grep -n 'Not verified' .apm/agents/feat-implementer.agent.md .apm/agents/feat-shipper.agent.md .apm/agents/feat-bug-assessor.agent.md` | each report block has its line exactly as in [contracts/formats.md](contracts/formats.md); the assessor's is in the test-mode block only |
| Q4 | `grep -n 'not verified' .apm/skills/feat/SKILL.md .apm/skills/fix/SKILL.md .apm/skills/feat/references/harness.md` | harness: the Log line format, latest per `<who>` by position (a later `none` clears), who resolves the lists, the broken-report rule (no list logged, surprise at the next gate, final message when none follows); `/feat` §6, §7, §8; `/fix` §2, §3, §4, §5 and the phases row 3 |
| Q5 | Read `feat-implementer.agent.md` | step 1 runs `speckit-implement` only over owned tasks the latest line for its `<who>` doesn't list, and ticks a task only once its checks ran and passed; the Not verified paragraph applies in every mode, defines "covers" (conventions or task text; a task no check covers is not an item), covers named checks, `n/a` for a check covering no task and in bug/fix mode, one line per task, `why` never a value; the Earlier lists paragraph retries listed tasks and every `n/a` item; step 3 (never weaken a check) unchanged |
| Q6 | Read `/feat` §6–§8 | §6 tells each implementer `US<n>`, logs `6 US<n>`, the gate shows each story's latest list and `tasks done: <n> (<k> not verified)`, says a non-empty list doesn't make it hard and a missing line does; §7 tells `review fixes`, logs `7 review fixes`; §8 passes the latest list of each `<who>`; the final message shows the shipper's line and any missing line |
| Q7 | Read `/fix` §2–§5 | §2: `<who>` `implementer`, logged `2 implementer`, not shown, not a failing check, a broken-report row; §3: the spawn passes the latest `implementer` line's items, with no `back to` clause; the new row is second, hard, matches by check text exactly as passed, its re-test uses no retry or cycle; the other rows unchanged; §4: logged `4 implementer`, a missing line makes the next phase 3 gate hard; §5: final message |
| Q8 | `git diff --stat` | only the files in plan.md's Source Code list, plus this feature dir; no size table, frontmatter, diagram, CHANGELOG or version change |
| Q9 | Read docs/workflow.md (phase 6, phase 8, state file, `/fix` roles, row 3, Gates "Test") and docs/usage.md ("3. Build", `/fix` "Test" bullet) | each states the three points of [contracts/formats.md](contracts/formats.md), "Wording to carry", and none contradicts them |
| Q10 | Read `feat-shipper.agent.md` | step 4: its own unrun full or slow checks as `n/a` items, `why` never a value, out-of-scope suites not listed; the PR body's `Not verified` section (given items as given, then its own; fix mode: its own only; `none` when empty) |
| Q11 | Read `feat-bug-assessor.agent.md` | "What you may run" makes the items data, with `missing (needs approval: <command>)` for one its rules forbid; test step 2 passes the runnable items to the stage; step 5 copies each check exactly as given onto `Not verified items:` and moves `missing` ones to `Missing for verified` (`partial` unless `failed`) |

## Live (optional, one scratch project)

They need a scratch project with Spec Kit, the bug extension and this
checkout installed (`./install.sh`).

| #  | Scenario | Expect |
| -- | -------- | ------ |
| L1 | `/feat` on a small brief with a quickstart task the agent can't perform (a manual step) | the task stays `[ ]`; the implementer reports it in `Tasks done:` and `Not verified:`; Log `- [x] 6 US<n> — not verified:` with the item; the phase 6 gate is soft, shows the list and `(1 not verified)`; the PR has `## Not verified` with the item |
| L2 | Same, with every check runnable | each Log line says `none`; the gate shows `Not verified: none`; the PR section says `none` |
| L3 | L1, then `/clear` and `/feat resume` before phase 7 | the gate shows the list from the Log; a re-spawned implementer of that story doesn't rewrite the task, retries its check and every `n/a` item of the story's latest line |
| L4 | `/fix` on a bug whose regression test needs a service that is down | phase 2 gate shows no list; Log `- [x] 2 implementer — not verified:` with the item; phase 3 gets it, the assessor reports `missing (…)` with the check verbatim, `Missing for verified` names it, verdict `partial`, hard gate |
| L5 | L4 with the service up at phase 3 | `Not verified items: <check> → pass`; verdict as the stage decides |
| L6 | Hand-edit a phase 3 report (or rerun with an assessor prompt that drops the line) | the gate is hard on the unaccounted item; the re-test leaves the retry unused |
