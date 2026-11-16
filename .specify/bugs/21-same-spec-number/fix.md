# Bug Fix: Parallel /feat runs can ship the same spec number

- **Slug**: 21-same-spec-number
- **Fixed**: 2026-11-16
- **Assessment**: ./assessment.md
- **Status**: applied

## Summary

The shipper no longer infers taken spec numbers from open PR branch names alone: a new script, `.apm/skills/feat/scripts/spec-number.sh`, fetches `origin/<default>` first and counts `specs/NNN-*` on it, in every open PR's files (paginated REST, so PRs with more than 100 files count) and in open PR branch names. The shipper runs it in step 1 and again just before pushing (renumbering the unpushed commits on a clash), and no longer renames the branch.

## Changes

| File | Change | Notes |
|------|--------|-------|
| `.apm/skills/feat/scripts/spec-number.sh` | added | `next <default>` prints the next free number; `check <default> <NNN-name>` prints `keep NNN` or `renumber MMM`, ignoring the caller's own dir. Exit 1 on any git/gh failure (no guess), 2 on usage errors |
| `.apm/agents/feat-shipper.agent.md` | modified | step 1 calls the script, drops `git branch -m`; step 4 re-checks before push and renumbers with `git commit --fixup` + `git rebase --autosquash origin/<default>`; script failure → `PR: blocked` with `! spec-number: …`; fix mode skips both. Report format unchanged |
| `.apm/skills/feat/SKILL.md` | modified | phase 2 says how the shipper numbers and that the branch keeps its name; phase 8 passes the script path |
| `tests/spec-number/run.sh` | added test | 16 offline cases |
| `tests/spec-number/bin/gh` | added test | stub `gh`: `pr list` and `api .../pulls/<n>/files` from case files; without `--paginate` it serves only the first 100 files, like GitHub |
| `mise.toml` | modified | `test:spec-number` task, shellcheck of the new tests in `lint`, `test:apm` asserts the script lands |
| `docs/workflow.md` | modified | phase 2 branch is `<short-name>` (stale `<NNN>-` fixed), phase 8 describes the numbering |
| `docs/design.md`, `docs/usage.md`, `README.md` | modified | no more `<NNN>-<short-name>` branch; layout lists the script and tests |
| `CHANGELOG.md` | modified | entry under `## Unreleased` |

## Diff Highlights (optional)

```bash
files="$(gh api --paginate "repos/{owner}/{repo}/pulls/$pr/files" \
  --jq '.[].filename')" || die "gh api files of PR #$pr failed"
```

## Tests Added or Updated

- `tests/spec-number/run.sh` "unnumbered PR branch, numbered spec in its files": open PR #363 on branch `typed-config-value` with `specs/088-typed-config-value/` and 087 on main → `089` (the issue's "done when").
- "PR with more than 100 files": the spec paths come after 120 other files → still `089`.
- "highest on main plus one", "three digits roll over" (`099` → `100`), "no specs anywhere" (`001`).
- "numbered PR branch without spec files": branch names still count.
- "main moved after the clone": the script fetches before reading `origin/<default>`.
- "check: own number free", "check: own dir is not a clash with itself", "check: taken by an open PR meanwhile" (`renumber 089`), "check: taken on main meanwhile, PR holds a higher one" (`renumber 090`).
- "gh pr list fails", "gh api fails", "fetch fails": exit 1, empty stdout, error on stderr.
- "files outside specs/ dirs are ignored", "usage errors" (exit 2, gh never called).

## Local Verification

- Commands run: `mise run lint` → pass (shellcheck on install.sh, both scripts, both test dirs; plugin validate; harness grep); `mise run test:tracker` → pass; `mise run test:spec-number` → pass (16 cases); `mise run test:apm` → pass (`spec-number.sh` lands under `.claude/skills/feat/scripts/`).
- Manual checks: `install.sh` and the plugin ship whole skill dirs, so the new script is picked up like `tracker.sh` with no packaging change.

## Deviations from Assessment

- Per the user's answers: the branch rename is dropped (not optional); no check after `gh pr create`; why earlier shippers skipped `git branch -m` was not investigated.
- The re-check runs after the rebase and checks and before the push (not after the push), so a renumber only rewrites unpushed commits. The renumber uses `git commit --fixup` plus `git rebase --autosquash` (non-interactive autosquash needs git 2.44 or later) because `docs(specs)` is usually not the last commit.
- The script takes the default branch as an argument instead of detecting it; the shipper is already given it.
- Also fixed stale `<NNN>-<short-name>` branch mentions in `docs/design.md`, `docs/usage.md` and `README.md` (outside the assessment's file list, same behaviour change).

## Follow-ups

- Residual race: two shippers that both re-check before either PR is opened can still pick the same number; the window is seconds wide (accepted by the user).
- Run one real `/feat` ship with the new script (haiku shipper) and confirm it follows the `keep` / `renumber` output.

## Review fixes

- B1: `/feat` phase 8 (`.apm/skills/feat/SKILL.md`) tells a `!` command apart from a `!` error line: an error (`! spec-number: error: …` or another hard failure) is shown as an error, the state file stays at `Current phase: 8 Ship` for `/feat resume`. Mirrored in `docs/workflow.md` §8.
- B2: `git ls-tree --full-tree`, so the script works from any subdirectory (fetch and gh already did). Test "run from a subdirectory".
- B3: a PR's branch-name number counts only when its files hold no `specs/` dir. Test "numbered PR branch with spec files: branch ignored".
- B4: the shipper returns `! <the script's stderr line, as is>` (no doubled `spec-number:` prefix), in step 1 and step 4.
- Spec: `docs/install.md` requires git ≥ 2.44 (`rebase --autosquash`); the README lists no requirements.
- S1: numbers are 3–4 digits only (`^([0-9]{3,4})-`, own name too); fork PRs (`isCrossRepository`) are skipped before their files are fetched. The stub `gh` serves `<number> <isCrossRepository> <branch>` lines. Tests "fork PR ignored", "long-digit names ignored", "four digits count".
- C1: `highest` and `taken` replaced by one `numbers [skip]` helper plus `next_free`; C2: the own number is kept when the args are parsed.
- CHANGELOG's Unreleased entry updated (issue branches, forks, long numbers, git 2.44, error handling).
