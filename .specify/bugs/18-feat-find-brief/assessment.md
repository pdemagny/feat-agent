# Bug Assessment: /brief writes the brief relative to the cwd and /feat only takes an exact path

- **Slug**: 18-feat-find-brief
- **Created**: 2026-11-18
- **Source**: pasted text (pdemagny/logistics#18, https://github.com/pdemagny/logistics/issues/18, read with `gh issue view`; host github.com, allowlisted)
- **Verdict**: likely valid, needs reproduction
- **Severity**: medium

## Report (verbatim or summarized)

> **/feat can't find a brief written in another session**
>
> ## Problem
> A brief written by `/brief` in a background job can end up in that job's tmp dir instead of `specs/briefs/` in the repo. A later `/feat` (after `/clear`, or in another session) then cannot find it, and in one run the user had to point at it.
>
> ## Done when
> - `/brief` always writes the brief to `specs/briefs/<short-name>.md` in the repo or its worktree, and says where.
> - `/feat <name>` also searches the repo's worktrees for the brief, and names the paths it searched when it finds none.

## Symptom

When `/brief` runs in a session whose working directory is not the repo (a background job working in a tmp dir), the brief is written to `specs/briefs/<short-name>.md` relative to that directory, outside the repo. A later `/feat` in a fresh context cannot find it: it only accepts the exact path it is given and never searches the repo or its worktrees. Expected: the brief always lands in the repo's (or its worktree's) `specs/briefs/`, `/brief` prints where, and `/feat <name>` finds it or lists where it looked.

## Reproduction

1. Start a Claude Code background job (or any session) whose cwd is a tmp dir rather than the repo root. [NEEDS CLARIFICATION: which kind of "background job" — a background agent, `claude -p`, a Workflow — and what its cwd was]
2. Run `/brief "<idea>"` and complete the interview; the brief is written to `<cwd>/specs/briefs/<short-name>.md`.
3. `/clear` (or open another session in the repo) and run `/feat specs/briefs/<short-name>.md` or `/feat <short-name>`.
4. Observed: `/feat` cannot read the brief; the user has to give its absolute tmp path.

Not run here: the steps need an interactive `/brief` interview in a session with a non-repo cwd, which this automated assessment cannot drive. Static evidence instead (read-only `grep`/`sed` on the skill files):

- `.apm/skills/brief/SKILL.md:113` — "Write it to `specs/briefs/<short-name>.md`:" — a relative path, with no anchor to the repo root (`git rev-parse --show-toplevel`) anywhere in the file; `<repo root>` is used only for `.logistics.yml` (line 32).
- `.apm/skills/brief/SKILL.md:188` — the closing block prints `Brief saved: specs/briefs/<short-name>.md` (relative), so the user is never told the absolute location.
- `.apm/skills/feat/SKILL.md:156-160` — "`$ARGUMENTS` must be a brief file … Read the brief": no resolution of a bare short name, no search of `specs/briefs/` in the repo root or in `git worktree list` worktrees, no message naming searched paths on failure.

## Suspected Code Paths

- `.apm/skills/brief/SKILL.md` §3 "The brief" (line ~113) — destination given as a cwd-relative path; nothing says to resolve the repo root (or the worktree root) first, nor to refuse/relocate when the cwd is outside a git checkout.
- `.apm/skills/brief/SKILL.md` §1, "From a brief" (lines ~80-89) — same relative `specs/briefs/<short-name>.md` "in this checkout" for the grown tiny brief.
- `.apm/skills/brief/SKILL.md` closing block (lines ~186-195) — prints the relative path only.
- `.apm/skills/brief/SKILL.md` §4 capability map — check whether the map's path has the same relative-path issue.
- `.apm/skills/feat/SKILL.md` §0 Setup step 1 (lines ~156-164) — takes `$ARGUMENTS` as a file path only; no lookup by name or across worktrees. (A `/tiny` brief is written in a `/tiny` worktree, `.apm/skills/tiny/SKILL.md:90`, so a brief outside the main checkout is already a normal case.)
- `.apm/skills/feat/SKILL.md` §2 step 3 (line ~199-200) — deletes `specs/briefs/<short-name>.md`; must delete the resolved path, not a cwd-relative one.

## Root Cause Hypothesis

`/brief` names the destination as a path relative to the session's working directory and never anchors it to the git top level, so a session started outside the repo (a background job in a tmp dir) writes the brief there; and `/feat`'s setup reads `$ARGUMENTS` as a literal file path with no fallback search, so a brief that is not exactly where the user points (wrong cwd, another worktree) is not found and the failure names no searched location. Confidence: medium for the `/brief` half (the text clearly leaves the anchor out; that the background job's cwd was a tmp dir is from the report, not reproduced), high for the `/feat` half (the setup text has no lookup at all).

## Proposed Remediation

**Preferred**: Two instruction changes, no script needed.

1. `/brief`: before writing, resolve the checkout root with `git rev-parse --show-toplevel` (the worktree's root when run inside one). If the cwd is not inside a git checkout, stop before the interview's output is lost to a tmp dir: ask for the repo path (or say the brief must be written in a repo checkout). Write the brief (and a capability map, and the grown tiny brief) to `<root>/specs/briefs/<short-name>.md`, and print the absolute path in the closing `Brief saved:` block, keeping the `/feat <path>` copy-paste line usable from the repo root.
2. `/feat` setup step 1: when `$ARGUMENTS` is not an existing file, treat it as a short name (or a relative brief path) and look for `specs/briefs/<name>.md` (and `<name>` as given) under the repo root, then under every worktree from `git worktree list --porcelain`. One match → use it and say which; several → list them and ask; none → stop and name every path searched. Phase 2 step 3 then deletes the resolved path (only when it is in this checkout; a brief found in another worktree is left as it is, like `/brief` does for a `/tiny` worktree).

**Alternatives**:
- Put the lookup in a script (`.apm/skills/feat/scripts/find-brief.sh`) with a bash test under `tests/` — more deterministic and testable, but adds a script, a shellcheck target, a `mise` test task and install wiring for what is a few lines of instruction.
- Only fix `/brief` (anchor the path) — fixes the reported cause but not the second "Done when" item; briefs in `/tiny` worktrees would still need an exact path.

**Files likely to change**:
- `.apm/skills/brief/SKILL.md` (anchor the write to the checkout root; absolute path in `Brief saved:`)
- `.apm/skills/feat/SKILL.md` (setup step 1 lookup; `argument-hint` to `specs/briefs/name.md | name | resume | rebase [PR]`; phase 2 step 3 deletes the resolved path)
- `docs/usage.md` and `docs/workflow.md` (where they describe `/brief`'s output and `/feat`'s argument), README.md's `/feat` line if the name form is documented
- Not touched: `references/harness.md` and `references/rebase.md` (the lookup is `/feat`-only, and `mise run lint` forbids the word "brief" there); `/tiny` (no change needed; it stays under its 200-line cap); the size tables (no model/effort change, so no `docs/workflow.md` matrix or `models.svg` re-render); `.claude-plugin/plugin.json` (no agent added).

**Tests to add or update**:
- The skills are prompts with no automated test harness; verification is manual: run `/brief` from a cwd outside the repo and check it stops or writes under the repo root with an absolute `Brief saved:` path; run `/feat <short-name>` with the brief in another worktree (found and named) and with no brief (stops naming each searched path).
- `mise run lint` and `mise run test:apm` must stay clean (harness.md/rebase.md word grep, /tiny line cap).
- If the script alternative is taken: a bash test in `tests/` for found / several / none, shellcheck-clean.

## Risks & Considerations

- A name lookup across worktrees can pick a stale brief from an abandoned worktree; with more than one match it must ask, not choose.
- Phase 2 deletes the brief after moving it into the state file: deleting a file in another worktree would surprise its owner; restrict the delete to the current checkout.
- `/brief` refusing to run outside a checkout changes behaviour for anyone running it from a non-repo dir on purpose; asking for the repo path is the gentler option.
- Public behaviour change: `/feat` accepts a short name and prints searched paths; `/brief` prints an absolute path. No interface between modules changes.
- No security, data or concurrency risk beyond the stale-match point above.

## Open Questions

- [NEEDS CLARIFICATION: what "background job" ran `/brief` (background agent, `claude -p`, Workflow script) and what its cwd was — does the fix also need `/brief` to detect a cwd that is inside a git checkout but not the intended repo?]
- [NEEDS CLARIFICATION: when `/brief` runs outside any checkout, should it stop or ask for the repo path?]
- [NEEDS CLARIFICATION: should `/feat` delete a brief it found in another worktree after moving it into the state file, or leave it?]
