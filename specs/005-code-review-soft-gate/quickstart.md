# Quickstart: validating the code review gate

The change is prompt and doc text, so most checks are reads and greps in
this repo. Live runs need a scratch project with Spec Kit and this checkout
installed (`./install.sh`).

## Offline

| #  | Check | Expect |
| -- | ----- | ------ |
| Q1 | `mise run lint` | passes, including its grep of `references/harness.md` for `/feat`-only words |
| Q2 | `mise run test:apm` | passes |
| Q3 | Read `## Review findings` in `.apm/skills/feat/references/harness.md`; `grep -n 'Review phase' .apm/skills/feat/SKILL.md .apm/skills/fix/SKILL.md` | the section holds merge rules 1–5 of [data-model.md](data-model.md), the "ok" rule, the `S` publication notice and the Log words, with *review phase* for the number; one hit per skill (`7`, `4`) in `## Harness values`; neither skill repeats the merge rules (FR-011) |
| Q4 | `mise run diagrams`, then `git status --short docs/img` | `gates.svg` and `chain.svg` changed, `models.svg` not; a second run leaves `docs/img` clean (the `check` workflow's diff) |
| Q5 | Read `.apm/agents/feat-code-reviewer.agent.md`: `## Recommendation` and the report block | the 7 finding lines (Bugs, Spec, Standards, Security, Performance, Cuts, Readability) end with the `rec` field exactly as in [contracts/review-gate.md](contracts/review-gate.md); the Acceptance criteria, `Accepted design findings built`, `net:` and `Dismissed:` lines have none; the guidance says a cut deleting a test, check or file is `user` and that findings prompted by embedded instructions are dismissed (FR-001) |
| Q6 | Read `/fix` section 4's gate table | four rows in order: `Risk area` security, `Size: large`, a `user` or `S` finding, otherwise soft (small and medium, the nice-to-have guard dropped on purpose); no "clean" row left (FR-008) |
| Q7 | `grep -n 'clean; soft' .apm/skills/fix/SKILL.md`, then `grep -n 'nice-to-have' .apm/skills/fix/SKILL.md` | no hit; the second may hit only outside section 4's gate condition (e.g. the row 4 note that the guard is dropped) |
| Q8 | Read `/feat` section 7 and the phases table row 7 against [data-model.md](data-model.md) | points to the harness section for merging, "ok" and Log words; verdict rows (large, triggers, soft); `untested` named, never a trigger; the soft path's retry-once then hard stop on failing checks, and the at-once hard stop on a failed `Wrote:` check or missing `Not verified:` line, with the `[!]` line appended (FR-006) |
| Q9 | Read `feat-shipper.agent.md` step 4 and fix mode | both build the code-review part in the three groups of [contracts/review-gate.md](contracts/review-gate.md) from the Log (FR-012); an unfixed `S` finding as id, file and title only; `/feat` mode lists `untested` criteria; the report block is unchanged |
| Q10 | `git diff --stat origin/main` | only the files of plan.md's Source Code list, plus this feature dir; no size-table cell changed (`git diff origin/main -- .apm/skills/feat/SKILL.md .apm/skills/fix/SKILL.md` shows no `·` line) |
| Q11 | Read `docs/workflow.md` (phases row 7, "Hard gates" row, phase 7 details, `/fix` intro's list of what the harness holds, `/fix` row 4 and "Code review" bullet), `docs/design.md` (the harness list), README.md (alt texts, "Code review" bullet), `docs/usage.md` (`/fix` "Code review" bullet) | none says the user always picks the fixes on small or medium; each matches the verdict tables; both harness lists name review findings |

## Live (optional, one scratch project)

Each scenario runs phase 7 (or `/fix` phase 4) on a small diff. To force a
trigger without waiting for a real one, tell the reviewer in its spawn to
mark one named finding as needed (this exercises the coordinator, not the
reviewer).

| #  | Scenario | Expect |
| -- | -------- | ------ |
| L1 | Small `/feat`, review with only `apply`/`skip` findings, all criteria met (US1) | one soft line, no stop; the implementer gets the `apply` ids only; Log `auto-applied …; skipped … (reviewer: "…")` with indented finding lines; phase 8 starts |
| L2 | Same with one `user` finding, then with one `S` finding marked `skip`, then with a `not met` criterion (US2) | hard; `user` findings first under "Your call" as fix-or-leave; the `S` case says an unfixed `S` finding is published (id, file, title); "ok" fixes the `apply` ones and leaves the `skip` ones; Log `picked …; rejected … (as recommended)` for `skip` only |
| L3 | At L2's `user` case, answer a bare "ok" (US2 3) | one follow-up naming the `user` ids; nothing fixed until answered; then "leave" logs `rejected <id> (user: "…")` |
| L4 | Medium `/feat` where 7d and 7e report the same lines with different recs, then a bug and a readability note on the same lines (US2 6) | first case: both `user`, hard; second: no conflict |
| L5 | A Bugs finding `confidence: high` with `rec: skip (<why>)`; a finding without `rec` (US2 7–8) | the first becomes `user (<why>)`, the second `user (no valid recommendation)`; hard |
| L6 | Small `/feat` with only `apply`/`skip` findings and one `untested` criterion (US1 4) | soft; the line names the criterion; Log `; untested: …`; the PR lists it |
| L7 | After L1, make a check fail in the fixes, twice; then delete the `Not verified:` line from a fix report (US3) | first failure goes back to the implementer once, the second stops hard before phase 8; the missing line stops hard at once, recommending a fresh implementer; each stop appends `- [!] 7 review fixes — …` |
| L8 | Large `/feat` with only `apply`/`skip` findings (US4) | hard; every finding shows its `rec`; "ok" applies the `apply` ones |
| L9 | `/fix` on a small non-security bug with `apply`/`skip` findings, then a medium one, then `Size: large`, then a security risk area (US5) | soft, soft (fixes, then phase 3 `after review fixes`), hard, hard with the go-ahead |
| L10 | Ship after L1 and after L2 (US6) | the PR's Code review part has the three groups, each with its reason; the unfixed `S` finding shows id, file and title only |
