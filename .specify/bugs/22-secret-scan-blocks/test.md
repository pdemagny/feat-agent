# Bug Verification: Secret scan blocks ordinary code

- **Slug**: 22-secret-scan-blocks
- **Tested**: 2026-11-18
- **Assessment**: ./assessment.md
- **Fix**: ./fix.md
- **Result**: verified

## Summary

Cycle: after review fixes (the previous report is `test-1.md`). In a throwaway git repo outside the worktree, every original false positive still passes `secret-scan.sh staged` (exit 0, no output), every true positive still blocks, and the three cases added by the review fixes (separator `=>` with a quoted literal, an unquoted JWT-shaped value, an unquoted value with `@`) are reported. A matched file whose name has a space is reported as `<name>:<line>: <rule>` with no tab. No run ever printed a value. Lint and the four test tasks pass; the worktree scan over every changed file and the bug dir is clean.

## Checks Performed

| Check | Command / Action | Result | Notes |
|-------|------------------|--------|-------|
| Reproduction (post-fix), false positives | temp repo, `bash secret-scan.sh staged` for 7 staged cases: removed key/literal line; Go variable named after a key assigned from a getter; YAML token key with env-var references; YAML boolean; short quoted and short unquoted values; long digitless unquoted value; `=>` with a variable | pass | all exit 0, no output |
| Reproduction (post-fix), true positives | same repo: quoted 18-char literal; unquoted 24-char value with digits; Go `:=` quoted literal; single-quoted api_key; AWS key id, GitHub token, Slack token, OpenAI-style key, private-key header (built at runtime by concatenation) | pass | all exit 1, each `<file>:<line>: <rule>` (`key-literal`, `aws-key-id`, `github-token`, `slack-token`, `openai-key`, `private-key`); line 2 of the AWS file reported as line 2 |
| New cases from the review fixes | same repo: `=>` with a quoted literal; unquoted JWT-shaped value (dots, 3 segments); unquoted value with `@` and dots | pass | all exit 1, `key-literal` |
| File name with a space (B1) | stage a matching file named `my file.txt`; byte dump of the output | pass | output is exactly `my file.txt:1: key-literal`, no tab |
| No value printed | every run's output searched for each sample value and the vendor prefix | pass | none found |
| New / updated tests | `mise run test:secret-scan` | pass | 8 ok lines (false positives, true positives, line numbers, worktree, could not run, sourced, separators and paths, self) |
| Tracker test | `mise run test:tracker` | pass | exit 0, includes `ok secret in body` |
| APM packaging | `mise run test:apm` | pass | exit 0 |
| Spec-number test | `mise run test:spec-number` | pass | exit 0 |
| Lint | `mise run lint` | pass | exit 0 (shellcheck, actionlint, plugin validation, harness grep) |
| Self scan | `secret-scan.sh worktree` over every changed and added file and the bug dir (this report included) | pass | exit 0, no output |

## Output Excerpts

```
PASS: FP removed key/literal line exit=0 (expected 0) out=
PASS: FP => with variable exit=0 (expected 0) out=
PASS: TP => quoted literal exit=1 (expected 1) out=a.php:1: key-literal
PASS: TP unquoted JWT-shaped exit=1 (expected 1) out=jwt.env:1: key-literal
PASS: TP unquoted with @ exit=1 (expected 1) out=at.env:1: key-literal
PASS: TP aws exit=1 (expected 1) out=aws.txt:2: aws-key-id
space name: rc=1 out=[my file.txt:1: key-literal]
overall fail=0
```

`test:secret-scan`: 8 `ok` lines. `lint`, `test:tracker`, `test:apm`, `test:spec-number`: exit 0.

## Residual Risks

- Intended trade-offs from the user's decisions: quoted values under 8 characters, unquoted values under 20 characters or without a digit, and values built with a dollar sign are not caught by the key rule; vendor prefixes still catch the common token formats.
- S2 was deliberately left unfixed: a `.gitattributes` `binary` or `-diff` entry hides a file's lines from the scan.
- Not exercised: a real `feat-shipper` run (the agent prompt change was read, not executed); the accept-with-reason override and gitleaks are out of scope by decision.
- The unquoted value class excludes the colon, so a colon-separated unquoted value is cut at the colon (as designed).

## Recommendation

Close the bug: verified. The review fixes hold: the false positives from the report still pass, the true positives and the new separator and character-class cases block, a file name with a space is reported cleanly, and no value is ever printed. All offline tests and lint pass.
