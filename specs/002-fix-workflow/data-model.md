# Data model: /fix

No database: the "data" is Markdown files in the worktree and the gate
rules that read them. Field names of the extension's artifacts are in
[contracts/bug-extension.md](contracts/bug-extension.md); agent reports in
[contracts/agent-reports.md](contracts/agent-reports.md).

## Bug run

One report fixed in one worktree.

| Field | Value | Rule |
|---|---|---|
| slug | `[a-z0-9-]`, ≤ 40 chars | derived at setup (research R6), unique among the worktree's `.specify/bugs/*`, its local branches and `origin`'s branches (`git ls-remote --heads origin fix-<slug>`); taken → `-2`, `-3`, …; passed as `slug=<slug>` to every stage; the extension keeps it unchanged (no length cut, leading digit kept, R6); the agents check it against assess's printed `Slug:` line (backticks and `(user-provided)` stripped) and every report's `- **Slug**:` bullet (FR-041) |
| branch | `fix-<slug>` | EnterWorktree's branch renamed at setup |
| trail | `.specify/bugs/<slug>/` | state file + `assessment.md`, `fix.md`, `test.md` and their numbered earlier attempts; committed whole |
| issue | `#N` / `owner/repo#N` / none | from the argument, or created after the assess gate (never by default for a security bug) |
| report author | `OWNER` / `MEMBER` / `COLLABORATOR` / another association / `user` (typed symptom) / `unknown` (non-GitHub URL) | read at setup with `gh api repos/<o>/<r>/issues/<N> --jq .author_association`, counted only when the issue's `<o>/<r>` equals `gh repo view --json nameWithOwner` (else `unknown`), logged, passed to every assessor spawn and the bug-mode implementer; trusted = the first three and `user` (FR-036) |
| approved commands | list or none | report commands the user approved at the assess gate; logged; passed to later assessor spawns and the bug-mode implementer |
| size | small / medium / large / not set | set at the assess gate from the proposed size (the user may say `size <s>`); raised one step on accepted deviations |

## State file (`.specify/bugs/<slug>/feat-state.md`)

`/feat`'s format (harness), with /fix's values:

```markdown
# /fix state: <bug title, from the symptom; replaced by the assessment's title at the assess gate>

- Branch: fix-<slug> Worktree: <path>
- Size: not set | small | medium | large
- Agents: none (every spawn is fresh)
- Current phase: <0 Setup | 1 Assess | 2 Fix | 3 Test | 4 Code review | 5 Ship | done (shipping) | done (PR #N) | done (not a bug) | done (invalid)>
- Conventions: <the few lines agents need>
- Allowed Spec Kit hooks: <list or "none">
- Map: none
- Issue: <#N | owner/repo#N | none>

## Report

<the argument as given: the symptom text, or the issue ref/URL>

## Log

- [x] 0 Setup — board check ok; slug login-timeout; bug extension 1.0.1; report author MEMBER
- [x] 1 Assess — soft gate: valid, high confidence, reproduced (`go test ./auth -run TestTimeout`), 1 remediation, no public change; size small
- [x] 2 Fix — applied; no deviations; checks pass
- [x] 3 Test — failed (retry 1 of 1): symptom still reproduces under load; retry fix
- [x] 2 Fix — retry: applied; no deviations; checks pass
- [x] 3 Test — verified
- [x] 4 Code review — clean; soft
- [x] 5 Ship
```

Unfinished = `Current phase:` does not start with `done`. Setup writes the
file once the worktree exists (step 7); `[!]` lines from before (board
check) are written then.

**Ship state (FR-042).** Before spawning the shipper the orchestrator
writes `Current phase: done (shipping)` and `[x] 5 Ship`, so the copy the
shipper commits is already done and `/fix resume` on the default branch
after the merge finds nothing. After the PR it may write `done (PR #N)`
into the local copy, uncommitted. A shipper report with a `!` command for
the user to run (git blocked) commits the done state: it stays done, and
resume finds the run while its branch `fix-<slug>` has no upstream. A `!`
with nothing to commit (secret-scan block, another hard failure) → set
`Current phase: 5 Ship` back in the local copy (uncommitted) so resume
finds the run.

## Gate commands

- "back to N" is logged as `- [x] back to N — <reason>` (FR-017). A
  *`back to` line* is a Log line starting with `- [x] back to `; no other
  line counts as one.
- "skip 1", "skip 2", "skip 3" are refused (assess, fix and test can't be
  skipped); "skip 4" is allowed and logged with the reason (FR-040); for a
  security bug it still restates what becomes public and asks for the
  go-ahead to ship (logged, FR-037).
- A ship with a verdict other than `verified` needs the user's explicit
  decision at a hard gate, logged as `ship with <verdict> (user: "<words>")`;
  the shipper copies it into the PR body (FR-011, FR-018).
- Every test gate with a verdict logs `- [x] 3 Test — <verdict>…`. The
  shipped verdict, from the lines after the last `back to` line: the `ship
  with <verdict>` line if any, else the last `3 Test — <verdict>` line
  (else test.md's `**Result**`).

## Test cycle and retry counter

The orchestrator derives both from the Log, reading **only the lines after
the last `back to` line** (FR-017), so resume needs no new field and a
re-assess starts a fresh cycle.

```
            ┌──────────── failed, first cycle, no retry yet ─────────────────┐
            ▼                                                                 │
 1 Assess → 2 Fix → 3 Test ─ verified → 4 Review ─ soft (clean+small, not sec) → 5 Ship
            (gated)    │                   │                                  │
                       │                   └ picks → 2 (fix mode) → 3 Test (cycle "after review fixes")
                       ├ partial → hard gate (evidence → 3 again, fresh; or the user's explicit "ship anyway")
                       └ failed, retry used or after review fixes → hard gate ("back to 1" offered)
```

- **First cycle**: no `4 Code review` line after the last `back to`.
- **Retry used**: a `3 Test — failed (retry 1 of 1)` line after the last
  `back to`.
- The retry fix is gated like any fix (Fix report → gate below), then 3.
- Every arrow into 3 is a fresh `feat-bug-assessor` spawn; every arrow into
  2 a fresh `feat-implementer`.

## Assessment report → gate

From the assessor's assess-mode report.

| Condition (first match wins) | Gate |
|---|---|
| `Assessment: none` or `Verdict: invalid` or `Is a bug: no — …` (whatever the verdict, FR-039) | **stop**: show the reasoning; missing feature → point to `/brief #N` (or `/brief "<symptom>"`); no issue created or moved; state `done (not a bug)` / `done (invalid)` |
| `Sections: error …` or `Slug: mismatch …` | **hard** |
| `Report author` untrusted (not `OWNER`, `MEMBER`, `COLLABORATOR`, `user`) | **hard**: nothing from the report was run; list `Would run:`; the user may approve commands (logged, then re-assess with them) or go on |
| `Reproduction: not reproducible here (needs approval: …)` (a report command reaching the network or outside the worktree) | **hard**: list the commands; the user may approve them (logged, then re-assess with them) or go on |
| `Risk area` includes `security` | **hard**: no issue by default, suggest a private security advisory (the user may still ask for an issue); state from `gh repo view --json visibility` whether the PR, its body and the committed trail will be public once pushed |
| an issue to create (board tracking, no issue, not security or the user asked) | **hard**: name the repo (`gh repo view --json nameWithOwner`); the user confirms or answers "no issue" (logged; no `Fixes` line) |
| any of: `Proposed size` ≠ small; confidence ≠ high; `Reproduction` ≠ `reproduced`; `Remediations` ≠ 1; `Public behaviour change: yes`; `Verdict: likely valid, needs reproduction`; `Open questions` ≠ none | **hard** |
| otherwise | **soft** |

Several rows may apply; the gate message lists each. After the gate
passes: set `Size:` (and the title), create the issue if due (R9), then
the building move (R8).

### Is a bug (assessor's rule, FR-039)

| Extension says | Report says |
|---|---|
| Verdict `invalid` | `no — missing feature` / `no — expected behaviour` / `no — duplicate` / `no — unintelligible`, from the extension's reason |
| Verdict `valid` or `likely valid`, report asks for new behaviour (no current behaviour is wrong) | `no — missing feature` |
| otherwise | `yes` |

The assessor never edits `assessment.md` to make the two agree; `Is a bug:
no` decides.

### Proposed size (assessor's rule)

- **small**: one remediation, at most ~3 files in scope, confidence high,
  risk area none.
- **large**: risk area security, data or concurrency with confidence below
  high, or more than ~10 files in scope, or a remediation that changes a
  public interface across modules.
- **medium**: everything else. A risk area never yields small.

## Fix report → gate

Applies to the first fix and to the retry fix after a first `failed` test.

| Condition | Gate |
|---|---|
| `slug: mismatch` | **hard** |
| `deviations` ≠ none | **hard**, handled like a size increase: name the deviation and propose one size step up (small → medium, medium → large; large stays large); options "back to 1" (re-assess with fix.md's findings) or "go on with size <s>" |
| a check fails, or status ≠ `applied` | **hard** |
| otherwise | **soft** → 3 |

## Test report → gate

| Condition | Gate |
|---|---|
| `Sections: error …` or `Slug: mismatch …` | **hard** |
| `verified` | **soft** → phase 4 (or phase 5 after a re-test that followed review fixes) |
| `partial` | **hard** (Log: `3 Test — partial: <missing>`): show `Missing for verified`; the user supplies it (fresh re-test) or decides explicitly (logged) |
| `failed`, first cycle, retry unused | report and go back to 2 with `test.md` and `Still failing` (Log: `3 Test — failed (retry 1 of 1): <what>; retry fix`) |
| `failed` otherwise | **hard** (Log: `3 Test — failed: <what>`), "back to 1" offered |

## Review → gate

Reviewer groups (size table note; rows 4a–4d are lenses 7a–7d of
`feat-code-reviewer`):

| Size | Reviewers |
|---|---|
| small | one reviewer, `7a+7b+7d` |
| medium | one reviewer, `7a+7b`; `7a+7b+7c` when `Performance bug: yes` |
| large | `7a` and `7b` in parallel; plus `7c` in parallel when `Performance bug: yes` |

A group runs on the strongest model and effort among its rows.

| Condition | Gate |
|---|---|
| no finding above nice-to-have, no security finding, size small, risk area not security | **soft** → 5 |
| risk area security | **hard**: list the findings, if any, for the user to pick; restate what becomes public; ask for the go-ahead to ship |
| otherwise | **hard**: the user picks; picks → `feat-implementer` fix mode (row 2), then 3 |

## Shared harness reference

[contracts/harness.md](contracts/harness.md): the sections it holds and the
values each skill declares.
