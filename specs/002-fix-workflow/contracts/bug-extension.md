# Contract: recorded names of Spec Kit's bug extension

Status: recorded by the spike on 2026-11-06, specify-cli 1.2.1, bug 1.0.1.
Scratch project: `git init`, `specify init --here --integration claude`,
`specify extension add bug`, a toy `calc.py` bug. Names below are read from
the generated skill files (`.claude/skills/speckit-bug-*/SKILL.md`) and the
extension's README; `speckit-bug-assess slug=average-off-by-one` was run
once headless (`claude -p`, Sonnet). Limits of the run: the scratch dir sat
under `~/.claude/`, which Claude Code treats as sensitive, so the stage's
Write of `assessment.md` was refused and `speckit-bug-fix` /
`speckit-bug-test` could not run on it; their printed lines below come from
the skill text, and live run 1 (quickstart S6) is the first real run of
both. These names are the only ones `/fix`, `feat-bug-assessor`,
`tracker.sh` and `install.sh check` use. They agree with spec.md and
plan.md.

## Install

- Command: `specify extension add bug` (bundled, no network). It prints
  `Bug Triage Workflow (v1.0.1)` and the three commands.
- Present when: `.specify/extensions/bug/` exists, and `bug` is listed under
  `installed:` in `.specify/extensions.yml` (the file also gets
  `settings: auto_execute_hooks: true` and `hooks: {}`).
- Version tested: bug **1.0.1** (`.specify/extensions/bug/extension.yml`,
  `extension.version`; extension id `bug`, commands `speckit.bug.assess`,
  `speckit.bug.fix`, `speckit.bug.test`). 1.0.2 (specify-cli 1.3.0) differs
  only in a README link.

## Skills (Claude integration)

| Stage | Skill | Writes |
|---|---|---|
| assess | `speckit-bug-assess` | `.specify/bugs/<slug>/assessment.md` |
| fix | `speckit-bug-fix` | `.specify/bugs/<slug>/fix.md` |
| test | `speckit-bug-test` | `.specify/bugs/<slug>/test.md` |

Generated at `.claude/skills/<skill>/SKILL.md`, frontmatter `name` equal to
the directory, `metadata.source: bug:commands/speckit.bug.<stage>.md`.

### Slug

- Passed as `slug=<slug>` (also accepted: `--slug <slug>`, a bare
  slug-like token; fix and test also take a path containing the slug).
- Normalisation (assess, user-provided slug): "use it verbatim after
  normalization (lowercase, hyphen-separated, no spaces, no special
  characters other than `-` and digits). Preserve the shape the user asked
  for — do not append timestamps or numbers." So: lowercased; spaces become
  `-`; characters outside `[a-z0-9-]` are dropped; **no length cut**; **a
  leading digit is kept** (the README's own example is `cve-2026-001`).
  A slug of research R6 (`[a-z0-9-]`, at most 40 characters, `<N>-<words>`
  for an issue) is therefore kept unchanged.
- Fix and test resolve the slug in this order: explicit input, the slug
  the session's previous stage reported, the single `.specify/bugs/*/`
  candidate on disk, else (automated mode) stop with an error listing the
  candidates. Passing `slug=<slug>` always takes the first branch.
- Every report carries the slug as its first header bullet,
  `- **Slug**: <slug>`.

### Existing report

- assess: "If `BUG_DIR/assessment.md` already exists, ask the user whether
  to overwrite it (in interactive mode); in automated mode, refuse and pick
  a new unique slug instead." The generated-slug branch also appends `-2`,
  `-3`, … or `-<yyyymmdd>` to avoid an existing directory.
- fix, test: "ask the user whether to overwrite it (interactive mode) or
  refuse (automated mode)"; they do not pick a new slug (the README says
  they do; the skill text does not).
- Either way the stage never overwrites: research R5 holds (rename the
  existing report to `<report>-<n>.md` first, then pass `slug=<slug>`).

### Writing

- assess and test: "never modify source files", write only inside
  `.specify/bugs/<slug>/`; the directory is created "using whatever
  mechanism is appropriate" (Write creates parents); each report is written
  whole ("Write to `BUG_DIR/<report>.md` using this structure"). In the
  spike run the assess stage used Read, Glob, Bash (`ls`, `cat`) and Write,
  never Edit. `feat-bug-assessor`'s `disallowedTools: Edit, NotebookEdit,
  Agent` fits (FR-029).
- fix: edits source (that is `feat-implementer`, which has Edit) and
  writes `fix.md` whole; "Never edit `assessment.md`".

## assessment.md

- Title line: `# Bug Assessment: <short title>`
- Header bullets, in order: `**Slug**`, `**Created**` (ISO 8601 date),
  `**Source**` (URL or `pasted text`), `**Verdict**`: `valid` |
  `likely valid, needs reproduction` | `invalid`; `**Severity**`:
  `critical` | `high` | `medium` | `low`
- Sections: `## Report (verbatim or summarized)`, `## Symptom`,
  `## Reproduction`, `## Suspected Code Paths`, `## Root Cause Hypothesis`
  (states confidence `high` / `medium` / `low`), `## Proposed Remediation`
  (`**Preferred**`, optional `**Alternatives**`, `**Files likely to
  change**`, `**Tests to add or update**`), `## Risks & Considerations`,
  `## Open Questions`. Unknowns are marked `[NEEDS CLARIFICATION: …]`.
  Instruction-like content from a fetched page is quoted under an
  `Unverified` heading. A URL report records the URL, its host and the
  trust-policy branch (`allowlisted` / `confirmed-by-user` /
  `auto-refused: <reason>`); an unrecognised host in automated mode is not
  fetched: `[UNVERIFIED — fetch skipped: host not on safe list: <host>]`.
- Unintelligible pasted report (empty, unrelated, spam): verdict `invalid`
  with a reason, **no assessment.md** written, no post-hooks, no
  completion report. (Before-hooks may already have run and the bug
  directory may exist, empty.)
- Required by `/fix` (the assessor errors if missing): title line,
  Verdict, Severity, Symptom, Reproduction, Suspected Code Paths, Root Cause
  Hypothesis, Proposed Remediation, Open Questions.
- Used by `tracker.sh create-issue`: title line, `## Symptom`,
  `## Root Cause Hypothesis`.

## fix.md

- Title line: `# Bug Fix: <short title>`
- Header bullets: `**Slug**`, `**Fixed**` (ISO 8601 date),
  `**Assessment**`: `./assessment.md`, `**Status**`: `applied` | `partial`
  | `not-applied`
- Sections: `## Summary`, `## Changes` (table `File | Change | Notes`),
  `## Diff Highlights (optional)`, `## Tests Added or Updated`,
  `## Local Verification`, `## Deviations from Assessment` (empty if none),
  `## Follow-ups`
- The stage stops before changing code when the verdict is `invalid`, and,
  in automated mode, when the verdict is `likely valid, needs reproduction`
  with unresolved `[NEEDS CLARIFICATION]` items (so `/fix` passes the
  user's answers). A wrong assessment: stop modifying code, record it under
  Deviations, recommend re-running assess.
- Required by `/fix`: Status, Deviations from Assessment.

## test.md

- Title line: `# Bug Verification: <short title>`
- Header bullets: `**Slug**`, `**Tested**` (ISO 8601 date),
  `**Assessment**`: `./assessment.md`, `**Fix**`: `./fix.md`,
  `**Result**`: `verified` | `partial` | `failed`
- Sections: `## Summary`, `## Checks Performed` (table `Check | Command /
  Action | Result | Notes`; per-check result `pass` | `fail` | `skipped` |
  `not-run`; rows "Reproduction (post-fix)", "New / updated tests",
  "Regression suite", "Lint / type-check"), `## Output Excerpts`,
  `## Residual Risks`, `## Recommendation`
- A reproduction listed in the assessment and not exercised caps the
  result at `partial`. Destructive, network-dependent or expensive checks
  are `skipped` without consent.
- Required by `/fix`: Result, Checks Performed.

## Hooks

The extension registers none of its own; it fires these events for other
extensions, read from `.specify/extensions.yml` under `hooks.<event>`:
`before_bug_assess`, `after_bug_assess`, `before_bug_fix`, `after_bug_fix`,
`before_bug_test`, `after_bug_test`. Pre-hooks run after slug resolution
and prerequisites (for assess the bug directory already exists), post-hooks
after the report is written. Hooks run in the agent's session as prompts
(mandatory ones invoked and awaited, optional ones shown); no variables are
injected. Entries with `enabled: false` or a non-empty `condition` are
skipped.

## What each stage prints

The completion report is prose the model writes; these are the items the
skill requires, and the one fixed line.

- Assess: the slug **on its own line**, `Slug: <slug>`, with how it was
  resolved; the spike printed ``Slug: `average-off-by-one` (user-provided)``,
  so the line may wrap the slug in backticks and add `(user-provided)`,
  `(asked-for)` or `(auto-generated)`. Then the path
  `.specify/bugs/<slug>/assessment.md`, the verdict and severity, and the
  next step `/speckit-bug-fix slug=<slug>`. An unintelligible report prints
  only the `invalid` verdict and its reason.
- Fix: "the slug and `BUG_DIR/fix.md` path", the status, the next step
  `/speckit-bug-test slug=<slug>`, and which slug-resolution path was used
  (`explicit` / `from context` / `single candidate` / `asked`). No fixed
  `Slug:` line is required.
- Test: the slug and `BUG_DIR/test.md` path, the result, the resolution
  path; on `failed`, a recommendation to re-run `/speckit-bug-assess`.

Slug check (FR-041): compare the passed slug with the `Slug:` line when
printed (backticks and the parenthesised resolution stripped) and with the
written report's `- **Slug**:` bullet, which every stage writes; a
difference, or a report written under another `.specify/bugs/<dir>/`, is a
mismatch.
