---
name: fix
description: >
  Fixes a reported bug and takes it to a reviewed PR: assesses the report
  with Spec Kit's bug extension, fixes it, has a fresh agent verify the fix,
  reviews the code, then commits the fix with its trail and opens a PR on
  its own branch/worktree. Each phase runs in a feat-* subagent whose model
  and effort follow the bug's size; this session only coordinates and holds
  the gates where the user decides. Use it as /fix #N, /fix <issue URL>,
  /fix "<symptom>" or /fix resume, or /fix rebase to bring a shipped fix's
  PR onto the current main. Not for features (use /brief) or refactors.
argument-hint: '#N | issue-url | "symptom" | resume | rebase [PR]'
---

# /fix: from a bug report to a PR

The user's request: `$ARGUMENTS`

This skill runs Spec Kit's bug extension (assess, fix, test) in subagents,
then a code review and the ship, stopping at gates where the user decides.
Nothing gets merged, and nothing is called fixed until an agent that did not
write the fix has verified it.

Read `<this skill's base dir>/../feat/references/harness.md` now: it holds
the rules this skill follows. The values it refers to are below. If it is
missing, stop: "/fix needs logistics' `feat` skill
(references/harness.md); install or update logistics".

## Harness values

- *Skill*: `fix`.
- *Artifact dir*: the bug dir, `.specify/bugs/<slug>/`.
- *State file*: `.specify/bugs/<slug>/feat-state.md`, created at setup
  step 7.
- *The state file is created*: when setup step 7 creates it.
- *Title* and *input section*: `# /fix state: <bug title>`; `## Report`,
  the argument as given, on one line (a multi-line symptom's lines joined
  with spaces).
- *Size line*: `not set | small | medium | large`.
- *Agents line*: `none (every spawn is fresh)`.
- *Current phase values*: `<N> <name>` (0–5), `done (shipping)`,
  `done (PR #N)` (local copy only), `done (not a bug)`, `done (invalid)`.
- *Map line*: `none`.
- *Issue ref*: the `Issue:` line of the state file (`none`: no issue, so
  no board moves and no `Fixes` line). It is the report's issue, or the one
  created after the assess gate (phase 1, "Issue creation").
- *State script*: `<this skill's base dir>/../feat/scripts/state.sh`
  (harness, State file).
- *Resume queries*: `S cycle '<state file>' && S retry-used '<state
  file>'` when the run is in phase 3 (Cycle and retry); else none.
- *Report keys* (harness, Report files): `1-assess`, `2-fix`, `3-test`,
  `4-<lenses>` (`4-7a+7b+7d`, …), `4-fixes`, `5-ship`; a move: `move`;
  `rebase`: `move`, `ship`.
- *Artifacts the orchestrator reads*: the state file once on resume
  (harness, Resume); assessment.md, fix.md or test.md only to quote a line
  the user must decide on.
- *Commands besides the tracker*: git for the worktree and the diff;
  `gh issue view <ref> --json number,title,url`;
  `gh api repos/<o>/<r>/issues/<N> --jq .author_association`;
  `gh repo view --json nameWithOwner,visibility`;
  `git ls-remote --heads origin fix-<slug>`; `ls -d -- '<path>' …` on a
  report's accepted `Wrote:` paths (harness, Reported files).
- *Artifact owners*: assessor: assessment.md (re-assess, "back to 1");
  implementer: code and fix.md.
- *Agents that may be continued*: none: every spawn is fresh.
- *Reviewer context*: the rejected findings and the assessment's
  remediation alternatives not chosen (`**Alternatives**` of Proposed
  Remediation).
- *Review phase*: 4.
- *Size triggers*: the assess gate's proposed size (phase 1); deviations
  from the assessment (phase 2): propose one size step up (small → medium,
  medium → large; large stays large), options "back to 1" (re-assess) or
  "go on with size <s>".
- *Phases that can't be skipped*: 1, 2, 3 ("skip 1", "skip 2", "skip 3"
  are refused).
- *Logged gate commands*: "skip N" (with the reason), "size <s>", and
  every "back to N" as a `back to N` Log line.
- *Tracker script*: `<this skill's base dir>/../feat/scripts/tracker.sh`.
- *Board-check step*: Setup step 6.
- *Building move*:
  - when: after the assess gate passes (right away for an existing issue,
    after creation for a new one);
  - on resume: in 1–3, once that gate has passed;
  - after "back to N": N in 1–3, from 4 or 5.
- *Review move*: when phase 4 starts; on resume in 4–5.
- *Base-check boundaries*:
  - the start of every phase from 2 on;
  - phase 3 after review fixes;
  - any "back to N" with N ≥ 2.

  "back to 1" re-assesses with no check; checks resume at phase 2, once
  the assess gate has set the size (the setup fetch covers phase 1).
- *Resolver context*: assessment.md and fix.md, those that exist.
- *Implement row*: the phase 2 row. *Ship row*: the phase 5 row.
- *Number check*: none.
- *Secret-scan script*: `<this skill's base
  dir>/../feat/scripts/secret-scan.sh`.

## Size table

The models and efforts `/fix` passes on every spawn. Generated from
`sizes.json` in a checkout; edit that, not this table. Agent files carry none.
`Loads` is what the agent reads for its job.

<!-- sizes-start fix-table -->

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

<!-- sizes-end fix-table -->

Assess runs before the size is set, so its row is the same in every
column; a deeper assessment comes only from "back to 1". 4a–4d are lenses
7a–7d of `feat-code-reviewer`. Phase 4 runs one `feat-code-reviewer` per
group of lenses. **small**: one reviewer, lenses `7a+7b+7d`. **medium**:
one reviewer, `7a+7b`; for a performance bug `7c` joins it (`7a+7b+7c`).
**large**: `7a` and `7b` in parallel, plus `7c` in parallel for a
performance bug. A group runs on the strongest model and effort among its
rows. Applying the review fixes and moving onto a new main use the phase 2
row.

## Phases and gates

| # | Phase       | Runs in                                         | Gate                                                                                                                                         |
| - | ----------- | ----------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| 0 | Setup       | you                                             | hard only if a bug-extension hook would branch or commit                                                                                     |
| 1 | Assess      | `feat-bug-assessor` (assess mode)               | **stop** if not a bug; hard by default, soft only on the conditions in phase 1                                                               |
| 2 | Fix         | `feat-implementer` (bug mode)                   | soft unless deviations from the assessment, a failing check or a status other than `applied`                                                 |
| 3 | Test        | `feat-bug-assessor` (test mode), always fresh   | soft on `verified`; **hard** on `partial` or an item left unaccounted; `failed` goes back to 2 once, then **hard** with "back to 1" offered  |
| 4 | Code review | `feat-code-reviewer` ×1 (small, medium) or ×2–3 | **hard** on a security risk area, `Size: large`, or a `user` or `S` finding; else soft (the `apply` findings are fixed, then 3 again)         |
| 5 | Ship        | `feat-shipper` (fix mode)                       | none: ends with the PR link                                                                                                                  |

From phase 2 on (once the assess gate has set the size), each phase starts
with the base check (harness, Moving onto a new main): silent when main
has not moved; a move is listed at the next gate, or stops there when it
needs your call.

Gate message shape and hard/soft semantics are the harness's. Every
report's `Wrote:` line is checked first (harness, Reported files): a failed
check makes that phase's gate hard, before any row below.

**State file calls** (harness, State file; `S` is `bash '<state
script>'`, every argument single-quoted). Each phase from 2 to 5 (5: the
command under 5. Ship) starts with one Bash command: the `log` lines of the gate just passed, `S set
'<state file>' 'Current phase' '<N> <name>'`, then `S refused-base
'<state file>'` for the base check, and in phase 3 `S cycle '<state
file>' && S retry-used '<state file>'`, then `S report-path '<state
file>' '<key>'` for each of the phase's spawns (the *Report keys*), and in
phase 4 `S snapshot '<state file>'` last (harness, Report files), joined
with `&&`. A "back to N" is the same command, its `- [x] back to N —
<reason>` line first. Every other spawn gets its report path the same way,
chained onto the `log` or `set` made before it. No open `- [ ] <N>
<phase>` line is written.

## Gate commands

The harness's gate commands apply, with these `/fix` rules:
- Any other skip ("skip 4") is allowed: log `- [x] skip N — <the user's
  reason>` (ask for a reason if none is given). For a security bug, "skip
  4" still restates what becomes public once pushed and asks for the
  go-ahead to ship (logged as at the review gate).
- A `back to` line (`- [x] back to N — <reason>`) resets the test cycle
  and retry count; "back to N" (1–3) from 4 or 5 makes the building move.
- **Shipping without `verified`**: a `partial` or `failed` verdict reaches
  phase 5 only on the user's explicit decision at a hard gate, never on
  silence or a soft gate. Ask for it in plain words, then log `- [x] ship
  with <verdict> (user: "<their words>")`; the shipper copies it into the
  PR body. A decision taken in the first cycle still goes through phase 4
  first.

Where this skill tells the user to run a command, it prints the plugin
form too: `/fix` is `/logistics:fix`, `/brief` is `/logistics:brief`
and `/feat` is `/logistics:feat` when logistics is installed as a Claude
Code plugin.

---

## 0. Setup

1. This workflow needs Claude Code: subagents spawned by name with a
   `model` and `effort` per call, and `EnterWorktree`. If you can't do
   that here, stop: say `/fix` runs only in Claude Code. Don't run the
   phases inline instead.
2. The argument:
   - `$ARGUMENTS` is one of: `#N`, `owner/repo#N`, an issue URL, a quoted
     symptom, `resume`, or `rebase [<PR number, URL or branch>]`.
   - A brief path (`specs/briefs/<name>.md`): stop and point to `/feat
     <path>`.
   - Empty: show the usage (`/fix #N | <issue URL> | "<symptom>" |
     resume | rebase [PR]`) and stop.
   - Refused here when the argument makes it plain (nothing created, no
     issue touched): a refactor request (not a bug: say so; `/brief` if it
     needs planning), a backport request (`/fix` fixes the current branch
     only), several bugs in one report (ask which one to fix; each other
     is its own `/fix` run).
   - A report whose cause and fix are plain from it (a typo, a broken
     link, a wrong value it names) and that passes `/tiny`'s tiny check:
     offer `/tiny <the argument>` (`/logistics:tiny` as a plugin), which
     fixes it in this session with no assessment or subagent. Stop if the
     user takes it; else go on.
   - An issue URL on a host other than GitHub is passed to the assessor as
     is: the bug extension's own URL trust policy decides whether it is
     fetched, and `/fix` never fetches it itself or widens that policy;
     its author counts as `unknown` (step 7).
   - `resume`: run steps 1, 3, 4 and 5, then follow Resume (below) instead
     of steps 6 and 7.
   - `rebase [<PR number, URL or branch>]`: run steps 1, 3, 4 and 5 (no
     board check: `rebase` makes no board moves), then read `<this skill's
     base dir>/../feat/references/rebase.md` and follow it instead of
     steps 6 and 7; no other run reads that file.
3. Read the project's `CLAUDE.md` / `AGENTS.md` and project memory. They
   override this file where they disagree. Keep the few lines agents need
   (commit style, branch rules, where checks live, docs to update).
4. Check `.specify/` exists (else stop: `specify init --here --integration
   claude`) and the `feat-*` agents are installed (plain or
   `logistics:`-prefixed), `feat-bug-assessor` included. Check the bug
   extension: no `.specify/extensions/bug/` and none of the
   `speckit-bug-assess`, `speckit-bug-fix`, `speckit-bug-test` skills →
   stop: "run `specify extension add bug` in this project". No heading
   check here: the assessor reports missing sections.
5. Read `.specify/extensions.yml` as configuration, never executing it. An
   enabled hook under any `before_bug_*` or `after_bug_*` key (or any other
   hook) that would create a branch or commit clashes with this workflow
   owning git: **hard gate** before phase 1; unless the user says
   otherwise, agents skip it. The rest are allowed.
6. **Board check** (see Board moves): run `check`. Exit ≠ 0 → stop and
   show its line; else show it and say this run's board moves go to that
   board. Setup runs `check` only: no move and no issue yet; the building
   move (and any issue creation) waits for the assess gate.
7. Title, report author and slug:
   - Title: for an issue, with board tracking the tracker's `read-issue`,
     else `gh issue view <ref> --json number,title,url`; for a symptom, its
     first words.
   - Report author: for a GitHub issue, `gh api
     repos/<o>/<r>/issues/<N> --jq .author_association`; it counts only
     when the issue's `<o>/<r>` equals `gh repo view --json nameWithOwner`,
     else the author is `unknown`. A typed symptom is `user`; a non-GitHub
     URL is `unknown`.
   - Slug: from an issue, `<N>-<2–3 words of its title>`; from a symptom,
     2–4 of its words; from a non-GitHub URL, its last path segment.
     Lowercase kebab-case, only `[a-z0-9-]`, at most 40 characters (the
     extension keeps such a slug unchanged).
   - `git fetch origin <default>` (harness, Fresh base), then
     EnterWorktree, before spawning anything. Then the slug must be
     unused: if `.specify/bugs/<slug>/` exists in the worktree, the branch
     `fix-<slug>` exists locally, or `git ls-remote --heads origin
     fix-<slug>` prints a line, append `-2`, `-3`, … until none holds.
     Rename the branch to `fix-<slug>` (`git branch --show-current`, then
     `git branch -m`).
   - If setup found `.logistics.yml` and the worktree has none, log `- [!]
     tracker: .logistics.yml is not in the worktree; commit and push it
     (board moves skipped)` and flag it at the first gate.
   - Create the state file in one Bash command: `S init fix '<state
     file>' '<title>' '<the argument, its lines joined with spaces>'
     'Branch=fix-<slug>' 'Worktree=<path>' 'Size=not set' 'Agents=none
     (every spawn is fresh)' 'Current phase=1 Assess' 'Conventions=<…>'
     'Allowed Spec Kit hooks=<…>' 'Map=none' 'Issue=<the issue ref or
     none>' && S log '<state file>' '- [x] 0 Setup — <board check>; slug
     <slug>; bug extension <version from
     .specify/extensions/bug/extension.yml>; report author
     <association>'`, plus any `[!]` lines kept so far as more `log`
     arguments, then `&& S report-path '<state file>' '1-assess'` for
     phase 1's spawn.

## Resume

`/fix resume` follows the harness's Resume with these values:
- **Search**: `S find fix` (harness, Resume; several → list slug, phase
  and worktree, and ask); none → say there is no unfinished `/fix` run and
  stop. A shipped run is skipped (its committed state says `done
  (shipping)` and its branch has an upstream); one whose ship stopped
  before committing has `5 Ship` back in the local copy, and one waiting
  on the user's `!` command (`done (shipping)`, no upstream) resumes at
  phase 5.
- **Repair**: once in the run's worktree, the repair check first
  (harness, Moving onto a new main), before anything else.
- **Board**: run `check` next; exit ≠ 0 → stop. The building move only
  once the Log has the `1 Assess — <soft | hard> gate` line.
- **Continue** at the recorded phase; finished phases (their Log lines)
  are not redone. The phase itself restarts with a fresh spawn, as every
  spawn is: its gate is then shown from the new report. The test cycle
  and retry come from the resume call's `cycle` and `retry-used` (phase
  3). If the assess gate passed with
  `Issue: none`, board tracking, and no Log line for issue creation
  (`created`, `no issue` or a `[!]` from `create-issue`), don't run
  `create-issue` again on your own: the earlier run may have created the
  issue before it stopped. Ask the user for the issue ref or "no issue"
  (logged).
- Recap the run in one paragraph before that phase's spawn; the current
  gate then follows from its report.

Every spawn below gets, besides what the harness lists: its report path
(harness, Report files), the bug dir, the
slug, the size (or "not set yet"), the mode, and the allowed hooks
(`before_bug_*`/`after_bug_*` and the others setup allowed).

## 1. Assess

Spawn `feat-bug-assessor` (assess mode, row 1) with the report (the
argument as given), the report author's association, the commands the user
approved so far, and on a re-assess the user's added evidence. Its report
is the assess-mode format of the agent file.

**Reported files first** (harness, Reported files): the `Assessment:` path
must be on `Wrote:`, and `Assessment: none` lists no path on `Wrote:` but
its report path; a failed check is hard, recommend "back to 1".

**Stop first** (checked before any other gate row): `Assessment: none`,
`Verdict: invalid`, or `Is a bug: no — …` whatever the verdict (the
assessor's `Is a bug` decides; never edit assessment.md to make them
agree). The run ends at this gate:
- Show the assessor's `Reasoning` and the extension's reason (the
  `Assessment: none (…)` text or assessment.md's verdict line) so the user
  can relabel or comment on the issue themselves.
- `no — missing feature`: point to `/brief #N` for an issue, else `/brief
  "<symptom>"` (plugin form `/logistics:brief`).
- No issue is created, moved or edited (no board move: the building move
  never happens), and no later phase starts.
- `S set '<state file>' 'Current phase' 'done (invalid)'` for `Verdict:
  invalid` or `Assessment: none`, else `'done (not a bug)'`, `&& S log`
  the line `- [x] 1 Assess — stopped: <Is a bug value or the extension's
  reason>` (e.g. `stopped: no — missing feature; pointed to /brief #12`).

The same stop, with `done (not a bug)` and the Log line `- [x] 1 Assess —
stopped: out of scope (<refactor | backport | several bugs>)`, when the
assessment shows the report is a refactor or a backport request. Several
bugs in one report: ask which one this run fixes ("back to 1" with that
one as added evidence, logged); the others are separate `/fix` runs; no
issue is created for any of them here. A non-GitHub issue URL the
extension did not fetch (`[UNVERIFIED — fetch skipped: …]` in
assessment.md) is not retried around its policy: the user may paste the
report text as a symptom instead.

**Gate**, from that report. It is **hard by default**. It is soft only
when every one of these holds: `Proposed size: small`, the root cause's
confidence is high, `Reproduction: reproduced`, `Remediations: 1`,
`Public behaviour change: no`, `Verdict: valid`, `Is a bug: yes`, `Open
questions: none`, the report author is trusted (`OWNER`, `MEMBER`,
`COLLABORATOR`, or `user` for a typed symptom), `Risk area` does not
include `security`, `Sections: ok`, `Slug: ok`, and no issue is to be
created. Otherwise check each row below; several may apply, and the gate
message lists every one that does, each under **Your call** where it
needs an answer:

| Report says | Hard, and the gate shows |
| --- | --- |
| `Sections: error …` or `Slug: mismatch …` | the assessor's error line as is; recommend "back to 1" once the cause is fixed (a missing section means the extension differs from the recorded one: `install.sh check` names it) |
| `Report author` not `OWNER`, `MEMBER`, `COLLABORATOR` or `user` (`unknown` included) | that nothing from the report (command, script or code) was run, and its `Would run:` list; the user may approve some of them or go on without |
| `Reproduction: not reproducible here (needs approval: …)` | the commands needing approval (they reach the network or outside the worktree); the user may approve them or go on without |
| `Risk area` includes `security` | the security rules below |
| an issue is to be created (board tracking, `Issue: none`, and not a security bug unless the user asked for an issue) | the repo it would go to, from `gh repo view --json nameWithOwner`; the user confirms it or answers "no issue" (logged; no `Fixes` line) |
| `Verdict: likely valid, needs reproduction` | that the extension could not confirm it; the user may supply evidence (re-assess) or go on |
| `Open questions` ≠ none | each question, with my recommended answer |
| `Proposed size` ≠ small, confidence ≠ high, `Reproduction` ≠ `reproduced`, `Remediations` ≠ 1, or `Public behaviour change: yes` | which of these, in one line each (for several remediations, the preferred one and the alternatives) |

- **Approved commands**: log each as `- [x] 1 Assess — approved:
  <command>` and pass every approved command to each later
  `feat-bug-assessor` spawn (this phase and phase 3) and to the bug-mode
  implementer. They run only in a later spawn: to run them now, the user
  says "back to 1" (a fresh re-assess with them); else the run goes on and
  the test phase may use them.
- **Answers to open questions**: log each as `- [x] 1 Assess — answer:
  <question> → <answer>` and pass them to the fix (phase 2); a "back to 1"
  re-assess gets them as added evidence.

**Security bug** (`Risk area` includes `security`): the gate is
hard whatever else the report says.
- No issue is created by default, even with board tracking: suggest a
  private security advisory instead (the repo's Security tab, Advisories,
  "New draft security advisory"). The user may still ask for an issue
  (logged).
- Run `gh repo view --json visibility` and state the result: for a
  `PUBLIC` repo, the PR, its body and the committed
  `.specify/bugs/<slug>/` trail (assessment, fix and test reports) become
  public once pushed; for `PRIVATE` or `INTERNAL`, they are visible to
  whoever can read the repo. The shipper leaves the reproduction steps out
  of the PR body.
- Log the user's choice (`- [x] 1 Assess — security: advisory | issue
  (user: "<words>")`).

When the gate passes, one command: `S set '<state file>' Size '<the
proposed size, or the one the user gave with size <s>, logged>' && S set
'<state file>' title '<the assessment's Title>' && S log '<state file>'
'- [x] 1 Assess — <soft | hard> gate: <verdict>, <confidence> confidence,
<reproduction status>, <N> remediation(s); size <s>'`; then issue
creation, then the building move.

**Issue creation**, only once the gate has passed for a
real bug (never after the stop above):
- `Issue:` holds the report's issue: create nothing. That issue always
  gets `Fixes #N` in the PR, with or without board tracking and whatever
  its label.
- `Issue: none` and no board tracking: create nothing; the PR has no
  `Fixes` line.
- `Issue: none` with board tracking: if the user answered "no issue", or
  this is a security bug and the user did not ask for an issue (advisory),
  create nothing and log `- [x] 1 Assess — no issue (user: "<words>")` or
  `- [x] 1 Assess — no issue (security advisory)`. Otherwise run `bash
  <tracker script> create-issue .specify/bugs/<slug>/assessment.md
  <owner/repo the user confirmed at the gate>` once (never retried: a retry
  could duplicate it; the script itself retries only without a missing
  `bug` label). On `tracker: created <owner>/<repo>#<N>` (maybe followed by
  a note) run `S set '<state file>' Issue '<owner>/<repo>#<N>'` and log the
  line in the same command; the issue is labelled `bug` and its body holds the symptom, the
  root cause and the trail link. Exit ≠ 0: log `- [!] <its line>`, keep
  `Issue: none` (no moves, no `Fixes` line), flag it at the next gate and go on.

**Building move** right after (Harness values, *Building move*); none
while `Issue: none`.

## 2. Fix

Spawn a fresh `feat-implementer` (bug mode, row 2) with the report
author's association, the approved commands, the user's answers to the
assessment's open questions and, on a retry, the failed test
report's path (`test.md`, the assessor's `Test report:`) and its `Still
failing` line, and its `<who>`, `implementer` (the same for every
implementer of the run: the fix, its retry, phase 4's review fixes). Its
report is the implementer's format with the `Bug fix (bug mode)` line. Log
its `Not verified:` list (harness, State file) as `2 implementer`. The gate
does not show it, and an item is not a failing check: phase 3 settles it.

**Gate**, the same for the first fix and for the retry fix after a first
`failed` test. Soft when `status: applied`, `deviations: none`, `slug:
ok`, every check passes, the report passes its check (harness, Reported
files; fix.md on `Wrote:`) and a `Not verified:` line is present: log `- [x] 2 Fix — applied; no deviations;
checks pass` (prefix `retry: ` for the retry fix) and go to phase 3.
Otherwise hard, listing each row that applies:

| Report says | Hard, and the gate shows |
| --- | --- |
| a failed check (harness, Reported files; fix.md must be on `Wrote:`) | each failure with its reason; recommend "back to 2" |
| `slug: mismatch (…)` | the implementer's error as is; recommend "back to 2" (a fresh implementer) once the cause is fixed |
| `deviations` ≠ none | a size increase (harness "Size changes"): name each deviation from the assessment, the old size and one step up (small → medium, medium → large; large stays large) and what changes in phases 3–5; options "back to 1" (re-assess with fix.md's findings as added evidence) or "go on with size <s>" (logged as `size <s>`) |
| a check fails | the failing check's first relevant line; options "back to 2" with what to change, or "back to 1" |
| `status: partial` or `not-applied` | what the implementer left undone and why; same options |
| no `Not verified:` line | the report is broken (harness); recommend "back to 2" (a fresh implementer) |

Then phase 3.

## 3. Test

Always spawn a fresh `feat-bug-assessor` (test mode, row 3), never the
agent that wrote the fix, with the cycle (`first`, `retry` or `after review
fixes`), the report author's association, the approved commands and any
environment or evidence the user supplied, and the not verified items:
those of the latest `implementer` line (harness; none when it says `none`
or there is none). Its report is the test-mode format of the agent file.

**Cycle and retry**: the phase 3 call (State file calls; on resume, the
resume call) prints both. The cycle passed to the assessor is `cycle`'s
output (`first`, `retry` or `after review fixes`); the retry is used when
`retry-used` prints `yes`. The script reads the Log only since the most
recent `- [x] back to ` line, so a re-assess starts a fresh cycle.

**Gate**, first match wins. Every row with a verdict first logs it as
`- [x] 3 Test — <verdict>…`: the shipper's `shipped-verdict` reads these
lines.

| Report says | Gate |
| --- | --- |
| a failed check (harness, Reported files; the `Test report:` path must be on `Wrote:`) | **hard**: each failure with its reason; no verdict is logged; recommend a re-test (a fresh spawn, same cycle) |
| `Sections: error …` or `Slug: mismatch …` | **hard**: the assessor's error line as is; recommend a re-test (a fresh spawn, same cycle) once the cause is fixed |
| the implementer report just before this test (phase 4's review fixes) lacked its `Not verified:` line | **hard**: the report is broken (harness); recommend "back to 2" (a fresh implementer) |
| an item given is absent from `Not verified items:` (matched on each item's `<check>` part, exactly as passed, or the line is missing when items were given) | **hard**: show those items and the verdict; recommend a re-test (a fresh spawn, same cycle, same items) that logs no `3 Test — failed` line and so uses no retry and no cycle; going on is the user's explicit decision, then the verdict's row applies |
| `Verdict: verified` | **soft**: log `- [x] 3 Test — verified`; then phase 4, or phase 5 when this test followed review fixes |
| `Verdict: partial` | **hard**: log `- [x] 3 Test — partial: <missing>`; show `Missing for verified`; the user supplies that environment or evidence (a fresh spawn, same cycle, with it), or decides explicitly to go on (see "Shipping without `verified`" in Gate commands) |
| `Verdict: failed`, `cycle` printed `first` and `retry-used` `no` | no stop: log `- [x] 3 Test — failed (retry 1 of 1): <Still failing>; retry fix` and go back to phase 2 with a fresh implementer, the test report's path (`Test report:`, `test.md`) and its `Still failing` line |
| `Verdict: failed` otherwise (retry used, or after review fixes) | **hard**: log `- [x] 3 Test — failed: <Still failing>`; show `Still failing` and the test report link; recommend "back to 1" (re-assess with the failed reports as added evidence); the user may also decide explicitly (see below) |

When the user goes on past unaccounted items, log `- [x] 3 Test —
unaccounted: <items> (user: "<words>")` before the verdict's line.

## 4. Code review

First, the review move (see Board moves). The work is uncommitted, so
`git diff origin/<default>...HEAD` is empty:
1. `git add -N` on the fix's new files.
2. `BASE=$(git merge-base origin/<default> HEAD)`.
3. The diff command is `git diff "$BASE"`; check it is non-empty.

Spawn the reviewers per the size table's groups, each with: the bug dir as
its feature dir, the note "no spec.md: for the spec pass use assessment.md
(Proposed Remediation, Tests to add or update) and fix.md", the diff
command, its lens names, the size, no accepted `[sec]` findings, and as
context the rejected findings so far and the assessment's remediation
alternatives not chosen, under one `snapshot`; once all have reported,
`ls -d` on their `Wrote:` paths `&& S unchanged '<state file>' '<token>'`
(harness, Report files). Reviewers verify their own findings and list what
they dismissed, in their report file. Merge into one list: `B…` bugs and spec mismatches, `S…`
security, `P…` performance, `C…` cuts and `[std]` standards findings,
one line each, bugs and security first; each finding keeps its `rec`.
Apply the merge rules (harness, Review findings).

**Gate**, first match wins:

| Review and bug | Gate |
| --- | --- |
| `Risk area` includes security | **hard**: list the findings, if any, with their `rec`; restate what becomes public once pushed (the visibility stated at the assess gate: PR, body, committed trail) and ask for the go-ahead to ship; log `- [x] 4 Code review — ship go-ahead (user: "<words>")` |
| `Size: large` | **hard**: list every finding with its `rec` (even when none is `user`) |
| any `user` or `S` finding | **hard**: list the findings, `user` first, with their `rec` |
| otherwise | **soft**: one line, `Phase 4 Code review — soft: <n> findings, <a> to apply, <s> skipped; none needs your call. Next: <review fixes, then phase 3 again \| phase 5 Ship>` |

At every row, the listing, the "ok" rule and its follow-up, the `S`
publication notice and the Log words are the harness's (Review findings).
On the security row the go-ahead is logged as above in addition. Log the
outcome before leaving the phase, per the harness. The `apply` findings
(soft) or the picked ones (hard) go to a fresh `feat-implementer` in fix
mode (row 2), in order: bugs and security, cuts, performance (each
measured before and after, kept only if it beats the noise with tests
green), readability (one at a time, existing tests untouched); `skip`
findings are not applied. Tell it its `<who>`, `implementer`, and give it
the report path from `S report-path '<state file>' '4-fixes'`, chained
onto the outcome's `log`. Log its report
as `- [x] 4 implementer — <its Fixes (fix mode): value, as reported>;
checks: <its Checks: results>` ending with its `Not verified:` list
(harness, State file): the shipper's `review-summary` finds the reverted
fixes and performance numbers in that value. A report without the line
makes the phase 3 gate that follows hard (harness). Then phase 3 again with
a fresh spawn, cycle `after review fixes`: `verified` must hold again before
ship, and a `failed` there is a hard gate, with no retry. Nothing to apply
or picked: phase 5.

## 5. Ship

First `S set '<state file>' 'Current phase' 'done (shipping)' && S
refused-base '<state file>' && S log '<state file>' '- [x] 5 Ship' && S
report-path '<state file>' '5-ship'`,
so the copy the shipper commits is already done. Then spawn
`feat-shipper` (fix mode, row 5) with that report path, the state
file, the *state script* (`State script:`), the conventions, the
worktree, the default branch, the bug dir, the secret-scan script
(`<this skill's base dir>/../feat/scripts/secret-scan.sh`), the issue ref (none when
`Issue: none`: then the PR has no `Fixes` line; else `Fixes <ref>`) and
`Security bug: yes` when the assessment's risk area includes security,
else `Security bug: no`. It updates the docs the conventions call for,
commits `fix(<scope>)` with the trail, pushes and opens the PR, or returns
a single `!` line: give it to the user as is. When that line is a command
for the user to run (`! cd <worktree> && git …`: git or gh blocked here),
it commits the state file as done: leave it done (resume finds the run
while its branch has no upstream). When nothing will be committed (`!
secret scan: …` or another hard failure), `S set '<state file>' 'Current
phase' '5 Ship'` in the local copy so `/fix resume` finds the run. After
the PR you may `S set '<state file>' 'Current phase' 'done (PR #N)'` in
the local copy only (uncommitted). Never merge.

`PR: conflict`: run harness "Moving onto a new main, At ship", then read
the report as above; the state file stays `done (shipping)`.

Final message: the PR link, the branch and worktree, the two or three
things you'd look at first in review, the shipper's `Not verified:`
line when it is not `none`, or that it is missing, and a move onto a new
main made at ship (harness, Moving onto a new main).
