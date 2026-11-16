# Bug Assessment: Parallel /feat runs can ship the same spec number

- **Slug**: 21-same-spec-number
- **Created**: 2026-11-16
- **Source**: pasted text (GitHub issue 21 of the pre-release repo, read with `gh issue view`; host github.com, allowlisted)
- **Verdict**: valid
- **Severity**: medium

## Report (verbatim or summarized)

> **Parallel /feat runs can ship the same spec number** (issue 21 of the pre-release repo)
>
> Two parallel `/feat` runs can give their specs the same number. On a private project,
> `specs/088-typed-config-value` (PR 363) and
> `specs/088-split-entry-lock` (PR 364) both shipped as 088 on
> 2026-11-13. Lint failed on main and broke every PR's CI until
> PR 370 renumbered one of them.
>
> Cause: `feat-shipper` step 1 finds the next number from the `specs/*`
> folders on `origin/<default>` and from the **branch names** of open PRs. The
> shipper of #363 numbered its spec folder 088 but kept the branch
> `typed-config-value`. When the shipper of #364 numbered its spec two minutes
> later, main's highest was still 087 and no open PR branch carried 088. #369
> (`secret-link-values`) also skipped the branch rename. Step 1 also reads
> `origin/<default>` before step 4 fetches it.
>
> Fix asked for: find taken numbers from the `specs/` paths in open PRs' files
> (`gh pr list --state open --json files`), fetch before reading
> `origin/<default>`, in a script under `.apm/skills/feat/scripts/` with a test;
> re-run the check just before `gh pr create` and renumber/amend if taken;
> make the branch rename optional or drop it.
>
> Done when: two features shipped at the same time get different numbers even
> when neither branch is renamed, and the script's test covers an open PR whose
> branch has no number but whose files include `specs/NNN-*`.

Evidence checked (read-only `gh` against the private project's repository):

- #363: head `typed-config-value`, created 2026-11-13T18:48:23Z, merged 19:03:42Z, 141 changed files, spec dir `specs/088-typed-config-value/` (from the paginated REST `pulls/363/files`).
- #364: head `088-split-entry-lock`, created 18:51:02Z, merged 19:05:29Z, spec dir `specs/088-split-entry-lock/`.
- #369: head `secret-link-values` (not renamed), spec dir `specs/089-secret-link-values/`.
- #370: "fix(specs): renumber split-entry-lock spec to 090", merged 2026-11-14.
- Its `main` at 41218bc (last commit before 18:51Z): highest `specs/*` entry is `087-describe-protocol-window`.

## Symptom

Two `/feat` runs shipping minutes apart both numbered their spec dir 088, so main ended up with two `specs/088-*` dirs and the project's lint failed. Expected: the second shipper sees that 088 is taken by the open PR and picks 089.

## Reproduction

The faulty logic is a prompt rule (shipper step 1), not code, so it was reproduced by applying the rule to that project's recorded state:

1. Read its `main` at the last commit before PR 364 (41218bc): highest spec `087-describe-protocol-window`.
2. Read open PR #363's head branch name: `typed-config-value` (no leading number).
3. Apply step 1's rule (highest leading `NNN` among `specs/*` on main and open PR branch names, plus one) with a scratch script (`bash /tmp/fix21-step1-sim.sh`). Output:

   ```
   step-1 rule gives: 088
   already taken by open PR #363: 088-typed-config-value
   ```

4. Result: the rule yields 088, the number #363 already used. Reproduced.

Additional finding while checking the proposed fix: `gh pr view 363 -R <owner>/<repo> --json files` returns only 100 of the PR's 141 files (`changedFiles: 141`, `files | length: 100`), and none of those 100 is under `specs/`. The same cap applies to `gh pr list --json files`. The issue's proposed source (`gh pr list --state open --json files`) would therefore also have missed PR 363's 088 in this very incident. The paginated REST endpoint (`gh api --paginate repos/<o>/<r>/pulls/<n>/files`) does list `specs/088-typed-config-value/…`.

## Suspected Code Paths

- `.apm/agents/feat-shipper.agent.md:12-19` (step 1) — takes the highest `NNN` from `specs/*` on `origin/<default>` and from `gh pr list --json headRefName`; an open PR whose branch was not renamed contributes nothing, and `origin/<default>` is read before any fetch.
- `.apm/agents/feat-shipper.agent.md:17-18` — `git branch -m <NNN>-<short-name>` is the only thing that makes a shipped number visible to the next shipper, and it is skipped in practice (#363, #369).
- `.apm/agents/feat-shipper.agent.md:37-44` (step 4) — fetch and rebase happen after numbering; there is no re-check before `gh pr create`, so a number taken meanwhile is not caught.
- `.apm/skills/feat/SKILL.md:36-37,149-152` — describe the phase-8 numbering ("on top of the fetched `origin/<default>`"), which step 1 does not actually guarantee.
- `docs/workflow.md:153` — says the coordinator creates branch `<NNN>-<short-name>` in phase 2, which is stale (the skill creates `<short-name>`).

## Root Cause Hypothesis

Taken numbers are inferred from open PR branch names, an indirect signal that only exists when the shipper's optional-in-practice `git branch -m` ran. When a shipper skips the rename (as #363's did, "Branch kept as `typed-config-value`"), its spec number is invisible to the next shipper until the PR merges, so a second shipper within that window computes the same next number. The stale `origin/<default>` read (step 1 before step 4's fetch) widens the window. Confidence: high.

## Proposed Remediation

**Preferred**: Add a script `.apm/skills/feat/scripts/spec-number.sh` (name to settle in the fix) that prints the next free spec number:

- `git fetch origin <default>` first, then collect leading `NNN` of `specs/*` on `origin/<default>` (`git ls-tree --name-only origin/<default> specs/`);
- for each open PR (`gh pr list --state open --json number,headRefName`), collect the `specs/NNN-*` dirs it adds, using a source that is not capped at 100 files: the paginated REST files list (`gh api --paginate repos/{owner}/{repo}/pulls/<n>/files --jq '.[].filename'`), or the head branch's tree (`git ls-tree --name-only origin/<headRefName> specs/` after fetching it), which costs one call per PR regardless of size;
- keep branch-name numbers as a further source (harmless);
- print highest + 1, zero-padded to three digits; take the excluded own dir name as an argument so a re-check does not count the shipper's own spec.

Shipper step 1 calls the script instead of describing the rule. Add a re-check after step 4's rebase and full checks, just before `gh pr create`: if the script now reports the number as taken, `git mv` to the new number, rewrite paths, and amend the `docs(specs)` commit (not yet pushed, so no force-push). Drop the `git branch -m` (or make it optional) and update the `/feat` skill and docs that mention it.

**Alternatives**:
- `gh pr list --state open --json files` as the issue proposes: one call, but silently capped at 100 files per PR; it would have missed #363 (141 files). Only acceptable with a fallback when `changedFiles > 100`.
- Scan every `origin/*` branch's `specs/` after `git fetch origin`: no GitHub API, but stale unmerged branches inflate the number (gaps, not collisions).
- Make the rename mandatory and keep branch names as the source: smallest change, but it is the step models already skip, and branch names say nothing for PRs opened by hand.

**Files likely to change**:
- `.apm/skills/feat/scripts/spec-number.sh` (new)
- `.apm/agents/feat-shipper.agent.md`
- `.apm/skills/feat/SKILL.md`
- `tests/spec-number/` (new: run script plus a `gh` stub, like `tests/tracker/bin/gh`) or an extension of `tests/tracker/`
- `mise.toml` (shellcheck the new test, add a test task; `test:apm` can assert the script lands)
- `docs/workflow.md`
- `CHANGELOG.md`

**Tests to add or update**:
- Open PR whose branch has no number but whose files include `specs/NNN-*` → next number is NNN+1 (the issue's "done when").
- Open PR with more than 100 files whose `specs/` paths come after the first 100 → still counted.
- Highest on `origin/<default>` only, no open PRs → highest + 1, zero-padded (`087` → `088`, `099` → `100`).
- Own spec dir excluded on the re-check.
- `gh` failure → non-zero exit with a clear message (never a silent guess).

## Risks & Considerations

- Residual race: two shippers that both re-check before either PR exists can still pick the same number; the re-check narrows the window to seconds but does not close it. A check after `gh pr create` (renumber with a follow-up commit if a lower-numbered PR now holds the number) would close it.
- GitHub API cost: one files request per open PR (more pages for big PRs); fine for typical repos, slower with many open PRs.
- Behaviour change visible to users: branches stay `<short-name>` (no `NNN-` rename), and the shipper may amend its `docs(specs)` commit before pushing.
- PRs from forks: the head branch is not on `origin`; the REST files list covers them, a `git ls-tree origin/<head>` approach does not.
- The shipper runs on haiku: a script keeps the rule deterministic across models; its report format is unchanged.
- Shellcheck must stay clean on the new script and tests.

## Open Questions

- [NEEDS CLARIFICATION: Drop the branch rename entirely, or keep it as optional cosmetics?]
- [NEEDS CLARIFICATION: Should the shipper also check after `gh pr create` to close the remaining seconds-wide race, or is the pre-create re-check enough?]
- [NEEDS CLARIFICATION: Why did #363's and #369's shippers skip `git branch -m` (a refused command in the worktree, or the model dropping the step)? It does not change the fix if branch names stop being the source.]
