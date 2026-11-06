# Contract delta: tracker.sh `create-issue` from an assessment

Base contract: `specs/001-board-tracking/contracts/tracker-cli.md`. Only
`create-issue` changes; `check`, `read-issue`, `set-status`, the config,
output and exit codes stay as they are.

## Usage

```
tracker.sh create-issue <brief-file | assessment-file> <owner/repo confirmed by the user>
```

The usage line names both. The path decides the source:

| Path pattern | Source | Directory that must resolve inside the repo |
|---|---|---|
| `^specs/briefs/[a-z0-9][a-z0-9-]*\.md$` | brief (unchanged) | `<root>/specs/briefs` |
| `^\.specify/bugs/[a-z0-9][a-z0-9-]*/assessment\.md$` | assessment (new) | `<root>/.specify/bugs/<slug>` |
| anything else | exit 2, `brief path must be specs/briefs/<name>.md or .specify/bugs/<slug>/assessment.md` | — |

Path checks before any `gh` call, as for briefs: `cd -P` on the directory
compared with `<root>/<dir>` resolved the same way (exit 2 `<dir> resolves
outside the repo`), the file regular and not a symlink (exit 2
`assessment is not a regular file`).

## Parsing an assessment

One section parser for both documents: the first line must start with the
document's title prefix; `## ` lines outside a ``` fence start sections;
leading and trailing blank lines trimmed.

- Title: first line minus `# Bug Assessment: ` (else exit 2 `assessment has
  no "# Bug Assessment: " first line`; empty → exit 2 `assessment title is
  empty`).
- `## Symptom` (else exit 2 `assessment has no Symptom section`).
- `## Root Cause Hypothesis` (else exit 2 `assessment has no Root Cause
  Hypothesis section`).

## Body and call

```
## Symptom
<section>

## Root cause
<section>

Trail: .specify/bugs/<slug>/
```

Before any `gh` call, the Symptom and Root Cause Hypothesis are matched
against FR-038's patterns (`-----BEGIN`, `gh[opsur]_`, `github_pat_`,
`AKIA`, `xox[bp]-`, `sk-` after a non-word character,
`(password|token|secret)["']?\s*[:=]`);
a match → exit 2 `tracker: error: assessment's Symptom or Root Cause
Hypothesis holds a secret-looking value; redact it first`, nothing
created.

`gh issue create -R <owner/repo> --title <title> --body-file <tmp> --label bug`
after the same current-repo check as briefs (resolved repo must equal the
confirmed one, else exit 1, nothing created). Never retried, except once
without `--label bug` when gh's error says the label was not found (gh
checks labels before creating anything, so nothing exists yet). Output:
`tracker: created <owner>/<repo>#<N>`, or after that retry `tracker:
created <owner>/<repo>#<N> (without the bug label: <owner>/<repo> has
none)`; failure: `tracker: error: could not create the issue (<reason>)`.

Brief issues keep no label (existing test asserts it).

## When the orchestrator calls it for a bug

Only after the assess gate passes, for a real bug, with board tracking and
no `Issue:` line, once the user has confirmed the repo. For a bug whose
risk area includes security it is **not** called by default: the assess
gate suggests a private security advisory instead, and the call happens
only if the user asks for an issue (FR-020, FR-037). The script itself has
no security switch: the decision is the orchestrator's, and the body it
builds (Symptom, Root cause, Trail) is the same either way.

## New offline cases (tests/tracker/run.sh)

13. **bug issue**: `repo` = `up/r`, `issue-url` =
    `https://github.com/up/r/issues/8`, an assessment whose Symptom holds a
    fenced `## ` line: `create-issue .specify/bugs/login-timeout/assessment.md up/r`
    prints `tracker: created up/r#8`; `calls` show `issue create -R up/r
    --title <title> --body-file <f> --label bug`; `body` holds the Symptom
    (fenced line included), the Root Cause Hypothesis and the last line
    `Trail: .specify/bugs/login-timeout/`; it holds nothing from Report,
    Reproduction or Proposed Remediation. Then `… other/r` exits 1 with no
    `issue create`.
14. **bad assessment path**: `.specify/bugs` a symlink outside the repo →
    exit 2, no `calls`; `.specify/bugs/x/fix.md` → exit 2 usage-pattern
    error, no `calls`.
15. **missing section**: an assessment without `## Root Cause Hypothesis`
    → exit 2 naming the section, no `calls`.
16. **missing bug label**: the stub fails `--label` with gh's `could not
    add label: 'bug' not found` (case file `no-label`): two `issue create`
    calls, the second without `--label`, output `tracker: created up/r#9
    (without the bug label: up/r has none)`; a failing retry exits 1; a
    failure other than the label is not retried (one call).
17. **secret in body**: a Symptom holding `password=…`, `"token": …`,
    `ghs_…`, `sk-…` or `-----BEGIN …` → exit 2 with the redaction message,
    no `calls`.
