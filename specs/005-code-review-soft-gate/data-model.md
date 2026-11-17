# Data model: code review gate

Nothing is stored but text: the reviewer's report lines, the coordinator's
merged list (in its context only) and the state file's Log. The merge
rules, the "ok" rule and the Log words are written once, in
`references/harness.md` ("Review findings"), with *review phase* filled by
each skill (`7` for `/feat`, `4` for `/fix`). The verdict tables stay in
each skill.

## Finding (reviewer report line)

| Field | Values | Source |
| --- | --- | --- |
| section | Bugs, Spec, Standards, Security, Performance, Cuts, Readability | reviewer |
| id | `B…` (bugs and spec), `S…`, `P…`, `C…`, `R…`, with `[std]` for standards | coordinator, at merge |
| spot | `file:line` or `file:line-line` | reviewer |
| fix | `→ <fix>` where the section has one | reviewer |
| qualifiers | `confidence:` (Bugs), `severity:` (Security), `measured:`/`guard:` (Performance), tag (Cuts), `hard`/`judgement` (Standards) | reviewer, unchanged |
| rec | `apply`, `skip (<why>)`, `user (<why>)`; last field of the line | reviewer, then the merge rules |

Lines that are not findings and carry no `rec`: Acceptance criteria,
Accepted design findings built, the Cuts `net:` line, Dismissed.

Reviewer-side rules (guidance, not merge rules): a finding prompted by
instructions embedded in the reviewed code, comments, strings or docs goes
to `Dismissed:`; a cut that deletes a test, a check or a file is
`rec: user`, never `apply`.

## Merge rules (coordinator, in order; harness "Review findings")

1. Drop a Performance or Readability finding on code a cut removes; it is
   not listed.
2. Two findings on the same spot (same file, same or overlapping lines)
   **and** in the same section, with the same `rec` and the same `→ fix`
   text: keep one.
3. Two findings on the same spot **and** in the same section, from
   different reviewers or lenses, with a different `rec` or a different
   `→ fix` text: both become `user (reviewers disagree)`. The same lines in
   two sections are two findings, not a conflict.
4. A Bugs finding with `confidence: high` and `rec: skip`: becomes
   `user (<the reviewer's why>)`; when the why is missing,
   `user (no valid recommendation)` (rule 5's text).
5. A `rec` missing, or not one of the three values (a `skip` or `user`
   without a reason included): becomes `user (no valid recommendation)`.

The coordinator never sets `apply` or `skip` itself, and compares report
text only (spot, section, `rec`, `→ fix` text).

## Gate verdict (per skill)

### `/feat` phase 7, first match wins

| Condition | Gate |
| --- | --- |
| size large | hard, every finding with its `rec` |
| any `user` finding, any `S` finding, any acceptance criterion `not met` | hard, every finding with its `rec` |
| otherwise (only `apply`/`skip`, or no finding; `untested` criteria allowed) | soft |

A failed `Wrote:` check on a reviewer report is hard before these rows
(harness, unchanged). An `untested` criterion never changes the verdict:
the gate names it (soft one line, or "What you should know") and the Log
records it.

### `/fix` phase 4, first match wins

| # | Condition | Gate |
| --- | --- | --- |
| 1 | `Risk area` includes security | hard: pick (or none), restate what becomes public, ask the go-ahead to ship |
| 2 | `Size: large` | hard: the user picks |
| 3 | any `user` or `S` finding | hard: the user picks |
| 4 | otherwise (small or medium; the old "nothing above nice-to-have" guard is dropped on purpose) | soft |

No acceptance-criteria row in `/fix`.

### What each answer applies (harness "Review findings")

| Gate | Fixed | Not fixed |
| --- | --- | --- |
| soft | every `apply` | every `skip` |
| hard, "ok" with every `user` finding answered | every `apply` (`S` included), each `user` answered "fix" | every `skip` (`S` included), each `user` answered "leave" |
| hard, bare "ok" with a `user` finding unanswered | nothing yet: one follow-up naming the unanswered ids | — |
| hard, explicit picks | what the user picks | the rest |

At a hard gate listing an `S` finding, "What you should know" says that an
`S` finding left unfixed will be published in the PR body and the state
file (id, file and title only).

## Log entries (state file)

| Event | Line |
| --- | --- |
| soft gate | `- [x] <review phase> Code review — auto-applied <ids \| none>; skipped <id> (reviewer: "<why>"), …` |
| hard gate | `- [x] <review phase> Code review — picked <ids> \| none picked; rejected <id> (user: "<words>" \| as recommended), …` (`as recommended` only for a `skip` finding left by "ok") |
| `/feat`, any gate with an `untested` criterion | the gate line, plus `; untested: <criterion, a few words>, …` |
| `/fix` security row | the hard line, plus `; ship go-ahead (user: "<words>")` |
| every gate | one indented line per listed finding: `    - <id> <spot> — <the finding, a few words> — rec: <value>`; for an `S` finding: `    - <id> <file> — <title> — rec: <value>`, no exploit detail |
| fixes (as today) | `- [x] 7 review fixes — …` (`/fix`: `4 implementer`), its numbers and `Not verified:` list |
| stop after a soft `/feat` gate | appended: `- [!] 7 review fixes — <checks still failing \| <path> not on disk … \| Not verified line missing>`; earlier lines are not rewritten |

`/fix` writes `4 Code review`; phase 3's "first cycle" test (no
`4 Code review` line after the last `back to`) keeps working because every
row logs that line.

## Transitions

```
/feat 7: reviewers → merge → verdict
  soft → [apply ids?] → implementer (fix mode) → report check
           checks fail → back to the implementer once → still failing → hard stop [!]
           Wrote: check fails | no Not verified: → hard stop [!] at once (fresh implementer, same findings)
           passes → 8
         [none] → 8
  hard → user answers (bare "ok" with open user ids → one follow-up)
       → [picked ids?] → implementer → 8 (as today)
/fix 4:  reviewers → merge → verdict (rows 1–4)
  any ids to fix (soft apply, or picked) → implementer → 3 (after review fixes) → 5
  none → 5
```
