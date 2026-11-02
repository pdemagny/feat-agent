# Research: Board tracking

No `NEEDS CLARIFICATION` was left in the Technical Context. Each item below
is a decision the spec left open; options the brief's "Alternatives
rejected" ruled out (a third skill, a subagent per move, another language or
location, skipping the check in `/feat`, creating the issue early, caching
IDs) are not reconsidered.

Probed live on 2026-11-02 with gh 2.103.3 (read-only calls against
`users/pdemagny/projects/2` and issue #11): the combined board-plus-issue
query, `repositoryOwner` + `ProjectV2Owner`, `--include` with `--jq` (and
the `X-Oauth-Scopes` header), compact `--json` output when piped, the
missing board, issue and repository errors (raw JSON on stdout, `gh:
<message>` on stderr, exit 1), and an unknown owner (exit 0, no output).
The exact documents and filters run are in
[contracts/tracker-cli.md](contracts/tracker-cli.md).

## R1. Talking to the board: `gh api graphql`, not `gh project`

- **Decision**: four fixed GraphQL documents through `gh api graphql`, values
  as `-f`/`-F` variables, responses flattened by gh's built-in `--jq`.
- **Rationale**: `gh project item-list` pages through every item of the board
  to find one issue, and `gh project field-list`/`item-edit` take IDs from
  other calls, so a move would cost 3–4 calls plus JSON parsing the script
  can't do without jq. One GraphQL read returns the board, its Status options
  and the issue's item on that board together. `--jq` is part of gh (gojq),
  so no jq dependency.
- **Alternatives**: `gh project` subcommands (more calls, output parsing);
  REST endpoints (no single call returns board, options and the issue's item
  together).

## R2. One query for user and organization boards

- **Decision**: `repositoryOwner(login:) { ... on ProjectV2Owner { projectV2(number:) } }`.
- **Rationale**: one document instead of a `user` and an `organization`
  variant chosen by the URL. Verified live.
- **Alternatives**: two documents selected by the URL's `users|orgs`; works,
  doubles the constants.

## R3. Checking the `project` scope inside the one `check` call

- **Decision**: `--include` on the `check` query and read `X-Oauth-Scopes`;
  require the exact `project` entry when the header is present; when absent
  (fine-grained PAT, app token), rely on `viewerCanUpdate`.
- **Rationale**: `read:project` is enough for the read but not for moves, so
  a read-only check would pass and every move fail later. The header comes
  with the same call (verified), so `check` is one call, not the brief's ~3.
  `viewerCanUpdate` covers write access for tokens without the header.
- **Alternatives**: `gh auth status` (human output, an extra call, format not
  stable); a second `gh api user --include` call (works, one call more).

## R4. Current repo for `#N` (amended after the design review)

- **Decision**: resolve it once per call with
  `gh repo view --json nameWithOwner --jq .nameWithOwner`, for `#N` in
  `read-issue` and `set-status` and always in `create-issue` (which passes
  it with `-R`); then `-f owner=… -f repo=…` like an `owner/repo#N` ref.
- **Rationale**: D2 asked for this in `create-issue`. Applying it everywhere
  keeps the three operations on one repo: `gh issue` and `gh repo` resolve
  the current repo with gh's "smart" base-repo rule (honours `gh repo
  set-default`, prefers the upstream of a fork), while `gh api`'s
  `{owner}`/`{repo}` placeholders take the first remote. In a fork, `/brief
  #N` would read the upstream issue and `set-status` would move the fork's.
  Cost: one read call per `#N` move (about three per feature). Untrusted
  strings always go through `-f`, because `-F` reads a file for a value
  starting with `@` and converts `true`/numbers.
- **Amended after the code review (S2)**: `create-issue` also takes the
  `owner/repo` the `/brief` gate named as an argument and refuses (exit 1,
  no issue) when its own resolution differs, so the issue lands only in the
  repo the user confirmed. The script still resolves the repo itself and
  never trusts the argument alone.
- **Alternatives**: `{owner}`/`{repo}` placeholders (no extra call; wrong
  repo in a fork, as above); using the repo `/brief` passes without
  resolving it again (one call less, but the script would trust a value the
  session typed).

## R5. Idempotence and "added first"

- **Decision**: read the item and its current option first; add only when
  absent, update only when different. A repeat makes one read and no
  mutation.
- **Rationale**: FR-008 and SC-006 are testable as "no mutation on repeat".
  `addProjectV2ItemById` is itself idempotent (it returns the existing item),
  but calling it every time is a write on every move and hides the "added"
  case the tests need to see.

## R6. Where the retry lives

- **Decision**: inside `set-status` (one retry of the whole attempt after
  `TRACKER_RETRY_DELAY` seconds, default 2, 0 in the tests); the attempt
  includes resolving a `#N` ref with `gh repo view` (amended after the code
  review, B3); never for `create-issue`, `check` or `read-issue`.
- **Rationale**: keeps `/feat` to "run, log the line" (FR-023). A retried
  attempt is safe because each step is idempotent. Creating an issue is not:
  a timeout after the server created it would make a duplicate, and its
  failure is a hard stop anyway. `check` failing stops the run with a fix.

## R7. How the skills know tracking is on

- **Decision**: the skill tests `<repo root>/.feat-agent.yml` itself; absent,
  it never runs the script; present, it requires the script and runs
  `check`. Later moves run when the file exists and the `Issue:` line is set.
  The script also answers `off` without the config.
- **Rationale**: FR-018 needs a missing script to stop the run only when the
  config exists, so the skill must look at the file before it can run
  anything; with only `brief` installed and no config, nothing changes
  (FR-001). No new state-file line: `Issue:` already carries the ref, and
  `/feat resume` reruns setup's check.
- **Alternatives**: a `Tracker:` header line in feat-state.md (one more thing
  to keep in sync; the check reruns on resume anyway).

## R8. Building the created issue from the brief file

- **Decision**: `create-issue <brief-file>`: the script takes the title from
  `# Brief: …` and the Why and Behaviour sections verbatim, appends
  `Brief: specs/briefs/<name>.md`, and passes a temp body file.
- **Rationale**: the body is the same every time without `/brief` composing a
  file by hand; the path is restricted to `specs/briefs/*.md`, so the script
  can't be pointed at another file. FR-020's body file is satisfied.
- **Alternatives**: `create-issue <title> <body-file>` with `/brief` writing
  the body (another file for the session to place and clean, and room to
  drift from the spec's body).

## R9. Config parsing in bash

- **Decision**: a line-by-line reader for the fixed grammar in
  [contracts/feat-agent-yml.md](contracts/feat-agent-yml.md), values into
  fixed variables, `[[ =~ ]]` for the URL.
- **Rationale**: the brief fixes the shape so no YAML library is needed;
  nothing from the file is evaluated, sourced or used as a variable name.
- **Hostile values**: errors on a bad line name its number and a fixed reason,
  never its text; status names and board options are echoed through
  `clean()`. A status value is only compared with option names.

## R10. Offline tests (amended after the design review: D8, D13)

- **Decision**: a stateless stub `gh` (bash) first on PATH: it logs its argv,
  answers `gh issue` and `gh repo` from per-case files, and hands
  `gh api graphql` to the real, pinned gh with `GH_CONFIG_DIR` pointing at a
  config whose `http_unix_socket` is a socket served by
  `tests/tracker/fake_github.py` (stdlib). The endpoint answers raw GraphQL
  JSON chosen by operation name from per-case files, logs each request, and
  keeps no state except a one-shot `<Op>.fail` marker for the retry case.
- **Rationale**: the real `-f`/`-F` handling, `--include` and `--jq` filters
  run in every test, so a filter bug fails offline, not on a live board.
  Verified on 2026-11-02 with gh 2.103.3: gh sends every request through
  `http_unix_socket` as plain HTTP (even for `api.github.com`), prints the
  filtered lines, and on an `errors` body exits 1 with `gh: <message>` on
  stderr, as against GitHub. Nothing can reach the network. `gh issue` and
  `gh repo view` stay canned: their GraphQL operations are gh internals that
  change between versions. `python3` is already required by `mise run lint`.
- **Alternatives**: canned `--jq`-shaped lines in the stub (the filters only
  run live); a stateful stub recording mutations (D13: more code, and
  "repeat is unchanged" is tested as well by an at-target fixture and no
  mutation in the log); a real `jq` in the stub (another dev tool, and not
  gh's gojq); `HTTP_PROXY` to a TCP port (port clashes, proxy env leaking);
  bats (a new dependency for twelve cases).

## R11. Repo root

- **Decision**: `git rev-parse --show-toplevel`, else `$PWD`.
- **Rationale**: the skills' shell may sit in a subdirectory; in a worktree it
  resolves to the worktree, which holds the committed config. git is already
  a prerequisite of the workflow, so this adds nothing.
- **Worktree gap** (D5): `/feat` setup runs before the worktree exists, in
  the main checkout, where the config may be uncommitted or unpushed; the
  worktree branches from `origin/<default>` and may lack it. `/feat`
  re-tests the file after entering the worktree and logs a `[!]` line if it
  is gone, rather than adding a state-file field.

## R12. Refusing brief paths outside `specs/briefs/` (D3)

- **Decision**: resolve the brief's directory with `cd -P` and `pwd -P`
  (builtins), require it to equal `<root>/specs/briefs` resolved the same
  way, and refuse a leaf symlink (`-L`); exit 2 before any gh call.
- **Rationale**: a check on the leaf alone misses a symlinked `specs` or
  `specs/briefs` directory, which would let `create-issue` publish any file
  as an issue body. `realpath` isn't on macOS before 13 and `readlink -f`
  differs between GNU and BSD, so leaf links are refused rather than
  resolved; a brief is never a link in practice.

## R13. gh version

- **Decision**: pin 2.103.3 in mise.toml (the probed version); the docs say
  "tested on gh 2.103.3" and state no minimum (amended after the code
  review, B6: no older gh was run).
- **Rationale**: the script uses `gh api graphql` with `-f`/`-F`, `--jq`,
  `--include`, `gh issue view|create` with `--json`/`--body-file`/`-R`, and
  `gh repo view --json`, all present in the 2.x line; only 2.103.3 was run.
