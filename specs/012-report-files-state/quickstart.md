# Quickstart: validating report files and the state script

Run from the repo root (the worktree). Every step but 8 and 9 is offline.

## 1. The offline tests

```sh
mise run test:state
```

Expected: one `ok <case>` line per case and exit 0. The cases cover
([contracts/state-cli.md](contracts/state-cli.md)):
- `init` both forms (title and brief copy, `## Report`, defaults,
  refusals), and its header field names equal the harness template's;
- `set` on every field, `Branch`/`Worktree` on one line, a `- Size:` line
  inside `## Brief` left alone, a field inserted into an older file;
- `log`: order, `'` kept, sub-lines, each refusal (newline, bad prefix,
  sub-line first, no `## Log`) naming the argument and writing nothing;
  an argument holding `'`, `$(…)`, a backtick and `;`, passed
  single-quoted with `'\''`, appended byte for byte (nothing runs);
- `init`, `set`, `log`, `restore-phase` on a state file path that is a
  symlink (dangling for `init`): `state: error: <path> is a symlink`, the
  target untouched;
- `state.sh` holds none of the bash 4 constructs the contract forbids;
- `cycle`, `retry-used`, `shipped-verdict`, `phase2-mode`, `refused-base`,
  `review-summary` on frozen copies of real state files (`specs/011-size-data`,
  `.specify/bugs/10-agents-report-files`, `.specify/bugs/22-secret-scan-blocks`)
  and synthetic ones for each branch of each rule: older formats included
  (`normal`/`big`, `accepted` design lines, `picked`-only, `hard gate:`
  prefixes, `4 Code review fixes`, stale `- [ ]` lines, dash-less
  sub-lines), and a Log line shaped like an instruction; `review-summary`
  with no outcome line prints `Code review was skipped.` and exits 0;
- `find feat|fix` with a scratch repo, two `git worktree add` worktrees, a
  local bare origin for upstreams and the stub `tests/state/bin/gh`
  (shipped, open, a `gh` failure, `done (shipping)` with and without an
  upstream, a deleted branch, an unsafe path); `find rebase` against the
  local origin (each skip reason, the worktree found or `none`);
- `report-path`: `.gitignore` written once with `*`, `-2`, `-3`, never an
  existing path, bad keys, a dir that doesn't exist; `reports` a symlink,
  `<key>.md` a symlink, `<key>-2.md` a symlink: each `<path> is a
  symlink`, no path printed;
- `snapshot`/`unchanged`: an edit to an already-modified file, a new
  untracked file and a deleted file give `changed` followed by those
  paths as `- <path>`; 12 differing paths print 10 and `- and 2 more`; a
  missing manifest prints the "paths unknown" line; a write under
  `reports/`, to an ignored file, or the same content rewritten give
  `unchanged` alone; `git add -N` between them gives `unchanged`; the
  manifest is gone after `unchanged`;
- `restore-phase` in a scratch repo;
- every usage error and stderr empty in every case.

## 2. Lint and packaging

```sh
mise run lint        # shellcheck incl. state.sh and tests/state, the old-wording grep
mise run test:apm    # state.sh lands in .claude/skills/feat/scripts/
```

## 3. The old wording is gone

Put back one old phrase (for example "only the lines after the last `back
to` line" into `.apm/skills/fix/SKILL.md`) and run `mise run lint`: it
fails. Restore the file.

## 4. A state file by hand

Plain commands (no `$(…)`, so they run under the worktree guard too); use
a fresh scratch dir:

```sh
bash .apm/skills/feat/scripts/state.sh init fix /tmp/state-qs/b/feat-state.md 'It'\''s broken' 'it crashes' 'Branch=fix-1-x' 'Size=not set' 'Current phase=1 Assess'
bash .apm/skills/feat/scripts/state.sh log /tmp/state-qs/b/feat-state.md '- [x] 0 Setup — ok' '    - note'
bash .apm/skills/feat/scripts/state.sh set /tmp/state-qs/b/feat-state.md Size small
bash .apm/skills/feat/scripts/state.sh report-path /tmp/state-qs/b/feat-state.md 3-test
cat /tmp/state-qs/b/feat-state.md /tmp/state-qs/b/reports/.gitignore
```

`report-path` prints `/tmp/state-qs/b/reports/3-test.md`.

Expected: the harness template's shape, title `It's broken`, `Size:
small`, the two Log lines.

## 5. Other tests stay green

```sh
mise run test:tracker && mise run test:spec-number && mise run test:secret-scan \
  && mise run test:story && mise run test:sizes && mise run test:measure
```

## 6. Agent files

- `grep -n '^disallowedTools' .apm/agents/feat-code-reviewer.agent.md
  .apm/agents/feat-design-reviewer.agent.md`: `Edit` listed, `Write` not.
- Each of the eight agents of [contracts/digests.md](contracts/digests.md)
  has the report-path rule; the four with a dropped line name it;
  `feat-brief-reviewer.agent.md` and `.apm/skills/tiny/SKILL.md` are
  unchanged (`git diff --stat origin/main -- <them>` is empty).

## 7. Docs

`docs/workflow.md` (the state file, report files, the reviewers' `Wrote:`),
`docs/design.md` (reviewers), `CONTRIBUTING.md` (scripts, tests),
`.claude/CLAUDE.md` (`test:state`) and `.github/workflows/check.yml`
(`mise run test:state`) name the new script and task.

## 8. A live run (after merge, in a scratch project)

Run `/fix "<a small symptom>"` to the PR, then `/feat` on a small brief:
- `ls <artifact dir>/reports/`: one file per spawn, `.gitignore` with `*`;
- `git show --stat HEAD~1 HEAD` on the PR branch: no `reports/` path;
- the transcript: no Edit or Write of `feat-state.md` by the coordinator;
- the PR body's `### Code review` part equals `review-summary`'s output.

## 9. SC-006 (after at least three runs post-merge)

```sh
mise run measure -- --since <merge date>
```

Median coordinator calls per run ≤ 62 (`/feat`) and ≤ 45 (`/fix`). For
"no state-file Edit": in each run's transcript, no coordinator `Edit` or
`Write` tool call whose `file_path` ends in `feat-state.md`.
