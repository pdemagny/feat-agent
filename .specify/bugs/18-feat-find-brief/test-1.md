# Bug Verification: /brief writes the brief relative to the cwd and /feat only takes an exact path

- **Slug**: 18-feat-find-brief
- **Tested**: 2026-11-18
- **Assessment**: ./assessment.md
- **Fix**: ./fix.md
- **Result**: partial

## Summary

The fix is in skill instructions, which have no automated harness. The instruction text now matches both "Done when" items and the user's decisions (read in the diff), the commands the instructions rely on resolve as described in a scratch repo, and `mise run lint`, `test:apm`, `test:tracker` and `test:spec-number` pass. The two end-to-end behaviours (an interactive `/brief` from a non-repo cwd, an interactive `/feat <name>`) cannot be driven in this automated mode and were not exercised, so the result is `partial`, not `verified`.

## Checks Performed

| Check | Command / Action | Result | Notes |
|-------|------------------|--------|-------|
| Reproduction (post-fix) | Interactive `/brief` from a non-repo cwd, then `/feat <name>` | not-run | Needs an interactive session (see Missing for verified). Approximated by the static and scratch checks below. |
| Static: `/brief` anchors the write | Read the diff of `.apm/skills/brief/SKILL.md` | pass | Writes `<root>/specs/briefs/<short-name>.md`, `<root>` = `git rev-parse --show-toplevel`; says the brief is not a temporary file and names `$CLAUDE_JOB_DIR/tmp`; outside a checkout asks for the repo path, else stops and shows the unsaved brief; closing block prints `Brief saved: <root>/...` and `/feat <root>/...`, written out absolute. Grown tiny brief, capability map and `create-issue` (run from `<root>`) follow. No cwd-relative brief destination remains (grep of `specs/briefs`, `specs/maps`). |
| Static: `/feat` lookup | Read the diff of `.apm/skills/feat/SKILL.md` | pass | Setup step 1: file as given, else `specs/briefs/<name>.md` in this checkout, then every other worktree from `git worktree list --porcelain`; one match used and named, several listed and asked, none stops naming every path searched. `argument-hint` and description take a name. Phase 2 step 3 deletes only in the starting checkout, else logs `- [!] brief left in another worktree: <path>`; the final-message list includes it. |
| Docs mirror | Read diff of `README.md`, `docs/usage.md`, `docs/workflow.md` | pass | All three describe the anchored path, the name lookup and the delete rule. No size-table, agent or diagram change, so no matrix or `docs/img` re-render needed. |
| Scratch: outside a checkout | `git rev-parse --show-toplevel` in a non-repo dir under the job tmp dir | pass | Exit 128, `fatal: not a git repository`: the case where `/brief` asks for the repo path. |
| Scratch: inside a worktree | Same command in a scratch worktree | pass | Prints the worktree's own root, so a `/brief` run in a worktree writes there. |
| Scratch: worktree enumeration | `git worktree list --porcelain` in the scratch repo (main + one extra worktree) | pass | Prints one `worktree <abs path>` line per checkout, so the documented search list can be built. |
| Scratch: lookup found / none | `ls` of `<wt>/specs/briefs/{demo,nope}.md` in both worktrees | pass | `demo.md` exists only in the other worktree (would be found, one match, left in place); `nope.md` is in neither (none: every path searched can be named). Scratch dir removed afterwards. |
| Lint | `mise run lint` | pass | Exit 0; `harness.md`/`rebase.md` word grep clean, `/tiny` under 200 lines. Plugin validator advice (no icon, no marketplace install line in README) is pre-existing and does not change the verdict. |
| Regression suite | `mise run test:apm`; `mise run test:tracker`; `mise run test:spec-number` | pass | All three exit 0 (`.claude/agents 9`, `.claude/skills 7`; "all spec-number tests passed"). |
| Hooks | Read `.specify/extensions.yml` | skipped | `hooks: {}`; none registered. |

## Output Excerpts

```
$ git rev-parse --show-toplevel        # cwd outside any checkout
fatal: not a git repository (or any of the parent directories): .git   (exit 128)

$ git worktree list --porcelain        # scratch repo
worktree <tmp>/t18/repo
branch refs/heads/main

worktree <tmp>/t18/wt-a
branch refs/heads/a

$ mise run lint
✔ Validation passed
[lint] $ test "$(wc -l < .apm/skills/tiny/SKILL.md)" -le 200 || ...      (exit 0)
```

## Residual Risks

- The instructions are prompts: whether a background job's model actually follows "never write to `$CLAUDE_JOB_DIR/tmp`" and asks for the repo path is untested; only an interactive or background run shows it.
- `/feat` name lookup with several matches (ask, never pick) and a stale brief in an abandoned worktree were verified by reading the text only.
- The Log line `brief left in another worktree` surviving `/feat resume` was not exercised.

## Recommendation

Hold on `verified` until the two manual checks run once in a real session (and a background job): `/brief` from a cwd outside the repo, and `/feat <short-name>` with the brief in another worktree and with no brief. Nothing found contradicts the fix and no regression appeared; once those pass, close the bug.
