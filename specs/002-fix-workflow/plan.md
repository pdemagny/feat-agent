# Implementation Plan: /fix, a bugfix workflow wrapping Spec Kit's bug extension

**Branch**: `fix-workflow` | **Date**: 2026-11-06 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-fix-workflow/spec.md` (brief in [feat-state.md](feat-state.md))

## Summary

A third skill, `/fix`, takes a bug (issue or symptom) to a reviewed PR the
way `/feat` takes a brief: a thin orchestrator holding gates, phases run by
subagents sized from its own table. Assess and test run in a new
`feat-bug-assessor` (two modes, a fresh spawn for every test run), the fix
in `feat-implementer`'s new `bug` mode, review in the unchanged
`feat-code-reviewer` with a lens subset, ship in `feat-shipper`'s new `fix`
mode. The stages themselves are Spec Kit's bug extension
(`speckit-bug-assess|fix|test`), never re-implemented. The rules `/feat`
and `/fix` share move verbatim from `feat/SKILL.md` into
`.apm/skills/feat/references/harness.md`, which both read. `tracker.sh
create-issue` learns to build a `bug` issue from `assessment.md`;
`install.sh check` reports the
extension. A spike in a scratch project confirms the extension's names
first.

## Technical Context

**Language/Version**: Markdown prompts (skills, agents); bash 4+ (`tracker.sh`, `install.sh`, tests).

**Primary Dependencies**: Spec Kit's bundled bug extension (`specify extension add bug`, v1.0.1 with the pinned specify-cli 1.2.1), a new **prerequisite for `/fix` only**, installed per project, no network; nothing else new. `gh` and `git` as today.

**Storage**: files: `.specify/bugs/<slug>/` (state file + the extension's reports), committed with the PR.

**Testing**: `mise run lint` (shellcheck, py_compile, `claude plugin validate .`, and a new grep keeping `/feat`-only words out of the harness), `mise run test:tracker` (3 new offline cases), `mise run test:apm` (asserts the harness and `fix` skill land), the harness text-diff check, and at most four live `/fix` runs plus cheap checks in [quickstart.md](quickstart.md) (FR-043).

**Target Platform**: Claude Code sessions (Linux/macOS), installed by APM, the plugin or `install.sh`.

**Project Type**: Claude Code skills/agents package.

**Performance Goals**: cost, not speed: `/fix` spawns 4–8 agents per run (assess, fix, test, 1–3 reviewers, ship, plus retries). The orchestrator context gains the harness (moved, not added, for `/feat`).

**Constraints**: `/fix` and `/feat` stay thin (FR-005); `/feat` unchanged (FR-027); agent frontmatter without model/effort/tools/color; size tables in `/feat`'s row format; the extension's guardrails and URL trust policy kept.

**Scale/Scope**: one bug per run; ~40 tasks.

## Constitution Check

*Constitution: the project's `.claude/CLAUDE.md` (`.specify/memory/constitution.md` is the unfilled template).*

| Rule (CLAUDE.md) | Status |
|---|---|
| Size table in `feat/SKILL.md` is the source of truth; `Loads` column; mirror in docs/workflow.md (matrix and agents table) | pass: `/feat`'s table unchanged; `/fix` gets its own table in the same format and `Loads` column, mirrored in docs/workflow.md (a `/fix` matrix and agents-table rows); CLAUDE.md updated to name both tables |
| Agent frontmatter: no `model`, `effort`, `tools`, `color`; use `disallowedTools` | pass: `feat-bug-assessor` has `disallowedTools: Edit, NotebookEdit, Agent` only (it writes reports with Write; the spike confirms the bug skills don't need Edit) |
| Phase 4/7 reviewer groups under the table | pass: `/fix`'s groups under its table |
| Third-party skill added → apm.yml, install.sh deps, install.md, agent `skills:`, `Loads` | pass: none added. The bug extension is a Spec Kit extension installed per project (like the `speckit-*` skills), so it goes in install.md's prerequisites and `install.sh check`, not `deps`/`apm.yml` |
| Agent reports keep a fixed format; change both sides | pass: assessor report new (both sides in this change); implementer gains one bug-mode line; shipper report unchanged ([contracts/agent-reports.md](contracts/agent-reports.md)) |
| `/feat` stays thin; new work goes into an agent | pass: `/fix` reads reports only; its non-agent commands are the harness value "Commands the orchestrator may run besides the tracker": git for the worktree and diff, `gh issue view` (title), `gh api … --jq .author_association` (report author), `gh repo view` (name, visibility), `git ls-remote` (slug); no heading check at setup |
| New agent in `.claude-plugin/plugin.json` | pass: planned |
| `version` in apm.yml and plugin.json match | pass: untouched (release bumps) |
| shellcheck clean on install.sh, tracker, tests | pass: planned, `mise run lint` |
| CHANGELOG `## Unreleased` | pass: planned |
| `mise run lint`, `mise run test:apm` before committing | pass: both extended and green |
| Bump tool pins when tested on newer versions | pass: the spike runs the pinned specify-cli 1.2.1; a newer one bumps the pin |

Post-design re-check: pass, no violations; Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/002-fix-workflow/
├── plan.md                      # this file
├── research.md                  # decisions R1–R15 and rejected options
├── data-model.md                # bug run, state file, gate rules, test cycle
├── quickstart.md                # offline checks and live scenarios S1–S15
├── contracts/
│   ├── harness.md               # what moves into the shared reference; values each skill declares
│   ├── agent-reports.md         # assessor modes and report; implementer bug mode; shipper fix mode; reviewer inputs
│   ├── bug-extension.md         # recorded skill names, sections, verdict words, hooks (spike confirms)
│   └── tracker-cli.md           # create-issue from an assessment; new test cases
└── tasks.md                     # phase 5
```

### Source Code (repository root)

```text
.apm/skills/feat/
├── SKILL.md                     # harness sections moved out; "read the harness" + Harness values; bugs → /fix
├── references/harness.md        # NEW: thin orchestrator, gates, state file, board moves, resume
└── scripts/tracker.sh           # create-issue accepts .specify/bugs/<slug>/assessment.md (label bug)
.apm/skills/fix/SKILL.md         # NEW: /fix: harness values, size table, phases and gates, setup, phases 1–5
.apm/skills/brief/SKILL.md       # bug-labelled issue / bug idea → /fix; description
.apm/agents/
├── feat-bug-assessor.agent.md   # NEW: assess and test modes
├── feat-implementer.agent.md    # bug mode; report line; description
└── feat-shipper.agent.md        # fix mode; description
tests/tracker/run.sh             # cases 13–15
install.sh                       # check: bug extension skills and headings (non-blocking); uninstall: fix
mise.toml                        # lint: harness grep; test:apm: test -f harness.md and fix/SKILL.md
.claude-plugin/plugin.json       # agents += feat-bug-assessor; description
apm.yml                          # description mentions /fix
docs/workflow.md                 # /fix section: phases, gates, size matrix, reviewer groups; agents table; board moments
docs/install.md                  # prerequisite row for the bug extension; counts (3 skills, 9 agents); section 3 line; plugin names
docs/usage.md                    # a /fix section; "not for bugfixes" → /fix; resume
docs/design.md                   # third-party table: bug extension overrides (slug, re-run, retry, hooks)
README.md                        # /fix in the intro, quick start, layout
CHANGELOG.md                     # ## Unreleased entry
.claude/CLAUDE.md                # three skills; both size tables
```

**Structure Decision**: `/fix` is a sibling skill directory of `feat`, so
`../feat/references/harness.md` and `../feat/scripts/tracker.sh` resolve
in all three installs (research R1); nothing new for the installers to
ship except `install.sh uninstall` naming `fix`.

## Design

### The shared harness (FR-026, FR-027)

Contract: [contracts/harness.md](contracts/harness.md). Moved verbatim
from `feat/SKILL.md`: "You are a thin orchestrator" with the subagent-prompt
list and spawning rules, the gate semantics (hard/soft, size changes, the
user's commands, the message shape), the state file template and logging
rules, "Board moves", and resume. `/feat`-specific nouns become the values
each SKILL.md declares in a `## Harness values` block: the full list is the
contract's table (artifact dir noun, reviewer context, `Agents`/`Map`/`Size`
lines, board-check step, commands besides the tracker, phases that can't
be skipped, logged gate commands, …). `mise run lint` greps the harness
for `specifier|planner|tasker|spec\.md|brief|phase [0-9]|/feat`
(case-insensitive) and fails on a match. `feat/SKILL.md`
opens with: "Read `<this skill's base dir>/references/harness.md` now: it
holds the rules this skill follows. The values it refers to are below."
Then its values, size table, reviewer groups, phases-and-gates table,
setup and phases, all as today.

### `/fix` (`.apm/skills/fix/SKILL.md`)

Frontmatter: `name: fix`, a description that triggers on bugs ("Fixes a
reported bug … Use it as /fix #N, /fix <issue URL>, /fix "<symptom>" or
/fix resume. Not for features (use /brief) or refactors"),
`argument-hint: '#N | issue-url | "symptom" | resume'`.

Body, in order:

1. Intro (two lines) and "read `<this skill's base dir>/../feat/references/harness.md`"; missing → stop with the install hint.
2. `## Harness values` (contract table, /fix column).
3. `## Size table`, in `/feat`'s format:

| Phase                                     | Agent                | Loads                              | small           | medium          | large           |
| ----------------------------------------- | -------------------- | ---------------------------------- | --------------- | --------------- | --------------- |
| 1 Assess                                  | `feat-bug-assessor`  | speckit-bug-assess                 | opus · medium   | opus · medium   | opus · medium   |
| 2 Fix                                     | `feat-implementer`   | speckit-implement, speckit-bug-fix | sonnet · medium | opus · medium   | opus · high     |
| 3 Test                                    | `feat-bug-assessor`  | speckit-bug-test                   | sonnet · medium | sonnet · high   | opus · medium   |
| 4a Correctness, spec, standards (lens 7a) | `feat-code-reviewer` | —                                  | sonnet · medium | opus · medium   | opus · medium   |
| 4b Security (lens 7b)                     | `feat-code-reviewer` | security-and-hardening             | sonnet · medium | opus · medium   | opus · high     |
| 4c Performance (lens 7c)                  | `feat-code-reviewer` | performance-optimization           | sonnet · medium | sonnet · medium | opus · medium   |
| 4d Over-engineering (lens 7d)             | `feat-code-reviewer` | —                                  | sonnet · medium | sonnet · medium | sonnet · medium |
| 5 Ship                                    | `feat-shipper`       | —                                  | haiku · medium  | haiku · medium  | haiku · medium  |

   Under it: "Assess runs before the size is set, so its row is the same in
   every column; a deeper assessment comes only from "back to 1". 4a–4d are
   lenses 7a–7d of `feat-code-reviewer`. Phase 4 runs one
   `feat-code-reviewer` per group of lenses. **small**: one reviewer,
   lenses `7a+7b+7d`. **medium**: one reviewer, `7a+7b`; for a performance
   bug `7c` joins it (`7a+7b+7c`). **large**: `7a` and `7b` in parallel,
   plus `7c` in parallel for a performance bug. A group runs on the
   strongest model and effort among its rows. Applying the picked fixes uses
   the phase 2 row." Reasons in research R12.
4. `## Phases and gates` table (phases 0–5, the gate column from
   data-model.md), and the rule that a gate's message shape and semantics
   are the harness's. `/fix`-only gate rules here, from data-model.md "Gate
   commands": "skip 1/2/3" refused (FR-040); every "back to N" logged as a
   `back to N` line, and the cycle and retry rules read only the Log after
   the last one (FR-017); a ship with a verdict other than `verified` only
   on the user's explicit, logged decision (FR-018).
5. `## 0. Setup`:
   1. Claude Code only (as `/feat` step 0).
   2. Argument: `#N`, `owner/repo#N`, an issue URL, a quoted symptom, or
      `resume`. A brief path → `/feat <path>`; empty → show the usage and
      stop.
   3. Conventions (as `/feat` step 2).
   4. `.specify/` exists (else `specify init --here --integration claude`);
      the agents are installed, `feat-bug-assessor` included; the bug
      extension: absent (no `.specify/extensions/bug/` and no recorded
      skill) → stop: "run `specify extension add bug`". No heading check
      here (FR-035): the assessor's `Sections:` line catches a missing
      section, `install.sh check` warns on drift.
   5. Read `.specify/extensions.yml` as config: an enabled hook under any
      `before_bug_*`/`after_bug_*` key that would branch or commit →
      **hard gate**; agents skip it unless the user says otherwise; other
      hooks are allowed (FR-004).
   6. Board check (`check`), no move yet (research R8).
   7. Title, author and slug (research R6): read the issue title (tracker
      `read-issue` with board tracking, else `gh issue view`) and, for a
      GitHub issue, the author's association (`gh api
      repos/<o>/<r>/issues/<N> --jq .author_association`; a typed symptom →
      `user`, a non-GitHub URL → `unknown`); derive the slug;
      EnterWorktree; rename the branch to `fix-<slug>`, suffixing `-2`, …
      when `.specify/bugs/<slug>/` exists, the branch exists locally, or
      `git ls-remote --heads origin fix-<slug>` prints a line;
      `.feat-agent.yml` missing in the worktree → `[!]` line (as `/feat`
      phase 2). Create the state file; the setup Log line names the slug,
      the extension version and the report author.
6. `## 1. Assess`: spawn `feat-bug-assessor` (assess mode, row 1) with the
   report author and any approved commands. Gate per data-model.md
   ("Assessment report → gate"; every row that applies is listed). Not a
   bug → stop, as data-model says. Untrusted author or commands needing
   approval → the gate lists `Would run:`; approved ones are logged and
   passed to later assessor spawns (a re-assess when the user wants them
   run now). Security risk area → no issue by default (suggest a private
   security advisory), `gh repo view --json visibility` stated. Passing:
   set `Size:` and the title; issue creation when due (R9: repo from `gh
   repo view --json nameWithOwner`, confirmed at this hard gate; `create-issue
   .specify/bugs/<slug>/assessment.md <owner/repo>`, write `Issue:`); then
   the building move. Answers to open questions are logged and passed to
   the fix.
7. `## 2. Fix`: spawn `feat-implementer` (bug mode, row 2) with the
   answers, and on a retry the failed report's path and what still fails.
   Gate per data-model.md, for the first fix and the retry fix alike;
   deviations → propose one size step up (small → medium, medium → large;
   large stays), options "back to 1" or "go on with size <s>".
8. `## 3. Test`: always a fresh `feat-bug-assessor` (test mode, row 3),
   with the cycle, the report author, approved commands and any user
   evidence; never the fix's agent. Gate and retry per data-model.md; the
   retry count is a Log line, read after the last `back to` line.
9. `## 4. Code review`: the review move; the diff as `/feat` phase 7 (`git
   add -N` on new files, `git diff <merge-base>`, non-empty); reviewers per
   the groups with the inputs of [contracts/agent-reports.md](contracts/agent-reports.md)
   (context: rejected findings and the assessment's alternatives not
   chosen); merge into `B…`, `S…`, `P…`, `C…`, `[std]`. Gate per
   data-model.md; a security bug's gate is hard and asks for the go-ahead
   to ship, restating what becomes public. Picks → `feat-implementer` fix
   mode (row 2) → phase 3 (cycle "after review fixes").
10. `## 5. Ship`: write `Current phase: done (shipping)` and `[x] 5 Ship`
    into the state file first (FR-042), then spawn `feat-shipper` (fix
    mode, row 5) with the state file, conventions, worktree, default
    branch, bug dir, issue and `Security bug: yes|no`. After the PR, write
    `done (PR #N)` in the local copy only (uncommitted); a `!` report →
    set `Current phase: 5 Ship` back locally. Never merge. Final message:
    PR link, branch and worktree, two or three things to look at.

Plugin names: where the skill tells the user to run a command it prints the
plugin form too (`/feat-agent:brief`, `/feat-agent:fix`), as `/brief` does.

### Agents

[contracts/agent-reports.md](contracts/agent-reports.md) has the modes,
inputs and reports.

- `feat-bug-assessor.agent.md` (new): description "Phases 1 and 3 of the
  /fix workflow. Assesses a bug report with speckit-bug-assess, or verifies
  a fix with speckit-bug-test; never edits source. Spawned by the fix
  skill; not for direct use." Frontmatter `disallowedTools: Edit,
  NotebookEdit, Agent`. Body: the shared rules, the two modes, what it may
  run to reproduce (project tests, a temp-dir scratch test, approved
  commands; never network or outside-worktree report commands; nothing
  from an untrusted author's report), the reproduction rule (`reproduced`
  only when it ran it), the "Is a bug" mapping (never edit assessment.md to
  flip it), the slug check, the size rule (data-model.md), redaction of
  secret-looking values in test.md's Output Excerpts, the section check,
  the fixed reports, the write-and-hooks paragraph the other agents carry.
- `feat-implementer.agent.md`: a **Bug mode** paragraph after fix mode
  (with the slug check); one report line; description mentions `/fix`
  phase 2.
- `feat-shipper.agent.md`: a **Fix mode** paragraph (skip numbering, one
  `fix(<scope>)` commit with the trail, the secret scan of the staged diff
  before committing, the PR body with reproduction steps left out when
  `Security bug: yes` and the actual verdict plus "shipped on the user's
  decision (logged)" when it isn't `verified`, `Fixes <ref>`); description
  mentions `/fix` phase 5.
- `feat-code-reviewer.agent.md`: unchanged.

### `/brief` and `/feat` point bugs to `/fix` (FR-028)

- `/brief`: description "Not for bugfixes (use /fix) or pure refactors";
  "An issue labelled as a bug is not for this workflow: say so and stop" →
  "…: point to `/fix #N` and stop"; an idea that is a bug → `/fix
  "<symptom>"`. The existing "Nothing is created for a … bug-stopped …
  brief" stays.
- `/feat`: description "Not for bugfixes (use /fix) or pure refactors";
  setup step 1: an argument describing a bug → `/fix "<symptom>"` (or
  `/fix #N`).

### Tracker (FR-023)

[contracts/tracker-cli.md](contracts/tracker-cli.md). `create-issue`
dispatches on the path; `brief_parts` becomes one section parser used by
both sources (title prefix and the two section names as arguments); the
assessment path gets the same physical-directory check; `--label bug` only
for assessments. Three new offline cases; the stub `gh` needs no change.

### install.sh and mise (FR-031, FR-035)

- `check` with a project dir: after the speckit skills, for each recorded
  bug skill print `ok skill <s>` or `note skill <s> (needed by /fix only:
  specify extension add bug)`; when present, one `grep -c` per skill for its
  recorded headings and verdict words, short → `warn <skill> differs from
  the names /fix was tested with (bug 1.0.1)`. Neither sets `missing`.
- `uninstall`: add `"$target"/skills/fix` to the list.
- `mise.toml` `test:apm`: add `test -f .claude/skills/feat/references/harness.md`
  and `test -f .claude/skills/fix/SKILL.md`. `lint`: add
  `"! grep -Eiq 'specifier|planner|tasker|spec\\.md|brief|phase [0-9]|/feat' .apm/skills/feat/references/harness.md"`
  (FR-026).

### Docs

- `docs/workflow.md`: a `/fix` section: roles (same coordinator rules),
  phases at a glance, gates, the size matrix (mirror of the table above,
  review rows named by lens 7a–7d) and reviewer groups, "why these choices"
  lines (assess size-independent on Opus · medium, "back to 1" for more;
  fresh test spawns; lens subset; untrusted reports and security bugs),
  the board moments for `/fix`
  (In progress after the assess gate, In review at phase 4), the state file
  location. Agents table: new `feat-bug-assessor` row; implementer and
  shipper rows gain `/fix` phases and modes.
- `docs/install.md`: prerequisites row "Spec Kit bug extension — `/fix`
  only — `specify extension add bug` in each project"; section 3 adds the
  command for `/fix`; APM paragraph counts 3 skills and 9 agents; plugin
  names add `/feat-agent:fix`; section 4 mentions the `note`/`warn` lines.
- `docs/usage.md`: a `/fix` section limited to the arguments, the gates the
  user sees and resume, linking docs/workflow.md for the rest; "not for
  bugfixes (use Spec Kit's bug commands)" → `/fix`.
- `docs/design.md`: one paragraph on the bug extension's overrides
  (interactive slug → passed and checked; overwrite refusal → renamed
  attempts; "re-run assess" on failed → one retry then the user; hooks →
  read as config, as for the other `speckit-*` skills; report commands not
  run blindly), pointing to `.apm/skills/feat/references/harness.md`,
  `.apm/skills/fix/SKILL.md` and `.apm/agents/feat-bug-assessor.agent.md`;
  one line on the harness file in "Distribution".
- `README.md`: `/fix` in the intro and quick start; Layout adds
  `.apm/skills/fix/` and `references/`.
- `CHANGELOG.md` `## Unreleased`: one entry for `/fix` (prerequisite
  `specify extension add bug`), one for `/brief`/`/feat` pointing to it.
- `.claude/CLAUDE.md`: three skills; both size tables are sources of truth
  (mirror both in docs/workflow.md).

### Implementation order

1. **Spike** (FR-033): scratch project, pinned CLI, `specify extension add
   bug`, run the three stages once on a toy bug; update
   [contracts/bug-extension.md](contracts/bug-extension.md) with what was
   recorded, including the slug normalisation rules and that the stages
   write their reports with Write (no Edit). A difference from the spec's
   names → report it as a design problem (the planner amends spec.md)
   before step 3.
2. **Harness extraction** and `/feat` values; the lint grep; confirm
   `test:apm` lands `references/harness.md` (if APM drops it, stop: R1
   fails); text diff check (R2, quickstart S13a).
3. Tracker variant, test-first (cases 13–15).
4. `feat-bug-assessor`, implementer bug mode, shipper fix mode, plugin.json.
5. `fix/SKILL.md`; `/brief` and `/feat` pointers.
6. `install.sh`, `mise.toml`.
7. Docs, CLAUDE.md, CHANGELOG.
8. Live validation, at most four `/fix` runs (FR-043, quickstart "Live"):
   run 1 small end to end (S6); run 2 `/fix "<symptom>"` with board tracking to the end
   (S9: issue creation, board moves, `Fixes #N`), with the resume check
   S12; run 3 one medium security bug (S10+S11: first test failed, retry,
   review picks, re-test, disclosure prompts); run 4 the assess-only
   reports (S7 untrusted not-a-bug, S8 unintelligible). Then the cheap
   checks: `/feat resume` on an existing state file (S13b, with the text
   diff S13a in place of a full `/feat` run), S14, S15. These need the
   user's projects and GitHub, so they are marked for the user.

## Complexity Tracking

None.
