# Roadmap

Ideas measured or designed but not built. Timings come from two real runs
on a private project (223 and 140 minutes, medium to large, 4–5 stories each); see
the cost notes (since moved out) for the tool. Re-measure before taking any of these.

## Parallel stories in phase 6

Phase 6 is the biggest block (55–58 minutes in both runs): one implementer
per story, in turn. Independent stories could run together, under rules
that default to sequential:

- Setup and foundational tasks done first, as their own step.
- No dependency between the stories, disjoint files and directories (a Go
  package is a directory), and none touching a shared file: lockfiles and
  manifests, generated code, migrations, CI config, the shared test harness.
- Medium or large only, at most 3 at a time.
- `feat-tasker` computes the groups and reports
  `Parallel: US2 ∥ US3 (disjoint: …) | none (reason)`; the user can veto it
  at the tasks gate.
- Each implementer gets a file allowlist and runs only tests scoped to its
  own directories; one full check after the batch; the coordinator
  intersects the changed-file lists and goes sequential on any overlap.

Why it waits: in a private project's specs 029–033 almost every pair of stories
shares a file (`cmd/root.go`, `cmd/harness_test.go`), so it would rarely
fire where it matters.

## Smaller ideas

- **One design reviewer for small features** instead of security, cost and
  clarity-and-fit separately. Each review takes under 3 minutes, so the gain
  is two cold starts and some cost, not wall-clock time. Keep 4c's fresh
  reader apart from whatever reads the planner's report.
- **Why does the shipper take 7–12 minutes?** It is mostly git, a rebase and
  check reruns, and in one run it was spawned twice. Read that transcript
  first, then decide.
