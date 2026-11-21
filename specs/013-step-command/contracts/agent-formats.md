# Contract: agent formats and digests

Each agent's format, its digest and `step.sh`'s parser change in one commit
(constitution principle IV). `/tiny` and `feat-brief-reviewer` do not
change; `feat-code-reviewer` given no report path hands back its full
format as today, `rec` values included.

## Parsing rules (all agents)

The parser fails closed: a slip makes the report unparsable (one reformat
turn, then hard: data-model.md, Reformat turn), never a missing finding,
risk or path.

- A field is a line starting at column 0 with `<Key>: ` (or `<Key>:` alone
  for a list). Keys match exactly, suffix included (`Fixes (fix mode):`).
  A field's key is one of the agent's format; the next such key ends the
  field before it.
- A list field is `<Key>: none` (or `n/a` where the format says so), with
  no items, or `<Key>:` followed by its items (alone, or with the count
  its format shows, as `Open markers: <n>` and `Files changed: <count>`):
  one `- <item>` line each, at column 0, never wrapped onto a second line.
  `Open markers: <n>` not matching its item count is unparsable
  (`Files changed` counts all files, its items only the notable ones). Blank lines inside
  a list are skipped. Any other non-blank line inside a list field (an
  indented item, a `*` item, a bare path, a wrapped continuation) makes
  the report unparsable, naming that line and the list's key.
- A one-line field never continues on the next line. Outside a list field,
  lines that are not a field of the format are ignored.
- **Required sections of a code reviewer**: each section of the lenses it
  was spawned with (its report key's lenses) must be present, written
  `<Key>: none` when empty: 7a `Bugs (7a)`, `Spec (7a)`, `Standards (7a)`,
  `Acceptance criteria (7a)`; 7b `Security (7b)`, `Accepted design
  findings built (7b)`; 7c `Performance (7c)`; 7d `Cuts (7d)` and `net`;
  7e `Readability (7e)`. A missing section is unparsable (`no <Key>:
  line`), never "no findings".
- **Design findings** start with `[sec]`, `[cost]` or `[design]` right
  after `- `; any other item under `Findings:` is unparsable.
- **Fixed-value fields** hold one value of their set exactly (R8),
  `Risk area` and `Performance bug` included (feat-bug-assessor).
- A required field missing, a fixed-value field holding a value outside
  its set, or a rule above broken makes the file unparsable (gates.md
  step 5), naming the file, the line number and the key, or the missing
  key; the line's text goes to stdout only.
- The file on disk is the one parsed; the digest is never read by
  `step.sh`.

Fixtures (`tests/step/fixtures/agents/<agent>/`): one per rule above (a
missing lens section, an indented and a `*` finding, an untagged design
finding, `Risk area: Security (token handling)`, `Performance bug: maybe`),
and per agent one report in today's layout (bare paths under `Wrote:`)
that is unparsable at its first bare path.

`Required` below = read by `step.sh`. **Bold** = changed or new.

## Shared text in every agent file

- "The orchestrator checks every `Wrote:` path on disk" becomes "`step.sh`
  checks every `Wrote:` path on disk before the run goes on".
- **`Wrote:` is a list field** in every agent's format: `Wrote: none`, or
  `Wrote:` alone followed by one `- <absolute path>` line per path. "One
  per line" in today's `Wrote:` descriptions becomes "one `- ` item per
  line". The same for every other field whose items are "one per line"
  (each agent below).
- The format block says: "Each list item is one `- ` line at column 0,
  never wrapped; write `none` for an empty field or section."
- The report-file paragraph names the digest: "hand back the digest: <the
  fields listed for this agent>". With no report path: no file, full
  format handed back (unchanged).
- **Reformat mode** (new paragraph, every agent `step.sh` reads): "When
  the prompt says `Mode: reformat`, with `From: <report>` and
  `Unparsable: <file>: line <n> (<Key>)`: read that report, write it again
  in the format below to your new report path, fixing the named line and
  any other line that breaks the format, and change nothing else: no other
  file, no new finding, no check run again. Hand back the digest." The
  agent rewrites its own content: a continued agent from its context, a
  fresh one from the `From:` file.

## feat-specifier

```
Spec: <absolute path to spec.md> | none
Stories: <US1 <title> (P1); US2 <title> (P2); …>                         one line
Requirements: <count>; <notable ones, "; "-separated>                   one line
Open markers: none | <n>
- <marker> — ask: <question> — recommended: <answer>
Blocker: none | <why the brief can't be specified as written>
Size remark: none | <the remark>
Assumptions: none | 1. <assumption> (recommended: keep as written); 2. …   one line
Unchecked checklist items: none | <file>: <item> (recommended: <answer>); …  one line
Skipped hooks: <hook → why, or "none">
Wrote:
- <absolute path>
```

Required: `Spec`, `Stories`, `Requirements`, `Open markers`, **`Blocker`**,
**`Size remark`**, `Assumptions`, `Unchecked checklist items`, `Wrote`.
Digest: `Stories`, `Requirements`, `Open markers` with its items,
`Blocker` and `Size remark` when not `none`, `Assumptions`, `Unchecked
checklist items`, `Skipped hooks` when not `none`.

## feat-planner

```
Plan: <absolute path to plan.md> (+ other artifacts written)
Approach: <two or three sentences>                                       one line
Touches:
- <package or file>
New dependencies or services: none
- <dependency or service> — <reason>
Constitution check: pass | violations
- <principle> — <why>
Assumptions: none
- <what> — why: <why> — recommendation: <rec> — needs user: yes | no
Blockers: none | <what stops the plan>
Size trigger: none | service | permissions | exposure | dependency — <what>
Skipped hooks: <hook → why, or "none">
Wrote:
- <absolute path>
```

`Assumptions` items are numbered by position (the first item is 1);
`step.sh` logs the numbers of the items ending `needs user: yes`.

Required: `Plan`, **`Constitution check`** (`pass`, or `violations` with
items), **`Assumptions`** (each item ends `needs user: yes|no`),
`Blockers`, **`Size trigger`**, `Wrote`. Digest: `Approach`, `Touches`,
`New dependencies or services`, `Constitution check`, `Assumptions`,
`Blockers`, `Size trigger`, `Skipped hooks` when not `none`.

## feat-tasker

```
Tasks: <absolute path to tasks.md>
Total tasks: <n>
Per story:
- setup/foundational: <IDs and ranges, comma-separated, or none>
- US1: <…>
- polish: <…>
MVP slice: <task IDs>
Analyze: ran | not run (<error>; cross-checked by hand)
Fixed: <MEDIUM/LOW findings fixed, "; "-separated, or none>
Open findings: none
- CRITICAL | HIGH | MEDIUM | LOW — <finding> → <proposed fix> (<artifact>)
Unchecked checklist items: none | open: <file>: <item>; …
Skipped hooks: <hook → why, or "none">
Wrote:
- <absolute path>
```

Required: **`Tasks`** (path only), **`Total tasks`**, **`Per story`**
(items), `Analyze` (missing is a reason, not unparsable), **`Open
findings`** (items, severity first), **`Unchecked checklist items`**,
`Wrote`. Ranges: `T001–T012` or `T001-T012`. Digest: `MVP slice`,
`Analyze` when not `ran`, `Open findings`, `Unchecked checklist items`.

## feat-implementer

```
Tasks done: <IDs, or n/a>
Tasks not done: none | n/a
- <ID> — <why>
Checks: none
- <command> → pass | fail (<first relevant error line>)
Not verified: none
- <task or n/a> → <check> → <why>
Design problems: none | <what the spec or plan gets wrong>
Files changed: <count>
- <notable file — what changed>
Fixes (fix mode): <id → applied | reverted (why)>; performance: <id: before → after (command)>   one line
Fix report (bug mode): <absolute fix.md path>
Status (bug mode): applied | partial | not-applied
Deviations (bug mode): none
- <deviation from the assessment>
Slug (bug mode): ok | mismatch (<printed slug>)
Move (rebase mode): <old7> → <new7> | undone (<old7> → <new7>) | nothing to do | repaired
Resolved alone (rebase mode): none
- <file> — <how> (an uncommitted check fix: <file> — check fix: <how>)
Decided (rebase mode): none
- <file> — <decision> (user: "<words>" | as recommended)
Needs decision (rebase mode): none
- <file> — run: <one line> — main: <one line> — rec: <one line>
Skipped hooks: <hook → why, or "none">
Wrote:
- <absolute path>
```

The `Bug fix (bug mode)` line splits into **`Fix report`**, **`Status`**,
**`Deviations`**, **`Slug`**; **`Decided (rebase mode)`** is new (the
`Decisions:` it applied, so `step.sh` logs the move's `asked:` sub-lines);
`Checks`, `Not verified` and **`Files changed`** become lists; `Wrote:`
lists created files (as today), which `step.sh` logs as `wrote:` facts for
the review diff. Required per mode: story:
`Checks`, `Not verified` (its absence is a reason, not unparsable),
`Design problems`, `Wrote`; fix: the same plus `Fixes (fix mode)`; bug:
`Fix report`, `Status`, `Deviations`, `Slug`, `Checks`, `Not verified`,
`Wrote`; rebase: `Move`, `Checks`, `Not verified`, `Resolved alone`,
`Decided`, `Needs decision`, `Wrote`.

Digest: `Tasks not done`, the failing `Checks` items, `Not verified`,
`Design problems`; fix mode `Fixes`; bug mode `Status` when not `applied`
and `Deviations`; rebase mode **`Move`**, **every `Checks` item** (the PR
note's `checks <result>`), `Resolved alone`, **`Decided`** and `Needs
decision`, and **`Wrote`** (rebase mode only: `rebase` runs outside
`step.sh` and checks the move's report itself from the digest,
coordinator.md, `references/rebase.md`); `Skipped hooks` when not `none`.

## feat-code-reviewer

```
Bugs (7a):
- <bug or missed edge case> — at: <file>:<line or a-b> — fix: <fix> — confidence: high | medium — rec: <rec>
Spec (7a):
- missing | scope creep | wrong: <finding> — spec: "<line quoted>" — at: <file>:<lines> — fix: <fix> — rec: <rec>
Standards (7a):
- hard | judgement: <finding> — standard: <cited, or smell name> — at: <file>:<lines> — fix: <fix> — rec: <rec>
Acceptance criteria (7a):
- <criterion> — met | not met (<why>) | untested
Security (7b):
- <short title, no exploit detail> — at: <file>:<lines> — fix: <fix> — severity: high | medium | nice-to-have — rec: <rec>
Accepted design findings built (7b):
- <D-id> — yes | no
Performance (7c):
- <bottleneck> — at: <file>:<lines> — fix: <fix> — measured: <command, baseline> | unmeasured (<why>) — verify with: <command> — guard: <test or "none"> — rec: <rec>
Cuts (7d):
- <tag>: <what to cut> — at: <file>:<lines> — fix: <what replaces it, or "nothing"> — rec: <rec>
net: -<N> lines possible | lean already
Readability (7e):
- <change> — at: <file>:<lines> — fix: <the change> — why: <why it reads better> — rec: <rec>
Dismissed: <things a skill raised that are not real, with why>
Wrote:
- <the report path you were given>
```

`<rec>`: `apply | skip (<why>) | user (<why>)`, always last. **Each finding
gets `at:` and `fix:` labels** (today's `<file:line> → <fix>`), the title
first; **Acceptance criteria and Accepted design findings become lists**.
Only the reviewer's lenses appear, **each of its sections present, `none`
when empty** (Parsing rules: required sections; `Accepted design findings
built (7b): none` when no accepted `[sec]` finding was given). With no
report path (`/tiny`): `Wrote: none`, the format otherwise as above.
Required: every section of the spawned lenses, `Wrote`. Digest (report
path given): `Findings: <count>`, `net:` (7d), and the `Accepted design
findings built` items marked `no`.

## feat-design-reviewer

```
Paraphrase (4c):
- What it does: <2–5 sentences>
- How the existing system works, per the documents: <2–5 sentences>
Paraphrase vs brief (4c): matches | contradicts (<what>)
Findings:
- [sec] <risk> — at: <artifact>: <section or line> — fix: <proposed change> — severity: high | medium | nice-to-have — rec: <rec>
- [cost] <cost or risk> — at: <artifact>: <section or line> — fix: <proposed change> — severity: … — rec: <rec>
- [design] <gap> — at: <artifact>: <section or line> — fix: <proposed change> — kind: clarity | fit | simplicity | readiness — severity: … — rec: <rec>
Checked and fine: <one line per lens>
Wrote:
- <the report path you were given>
```

**`Paraphrase vs brief (4c)`** is new: lens 4c writes its paraphrase from
the spec and plan first, then reads the state file's brief section and
compares. **`at:`/`fix:` labels** replace `→ … (<artifact>: <section>)`.
**Each `Findings:` item starts `[sec]`, `[cost]` or `[design]`** right
after `- `; `Findings: none` when there is none. Required: `Findings`
(`none` or items), `Paraphrase vs brief (4c)` when 4c is among the lenses,
`Wrote`. Digest: the `Paraphrase (4c)` items, and `Paraphrase
vs brief` when it says `contradicts`.

## feat-bug-assessor

Assess mode:

```
Mode: assess
Assessment: <absolute path> | none (<the extension's reason>)
Slug: ok | mismatch (<printed slug>)
Verdict: valid | likely valid, needs reproduction | invalid
Is a bug: yes | no — missing feature | no — expected behaviour | no — duplicate | no — unintelligible | no — refactor | no — backport
Several bugs: no | yes — <each in a few words, "; "-separated>
Reasoning: <one or two sentences; required when not "yes">
Report author: <as today>
Title: <short title>
Symptom: <one line>
Root cause: <one line>
Confidence: high | medium | low
Severity: critical | high | medium | low
Files in scope: <paths, comma-separated>
Remediations: <N>
Preferred remediation: <one line>
Alternatives: none | <one line each, "; "-separated>
Reproduction: reproduced | not reproduced | not reproducible here | needs approval
Reproduction detail: <command or steps run | what was run and what happened | what is missing | the commands needing approval>
Would run: none
- <command from the bug report, not run>
Public behaviour change: no | yes (<what callers or users see change>)
Risk area: none | <one or more of security, data, concurrency, ", "-separated, nothing else>
Performance bug: yes | no
Open questions: none
- <question> — recommended: <answer>
Proposed size: small | medium | large — <scope, confidence, risk area>
Sections: ok | error: <file> lacks <section>, …
Skipped hooks: <hook → why, or "none">
Wrote:
- <absolute path>
```

(`Wrote: none` with `Assessment: none` and no report path.) **`Risk area`** is a fixed value: `none`, or a comma-separated subset of
`security`, `data`, `concurrency` (no notes: `Risk area: Security (token
handling)` is unparsable; the detail goes under `Reasoning` or `Proposed
size`). **`Performance bug`** is `yes` or `no`.

New or split: **`Is a bug`** gains `no — refactor` and `no — backport`;
**`Several bugs`**; **`Confidence`** (out of `Root cause`);
**`Remediations`** (a number) with **`Preferred remediation`** and
**`Alternatives`**; **`Reproduction`** (a fixed value) with
**`Reproduction detail`**; `Would run` and `Open questions` become lists.
Required: `Mode`, `Assessment`, `Slug`, `Verdict`, `Is a bug`, `Several
bugs`, `Title`, `Confidence`, `Remediations`, `Reproduction`, `Public
behaviour change`, `Risk area`, `Performance bug`, `Open questions`,
`Proposed size`, `Sections`, `Wrote`. Digest: `Reasoning`, `Title`,
`Symptom`, `Root cause`, `Confidence`, `Severity`, `Several bugs` when
`yes`, `Remediations`, `Preferred remediation`, `Alternatives`,
`Reproduction detail`, `Would run`, `Public behaviour change` when `yes`,
`Open questions`, `Proposed size`, `Sections` when an error.

Test mode:

```
Mode: test
Test report: <absolute path>
Slug: ok | mismatch (<printed slug>)
Verdict: verified | partial | failed
Reproduction (post-fix): pass | fail | skipped | not-run — <command or note>
Checks:
- <check> → <result>
Missing for verified: n/a | <environment or evidence>
Not verified items: n/a
- <check, exactly as given> → pass | fail | missing (<why>)
Still failing: n/a | <what>
Would run: none
- <command from the bug report, not run>
Redacted: <count, or "none">
Sections: ok | error: test.md lacks <section>, …
Skipped hooks: <hook → why, or "none">
Wrote:
- <absolute path>
```

`Checks`, `Not verified items` and `Would run` become lists. Required:
`Mode`, `Test report`, `Slug`, `Verdict`, `Not verified items`, `Still
failing`, `Missing for verified`, `Sections`, `Wrote`. Digest:
`Reproduction (post-fix)`, `Missing for verified`, `Not verified items`,
`Still failing`, `Would run`, `Redacted` when not `none`.

## feat-shipper

```
PR: <url> | blocked | conflict
Command for the user: none | <the ! line, if blocked>
Conflicts: none
- <path the rebase stopped on>
Commits:
- <hash subject>
Left uncommitted: <paths, or "none">
Docs updated: <paths, or "none">
Wrote:
- <absolute path of each file or dir created, at its final path>
Not verified: none
- <n/a → check → why>
```

Fields as today; **`Conflicts`, `Commits`, `Wrote` and `Not verified`
become lists** (today "one per line"); `Command for the user: none` when
not blocked, and a command for the user starts `! cd <worktree> && `
(gates.md, 8 Ship). Required: `PR`, `Command for the user`, `Conflicts`,
`Wrote`, `Not verified`. Digest: `PR`, `Command for the user` when
blocked, `Conflicts` when `conflict`, `Left uncommitted` when not `none`,
`Not verified`; in rebase mode also `Wrote` (`rebase` checks it).

The shipper's text that says the orchestrator checks `Wrote:` and reads
the renumbered path is reworded for `step.sh`; its `review-summary` and
`shipped-verdict` calls are unchanged (the queries read the new lines).
