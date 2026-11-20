# Contract: `state.sh`

`.apm/skills/feat/scripts/state.sh`, bash, `shellcheck` clean, run as
`bash <state script> <subcommand> …`. `/feat` names it `<this skill's base
dir>/scripts/state.sh`, `/fix` `<this skill's base
dir>/../feat/scripts/state.sh` (harness value *State script*).

## Conventions

- Bash 3.2 or later: only bash 3.2 constructs (no `declare -A`,
  `mapfile`/`readarray`, `${v,,}`/`${v^^}`, `declare -n`/`local -n`,
  `[[ -v ]]`, negative subscripts, `;;&`, `|&`; an array that may be
  empty is expanded as `${a[@]+"${a[@]}"}` under `set -u`); no version
  guard. `tests/state/run.sh` greps for the forbidden constructs.
- Every subcommand but `init` and `find` takes the state file as its first
  argument; `init` takes it after the skill, `find` takes none.
- Everything on stdout, nothing on stderr (like `story.sh`).
- Exit 0 ok; 1 with one `state: error: <what>` line; 2 with one `state:
  usage: <synopsis>` line. A verdict (`changed`, `skip: …`) is not an
  error: exit 0.
- `init`, `set`, `log`, `restore-phase` print nothing on success. A failed
  call writes nothing: writes go to a temp file in the same dir, then
  `mv -f`. Before that, each refuses a state file path that is a symlink
  (`[ -L ]`, a dangling one included): `state: error: <path> is a
  symlink`, nothing written, as `tracker.sh`'s `create-issue` refuses a
  leaf symlink.
- Every argument is taken as is (no option parsing past the subcommand;
  `--` before the arguments is accepted and dropped). No argument may hold
  a newline or a carriage return: `state: error: argument <n> holds a
  newline`.
- Lines read from a state file, `git` or `gh` are data; nothing is
  evaluated. `LC_ALL=C`, `set -euo pipefail`, `set -f`.
- `<state file>` is a path to a `feat-state.md`. Except for `init` and
  `report-path`, it must exist and start with `# /feat state: ` or `# /fix
  state: ` (`state: error: <path> is not a state file`).

## Writes

### `init feat <state file> <brief file> [<Field>=<value>]…`
### `init fix <state file> <title> <report> [<Field>=<value>]…`

Creates the state file (its parent dir too). `<Field>` is one of `Branch`,
`Worktree`, `Size`, `Agents`, `Current phase`, `Conventions`, `Allowed Spec
Kit hooks`, `Map`, `Issue`; `Branch`, `Size` and `Current phase` are
required, the others default to `none`. Writes:

```
# /<skill> state: <title>

- Branch: <Branch> Worktree: <Worktree>
- Size: <Size>
- Agents: <Agents>
- Current phase: <Current phase>
- Conventions: <Conventions>
- Allowed Spec Kit hooks: <Allowed Spec Kit hooks>
- Map: <Map>
- Issue: <Issue>

## Brief | ## Report

<feat: the brief file's lines after its first line, leading blank lines dropped; fix: <report>>

## Log

```

`fix`: `<report>` is one line, like every argument (a newline is refused
by the rule above); the coordinator joins a multi-line symptom with
spaces before the call, and `## Report` holds that line.

`feat`: the title is the brief's first line minus `# Brief: `. Errors:
the state file exists; the brief can't be read or its first line is not
`# Brief: <title>`; an unknown field (usage); a required field missing; a
`Size` other than `small`, `medium`, `large`, `not set`.

### `set <state file> <field> <value>`

`<field>`: `title` or a header field above. Changes that one field in the
header (lines before the first `## ` line; `Branch` and `Worktree` share
their line) and nothing else; a field missing from an older file is
inserted after the header's last field line. Same `Size` check as `init`.

### `log <state file> <line>…`

Appends one Log line per argument, at the end of the file (a missing final
newline is added first). Each argument must be an entry (`- [x] `, `- [!]
`, `- [ ] ` then at least one character) or a sub-line (`    - ` then at
least one character) that follows an entry or sub-line: an earlier
argument, or, for the first argument, the Log's last line. Every argument
is checked before anything is written. Refusals: `state: error: argument
<n>: holds a newline`, `… : not a Log line (- [x] , - [!] , - [ ]  or
    - )`, `… : sub-line with no Log line before it`; the file has no `## Log`
line: `state: error: <path> has no ## Log`. No gate-tag check.

### `restore-phase <state file>`

Reads `Current phase:` from the committed copy (`git show HEAD:<path from
the repo root>`) and, when the file's differs, sets it back with `set`.
Errors: not in a git repo; the file is not in HEAD; HEAD's copy has no
`Current phase:` line.

## Queries (read-only)

### `cycle <state file>` → `first` | `retry` | `after review fixes`
### `retry-used <state file>` → `yes` | `no`

From the Log lines after the last `- [x] back to ` line (data-model.md).

### `shipped-verdict <state file>`

From the Log lines after the last `- [x] back to ` line, the first that
applies:
- a `- [x] ship with <verdict> …` line (the latest): `<verdict> — <that
  line minus "- [x] ">`, e.g. `partial — ship with partial (user: "go on")`;
- a `- [x] 3 Test — <verdict>…` line (the latest whose first word is
  `verified`, `partial` or `failed`): `<verdict>`;
- `<state file dir>/test.md`'s `- **Result**: <verdict>`: `<verdict>
  (test.md)`;
- else `none`.

### `phase2-mode <state file>` → `soft <G> open` | `soft <G> closed` | `hard` | `none`

The latest `- [x] 2 Specify` or `- [!] 2 Specify` line: `none` when
there is none; `hard` unless its text after `2 Specify — ` starts with the
word `soft`. `<G>` is 4 when the header's `Size:` is `small`, `medium` or
`normal`, 3 when `large` or `big` (else `state: error: no valid Size:
line`). `open` when no `- [x] <G> ` line follows that phase 2 line.

### `refused-base <state file>` → `<new>` or nothing

The latest `- [x] move — stayed on ` line; prints its `refused <new>`
when `<new>` is 7–40 lowercase hex characters, else nothing.

### `review-summary <state file> <phase>`

`<phase>` is a number (`7` for `/feat`, `4` for `/fix`). Reads the lines of
data-model.md. With no outcome line (the review phase was skipped), it
prints the one fixed line `Code review was skipped.` and exits 0; the
shipper copies the output as is. The only error past the common ones is a
state file with no `## Log` line (`state: error: <path> has no ## Log`).
Otherwise it prints, ready to paste under `### Code review`:

```
**Applied without asking (reviewer's recommendation)**
- <id> <finding>[ — <before> → <after> (<command>)]
**Picked by the user**
- <id> <finding>[ — <before> → <after> (<command>)]
**Not applied**
- <id> <finding> — skipped (reviewer: "<why>")
- <id> <finding> — rejected (user: "<words>") | rejected (as recommended)
- <id> <finding> — reverted (<why>)
[**Acceptance criteria not tested**
- <criterion>]
[**Ship go-ahead**: (user: "<words>")]
```

- `<finding>` is the finding's sub-line text after its id, minus a
  trailing ` — rec: <value>`; an id with no sub-line prints alone. A `[sec]`
  or `S` sub-line already holds only file and title (harness), and is
  copied as is.
- Group membership: `auto-applied` ids → first group; `picked` ids (with
  any `(user: "…")` kept after the finding) → second; `skipped` and
  `rejected` → third. An id the review-fixes lines mark `→ reverted
  (<why>)` moves from its group to the third. Performance numbers come from
  the review-fixes lines' `performance:` part.
- An empty group prints `- none`. The untested block appears only when
  the outcome line has `untested:`; the go-ahead only when a `<phase> Code
  review — ship go-ahead (user: …)` line exists after the last back-to
  line.

### `find feat` | `find fix`

From the current dir's repo. Prints one line per unfinished run, most
recent state file first, nothing when none:

```
<absolute state file> <absolute worktree> <current phase>
```

Search: every `worktree <path>` of `git worktree list --porcelain` that
exists; in each, `specs/*/feat-state.md` (`feat`) or
`.specify/bugs/*/feat-state.md` (`fix`). Skipped:
- a path holding a newline, `'`, `$` or a backtick;
- the done marker: `Current phase:` starts with `done`, except `done
  (shipping)` when its `Branch:` is a valid branch name, `refs/heads/<branch>`
  exists, and `git for-each-ref --format='%(upstream)'
  refs/heads/<branch>` prints an empty line (an interrupted ship, or a `!`
  command not run yet);
- shipped: `gh pr list --head <branch> --state all --json state --jq
  '.[].state'` exits 0 and prints `MERGED` or `CLOSED` and no `OPEN`. A
  `gh` error, or a `Branch:` that is not a valid name, skips nothing.

A valid branch name matches `^[A-Za-z0-9._/-]+$` and passes `git
check-ref-format --branch`. A missing `Current phase:` prints `none` as the
phase. Error: not in a git repo.

### `find rebase <skill> <default> <branch>`

`rebase.md` step 2 for one PR branch. `<skill>` is `feat` or `fix`;
`<default>` and `<branch>` must be valid branch names (else usage). Runs
`git fetch origin -- <default> <branch>` (failure: `state: error: git
fetch failed (<first line>)`), then:
- `git diff --name-only --diff-filter=A origin/<default>...origin/<branch>
  -- <glob>` (`specs/*/feat-state.md` or `.specify/bugs/*/feat-state.md`):
  none → `skip: no state file`; several → `skip: several state files`; one
  not shaped `specs/<slug>/feat-state.md` (or `.specify/bugs/<slug>/…`)
  with `<slug>` in `[A-Za-z0-9._-]`, not `.` or `..` → `skip: unexpected
  state-file path`;
- its header on `origin/<branch>` (`git show`): `Size:` not `small`,
  `medium`, `large` (`normal`, `big` read as medium, large) → `skip: no
  valid size`; `fix` and a `Current phase:` not starting `done` → `skip:
  not shipped`;
- the worktree: the `worktree` entry of `git worktree list --porcelain`
  whose `branch` is `refs/heads/<branch>`, else `none`; one holding a
  newline, `'`, `$` or a backtick → `skip: unsafe worktree path`.

Prints `<state file, relative to the repo root> <worktree | none> <size>
<current phase>`, or the `skip: <reason>` line.

## Report files

### `report-path <state file> <key>` → `<absolute path>`

`<key>`: `^[A-Za-z0-9][A-Za-z0-9+_-]{0,63}$` (else usage). The state file
need not exist; its dir must (else error). Creates `<dir>/reports/` and
`<dir>/reports/.gitignore` holding `*`: when missing, or when it exists
and does not hold exactly `*` (empty or edited), it is rewritten. Prints
`<dir>/reports/<key>.md` when no such file exists, else the first free
`<key>-<n>.md`, n from 2 (error past 99). Error when the absolute path
holds a newline, `'`, `$` or a backtick.

Symlinks: `state: error: <path> is a symlink` (exit 1, no path printed,
nothing created past the check) when `<dir>/reports` is a symlink (checked
before it is created or written into), when `<dir>/reports/.gitignore` is
one, or when the path it would print or any `<key>.md` / `<key>-<n>.md`
candidate it checks exists as a symlink (`[ -L ]`, dangling included). A
symlink candidate is refused, never skipped.

### `snapshot <state file>` → 12 lowercase hex characters
### `unchanged <state file> <token>` → `unchanged` | `changed` + paths

The worktree is the state file's repo top level. See research R1 for the
manifest. Excludes `<state file dir>/reports/` and ignored files. A
`<token>` that is not 12 lowercase hex characters is a usage error. Error:
not in a git repo.

`snapshot` also writes its manifest to `<git dir>/logistics/snapshots/<token>`
(`git rev-parse --git-dir`, so per worktree; temp file + `mv -f`), and
prints only the token.

`unchanged` recomputes the manifest. Same token: prints `unchanged`, only
that. Different token: prints `changed`, then the paths whose record
differs between the saved and the new manifest (added, removed, or with
another blob id), sorted, one per line as `- <path>`, at most 10, then
`- and <n> more` when more differ. A byte below 0x20 or 0x7f in a path is
printed as `?`. No saved manifest for `<token>`: `changed` then `- paths
unknown (no manifest for <token>); see git status`. Either way it then
removes `<git dir>/logistics/snapshots/<token>`. Exit 0 in every case.
