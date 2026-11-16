# Bug Verification: Parallel /feat runs can ship the same spec number

- **Slug**: 21-same-spec-number
- **Tested**: 2026-11-16
- **Assessment**: ./assessment.md
- **Fix**: ./fix.md
- **Result**: verified

## Summary

Second cycle, after the code-review fixes (B1-B4, Spec, S1, C1, C2). The original incident still does not reproduce: with an unnumbered open PR branch holding `specs/088-…` past its first 130 files, the next shipper gets 089 and a second shipper holding 088 is told `renumber 089`. Each review fix holds in an independent scratch run and in the 21 offline tests, the script still fails closed on git/gh errors, and lint, tracker, spec-number and apm checks pass. The shipper and `/feat` phase 8 are prompts (not run end to end): their wording was read, not executed. Cycle 1 report: ./test-1.md.

## Checks Performed

| Check | Command / Action | Result | Notes |
|-------|------------------|--------|-------|
| Reproduction (post-fix) | scratch `/tmp/fix21-verify/scratch2.sh` section A: local origin with `specs/087-old`, repo's stub `gh`, PR #363 on `typed-config-value` (not renamed), 131 files, `specs/088-typed-config-value/spec.md` last | pass | `next` → `089`; `check main 088-split-entry-lock` → `renumber 089`; owner's `check main 088-typed-config-value` → `keep 088` |
| Subdirectory (B2, `--full-tree`) | scratch B: same repo, cwd `src/deep`: `next`, `check 087-old`, `check 090-new` | pass | `089`, `keep 087`, `keep 090`; same answers as from the root (offline test "run from a subdirectory" also ok) |
| Issue-style branch (B3) | scratch C: PR #401 branch `370-foo`, files `README.md` only; PR #402 branch `380-bar` with `specs/088-bar/` | pass | #401 without spec files → `371` (branch counts); #402 alone → `089` (branch `380-bar` ignored because the PR has `specs/` files); both → `371` |
| Fork PRs (S1) | scratch D: PR #500 `isCrossRepository=true`, branch `300-forky`, `specs/250-forky/` in its files; logged `gh` argv | pass | `next` → `088`; the call log has no `pulls/500` request (files never fetched); with a same-repo PR #501 added only `pulls/501/files` is fetched → `089` |
| Long numbers (S1) | scratch E: PR branch `12345678901234567890-x`, spec dirs `99999999999999999999-big` (PR files and then on main) and `12345-five`; `check main 12345-x`; PR branch `1000-x` | pass | all ignored → `088`, exit 0, no arithmetic error; 5-digit own name → exit 2 `not a numbered spec dir name`; 4-digit `1000-x` counts → `1001` |
| Fail closed | scratch F: `gh pr list` fails, `gh api` fails, malformed `pr list` line, origin unreachable, unknown default branch, `gh` missing from PATH | pass | each exit 1, empty stdout, `spec-number: error: …` on stderr |
| Error line, no doubled prefix (B4) | scratch F7 plus read of `.apm/agents/feat-shipper.agent.md` steps 1 and 4 | pass | the script's line has one `spec-number:`; shipper returns `! <its stderr line, as is>` in step 1 and step 4 (the old "prefix it again" wording is gone) |
| /feat phase 8 treats the error line as an error (B1) | read `.apm/skills/feat/SKILL.md` §8 and `docs/workflow.md` §8 | pass (read only) | a `! cd <worktree> && git …` command → shown as is, state marked done; `! spec-number: error: …` or another hard failure → shown as an error, state not marked done, `Current phase: 8 Ship` kept for `/feat resume`. Mirrored in workflow.md. Not executed |
| docs/install.md git floor | `grep -n 2.44 docs/install.md` | pass | line 11: `git ≥ 2.44 … phase 8 renumbers with rebase --autosquash` |
| Real gh field names | `gh pr list -R <owner>/<repo> --state all --limit 3 --json number,isCrossRepository,headRefName --jq '…'` (read-only) | pass | prints `374 false fix-sync-orphans-environment` etc., so `isCrossRepository` exists and the script's `--jq` line format is what real `gh` gives |
| New / updated tests | `mise run test:spec-number` | pass | 21 cases ok (5 new: branch ignored with spec files, subdirectory, fork PR, long-digit names, four digits), "all spec-number tests passed" |
| Regression: tracker | `mise run test:tracker` | pass | exit 0 |
| Regression: APM | `mise run test:apm` | pass | exit 0 (agents 9, skills 6 land) |
| Lint | `mise run lint` | pass | exit 0: shellcheck, plugin validate, harness grep (README marketplace advice is not a failure) |

## Output Excerpts

```
test:spec-number: ok unnumbered PR branch, numbered spec in its files
test:spec-number: ok PR with more than 100 files
test:spec-number: ok numbered PR branch with spec files: branch ignored
test:spec-number: ok run from a subdirectory
test:spec-number: ok fork PR ignored
test:spec-number: ok long-digit names ignored
test:spec-number: all spec-number tests passed
A1: rc=0 out=[089]      A2: rc=0 out=[renumber 089]
B : rc=0 out=[089]      (cwd src/deep)
D1: rc=0 out=[088]      (no pulls/500 call logged)
E1: rc=0 out=[088]      E3: rc=2 not a numbered spec dir name: 12345-x
F1: rc=1 out=[] err=[HTTP 502 / spec-number: error: gh pr list failed]
```

## Residual Risks

- The shipper (haiku, a prompt) and `/feat` phase 8 were not run end to end; the fix.md follow-up (watch one real `/feat` ship) stands.
- When `git` or `gh` fails, stderr holds the tool's own lines (`HTTP 502`, `fatal: …`) before the `spec-number: error: …` line. The shipper prompt says "its stderr line, as is": a model that takes the first line instead of the `spec-number: error:` one would return a different `!` line. Phase 8 still treats any `!` line that is not a command as an error only if it recognises it as one; consider wording the shipper step as "the stderr line that starts with `spec-number: error:`".
- Two shippers that both re-check before either PR is opened can still pick the same number (seconds-wide window, accepted by the user).
- Tests use a stub `gh`; the real `gh api --paginate` was checked in cycle 1 against the private project, and the `pr list` field names this cycle, but not a run of the script against a repo with live open PRs.
- git older than 2.44 (the documented floor) was not tried; scratch runs used git 2.53.0.

## Recommendation

Close the bug as verified: the original scenario stays fixed and every review fix holds. Optionally tighten the shipper's wording on which stderr line to return (see Residual Risks), and watch the first real `/feat` ship.
