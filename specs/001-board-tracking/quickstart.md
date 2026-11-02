# Quickstart: validating board tracking

## Offline (every change)

```sh
mise install           # gh 2.103.3 (pinned): the tests run the real gh against a fake endpoint
mise run lint          # shellcheck install.sh, the tracker script and the bash tests; py_compile; plugin validate
mise run test:apm      # APM install count, plus: test -f .claude/skills/feat/scripts/tracker.sh
mise run test:tracker  # tests/tracker/run.sh: stub gh + real gh --jq against tests/tracker/fake_github.py
```

Expected: all exit 0; `test:tracker` prints one `ok <case>` line per case and
fails on the first wrong one. No case can reach GitHub: the stub answers
`gh issue`/`gh repo`, and the real gh sends every request to the fake
endpoint's unix socket. The twelve cases (FR-025) and their assertions,
including the read-issue case and the missing-`project`-scope case, are
listed in [plan.md](plan.md#tests-teststracker).

## Live (once, before merging)

Prerequisites: a test board you own with a Status field holding Todo, Brief,
In progress, In review and Done, "Item closed" enabled; `gh auth refresh -s
project`; a test repo with a committed and pushed `.feat-agent.yml` pointing
at it.

1. `bash .apm/skills/feat/scripts/tracker.sh check` in the test repo →
   `tracker: ok users/<you>/projects/<n> (Brief, In progress, In review)`.
2. `set-status brief #<an issue not on the board>` → `set to "Brief" (added to
   board)` (runs `M_ADD` and `M_SET`, which planning didn't run); again →
   `already "Brief"`; the card shows Brief.
3. Change `review:` to a wrong case → `check` lists the board's options.
4. `read-issue #<issue>` → one JSON line with `labels`.
5. In the test repo, `/brief #<issue>` → the check's line is shown with the
   board sentence; card in Brief before the review runs; `/feat` → line shown
   again, In progress after setup; phase 7 → In review; merge → Done (US1).
6. `/brief "idea"` → the gate names the repo; confirm → `tracker: created
   <owner>/<repo>#N` above the final block, a new issue with the one-liner as
   title, the Why, Behaviour and `Brief:` line as body, no labels, in Brief,
   and the brief's `Issue:` line holds `<owner>/<repo>#N` (US2).
7. Remove the config from the default branch only (keep it in the main
   checkout), run `/feat` → a `[!]` "not in the worktree" line at the first
   gate (FR-032).
8. In a repo without `.feat-agent.yml`, `/brief` and `/feat` show no tracker
   line (US4).
