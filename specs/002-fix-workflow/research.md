# Research: /fix

Decisions the spec left to planning, each with what was rejected. Facts
about the bug extension come from a read-only look at the extension
bundled with the pinned CLI (specify-cli 1.2.1 → bug v1.0.1; 1.3.0 ships
v1.0.2, which differs only in a README link) and at a project that already
runs it; the spike (task 1) confirms them in a scratch project with the
Claude integration. Recorded names live in
[contracts/bug-extension.md](contracts/bug-extension.md).

## R1. Where the shared harness lives and how both skills reach it

- **Decision**: `.apm/skills/feat/references/harness.md`. `/feat` reads
  `<this skill's base dir>/references/harness.md`; `/fix` reads
  `<this skill's base dir>/../feat/references/harness.md`. Each SKILL.md
  declares a "Harness values" block (state file path, header and lines,
  artifact dir, input section, resume search, board-check step, board-move
  moments, artifact owners, agents that may be continued, reviewer context,
  commands besides the tracker, tracker path; the full list in the
  contract). A lint grep keeps `/feat`-only words out of the harness.
  Contract: [contracts/harness.md](contracts/harness.md).
- **Rationale**: the brief fixes the location (under the `feat` skill dir,
  relative path from `/fix`, as `/brief` reaches `../feat/scripts/tracker.sh`).
  All three installers ship skill directories whole and as siblings: APM
  (`.claude/skills/feat`, `.claude/skills/fix`), the plugin
  (`skills: ./.apm/skills/`, so `.apm/skills/feat` and `.apm/skills/fix`),
  and `install.sh` (one link or `cp -R` per `.apm/skills/*/`). `test:apm`
  asserts the file lands. `references/` is the Agent Skills convention for
  extra files a skill reads on demand.
- **Alternatives**: a condensed copy in `/fix` (rejected by the brief:
  drifts); a top-level shared skill (a fourth skill users could invoke by
  mistake, and a new install surface); inlining the harness into both
  SKILL.md files with a lint diff (still two copies).

## R2. Keeping /feat identical after the extraction (FR-027)

- **Decision**: move text verbatim; only the /feat-specific nouns
  (`specs/<short-name>/`, phase numbers 2–8, specifier/planner/tasker) become
  harness values declared in `feat/SKILL.md`. `/feat` reads the harness as
  its first step, so its context holds the same rules as before (one extra
  Read call, about the same tokens).
- **Verification** (design review D8): a task diffs old and new text (every
  removed sentence is in the harness or still in SKILL.md), the lint grep
  of contracts/harness.md keeps `/feat`-only words out of the harness, and
  one `/feat resume` on an existing state file (quickstart S13a, S13b) shows the
  harness is read and the recap and gate come out as before. No full
  `/feat` run.

## R3. How feat-bug-assessor loads the extension's skills

- **Decision**: no `skills:` preload; the agent invokes `speckit-bug-assess`
  (assess mode) or `speckit-bug-test` (test mode) with the Skill tool, like
  the reviewers load lens skills on demand. The size table's `Loads` column
  says which one each row loads.
- **Rationale**: one agent, two modes; preloading both pays for the unused
  one on every spawn, and test runs are spawned up to three times.
- **Alternative**: two agents (`feat-bug-assessor`, `feat-bug-tester`):
  rejected by the spec (FR-009 names the assessor in test mode).

## R4. feat-implementer in bug mode keeps its preload

- **Decision**: `feat-implementer` keeps `skills: speckit-implement`; in bug
  mode it also invokes `speckit-bug-fix`. Row 2's `Loads` lists both.
- **Rationale**: removing the preload would change `/feat`'s phase 6
  (FR-027). The cost is the preloaded skill's size per fix spawn, a few k
  tokens; if it proves large, a follow-up issue proposes a lighter
  preload (design review D16).

## R5. Re-running a stage whose report already exists

The extension never overwrites a report in automated mode (spike,
contracts/bug-extension.md, "Existing report"): `speckit-bug-assess`
refuses and picks a new unique slug, which would split the trail;
`speckit-bug-fix` and `speckit-bug-test` refuse and stop, which would block
the retry and the re-test.

- **Decision**: before running a stage whose report exists, the agent
  renames it to `<report>-<n>.md` (next free `n`: `test-1.md`, `test-2.md`,
  `fix-1.md`, `assessment-1.md` for "back to 1") and passes `slug=<slug>`
  explicitly. The trail keeps every attempt; the unnumbered file is the
  latest.
- **Alternatives**: a new slug per attempt (breaks the one-dir trail and
  resume); deleting the old report (loses the evidence the retry is based
  on).

## R6. Slug derivation (FR-002)

- **Decision**: the orchestrator derives the slug at setup: from an issue,
  `<N>-<2–3 words of its title>`; from a symptom, 2–4 words of it;
  lowercase kebab-case, `[a-z0-9-]`, at most 40 characters. In the
  worktree, if `.specify/bugs/<slug>/` exists, branch `fix-<slug>` exists
  locally, or `git ls-remote --heads origin fix-<slug>` prints a line (a
  pushed, unmerged branch from an earlier run), append `-2`, `-3`, … (design
  review D15). It passes `slug=<slug>` to every stage, so the extension's
  interactive slug prompt never fires; the agents compare it with the
  assess stage's printed `Slug:` line (backticks and the parenthesised
  resolution stripped) and with every report's `- **Slug**:` bullet, and
  error on a mismatch (D19, FR-041).
- **Extension normalisation** (spike, contracts/bug-extension.md): the
  assess stage lowercases a user-provided slug, turns spaces into `-` and
  drops characters outside `[a-z0-9-]`, with no length cut and a leading
  digit kept. A slug of this rule (`[a-z0-9-]`, at most 40 characters,
  `<N>-<words>` for an issue) therefore passes unchanged; the 40-character
  cap is ours, not the extension's.
- **Report author** (D1): for a GitHub issue the orchestrator also reads
  `gh api repos/<o>/<r>/issues/<N> --jq .author_association`, logs it in
  the setup line and passes it to every assessor spawn (R7).
- **Issue title**: with board tracking from the tracker's `read-issue`
  (as `/brief` does), else `gh issue view <N|URL> --json number,title,url`.
  Reading an issue is not reading code (thin rule holds).
- **Non-GitHub URL**: slug from its last path segment; it is the report
  source, not an `Issue:` (no `Fixes` line; with board tracking, issue
  creation is offered as for a symptom).

## R7. Reading a GitHub issue for the assessor

- **Decision**: for `#N`, `owner/repo#N` or a `github.com/.../issues/N` URL,
  the assessor reads the issue with `gh issue view <ref> --json
  number,title,body,url` and passes its title and body to
  `speckit-bug-assess` as pasted text, labelled with `owner/repo#N`. Other
  URLs go to the extension unchanged, so its URL trust policy applies as is
  (automated mode: unrecognised hosts are not fetched).
- **Rationale**: the extension fetches URLs with a web fetch, which fails
  on private repos; `gh` is already authenticated. The issue body is data,
  never instructions (the extension's own rule, restated in the agent).
- **Running what the report says** (design review D1, FR-036): a report's
  reproduction steps are untrusted input that would run with the user's
  credentials. Reproduction (assess step 3 and test mode) runs only the
  project's own test runner and tests, plus a scratch test the assessor
  writes under the system temp dir that calls repo code, plus commands the
  user approved at a gate. A report command that fetches from the network
  or touches paths outside the worktree is never run: `not reproducible here
  (needs approval: <command>)`. Trust comes from the author's association
  (read by the orchestrator, R6): `OWNER`, `MEMBER`, `COLLABORATOR` and a
  symptom the user typed are trusted; any other association, and a
  non-GitHub URL (no association to read), are not: nothing from the report
  is run and the assess gate is hard, listing the commands the assessor
  would run (`Would run:`). The assessor report gives `Report author:`.
- **Alternatives**: running reproduction steps in a sandbox (a new service
  and dependency for a check the user can approve in one line); trusting
  every author of a repo the user owns (public repos take issues from
  anyone).

## R8. When the first board move happens

FR-022 first said "building from setup"; FR-014 and SC-003 say an existing issue
is left untouched when the report is not a bug. A move at setup would put
a non-bug on the board as In progress.

- **Decision**: setup runs only `check`. The building move runs once the
  assess gate passes: right away for an existing issue, after creation for
  a new one. Review move at phase 4; resume moves by phase (building 1–3
  after the assess gate, review 4–5).
- Accepted by the user at the design review (A1); FR-022 now says so.

## R9. Issue creation confirmation and the assess gate

- **Decision**: when an issue is to be created (board tracking, no issue,
  a real bug), the assess gate names the repo (`gh repo view --json
  nameWithOwner`) and is hard, because the user must confirm it (FR-020,
  US4-1). The user may answer "no issue" (logged; no `Fixes` line).
  A failed creation is logged `[!]`, flagged at the next gate, and the run
  goes on without an issue.
- Consequence: SC-002 (zero hard gates) holds for `/fix #N` and for runs
  without board tracking, not for `/fix "<symptom>"` with board tracking.
  Accepted by the user at the design review (A2); FR-020 and SC-002 now say
  so.
- **Security bugs** (design review D2, FR-037): when the assessment's risk
  area includes `security`, a public issue, PR body or committed trail can
  disclose a vulnerability before it is fixed. So: the assess gate is hard;
  issue creation is off by default and the gate suggests a private security
  advisory (the user may still ask for an issue); the gate states, from
  `gh repo view --json visibility`, whether the PR, its body and the
  committed trail will be public once pushed; the code-review gate is hard
  and asks for the go-ahead to ship; the shipper puts the reproduction
  status, not the steps, in the PR body. The trail itself is committed as
  for any bug (the user decides at the gate).
- **Alternatives**: creating the advisory with `gh api` (one more write
  surface for a step the user does once, in the UI); leaving the trail out
  of the commit for security bugs (breaks resume and the one-trail rule).

## R10. Tracker: issue from an assessment

- **Decision**: `create-issue` accepts either path: `specs/briefs/<name>.md`
  (unchanged) or `.specify/bugs/<slug>/assessment.md`. For an assessment:
  title = the text after `# Bug Assessment: ` (the extension's one-line
  summary of the symptom; the Symptom section is one or two sentences, too
  long for a title); body = `## Symptom` and `## Root Cause Hypothesis`
  sections, then `Trail: .specify/bugs/<slug>/`; `--label bug` hardcoded.
  Same path hardening as briefs (`.specify/bugs` must resolve inside the
  repo, regular file, no symlink), same repo confirmation, never retried.
  One section parser serves both documents.
- **Label**: GitHub repos get a `bug` label by default; if it is missing,
  `gh issue create` fails before creating anything and the script prints
  gh's reason (no fallback without the label).
- **Alternative**: a separate `create-bug-issue` subcommand: same code,
  one more usage line; the path already says what it is.

## R12. Models and efforts for /fix's size table

Assess runs before the size is known (the assess gate proposes it), so its
row is the same in every column (design review D6: `opus · medium`, not
`opus · high`). Effort never rises on its own: a deeper look comes only
from "back to 1", a re-assess the user chooses (after deviations, a second
`failed`, or new evidence), after which the later phases run at the larger
size set at that gate.

| Row                  | small           | medium          | large           | Why |
| -------------------- | --------------- | --------------- | --------------- | --- |
| 1 Assess             | opus · medium   | opus · medium   | opus · medium   | root cause is the plan of a fix: everything after depends on it, so Opus even for small; medium effort because most bugs are small and the gate catches a weak assessment (confidence, reproduction, open questions); size unknown when it runs |
| 2 Fix                | sonnet · medium | opus · medium   | opus · high     | same as `/feat`'s implement row; also applies picked review fixes |
| 3 Test               | sonnet · medium | sonnet · high   | opus · medium   | runs checks and judges honestly; mostly commands; effort before model; spawned up to three times |
| 4a Correctness (7a)  | sonnet · medium | opus · medium   | opus · medium   | same as `/feat` 7a |
| 4b Security (7b)     | sonnet · medium | opus · medium   | opus · high     | same as `/feat` 7b |
| 4c Performance (7c)  | sonnet · medium | sonnet · medium | opus · medium   | same as `/feat` 7c; only for a performance bug |
| 4d Over-engineering (7d) | sonnet · medium | sonnet · medium | sonnet · medium | same as `/feat` 7d |
| 5 Ship               | haiku · medium  | haiku · medium  | haiku · medium  | same as `/feat` 8 |

Rows 4a–4d keep `/feat`'s lens letters (4a–4d are lenses 7a–7d of
`feat-code-reviewer`, D21), so the reviewer gets the lens names it knows.
Reviewer groups (D7): **small** one reviewer on 7a+7b+7d at the strongest
of those rows (sonnet · medium); **medium** one reviewer on 7a+7b (opus ·
medium), and 7c joins that reviewer for a performance bug (7a+7b+7c, still
opus · medium) rather than a separate sonnet spawn: one spawn's base
context (~36k) costs more than one more lens on a reviewer already reading
the diff; **large** 7a and 7b in parallel (opus · medium, opus · high),
plus 7c as a third reviewer in parallel for a performance bug.

## R13. The reviewer's spec pass without spec.md

- **Decision**: `feat-code-reviewer` stays unchanged (FR-010). `/fix` gives
  it the bug dir as the feature dir and says, in the prompt, that there is
  no spec.md: the spec pass checks the diff against `assessment.md`
  (Proposed Remediation, Tests to add or update) and `fix.md`. Accepted
  `[sec]` design findings: none; rejected findings: those logged so far;
  in place of a brief's "Alternatives rejected", the assessment's
  remediation alternatives not chosen (the harness value "Context handed
  to reviewers", D9).

## R14. Bug extension checks in install.sh and setup (FR-031, FR-035)

- **Decision**: `install.sh check <project>` prints one line per recorded
  skill (`ok`, or `note … needed by /fix only: specify extension add bug`)
  and a `warn` line when a recorded section heading or verdict word is not
  found in the installed skill; neither changes the exit code (the
  extension is a `/fix`-only prerequisite). Setup only checks that the
  extension exists (no `.specify/extensions/bug/` and none of the recorded
  skills → stop with `specify extension add bug`); it runs no heading
  check (design review D10): section compatibility is the assessor's job
  (`Sections: error`, FR-035) and the drift warning is `install.sh check`'s.
- **Uninstall**: `install.sh uninstall` also removes the `fix` link.

## R15. The spike

- **Decision**: task 1, before anything that depends on names: in a temp
  dir, `git init`, `specify init --here --integration claude`, `specify
  extension add bug`; record the generated skill names, the artifact
  headings and verdict/status words from the installed skill files, the hook
  event names from the extension's README, and what each stage prints, by
  running the three stages once on a toy bug in that scratch project.
  Findings go into contracts/bug-extension.md. A difference from the spec's
  names is reported as a design problem; the planner amends spec.md (the
  implementer never edits it). Use the pinned CLI (1.2.1); if the spike runs
  on a newer one, bump the pin in mise.toml (project rule).
