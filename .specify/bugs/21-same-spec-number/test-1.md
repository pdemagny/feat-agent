# Bug Verification: Parallel /feat runs can ship the same spec number

- **Slug**: 21-same-spec-number
- **Tested**: 2026-11-16
- **Assessment**: ./assessment.md
- **Fix**: ./fix.md
- **Result**: verified

## Summary

The incident no longer reproduces: with main at 087 and an open PR whose branch was never renamed (`typed-config-value`) holding `specs/088-…` past the first 100 of its files, the new script gives the next shipper 089, and `check` tells a second shipper holding 088 to renumber to 089. The script fails closed (exit 1, empty stdout) on every git/gh failure tried, and lint, tracker, spec-number and apm checks all pass. The shipper's own behaviour (a prompt followed by a model) was not run end to end.

## Checks Performed

| Check | Command / Action | Result | Notes |
|-------|------------------|--------|-------|
| Reproduction (post-fix) | scratch scenario `/tmp/fix21-verify/scratch.sh`: local origin with `specs/087-old`, repo's stub `gh`, PR #363 `typed-config-value` with 131 files, `specs/088-typed-config-value/spec.md` last | pass | `next` → `089` (before the PR existed: `088`); `check main 088-split-entry-lock` → `renumber 089`; the owner's own check `088-typed-config-value` → `keep 088`; with a second unnumbered-branch PR holding 089, `next` → `090` |
| Live API shape (read-only gh, private project) | `gh api --paginate repos/<owner>/<repo>/pulls/363/files` vs `gh pr view 363 --json files` | pass | paginated REST lists 141 files incl. `specs/088-typed-config-value/…`; the `--json files` route returns only 100 (the cap the script avoids). The PR is merged, so the script cannot be replayed live against open PRs |
| Fail closed | scratch: `gh api` fails, `gh pr list` fails, origin unreachable, unknown default branch, `gh` missing from PATH | pass | each exit 1, empty stdout, `spec-number: error: …` on stderr; no number printed |
| Argument validation | scratch: `next 'main;touch …'` | pass | exit 2 `bad branch name`, nothing executed |
| Renumber mechanics | scratch `/tmp/fix21-verify/autosquash.sh`: `git mv`, `git commit --fixup=<docs(specs) hash>`, `git rebase --autosquash origin/main` (no -i), git 2.53.0 | pass | fixup folded into `docs(specs)`, tree has `specs/090-x/` only. The git ≥ 2.44 floor was not tested on an older git |
| New tests | `mise run test:spec-number` | pass | 16 cases ok, including the issue's "done when" cases and the >100-file case |
| Regression: tracker | `mise run test:tracker` | pass | exit 0 |
| Regression: APM | `mise run test:apm` | pass | exit 0; asserts `spec-number.sh` lands in `.claude/skills/feat/scripts/` |
| Lint / type-check | `mise run lint` | pass | exit 0: shellcheck (install.sh, scripts, both test dirs), py_compile, `claude plugin validate .` (advice only: README has no marketplace install line), harness grep |

## Output Excerpts

```
test:spec-number: ok unnumbered PR branch, numbered spec in its files
test:spec-number: ok PR with more than 100 files
test:spec-number: ok gh pr list fails / gh api fails / fetch fails
test:spec-number: all spec-number tests passed
scratch 2: rc=0 out=[089]
scratch 3: rc=0 out=[renumber 089]
scratch 6: rc=1 out=[] err=[spec-number: error: gh api files of PR #363 failed]
```

## Residual Risks

- The shipper is a prompt run by a haiku model: whether it calls the script, follows `keep` / `renumber` and leaves the branch name alone was not exercised (fix.md's follow-up: run one real `/feat` ship).
- Two shippers that both re-check before either PR is opened can still pick the same number (seconds-wide window, accepted by the user).
- Tests use a stub `gh`; the real `gh api --paginate --jq` and `{owner}/{repo}` expansion were checked only for the files endpoint against the private project, not the script's `gh pr list` call on a repo with open PRs.
- Not checked: git older than 2.44 (documented floor); `docs/install.md` does not yet list the minimum (state file defers it to review fixes).
- PRs from forks: their files are counted through the REST list, but their branch names count too, so a fork branch named `NNN-…` can raise the number (gaps, not clashes).

## Recommendation

Close the bug as verified: the original symptom no longer reproduces and the checks pass. Before release, add the git ≥ 2.44 minimum to `docs/install.md` (as agreed) and watch the first real `/feat` ship for the shipper following the script.
