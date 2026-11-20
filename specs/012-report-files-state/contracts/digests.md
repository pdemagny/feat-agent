# Contract: report files and digests

## The agent side

Eight agents gain the same short rule, placed just before their report
format: `feat-specifier`, `feat-planner`, `feat-tasker`,
`feat-implementer`, `feat-code-reviewer`, `feat-design-reviewer`,
`feat-bug-assessor`, `feat-shipper`. `feat-brief-reviewer` doesn't change.

Meaning of the rule (wording is the implementer's, a few lines):
- The orchestrator may give a report path with a request (a spawn, or a
  message asking for a new report). Then, once the work is done, write the
  full report (the format below, unchanged, its `Wrote:` line listing the
  report path) to that path with Write, as the last write, and hand back
  the digest: the same report minus the lines in the table below. Each
  request's report goes to the path given with it; never write an earlier
  path again.
- No report path: write no report file and hand back the full report.

Each agent's `Wrote:` description adds "and the report path, when one was
given".

### Digest

| Agent | Dropped from the hand-back (kept in the file) |
| --- | --- |
| `feat-code-reviewer` | `Dismissed:` |
| `feat-design-reviewer` | `Checked and fine:` |
| `feat-implementer` | the notable files of `Files changed:` (the line becomes `Files changed: <count>`) |
| `feat-tasker` | `Fixed:` |
| `feat-specifier`, `feat-planner`, `feat-bug-assessor`, `feat-shipper` | nothing |

`Resolved alone:` (implementer) stays whole. No length cap.

### The two reviewers

`feat-code-reviewer` and `feat-design-reviewer`:
- frontmatter: `disallowedTools` drops `Write`, keeps `Edit` (both become
  `Edit, NotebookEdit, Agent, Artifact, EnterWorktree`);
- description: "Read-only; reports findings" → read-only except its report
  file;
- body: "Write only the report file you are given; with none, write
  nothing." The existing read-only paragraph keeps its Bash rule;
- format: `Wrote: <the report path you were given, or "none">`.

### The shipper

- Given a report path under `specs/<short-name>/reports/` and numbering the
  dir in step 1 (or renumbering it in step 3): it writes the report under
  the dir's final path (`specs/<NNN>-<short-name>/reports/<same name>`)
  and lists that path on `Wrote:`, next to the renumbered dir. The
  shipper's agent file says this once, in its report-path rule.
- Staging: by path as today, never `reports/` (it ignores itself; `git add
  <spec dir>` skips it). Fix mode commits the bug dir: "state file,
  assessment, fix and test files, numbered attempts included; not
  `reports/`".
- New input: `State script: <path>`. It runs `review-summary` (`/feat`:
  `7`; fix mode: `4`) for the `### Code review` part, `shipped-verdict` in
  fix mode, `restore-phase` in rebase mode step 3. The prose rules they
  replace go.

## The coordinator side

Harness, *Reported files*, gains:
- a spawn given a report path: that path must be on `Wrote:` (`<path> not
  on Wrote:` otherwise), and passes the same `ls -d` check. Stated once,
  with no `/feat`-only words: "When the shipper renumbered the artifact
  dir, its `Wrote:` lists the new dir; the report path then counts as on
  `Wrote:` when the same `reports/<file>` under that new dir is";
- around each batch of code or design reviewers: `snapshot` before, then
  `unchanged` once the batch has reported (research R2). `changed` is a
  failed report check: log `- [!] <N> <phase> — files changed outside the
  reports`, hard gate; "What you should know" says a reviewer changed the
  worktree and shows the `- <path>` lines `unchanged` printed after
  `changed` (at most 10, then `- and <n> more`; with no manifest, its
  "see git status" line), as data; recommend reverting what it changed,
  then "back to N". The success path prints only `unchanged`, so nothing
  is shown then.

Rules that read the dropped lines change with them (same commit as the
agent files):
- `/feat` phase 7, `/fix` phase 4: "Reviewers verify their own findings
  and list what they dismissed" → "… what they dismissed, in their report
  file";
- `docs/workflow.md`: the same sentence and the `Wrote:` paragraph.

## Report keys (harness value *Report keys*)

| Skill | Keys |
| --- | --- |
| `/feat` | `2-specify`, `3-plan`, `4-<lenses>` (`4-4a+4b+4c`, `4-4a`, …), `5-tasks`, `6-US<n>`, `7-<lenses>` (`7-7a+7b`, `7-7a`, …, `7-7e`), `7-fixes`, `8-ship`; a move: `move`; `rebase`: `move`, `ship` |
| `/fix` | `1-assess`, `2-fix`, `3-test`, `4-<lenses>` (`4-7a+7b+7d`, …), `4-fixes`, `5-ship`; a move: `move`; `rebase`: `move`, `ship` |

A rerun (back to N, a retry, a resume, a continued agent's new report)
uses the same key; `report-path` numbers it.

## Not changed

`/tiny` (its `feat-code-reviewer` gets no report path: full report, writes
nothing) and `/brief`'s `feat-brief-reviewer`.
