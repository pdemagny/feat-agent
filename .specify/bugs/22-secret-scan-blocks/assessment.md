# Bug Assessment: Secret scan blocks ordinary code

- **Slug**: 22-secret-scan-blocks
- **Created**: 2026-11-18
- **Source**: pasted text labelled pdemagny/logistics#22 (https://github.com/pdemagny/logistics/issues/22, read with `gh issue view 22`; host github.com, allowlisted)
- **Verdict**: valid
- **Severity**: medium

## Report (verbatim or summarized)

Summarized (the issue body quotes secret-looking sample lines, so it is not
copied verbatim here, where the shipper's own scan would match them):

> **Secret scan blocks ordinary code and has no override.** The shipper's
> secret scan (`feat-shipper.agent.md`, and `RE_SECRET` in `tracker.sh`)
> blocked 4 ships on false positives, each cleared by hand.
>
> - It scans removed lines too: `git diff --cached -G` lists a file when an
>   added *or* removed line matches, so deleting a secret-looking line
>   blocks the ship.
> - The key/value rule `(password|token|secret)["']?\s*[:=]` matches code
>   that handles secrets without holding one: a Go short declaration of a
>   variable named `secret` from a config getter, a YAML key named `token`
>   whose value is an env-var reference, a boolean flag named `secret`,
>   test fixture keys.
> - A false positive has no exit: the shipper stops and hands the user a
>   `!` command.
>
> **Done when**: only added lines are scanned; the key/value rule requires a
> literal value (quoted, 8+ chars, no `$`; or an unquoted 20+ char value at
> end of line for `.env`/YAML), vendor-prefix rules unchanged; a match is
> reported as `file:line` with the value masked, the user can accept it at
> the gate with a reason, the decision is logged in the state file and the
> shipper re-runs skipping only those lines; optionally gitleaks when
> installed; an offline test in `tests/` with a `mise run test:…` task;
> `tracker.sh`'s `RE_SECRET` follows the same pattern.

## Symptom

The shipper refuses to commit (`PR: blocked`, `! secret scan: …`) when the staged diff merely removes a secret-looking line, or adds ordinary code where a key named password, token or secret is followed by a colon or equals sign with no literal value (a variable assignment, an env-var reference, a boolean). Expected: only added lines holding a literal secret value block the ship.

## Reproduction

Scratch test (`$TMPDIR/fix22-scratch/repro.sh`, a throwaway git repo under
the system temp dir; no source changed). It commits a file holding a
key/literal line, then stages: (A) that line deleted, (B) a Go file reading
a config value into a variable named `secret`, (C) a YAML key named `token`
set to an env-var reference, (D) a YAML key named `secret` set to `true`,
(E) a clean file. It runs the shipper's exact command
`git diff --cached --name-only -G'<the shipper pattern>'`, then
`tracker.sh`'s `RE_SECRET` on the same lines.

Output (values redacted):

```
== shipper scan (git diff --cached --name-only -G<pattern>) ==
ci.yml
code.go
deleted.txt
flags.yml
exit=0
== deleted.txt staged diff ==
-<redacted>
== tracker.sh RE_SECRET on the same lines ==
match: <redacted>
match: <redacted>
match: <redacted>
no match: hello
```

All four ordinary files are listed; `deleted.txt` is listed although its
only change is a removed line. Each listing would block the ship. Baseline
`mise run test:tracker` passes (case 17 "secret in body" included).

## Suspected Code Paths

- `.apm/agents/feat-shipper.agent.md:103-112` — the fix-mode secret scan: `git diff --cached --name-only -G'…'`. `-G` selects files whose diff has an added *or* removed line matching, and the last alternative `(password|token|secret)["']?[[:space:]]*[:=]` needs no value after the separator. A listed file stops the ship with no way past it.
- `.apm/agents/feat-shipper.agent.md:129-131` — the `!` fallback scans whole files with Grep using the same pattern, so it inherits the over-broad key/value rule (and scans unchanged lines, not just added ones).
- `.apm/skills/feat/scripts/tracker.sh:33` — `RE_SECRET`, the same pattern, used at line 457 to refuse an issue body (assessment Symptom/Root Cause) holding a secret-looking value.
- `tests/tracker/run.sh:398-413` — case 17 asserts the current `RE_SECRET` on five values; two of them (short key/value literals) would no longer match the narrower rule the issue proposes.
- `.apm/agents/feat-bug-assessor.agent.md:58-63` — the redaction rule is written against the current pattern ("so the shipper's scan does not match it again"); it redacts a superset, which stays safe after narrowing.
- `.apm/skills/fix/SKILL.md:479-486` and `.apm/skills/feat/SKILL.md:373-376` — the orchestrators' handling of the `! secret scan: …` line (they only relay it; no override path exists).

## Root Cause Hypothesis

The scan is a single `git diff --cached --name-only -G<regex>` whose regex ends with an unanchored key/separator rule: `-G` matches the pickaxe against both sides of the diff, so removed lines count, and the key/separator rule fires on any identifier named password/token/secret followed by `:`/`=`, regardless of whether a literal value follows. Every match is a hard stop with no accepted-exception path. Confidence: high (reproduced with the shipper's exact command).

## Proposed Remediation

**Scope.** The bug is the false positives: removed lines counted, and the
key/separator rule firing without a literal value. Those two fixes make the
scan correct. The accept-with-reason override at the ship gate (state-file
log, re-run skipping accepted lines, new report lines between the shipper
and both orchestrators) is new behaviour, not a correction: it adds a gate
interaction to `/feat` and `/fix` and changes the shipper's fixed report
format on both sides. It belongs in a separate feature issue (via `/brief`),
together with the optional gitleaks integration. The masked `file:line`
report is cheap and helps the user clear a true positive, so it fits this
fix.

**Preferred**: add one offline scanner script,
`.apm/skills/feat/scripts/secret-scan.sh`, run by the shipper in place of
the inline `-G` command. It lists the staged files (`git diff --cached
--name-only --diff-filter=ACMR`), reads only their added lines
(`git diff --cached -U0`, lines starting with `+` but not `+++`), tracks the
new-file line number from the `@@` hunk headers, and prints
`<file>:<line>: <rule>` for each match, never the value; exit 0 clean, 1 on
a match, 2 when it can't run. Rules: the vendor prefixes unchanged
(private-key header, GitHub token prefixes, the AWS key id prefix, Slack
prefixes, the OpenAI-style key prefix after a non-word character); the key/value rule narrowed to
a literal value, as the issue proposes: a quoted value of 8+ characters with
no `$` or whitespace, or an unquoted 20+ character token running to end of
line. Define the pattern once (sourced or printed by the script) and have
`tracker.sh`'s `RE_SECRET` use the same alternatives. Update the shipper
prompt (scan command, block message `! secret scan: <file>:<line> matches
<rule>`, and the `!` fallback scanning the added lines of the files it
would stage with the same script). A script also avoids the pipes the
worktree guard refuses.

**Alternatives**:
- Keep the scan inline in the shipper prompt: `-G` with the narrowed regex to find candidate files, then the agent reads `git diff --cached -U0 <file>` and Greps the `+` lines. No new script, but the logic lives in prose, is untestable offline, and the tracker cannot share it.
- Fix the bug and add the override in one change, as the issue's "Done when" lists. Closes the issue in one PR, but makes the change large: new gate wording in both orchestrators, a new state-file Log line, a shipper report-format change on both sides, and a security-sensitive bypass path.
- Use `gitleaks protect --staged` when installed, the regex as fallback. Better rule coverage, but a new optional dependency (`apm.yml`, `install.sh`, `docs/install.md`) and two code paths to test; better as part of the override feature.

**Files likely to change**:
- `.apm/skills/feat/scripts/secret-scan.sh` (new)
- `.apm/agents/feat-shipper.agent.md`
- `.apm/skills/feat/scripts/tracker.sh`
- `tests/secret-scan/run.sh` (new)
- `tests/tracker/run.sh` (case 17 values)
- `mise.toml` (a `test:secret-scan` task; lint already covers `tests/` and the scripts dir, to confirm)
- `docs/workflow.md` (if it describes the scan)

**Tests to add or update**:
- New offline test in a temp git repo: false positives (a deleted key/literal line; a Go variable named `secret` assigned from a getter; a YAML key named `token` set to an env-var reference; a boolean flag; a short quoted value) produce no match; true positives (each vendor prefix; a quoted 8+ char literal after a password/token/secret/api-key key; an unquoted 20+ char literal in `.env` style) are reported with the right `file:line` and no value in the output. Build the true-positive fixtures at runtime (string concatenation), so the test file itself does not trip the scan when it is shipped.
- `tests/tracker/run.sh` case 17: replace the short key/value samples with literals the new rule matches, and add a negative case (a key followed by a variable reference is accepted).

## Risks & Considerations

- Security: narrowing the rule lets some real secrets through (short literals under 8 chars, unquoted values under 20 chars, values built with `$`). That is the intended trade; vendor-prefix rules keep catching the common token formats.
- The fix's own test file and this bug's trail hold secret-looking samples; the shipper scans them when it ships this fix. Fixtures should be built at runtime, and the trail is already written to avoid matches.
- `tests/tracker/run.sh` already holds literal samples (case 17) that match the current and the new vendor rules; it shipped before, so it was cleared by hand. With only added lines scanned, an unchanged line there no longer blocks; an edited one still would.
- The tracker's `RE_SECRET` guards an issue body that goes public; narrowing it there loosens that guard too. The assessor's redaction rule still redacts the broader set before the tracker sees it.
- shellcheck must stay clean on the new script and test.

## Open Questions

- Should the accept-with-reason override and optional gitleaks be split into a separate feature issue (recommended), or done in this fix?
- Should `tracker.sh` keep the broader key/separator rule for public issue bodies (stricter is cheap there: the assessor redacts first), or follow the narrowed scan rule as the issue asks?
- Should the narrowed key list include `passwd` and `api[_-]?key` as the issue proposes? (Assumed yes.)
