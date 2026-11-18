# Bug Assessment: speckit-analyze cannot find the unnumbered spec dir, and the phase 5 gate hides it

- **Slug**: 14-speckit-analyze-unnumbered
- **Created**: 2026-11-18
- **Source**: pdemagny/logistics#14 — https://github.com/pdemagny/logistics/issues/14 (host: github.com; allowlisted; read with `gh issue view`, no further pages fetched)
- **Verdict**: valid
- **Severity**: medium

## Report (verbatim or summarized)

> **speckit-analyze fails on the unnumbered spec dir**
>
> ## Problem
> `/feat` keeps the spec dir unnumbered until ship (`specs/<short-name>/`), and Spec Kit's analyze script cannot resolve such a dir (it also failed under a worktree guard). In 8 real runs the tasker could not run speckit-analyze and cross-checked spec, plan and tasks by hand instead; the gate did not make that clear.
>
> ## Done when
> - The tasker runs analyze against the unnumbered feature dir explicitly (or the prerequisite script is given the dir).
> - If analyze still cannot run, the report says so and the phase 5 gate is hard.

Report author: OWNER.

## Symptom

In `/feat` phase 5, `feat-tasker` runs `speckit-analyze`, whose first step (`.specify/scripts/bash/check-prerequisites.sh --json --require-spec --require-tasks --include-tasks`) fails to resolve the feature dir `specs/<short-name>/`, so analyze never runs; the tasker falls back to a manual cross-check, and neither its report nor the phase 5 gate says so. Expected: analyze runs against the unnumbered dir, or, when it cannot, the report says it did not run and the gate is hard.

## Reproduction

Run in the worktree with no `.specify/feature.json` and no `SPECIFY_FEATURE_DIRECTORY` (the tasker's situation when nothing hands the dir to the script):

1. `.specify/scripts/bash/check-prerequisites.sh --json --require-spec --require-tasks --include-tasks`
   Output:
   ```
   ERROR: Feature directory not found. Set SPECIFY_FEATURE_DIRECTORY or run the specify command to create .specify/feature.json.
   ERROR: Failed to resolve feature paths
   ```
   exit 1 — reproduced.
2. Control: with a scratch unnumbered dir (`/tmp/fix14/specs/some-feature/` holding non-empty spec.md, plan.md, tasks.md):
   `SPECIFY_FEATURE_NO_PERSIST=1 SPECIFY_FEATURE_DIRECTORY=/tmp/fix14/specs/some-feature .specify/scripts/bash/check-prerequisites.sh --json --require-spec --require-tasks --include-tasks`
   Output: `{"FEATURE_DIR":"/tmp/fix14/specs/some-feature","AVAILABLE_DOCS":["tasks.md"]}`, exit 0, and `git status` shows no `.specify/feature.json` written.

So the script has no trouble with an unnumbered name; it fails only because it is not told which dir to use. The failure "under a worktree guard" in the report was not reproduced here [NEEDS CLARIFICATION: which command the guard refused — an env-prefixed command, or the skill's own `$(…)`-style invocation].

## Suspected Code Paths

- `.specify/scripts/bash/common.sh:get_feature_paths()` (~line 163) — resolves the feature dir only from `SPECIFY_FEATURE_DIRECTORY` or `.specify/feature.json`; otherwise errors. No branch-name or `specs/` scan fallback. (Vendored Spec Kit; not to be patched.)
- `.claude/skills/speckit-analyze/SKILL.md` step 1 — calls `check-prerequisites.sh` and aborts when it fails.
- `.claude/skills/speckit-specify/SKILL.md` step 3 — auto-generates `specs/<NNN>-<short-name>` and writes `.specify/feature.json` unless `SPECIFY_FEATURE_DIRECTORY` is given explicitly; `.specify/feature.json` is gitignored (`.specify/.gitignore`), so it is per-checkout and may be missing or point at another dir.
- `.apm/agents/feat-specifier.agent.md` step 1 — passes the short name, not `SPECIFY_FEATURE_DIRECTORY=specs/<short-name>`, so nothing guarantees `feature.json` names the unnumbered dir.
- `.apm/agents/feat-tasker.agent.md` steps 2–4 and its report — runs `speckit-analyze` without handing it the feature dir, and the report has no line saying whether analyze ran.
- `.apm/skills/feat/SKILL.md` `## 5. Tasks` (~line 296) and the gate table row 5 (~line 132) — the hard-gate conditions don't include "analyze did not run".
- `docs/workflow.md` lines ~36, ~257 — mirror phase 5's description and gate.

## Root Cause Hypothesis

Since `e4a7003` (`fix(feat): number the spec dir at ship time`) the feature dir is `specs/<short-name>/`, but nothing in the tasker's (or specifier's) instructions makes Spec Kit's resolver point at it: the resolver needs `SPECIFY_FEATURE_DIRECTORY` or a `.specify/feature.json` naming the dir, and the tasker supplies neither, so `check-prerequisites.sh` exits 1 and `speckit-analyze` aborts. The tasker's report format has no field for "analyze did not run", so its manual cross-check reaches the orchestrator as a normal result and the phase 5 gate stays soft. Confidence: medium — the resolver failure is reproduced and an explicit dir is shown to work; whether the real runs lacked `feature.json` or had a stale one, and what the worktree guard refused, is not confirmed.

## Proposed Remediation

**Preferred**: Hand the dir to the script and surface failure.
1. `feat-tasker.agent.md`: tell the tasker to run `speckit-analyze` (and `speckit-tasks`, which resolves the same way via `setup-tasks.sh`) with the feature dir given explicitly — the prerequisite script called as `SPECIFY_FEATURE_DIRECTORY=<absolute feature dir> SPECIFY_FEATURE_NO_PERSIST=1 .specify/scripts/bash/check-prerequisites.sh …`, a plain command with no `$(…)` so the worktree guard accepts it. Add a report line `Analyze: ran | not run (<error>; cross-checked by hand)`.
2. `.apm/skills/feat/SKILL.md` phase 5: hard gate when `Analyze:` is `not run` (or the line is missing), shown under "What you should know"; update gate table row 5.
3. `docs/workflow.md`: mirror the gate row and the phase 5 paragraph.

**Alternatives**:
- Have `feat-specifier` pass `SPECIFY_FEATURE_DIRECTORY=specs/<short-name>` to `speckit-specify` so `.specify/feature.json` names the unnumbered dir for every later skill (plan, tasks, analyze, implement). Fixes the whole chain in one place, but `feature.json` is gitignored and per-checkout, so a resume in another checkout or a later feature in the same worktree can leave it stale; best combined with the preferred fix, not instead of it.
- Patch `check-prerequisites.sh`/`common.sh` to fall back to `specs/<branch>/` — rejected: vendored Spec Kit files, overwritten on refresh.

**Files likely to change**:
- `.apm/agents/feat-tasker.agent.md`
- `.apm/skills/feat/SKILL.md`
- `docs/workflow.md`
- (alternative) `.apm/agents/feat-specifier.agent.md`

**Tests to add or update**:
- `mise run lint` and `mise run test:apm` stay green.
- If `mise run lint` (or `test:apm`) checks agent report formats against the orchestrator, extend it so the tasker's `Analyze:` line and the phase 5 gate's reading of it stay in sync.
- Manual check: in a worktree with no `feature.json`, the tasker's documented command resolves `specs/<short-name>/` (as in Reproduction step 2).

## Risks & Considerations

- Report-format contract: the tasker's report and `/feat`'s phase 5 reading change together (`.claude/CLAUDE.md`).
- `/feat` stays thin: the orchestrator only reads the new line; running the script is the tasker's job.
- `SPECIFY_FEATURE_NO_PERSIST=1` avoids rewriting `feature.json`; without it the script persists the env value, which is harmless (gitignored) but changes per-checkout state.
- The same resolver gap may affect `feat-planner` (`setup-plan.sh`) and `feat-implementer` (`check-prerequisites.sh --require-tasks`); the report only names analyze.
- No `/feat`-only words may be added to `.apm/skills/feat/references/harness.md` if anything shared is touched.

## Open Questions

- [NEEDS CLARIFICATION: what exactly the worktree guard refused in the real runs — the fix assumes an env-prefixed plain command is accepted.]
- [NEEDS CLARIFICATION: should the fix also cover `speckit-plan`/`speckit-tasks`/`speckit-implement` (planner, tasker, implementer), which resolve the dir the same way, or only analyze as the issue asks?]
- [NEEDS CLARIFICATION: in the 8 runs, was `.specify/feature.json` missing or pointing at another dir? Either way the preferred fix covers it.]
