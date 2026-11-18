# Bug Verification: Secret scan blocks ordinary code

- **Slug**: 22-secret-scan-blocks
- **Tested**: 2026-11-18
- **Assessment**: ./assessment.md
- **Fix**: ./fix.md
- **Result**: verified

## Summary

The original reproduction no longer blocks: staged diffs that only remove a key/literal line, or add a Go variable named after a key assigned from a getter, a YAML env-var reference or a YAML boolean, pass `secret-scan.sh staged` (exit 0, no output). True positives (quoted literal 8+ chars, unquoted 20+ chars with a digit, every vendor prefix) still block with `<file>:<line>: <rule>` and no value. Lint and the five test tasks pass; no regressions found.

## Checks Performed

| Check | Command / Action | Result | Notes |
|-------|------------------|--------|-------|
| Reproduction (post-fix), false positives | throwaway git repo under the system temp dir; for each of 8 staged cases run `bash secret-scan.sh staged` (removed key/literal line; Go variable named secret assigned from a config getter; YAML token key with env-var references; YAML boolean; clean file; short quoted value; short unquoted `.env` value; long digitless unquoted value) | pass | all 8 exit 0, no output. The old shipper `-G` pattern still lists the Go and YAML-boolean files in the same repo (baseline); the new scanner lists none |
| Reproduction (post-fix), true positives | same repo, staged: quoted 16-char literal; unquoted 24-char value with digits; single-quoted api_key; upper-case PASSWORD key; Go `:=` with a quoted literal; AWS key id, GitHub token, Slack token, OpenAI-style key, private-key header (all built at runtime by concatenation) | pass | all 10 exit 1, each reported as `<file>:<line>: <rule>` (`key-literal`, `aws-key-id`, `github-token`, `slack-token`, `openai-key`, `private-key`); the output never held the value (checked) |
| Line numbers | AWS sample on line 4 of a new file; literal on line 2 of a modified file | pass | `aws.txt:4: aws-key-id`, `mod.txt:2: key-literal` |
| Could not run | `secret-scan.sh staged` outside a repo; `secret-scan.sh bogus` | pass | both exit 2 with `secret-scan: error: ...` on stderr |
| Self scan | `secret-scan.sh worktree .apm .github docs mise.toml tests .specify/bugs/22-secret-scan-blocks` | pass | exit 0 over the source files and the bug dir (this report included, after a rewording) |
| New / updated tests | `mise run test:secret-scan` | pass | 7 cases ok |
| Tracker test (case 17 updated) | `mise run test:tracker` | pass | exit 0, includes `ok secret in body` |
| APM packaging | `mise run test:apm` | pass | exit 0; script lands in the package |
| Spec-number test | `mise run test:spec-number` | pass | exit 0, all spec-number tests passed |
| Lint | `mise run lint` | pass | exit 0 (shellcheck, actionlint, plugin validation, harness grep) |

## Output Excerpts

```
== I quoted literal 16 chars: exit=1 (expected 1)
q.txt:2: key-literal
== L aws key id: exit=1 (expected 1)
aws.txt:4: aws-key-id
== D YAML boolean: exit=0 (expected 0)
(no output)
old pattern (key/sep only, -G):  code.go f.yml
new scanner: exit=0
non-repo exit=2 / usage exit=2
```

`test:secret-scan`: 7 `ok` lines (false positives, true positives, line numbers, worktree, could not run, sourced, self). `lint`, `test:tracker`, `test:apm`, `test:spec-number`: exit 0.

## Residual Risks

- Intended trade-offs from the user's decisions: quoted values under 8 chars, unquoted values under 20 chars or without a digit, and values containing `$` are not caught by the key rule; vendor prefixes still catch the common token formats.
- Not exercised: a real `feat-shipper` run (the agent prompt change was reviewed by reading the diff, not executed); the accept-with-reason override and gitleaks are out of scope by decision.
- A first draft of this report held a placeholder in quotes after a Go key and tripped the scan (key-literal, line 18): a reminder that prose in the trail must avoid a quoted 8+ char token after a key name. Fixed by rewording.
- An upper-case key sample in my first run used a non-key name and did not match (a sample error, not a defect); the corrected sample is reported (exit 1).

## Recommendation

Close the bug: verified. The false positives from the report no longer block, true positives still do and are reported by file:line and rule without the value, and the offline tests, tracker test, packaging check, spec-number test and lint all pass.
