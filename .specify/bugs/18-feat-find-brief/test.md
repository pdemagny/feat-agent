# Bug Verification: /brief writes the brief relative to the cwd and /feat only takes an exact path

- **Slug**: 18-feat-find-brief
- **Tested**: 2026-11-18
- **Assessment**: ./assessment.md
- **Fix**: ./fix.md
- **Result**: partial

## Summary

Cycle: after review fixes (the previous report is `test-1.md`). The fix is in skill instructions, which have no automated harness. The diff against `0a2be2d` now matches both "Done when" items, the user's decisions and the review fixes B1, B2 and std1. Scratch approximations of the lookup, the short-name pattern and the delete rule behave as the text says, and `mise run lint`, `test:apm`, `test:tracker` and `test:spec-number` pass. The interactive `/brief` and `/feat` runs cannot be driven in this automated mode and were not exercised, so the result stays `partial`, not `verified`.

## Checks Performed

| Check | Command / Action | Result | Notes |
|-------|------------------|--------|-------|
| Reproduction (post-fix) | Interactive `/brief` from a non-repo cwd (and a background job), then `/feat <name>` | not-run | Needs an interactive Claude Code session (see Missing for verified). Approximated by the static and scratch checks below. |
| Static: `/brief` anchors the write (B2, std1) | Read the diff of `.apm/skills/brief/SKILL.md`; grep `specs/briefs`, `specs/maps`, `repo root>` | pass | `<root>` (`git rev-parse --show-toplevel`) is defined once before step 1; outside a checkout it asks for the repo path now and stops without one. `.logistics.yml`, `CLAUDE.md`/`AGENTS.md`, code reads, `gh repo view`, `create-issue` (run from `<root>`), the grown tiny brief, the brief (§3) and the capability map all use `<root>`. §3 says the brief is not a temporary file and names `$CLAUDE_JOB_DIR/tmp`; the unsaved-brief fallback covers only a failed write. Closing block prints `Brief saved: <root>/specs/briefs/...` and `/feat <root>/...`, written out absolute. No `<repo root>` left in `/brief`; the remaining ones are in `harness.md`, `rebase.md`, `tracker.sh` and `/tiny`, out of scope. |
| Static: `/feat` lookup | Read the diff of `.apm/skills/feat/SKILL.md` | pass | Setup step 1: file as given, else `<name>` (leading `specs/briefs/` and trailing `.md` stripped) which must match `[a-z0-9][a-z0-9-]*`, else stop as for no match; then `specs/briefs/<name>.md` in this checkout, then every other worktree from `git worktree list --porcelain`. One match used and its absolute path said, several listed and asked (never picked), none stops naming every path searched and points to `/brief`. `argument-hint` and description take a name. |
| Static: `/feat` delete rule (B1) | Read phase 2 step 3 and the final-message list | pass | Deletes only when the brief's path is exactly `<this checkout's top level>/specs/briefs/<short name>.md` with the short name matching the pattern (a file given by path counts only then); anything else logged `- [!] brief left in place: <path>` and named in the final message via the Log line. The old wording `left in another worktree` is gone from `.apm`, `docs` and README. |
| Docs mirror | Read diff of `README.md`, `docs/usage.md`, `docs/workflow.md` | pass | All three describe the anchored path, the name lookup and the delete rule (docs/usage.md: "any other brief (in another worktree, or a file elsewhere you gave by path) stays, and the final message names it"). No size-table, agent or diagram change, so no matrix or `docs/img` re-render needed. |
| Scratch: short-name pattern (B1) | Bash `[[ "$n" =~ ^[a-z0-9][a-z0-9-]*$ ]]` over 12 names | pass | Accepted: `foo`, `foo-bar`, `a1`. Rejected: `../x`, `Foo`, `-x`, `x_y`, empty, `foo/bar`, `foo.md`, `specs/briefs/foo`, ` foo`. The pattern is the name part of `tracker.sh`'s `RE_BRIEF_PATH` (`^specs/briefs/[a-z0-9][a-z0-9-]*\.md$`). |
| Scratch: outside a checkout | `git rev-parse --show-toplevel` in a non-repo dir under the job tmp dir | pass | Exit 128, `fatal: not a git repository`: the case where `/brief` asks for the repo path. |
| Scratch: toplevel in a worktree | Same command in a subdir of a scratch worktree and in the main scratch checkout | pass | Prints each checkout's own top level (the worktree root, not the main repo), so a `/brief` run in a worktree writes there. |
| Scratch: lookup | Scratch repo + one worktree; for names `here`, `demo`, `dup`, `nope`: this checkout's `specs/briefs/<name>.md` first, then each `git worktree list --porcelain` worktree | pass | `here` (this checkout) 1 match; `demo` (other worktree only) 1 match; `dup` (both) 2 matches, so the text's "ask, never pick" applies; `nope` 0 matches, with both searched paths nameable. |
| Scratch: delete rule | Compared the found/odd path with `<top>/specs/briefs/<name>.md` and the name pattern | pass | Deleted only for `<top>/specs/briefs/here.md`. Left in place: the other worktree's `demo.md` and `dup.md`, `<top>/specs/briefs/sub/here.md`, `<top>/other/briefs/here.md`, `<top>/specs/briefs/../briefs/here.md`, `<top>/specs/briefs/Here.md`. Scratch dir removed afterwards (checked). |
| Lint | `mise run lint` | pass | Exit 0, `Validation passed`; `harness.md`/`rebase.md` word grep clean, `/tiny` under 200 lines. Plugin validator advice (no marketplace install line in README) is pre-existing and does not change the verdict. |
| Regression suite | `mise run test:apm`; `mise run test:tracker`; `mise run test:spec-number` | pass | All three exit 0 (`.claude/agents 9`, `.claude/skills 7`; "all spec-number tests passed"). |
| Hooks | None allowed by the orchestrator | skipped | No Spec Kit hooks configured. |

## Output Excerpts

```
$ git rev-parse --show-toplevel        # cwd outside any checkout
fatal: not a git repository (or any of the parent directories): .git   (exit 128)

short name: accept foo, foo-bar, a1
            reject ../x, Foo, -x, x_y, "", foo/bar, foo.md, specs/briefs/foo

name=demo matches=1  (other worktree)  -> delete rule: leave in place
name=dup  matches=2  (both)            -> ask, never pick
name=nope matches=0                    -> stop, name both searched paths

$ mise run lint
✔ Validation passed          (exit 0)
```

## Residual Risks

- The instructions are prompts: whether a background job's model actually follows "never write to `$CLAUDE_JOB_DIR/tmp`" and asks for the repo path when outside a checkout is untested; only an interactive or background run shows it.
- The scratch checks reproduce the commands and the stated rules in bash, not a model following the skill text; the multi-match question, the stale-brief-in-abandoned-worktree case and the `brief left in place` Log line surviving `/feat resume` are verified by reading the text only.

## Recommendation

Hold on `verified` until the manual checks run once in a real session (and a background job): `/brief` from a cwd outside the repo, and `/feat <short-name>` with the brief in another worktree, with two matches and with no brief. Nothing found contradicts the fix, the review fixes B1, B2 and std1 are in place and no regression appeared; once those pass, close the bug.
