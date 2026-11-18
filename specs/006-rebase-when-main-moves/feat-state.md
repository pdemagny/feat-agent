# /feat state: /feat and /fix keep their run on the current main, before and after the PR opens

- Branch: rebase-when-main-moves Worktree: /home/pierre/Projects/logistics/.claude/worktrees/brief-rebase-when-main-moves
- Size: medium
- Agents: specifier a333647034bfae27a, planner a97fc78166ea57086 (amend; first planner a32efe71298ef578f), tasker a431f9fe1791ac92c
- Current phase: done (PR #40)
- Conventions: conventional commits `type(scope): msg`, one logical change per commit, no co-author trailer; in worktrees call `/usr/bin/git`, one plain command per call (no heredocs, pipes, globs, `$(…)`); `rm`/`cp`/`mv` are `-i` aliases: use `command rm -f` etc.; follow `.claude/CLAUDE.md` (size tables mirrored in `docs/workflow.md`; D2 diagrams re-rendered with `mise run diagrams` and committed; `harness.md` free of `/feat`-only words; agent report formats change with their coordinator; `/feat` and `/fix` stay thin; plugin.json lists agents); `mise run lint` and `mise run test:apm` before committing; CHANGELOG generated, never edited; PR body says `Closes #13`, never a commit message; never name private projects from outside this repo (use "a private project" or `~/Projects/my-app`)
- Allowed Spec Kit hooks: none (`hooks: {}`)
- Map: none
- Issue: #13

## Brief

- Size: medium — ~35–45 tasks expected: prompt and doc text across the harness, both skills, two agents, docs and two diagrams; the shipper gains a force-push (`--force-with-lease`), a new permission
- Short name: rebase-when-main-moves
- Issue: #13

### Why
Several `/feat` and `/fix` runs going at once, each in its own worktree, is the
normal way of working: in ~84 real runs, 67 overlapped another, up to 6 at a
time. When one of them merges, the others fall behind main. In at least 6 runs
this caused rebase conflicts after the PR had opened, one spec was written
against a stale base, and the user had to drive the follow-up by hand. The
costliest part, for the user running the workflow: telling the agent to rebase
and resolve the conflicts, then being handed a force-push command to run on the
PR branch themselves.

### Today
- **Setup** (`/feat` 0, `/fix` 0): `EnterWorktree` branches from the *local*
  `origin/<default>`, with no fetch first, so a run can start on a stale base.
- **During the run** (`/feat` phases 2–7, `/fix` phases 1–4): nothing checks
  main. It can move for hours while the plan and the code are written against
  the old base. Nothing is committed before the ship phase: the work sits
  uncommitted in the worktree.
- **Ship** (`feat-shipper`, step 4, both workflows): `git fetch origin && git
  rebase origin/<default>`, then the full checks, then push. A rebase conflict
  has no rule ("fix or report what fails"), on a haiku-run agent with no spec
  context. The shipper must "never force-push".
- **After the PR opens**: nothing. When another PR merges first, the user sees
  the conflict on GitHub, asks for a rebase and a resolution by hand, and runs
  the force-push command they are given.

### Behaviour
- **Fresh base at setup**: `/feat` and `/fix` fetch `origin/<default>` before
  creating the worktree, so every run starts on the current main.
- **Check at every phase boundary**: before each phase starts, once the state
  file exists (`/feat`: from phase 3 on, the state file being created in
  phase 2; `/fix`: from phase 1 on, its state file being created at setup;
  earlier boundaries are covered by the setup fetch), the coordinator
  fetches and checks whether `origin/<default>` has moved past the worktree's
  base (git only, which the thin coordinator may run). If it hasn't, nothing
  happens and nothing is shown. If it has, an agent brings the worktree onto
  the new main before the phase runs. Uncommitted work (everything before ship)
  moves with it: conflicts surface when that work is re-applied, and are
  resolved the same way as rebase conflicts.
- **Who resolves**: a rebase mode of `feat-implementer`, given the spec and
  plan (`/feat`) or the assessment and fix (`/fix`) as context, on the model
  and effort of the implement row (`/feat` phase 6, `/fix` phase 2), as review
  fixes already do. The coordinator never edits code. After every move onto
  the new main, clean or not, it reruns the project's checks: a failure after
  a clean rebase is a semantic conflict and is handled like a textual one.
- **Resolved alone, reported afterwards**: when the resolution keeps both
  sides' intent without choosing between them: both sides added entries to the
  same list or table, adjacent-line edits, following a rename or move that
  main made, formatting, generated files (re-rendered, never merged, e.g.
  `docs/img` with `mise run diagrams`). The next gate lists what it resolved,
  one line per file. No gate is added for it.
- **Stops and asks** (hard gate: the file, each side in one line, the agent's
  recommendation) when resolving would drop or change behaviour from either
  side; when main changed something the spec or plan relies on (it already
  implements part of the feature, or contradicts a requirement), even without
  a textual conflict; when the checks fail after the move and the fix is not
  mechanical; and, on a shipped run, when the resolution changes what the PR's
  reviewers have already seen. The test: would a reviewer of this PR want to
  know before it is pushed. The spec-and-plan check is bounded: it runs only
  when main moved, and reads only what main brought since the last base.
- **Undoing a move**: when the user refuses a hard-gate recommendation, or
  stops there, the rebase is aborted and the worktree is left on the old base
  with its uncommitted work as before (the WIP commit undone). A run that
  died mid-move is repaired by resume as its first step: a leftover WIP
  commit is undone, an unfinished rebase is aborted.
- **At ship**: the shipper still fetches and rebases just before pushing.
  Because the boundary check ran just before ship, this is normally a no-op;
  if main moved in between and the rebase conflicts, the shipper aborts the
  rebase and stops, reporting the conflicting files. The coordinator then runs
  the rebase mode and spawns the shipper again. The shipper never resolves
  conflicts itself.
- **After the PR opens**: `/feat rebase` and `/fix rebase` (plugin:
  `/logistics:feat rebase`, `/logistics:fix rebase`) re-enter a shipped run:
  with a PR number or branch, that run; without one, every shipped run of this
  repo whose open PR GitHub reports as conflicting, one after another. A
  shipped run is an open same-repo PR whose branch holds a
  `specs/*/feat-state.md` (`/feat`) or `.specify/bugs/*/feat-state.md`
  (`/fix`) marked done. It enters the run's worktree, or recreates one on the
  PR branch if it was removed. It rebases, resolves under the same rules,
  reruns the full checks, rechecks the spec number (`/feat`, as the shipper
  does), and pushes with `--force-with-lease` itself, on that branch only.
  It ends with the PR link and what it resolved. A run with nothing to do
  says so and stops. The state file stays marked done, so `resume` does not
  pick the run up.
- **Batch with a decision pending**: in a run without argument, a PR that
  needs the user's decision is left unpushed and the batch goes on with the
  others; all pending decisions are asked together at the end, then those
  PRs are finished and pushed.
- **Logging**: every move onto a new main is logged in the state file (old
  and new base, files resolved alone, decisions asked and the user's answer),
  so resume and the PR body can show them. On a shipped run, the Log lines
  are committed as `docs(specs): log rebase onto <short sha>` before the
  push, and the PR body gets a one-line note per rebase (`gh pr edit`).

### Out of scope
- Detecting or reporting overlap between in-flight runs or open PRs before any
  conflict exists (see Alternatives rejected).
- Triggering anything when a PR merges on GitHub: post-PR rebasing starts when
  the user runs `/feat rebase` or `/fix rebase`.
- Merging PRs, or choosing the order in which they merge.
- PRs not opened by `/feat` or `/fix` (no spec, plan or bug trail to resolve
  against).
- Rebasing onto anything other than `origin/<default>`.

### Alternatives rejected
- **Plan-time overlap report** (the issue's first "Done when": list files the
  plan touches that other worktrees or open PRs also touch) — as a soft line it
  is ignored; as a hard gate it fires on nearly every run here, since most
  features touch the same few files (`feat/SKILL.md`, `docs/workflow.md`,
  `harness.md`), and gates that always stop get approved unread. Either way it
  informs without removing the rebase-and-resolve work, which is the cost.
- **Rebase only at ship** (today) — main drifts for hours while the plan and
  code are written against the old base, and post-PR conflicts stay manual.
- **A GitHub Action that resolves conflicts in CI on every merge to main** — a
  new service, an API-key secret and push rights in every project that installs
  logistics, plus unattended force-pushes with nobody watching. A separate
  issue if ever wanted.
- **A standalone `/rebase` skill run under `/loop`** — the user wants the rebase
  inside the workflow's own flow; the post-PR case is an entry point of `/feat`
  and `/fix`, reusing the same agent mode and rules.
- **`gh pr update-branch --rebase` / GitHub's "Update branch"** — refuses as
  soon as there is a conflict, which is exactly the costly case.
- **The shipper resolving conflicts itself** — runs on haiku with no spec or
  plan in context; it stops and hands over instead.
- **Stretching `/feat resume` to re-enter shipped runs** — resume skips runs
  marked done by design; an explicit `rebase` argument keeps resume's meaning.
- **`git stash` to carry uncommitted work across the move** — the stash stack
  is shared by every worktree of the repo; with several runs in parallel, one
  run can pop another's work.
- **Doing nothing** — the user keeps driving every post-PR conflict and running
  force-push commands by hand.
- **Limiting the "main contradicts the spec or plan" check to boundaries
  before phase 6** (review finding, yagni) — "main already implements part of
  this" matters most after the PR opens; the check is already bounded to
  moves, and to what main brought since the last base.
- **Pausing a `/feat rebase` batch at the first decision** — one PR waiting
  on the user would hold back the clean ones; decisions are asked together at
  the end instead.
- **Hard-coding a git path (such as `/usr/bin/git`) for worktrees** — that is
  one machine's convention, not logistics'; it comes from the project
  conventions read at setup.

### Acceptance
- A run started after main moved locally but before `origin/<default>` was
  fetched starts on the current remote main.
- When main has not moved at a phase boundary, no agent is spawned and the
  gate output is unchanged.
- When main moved and the re-apply is clean, the phase runs on the new base,
  the checks were rerun, and the next gate shows the move in one line.
- A conflict of the "keep both sides" kind is resolved without a stop and
  listed, one line per file, at the next gate.
- A conflict that drops behaviour, or a requirement that main now contradicts,
  stops at a hard gate naming the file, both sides and a recommendation.
- Checks that fail after a clean rebase, with no mechanical fix, stop at a
  hard gate.
- A rebase conflict inside the shipper aborts the rebase, pushes nothing, and
  reports the conflicting files; the coordinator resolves through the rebase
  mode and ships again.
- `/feat rebase <PR>` on a shipped run whose PR conflicts ends with the PR
  rebased, the checks green, and the branch pushed with `--force-with-lease`,
  with no command handed to the user; without an argument it does this for
  every conflicting PR from a shipped run of this repo.
- `/fix rebase` does the same for a shipped bug fix.
- `--force-with-lease` is the only force-push anywhere, and only on the run's
  own branch.
- Moving uncommitted work onto a new main never touches the shared stash
  stack; afterwards every new file is still present, untracked files still
  untracked and intent-to-add files (phase 7's `git add -N`) still
  intent-to-add.
- Refusing a hard-gate recommendation leaves the worktree on the old base
  with its uncommitted work intact; resuming a run that died mid-move first
  undoes the leftover WIP commit or aborts the unfinished rebase.
- In a `/feat rebase` batch, a PR that needs a decision is not pushed until
  the user answers; the other PRs are pushed meanwhile.
- Every move onto a new main appears in the state file's Log; on a shipped
  run, as a `docs(specs): log rebase …` commit pushed with the rebase, and as
  a note in the PR body.
- After `/feat rebase`, the run's state file is still marked done.

### Constraints / decisions already made
- `/feat` and `/fix` stay thin: the coordinator only runs git to fetch and
  compare bases; reading, resolving and checks belong to an agent. Its git
  calls follow the project conventions read at setup (some projects require
  a given git path or one plain command per call in worktrees).
- Build order: the rebase mode of `feat-implementer` and `/feat rebase` /
  `/fix rebase` (the post-PR case, where the user's stated cost sits) land
  first; the per-boundary checks during a run come after them.
- Shared rules go into `.apm/skills/feat/references/harness.md`, written with
  named values that each skill's `## Harness values` block fills (which
  boundaries, which context the resolver gets, the resume and rebase search);
  no `/feat`-only words there (`mise run lint` greps it).
- No new size-table row: the rebase mode uses the implement row (`/feat` 6,
  `/fix` 2). If the plan adds a row anyway, mirror it in `docs/workflow.md`.
- Agent report formats change together with the coordinator that reads them
  (the implementer's rebase mode report, the shipper's conflict report).
- A change to `/feat`'s phases or gates updates `docs/diagrams/gates.d2` and
  `chain.d2`, re-rendered with `mise run diagrams`, both committed.
- `feat-shipper`'s "never force-push" becomes "never force-push, except
  `--force-with-lease` on the run's own branch in rebase mode"; never merge
  stays.
- Uncommitted work moves onto the new base through a temporary WIP commit on
  the run's branch (rebased, then un-committed), never through `git stash`.
  New files are added for the WIP commit; afterwards the agent restores
  their state, re-running `git add -N` on those that were intent-to-add.
- Worktree tooling: `EnterWorktree` creates new branches; re-entering a removed
  worktree on an existing PR branch needs `git worktree add` then
  `EnterWorktree` with `path`. In worktrees, git and shell commands are
  subject to the worktree guard (plain commands, no `$(…)`), as the existing
  agent files already say.

## Log

- [x] 0 Setup — no Spec Kit hooks; board users/pdemagny/projects/2 ok; #13 → In progress; branch renamed to rebase-when-main-moves; base = origin/main (0 behind after fetch)
- [x] 2 Specify — soft
    - Stories: US1 Rebase a shipped run whose PR conflicts (/feat rebase, /fix rebase) (P1); US2 Implementer rebase mode: keep-both-sides resolved silently and listed, the rest a hard gate (P1); US3 Fresh base at setup (P2); US4 Check main at every phase boundary, uncommitted work via WIP commit (P2); US5 Shipper aborts and reports on conflict, coordinator rebases and re-spawns it (P2); US6 Undo and recover (P2); US7 Batch with pending decisions, plus logging (P3)
    - Requirements: 26 FRs, 9 SCs; FR-005/006 WIP commit not stash, untracked and intent-to-add restored; FR-009 the four hard-gate conditions; FR-014 shipper never resolves; FR-016/017/018 shipped run, lease push, state stays done; FR-021 --force-with-lease only, own branch; FR-022 shared rules in harness.md; FR-025 docs and gates/chain diagrams; FR-026 git path from conventions
    - Spec assumptions: 1. "The checks" = the checks the shipper already runs before pushing (here mise run lint, mise run test:apm) (recommended: keep as written); 2. The last base is recorded in the state file, location left to planning (recommended: keep as written); 3. "Conflicting" = GitHub's mergeable state; unknown is re-queried once, then treated as not conflicting (recommended: keep as written); 4. A PR only behind main, with no conflict, is skipped in the no-argument batch and rebased when named (recommended: keep as written); 5. A refused lease push is reported, never retried with a stronger force (recommended: keep as written); 6. No checks found → the move proceeds and the report says so (recommended: keep as written); 7. .specify/feature.json written (gitignored, never committed) (recommended: keep as written)
    - Unchecked checklist items: none
- [x] 3 Plan — plan.md, research.md (R1–R18), data-model.md, contracts/move.md, quickstart.md; no blockers; size trigger: permissions (force-with-lease, gh pr edit), already counted in medium; no new deps; constitution pass (cost note: ~45-line harness section read every run)
    - Planner assumptions: 1. /feat marks done (shipping) before spawning the shipper, as /fix does; rebase search also counts a /feat state at `8 Ship` with an open PR as shipped (widens FR-016) — needs user: yes; 2. a move needing a decision is undone before the report, approval re-runs it in a fresh spawn; 3. "stay" logs the refusal and runs the phase on the old base; 4. WIP commit: git add -A, --no-verify, no signing; 5. lease pinned to the PR head SHA; 6. local branch behind PR head is fast-forwarded, diverged → decision item; 7. review diff base = merge-base origin/<default> HEAD; 8. in-run moves rerun fast checks, shipped moves full checks, a check that can't run is logged, not blocking; 9. failed fetch at a boundary logged [!], run goes on; 10. after PR: conflict the re-spawned shipper folds the Log line via --fixup/autosquash; 11. last base = merge-base, not stored
- [x] 3+4 Plan and design review — hard (findings above nice-to-have, planner assumption 1 needs user); user: "ok" → accepted D1–D21 as recommended, D22 no change; spec assumptions 1, 3–7 kept as recommended, 2 replaced by D13 (merge-base); planner assumptions 2–9, 11 kept, 1 replaced by D10, 10 replaced by D12; no unchecked checklist items
    - D1 [sec] validate PR input before any git (drop cross-repo via JSON, check-ref-format + [A-Za-z0-9._/-], state-file path shape, single quotes and --)
    - D2 [sec] only the user's PRs (--author @me in batch; explicit PR by another author → hard gate before fetch/run; Size must be small|medium|large)
    - D3 [sec] reject other-repo PR URL (nameWithOwner); shipper uses PR URL
    - D4 [sec] repair also finds logistics-wip: HEAD without ref; both shipper modes block push on logistics-wip: commit in range
    - D5 [sec] rebase mode runs the secret scan on state file and rewritten range before push
    - D6 shipper rebase mode commits the Log lines first (Log only), then rebases and pushes
    - D7 refused lease push → shipper resets to lease sha; diverged item from a previous move recommends reset and redo
    - D8 /fix boundary checks start at phase 2; back to 1 = no check until size set (FR-002, US4 AC3)
    - D9 discovery: gh pr list --limit 1000 with author/cross-repo in one call; state file via git diff --name-only on the fetched branch
    - D10 /feat shipped run = open same-repo PR of the user whose branch holds specs/*/feat-state.md, any phase; no phase 8 reorder or done-marker change; rebase marks a recreated worktree's local state file done (narrows FR-016)
    - D11 Decisions: one line per item `<file> — <accepted rec | user's words>`; "ok" copies recs
    - D12 drop the after-conflict fixup/autosquash; an at-ship move's Log line stays local and is in the final message (narrows FR-020)
    - D13 FR-011 lists the coordinator's real commands; last base = merge-base, not stored
    - D14 rebase entry point in references/rebase.md read only on rebase; mise.toml lint grep and test -f extended; FR-022 amended; size figure corrected
    - D15 rebase mode: blocked git/gh → error ! line, never a command
    - D16 chain.d2: one layout pass, else new step only in gates.d2
    - D17 [sec] PR-body temp file outside the worktree, deleted after gh pr edit
    - D18 implementer wording: step 1 doesn't apply; step 4 applies except the WIP commit
    - D19 update the PR body's state-file link on renumber
    - D20 drop the WIP: yes|no report field
    - D21 undo promises tracked content and index as before; fast-forward after the ref
- [x] 4 amend (planner) — D1–D21 written into spec (new FR-027–FR-032), plan, research, data-model, contracts/move.md, quickstart; no blockers; no new size trigger; Touches adds .apm/skills/feat/references/rebase.md, mise.toml, .claude/CLAUDE.md
    - Amend assumptions (needs user: no): 1. refused push resets with `git reset --keep <lease>` (not D7's --hard: keeps user's uncommitted changes, refuses rather than overwrite); 2. same reset on a conflict in shipper rebase mode; 3. a shipped branch ahead of the PR head is a decision item like diverged; 4. local done mark kept out of the Log commit by restoring `Current phase:` before staging; coordinator rewrites done (PR #n) after each shipper report; 5. at-ship Log line written after the second shipper's report; 6. shipped fast-forward = `git rebase <lease>` after WIP commit and ref; 7. Size read with anchored git grep; 8. D5 range includes main's commits: a false stop possible, never a leak; 9. `--` forms of git fetch/worktree add untested (quickstart M5); 10. .claude/CLAUDE.md harness bullet names rebase.md
- [x] 5 Tasks — soft: 44 tasks (fits medium); order Setup T001–T002, Foundational T003–T005, US2 T006–T008, US1 T009–T018, US5 T019–T022, US6 T023–T026, US7 T027–T028, US3 T029–T032, US4 T033–T037, Polish T038–T044; MVP T001–T018 + T041; analyze: 3 LOW (T025 conditional; T044 may fix `--` forms; diagrams land with commit 2), no fix needed; no unchecked checklist items; tasker read the artifacts itself rather than invoking speckit-analyze; main unmoved (0 behind)
- [x] 6 US2 — T002–T008 done; T001 written, unticked (its `test -f rebase.md` in test:apm fails until T009 creates rebase.md: task-order issue, handed to US1); lint pass, test:apm fail (that assertion only); not verified: none
- [x] 6 US1 — T001, T009–T018 done; lint, test:apm, test:tracker, test:spec-number pass; notes: rebase.md step 6 (undone move, batch waiting) comes with T027; shipper rebase mode refers to step 4's WIP check from T019; not verified: none
- [x] 6 US5 — T019–T022 done; lint, test:apm pass; shipper step 4 conflict abort + WIP check before any push; /feat §8 and /fix §5 handle PR: conflict; not verified: none
- [x] 6 US6 — T023–T026 done; lint, test:apm pass; deviation from contract §3 (same meaning): repair aborts the rebase first when `git branch --show-current` is empty mid-rebase, then reads the ref and resets; repair reads intent-to-add paths from the WIP body, runs no checks; feat SKILL.md not edited (harness Resume covers it); not verified: none
- [x] 6 US7 — T027–T028 done; lint, test:apm pass; rebase.md step 6 (move gate / batch of waiting PRs, heading `## Main moved under <k> PRs — needs your call`, chosen by the implementer); docs workflow/usage updated; not verified: none
- [x] 6 US3 — T029–T032 done; lint, test:apm pass; not verified:
    - n/a → quickstart L1 (live: start /feat after remote main gained an unfetched commit) → needs a live run against a moved remote main
- [x] 6 US4 — T033–T044 done; lint, test:apm, test:tracker, test:spec-number, diagrams (byte-identical re-render), quickstart Q5–Q13, Q8 read-through, M1–M5 (scratch repo + bare remote) pass; rebase.md Q10 rewrap; gates.d2 move step placed after the open-questions gate (base check starts at phase 3); chain.svg kept on first render; noted: shipper `git reset --keep <lease>` turns intent-to-add files untracked (content kept; shipped runs with uncommitted add -N files only), text unchanged; private project name found in tasks.md line 9 (Conventions) and the state file's Conventions (state file fixed; tasks.md to be scrubbed before commit); not verified: none
- [x] 6 Implement — soft: tasks done 44 (1 not verified: US3 L1)
- [x] 7 Code review — hard; picked B1, B2, B3, B4, B5, B6, S2, S3, S4, C1, C2, C4, R1–R10; S1 deferred (user: "rebase onto main because we just merged work about secret scanning that may change this finding") → re-review on the new base; rejected P1 (user: "follow-up issue"); rejected P3 (user: "leave"); rejected C3 (user: "leave"); rejected P2, P4, C5, std, R11 (as recommended); untested: fresh remote base at start (L1), end-to-end against a real PR
    - B1 feat-implementer.agent.md:113 — pre-move ref only set on a dirty tree — rec: apply
    - B2 feat-implementer.agent.md:134,144 / feat-shipper.agent.md:150 — shipped run's regenerated files and mechanical fixes never committed — rec: user → fix: regenerate at the conflict stop before rebase --continue; other post-rebase changes in their own commit by the shipper before its Log commit; no fixup/autosquash
    - B3 feat-implementer.agent.md:113,142 — staged-new files come back untracked — rec: apply
    - B4 rebase.md:19 — `state` missing from the batch --json — rec: apply
    - B5 feat/SKILL.md:399, rebase.md:72 — stale unnumbered path after renumber — rec: apply
    - B6 docs/workflow.md:433 — "full checks" wording — rec: apply
    - S1 feat-shipper.agent.md — scan range includes main's changes — rec: user → deferred to re-review after the move
    - S2 feat-shipper.agent.md / feat-implementer.agent.md — PR data not marked as data in rebase modes — rec: apply
    - S3 feat-shipper.agent.md — blocked line carries force-push arguments — rec: apply
    - S4 rebase.md — baseRefName not checked — rec: apply
    - P1 feat-implementer.agent.md — rebase-mode text loaded on every spawn — rec: user → follow-up issue
    - P2 feat-shipper.agent.md — same, shipper — rec: skip
    - P3 feat-implementer.agent.md step 8 — checks rerun with a decision open — rec: user → leave
    - P4 rebase.md — repeated fetches — rec: skip
    - C1 feat/SKILL.md §8, fix/SKILL.md §5 — PR: conflict paragraph duplicates harness At ship — rec: user (reviewers disagree) → fix as 7d wrote it
    - C2 docs/workflow.md — duplicate At ship bullet — rec: apply
    - C3 feat-implementer.agent.md step 5 — git cherry / docs(specs) subject tests — rec: user → leave
    - C4 docs/workflow.md When main moves — three bullets restate prompts — rec: user → fix (one sentence each)
    - C5 docs/usage.md — fetch-failed row — rec: skip
    - std feat/SKILL.md, fix/SKILL.md — duplicated PR: conflict paragraph — rec: skip
    - R1–R10 implementer, shipper, SKILL.md, harness, rebase.md — readability — rec: apply
    - R11 harness Resume — one sentence — rec: skip
- [!] 7 move onto origin/main e4181b4 (was 9a7d55f; main gained 8bf1ef0 fix(shipper) scan, e4181b4 fix(assessor) redact) — undone (9a7d55f → e4181b4): main replaced the inline `-G` scan with `secret-scan.sh staged|worktree` (added lines, literal value), no range mode; the feature's rebase-mode step 5 uses the removed `-G` pattern (plan, contract §4, research D5 name it); worktree restored (HEAD 9a7d55f, 10 ita paths re-added, ref deleted, stash untouched); other hunks: Fix mode "The rest as above" mechanical; fix/SKILL.md, docs/workflow.md, mise.toml auto-merged; not verified: n/a → checks → move undone before checks
    - move gate — user: "ok" → accepted: add `range <from> <to>` to secret-scan.sh (git diff -U0 through scan_diff) + test in tests/secret-scan/run.sh; shipper rebase-mode step 5 = `bash <secret-scan script> range origin/<default> HEAD` (resolves S1); step 2 keeps fix mode's `staged`; script path in rebase-mode inputs and both SKILLs' rebase spawns; order: planner amend → move retry → fix pass → ship
- [x] 7 amend (planner) — FR-030 rewritten (staged scan before Log commit; `range origin/<default> HEAD` before push; script gains `range <from> <to>` + offline test; both skills pass the script path); plan (secret-scan.sh range mode, tests/secret-scan/run.sh case, *Secret-scan script* Harness value in both skills, rebase.md step 5 passes it, docs clause), research R19, contract §1b/§2/§4, quickstart Q3/Q11/Q14/L14/L18; old -G pattern gone; assumptions (needs user: no): Harness value *Secret-scan script*; `--end-of-options`; whole PR scanned (a stop, never a leak); tasks.md T010 still quotes the old command (tasker's file; fix pass follows plan/contract); docs clause; blockers: none
- [x] 7 move — 9a7d55f → e4181b4; resolved alone: feat-shipper.agent.md (Fix mode "rest as above" = feature text + main's `worktree` fallback; Rebase mode inputs + script path, step 2 `staged`, step 5 `range origin/<default> HEAD`, no -G left), fix/SKILL.md, docs/workflow.md, mise.toml auto-merged; decisions: per the move gate; checks lint, test:apm, test:tracker, test:spec-number, test:secret-scan, diagrams pass; ita restored, stash untouched, ref deleted; gap for the fix pass: rebase.md step 5 and both Harness values don't pass *Secret-scan script*; not verified: none
- [x] 7 S1 re-review — not needed: resolved by the move-gate decision (scan `range origin/<default> HEAD` with main's secret-scan.sh)
- [ ] 7 S1 re-review
- [x] 7 review fixes — applied B1–B6, S1 (secret-scan.sh `range` mode + test case, *Secret-scan script* Harness value in both skills, passed by rebase.md), S2–S4, C1, C2, C4, R1–R10; B2 built as: generated files regenerated at the conflict stop; on a shipped run, mechanical check fixes listed as `<file> — check fix: <how>` on Resolved alone, passed as `Check fixes:`, committed by the shipper in their own commit (`fix(<scope>): adapt to main <new7>`) before the Log commit; shipper rebase-mode steps renumbered (scans now steps 3 and 6); private name removed from tasks.md (grep clean); T010 updated; checks lint, test:apm, test:tracker, test:spec-number, test:secret-scan (9 cases), diagrams (stable sha256) pass; note: staged-new files come back intent-to-add, not staged (index exact only for the add -N convention); not verified: none
- [ ] 8 Ship
