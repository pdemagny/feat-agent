# Bug Fix: Secret scan blocks ordinary code

- **Slug**: 22-secret-scan-blocks
- **Fixed**: 2026-11-18
- **Assessment**: ./assessment.md
- **Status**: applied

## Summary

The shipper's secret scan moved from an inline `git diff --cached -G` into
an offline script, `secret-scan.sh`, which reads only the lines the staged
diff adds and narrows the key/value rule to a literal value; it reports
`<file>:<line>: <rule>`, never the value. `tracker.sh` sources the same
rules, so its issue-body guard follows them. The accept-with-reason
override and gitleaks stay out (a separate feature, per the user).

## Changes

| File | Change | Notes |
|------|--------|-------|
| `.apm/skills/feat/scripts/secret-scan.sh` | added | `staged` and `worktree <path>...` modes; exit 0 clean, 1 match, 2 could not run; sourced, it only defines functions and the rule variables and runs nothing |
| `.apm/skills/feat/scripts/tracker.sh` | modified | `RE_SECRET` replaced by sourcing `secret-scan.sh` and calling `secret_rule` on the Symptom and Root Cause |
| `.apm/agents/feat-shipper.agent.md` | modified | fix mode: takes the secret-scan script's path, runs `staged` before committing; block line `! secret scan: <file>:<line> matches <rule>`; the `!` fallback runs `worktree` on the files it would stage |
| `.apm/skills/fix/SKILL.md` | modified | phase 5 passes the secret-scan script (`<base dir>/../feat/scripts/secret-scan.sh`) to the shipper |
| `tests/secret-scan/run.sh` | added test | offline, scratch git repos |
| `tests/tracker/run.sh` | modified test | case 17: literal-value samples; new negative samples |
| `mise.toml` | modified | `test:secret-scan` task; lint shellchecks the new test with the script; `test:apm` checks the script lands |
| `.github/workflows/check.yml` | modified | runs `mise run test:secret-scan` |
| `docs/workflow.md` | modified | the `/fix` shipper bullet describes the scan |

## Diff Highlights (optional)

Rules (the key/value rule is matched on the lowercased line):

- Vendor prefixes, unchanged in substance: private-key, github-token,
  aws-key-id, slack-token, openai-key. Each pattern in the script holds one
  bracketed letter so the script's own text does not match it.
- key-literal: a key (password, passwd, token, secret, api key with `_`,
  `-` or nothing between), an optional quote, `:`, `=`, `:=` or `=>`, then
  either a quoted value of 8+ characters with no `$` and no whitespace, or
  an unquoted value of 20+ token characters (letters, digits, `_/+=.@-`)
  that holds a digit and runs to the end of the line.

The scanner parses `git diff -U0` (explicit prefixes, no textconv, no
external diff, `--no-relative`, ACMR only), numbers added lines from the
`@@` hunk headers, and skips removed lines.

## Tests Added or Updated

- `tests/secret-scan/run.sh` "false positives": a removed key/literal line,
  a Go variable named after a key assigned from a config getter, YAML keys
  set to env-var references, a boolean flag, a short quoted value, a call,
  short and digitless unquoted `.env` values: exit 0, no output.
- "true positives": each vendor prefix and each key with a quoted or
  unquoted literal, reported as `<file>:<line>: <rule>` in order, and no
  value appears in the output.
- "line numbers": only added lines of a modified file, numbered in the new
  file; an unchanged secret-looking line is not reported.
- "worktree": a tracked file's added lines over HEAD, every line of an
  untracked file, paths outside the arguments ignored.
- "could not run": usage errors and no git repo exit 2.
- "sourced": `secret_rule` over multi-line text, as the tracker uses it.
- "separators and paths": a quoted literal after `=>`, an unquoted
  JWT-shaped value and an unquoted value with `@` are reported; a short
  `@` value and a `=>` variable are not; a file name with a space is
  reported without git's trailing tab.
- "self": the script and the test file pass their own scan.
- `tests/tracker/run.sh` case 17: the refused samples now hold literal
  values (quoted, and an unquoted `.env` one) besides the vendor ones; a
  short unquoted value, a short quoted value, an env-var reference and a
  call are accepted and create the issue. All samples are built by
  concatenation.

## Local Verification

- Commands run: `mise run lint` → pass; `mise run test:apm` → pass;
  `mise run test:tracker` → pass; `mise run test:spec-number` → pass;
  `mise run test:secret-scan` → pass (7 cases).
- Manual checks: `secret-scan.sh worktree` over every changed and new file
  and this bug dir → clean (exit 0).

## Deviations from Assessment

- Scope expansion: `.github/workflows/check.yml` runs the new test task
  (CI runs the other offline tests there), and the `shellcheck` tool
  comment in `mise.toml` now covers all scripts. Neither was listed in
  Files likely to change.
- The tracker shares the rules by sourcing the script (it only defines
  functions and the rule variables when sourced) rather than by sharing one
  regex: the unquoted
  rule needs a per-line end anchor and a digit check.
- The unquoted value must hold a digit, a guard the issue did not state:
  without it a long identifier (a constant name, a dotted-free variable)
  assigned to a key would match.

## Review fixes

- S1 (security): key-literal missed real secrets. The separator now also
  accepts `=>` (PHP, Ruby hashes), and the unquoted value class adds `.`
  and `@` (a JWT, a password with `@`); still 20+ characters, a digit, end
  of line. `:` stays out of the class.
- B1 (bug): a path with a space was reported with git's trailing tab from
  the `+++ b/<path>` header; the tab is now stripped. C-quoted names are
  left as git prints them.
- [std]1: the script's header and this file no longer say sourcing
  defines only two functions; it defines functions and the rule variables
  and runs nothing.
- Not applied, by the user's choice: S2 (a `.gitattributes` `binary` or
  `-diff` entry hides a file's lines from the scan; no `--text`).

## Follow-ups

- Separate feature (via `/brief`): accept a scan match at the ship gate
  with a reason, logged in the state file, and optional gitleaks.
- `feat-bug-assessor`'s redaction rule still redacts the broader old set;
  it stays safe (a superset) and could be aligned later.
