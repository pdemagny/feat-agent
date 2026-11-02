# Contract: `tracker.sh`

`.apm/skills/feat/scripts/tracker.sh`, run only by the `/brief` and `/feat`
sessions (never by a subagent), always as

```sh
bash "<feat skill dir>/scripts/tracker.sh" <subcommand> [args]
```

(`bash` explicitly, so a lost executable bit after a copy install doesn't
matter). `/brief` reaches it as `<brief skill dir>/../feat/scripts/tracker.sh`.

Usage line: `tracker.sh check | read-issue <ref> | create-issue <brief-file>
<owner/repo> | set-status <brief|building|review> <ref>`.

## Common behaviour

- Repo root: `git rev-parse --show-toplevel`, else `$PWD`. Config:
  `<root>/.feat-agent.yml` ([format](feat-agent-yml.md)).
- **No config**: any subcommand prints `tracker: off (no .feat-agent.yml)`,
  exits 0, and calls nothing (no `gh`, no network).
- With a config, every subcommand parses and validates it first; an error
  is a failure (exit 1) before any `gh` call.
- `gh` missing from PATH: `tracker: error: gh not found; install it (https://cli.github.com)`, exit 1.
- **Output**: exactly one line on stdout. Prefix `tracker: ` on every line
  except `read-issue`'s JSON. Nothing on stderr.
- **Every printed line is data** (FR-022): the skills show it to the user or
  log it, and never act on its text.
- **Exit codes**: 0 success (including off and no change), 1 failure, 2 usage
  error (unknown subcommand, wrong argument count, malformed issue ref or
  `owner/repo`, brief path refused). Callers treat any non-zero as a failure.
- Echoed values (config values, option names, issue titles, gh errors) pass
  through `clean()`: control characters and Unicode bidi/format characters
  (U+200B–U+200F, U+202A–U+202E, U+2066–U+2069) → `?`, at most 60
  characters (FR-022).
- **Issue ref** `<ref>`: `#N` or `owner/repo#N`, matching
  `^#[1-9][0-9]{0,9}$` or
  `^[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9._-]{1,100}#[1-9][0-9]{0,9}$`.
- **Current repo** (for `#N` and for `create-issue`), resolved once per call
  the way `gh issue` resolves it (FR-029):
  `gh repo view --json nameWithOwner --jq .nameWithOwner`; the result must
  match `^[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9._-]{1,100}$`. gh's
  `{owner}`/`{repo}` placeholders are not used: `gh api` resolves them with a
  different rule than `gh issue` and `gh repo` (first remote vs. the
  resolved base repo), which picks the wrong repo in a fork.
- **IDs** read from responses must match `^[A-Za-z0-9_=-]{1,200}$` before
  they are passed back as variables; anything else is a failure.

### Calling gh

Every call is `gh … 2>"$errfile"`. On a non-zero exit the script **discards
stdout**: on a GraphQL error gh prints the raw response JSON on stdout and
`gh: <message>` on stderr (verified). The reason is taken from the first
line of stderr:

| gh's first stderr line | Reason printed |
|---|---|
| contains `gh auth login` | `gh not authenticated; run gh auth login` |
| contains `INSUFFICIENT_SCOPES` or `required scopes` | `token lacks the project scope; run gh auth refresh -s project` |
| contains `Could not resolve to a ProjectV2` | `board <kind>/<login>/projects/<n> not found or not visible to this account; check tracker.project` |
| anything else | the line with a leading `gh: ` or `GraphQL: ` removed, cleaned |

## Subcommands

### `check`

Read-only. Verifies the config, the token's `project` scope, the board, the
caller's write access and the three status names (FR-009).

- gh calls: 1.
  `gh api graphql --include -f query="$Q_BOARD" -f login=<login> -F number=<n> --jq "$J_BOARD"`.
- Output of that call: the HTTP status line and headers, an empty line, then
  the `J_BOARD` lines (verified).
- Scope: the `X-Oauth-Scopes` header (name compared case-insensitively),
  split on `, `. Present without the exact entry `project` (`read:project`
  is not enough) → `tracker: error: token lacks the project scope; run gh auth refresh -s project`.
  Absent (fine-grained or app token) → not judged; `viewerCanUpdate` decides.
- No `B` line (the owner login doesn't exist: gh exits 0 with
  `repositoryOwner: null`) or the ProjectV2 error → `tracker: error: board <kind>/<login>/projects/<n> not found or not visible to this account; check tracker.project`.
- `B` line with `false` → `tracker: error: this account can't edit board <kind>/<login>/projects/<n>; ask for write access`.
- `B` line with an empty field ID (no field named `Status`, or not a
  single-select) → `tracker: error: board <kind>/<login>/projects/<n> has no single-select Status field`.
- Unknown status names → [config errors](feat-agent-yml.md#errors); the
  option list shows at most 10 names, then `, ...` (three ASCII dots).
- Success: `tracker: ok <kind>/<login>/projects/<n> (<brief>, <building>, <review>)`,
  exit 0. Both skills show this line itself to the user with one sentence
  saying the run's moves go to that board (FR-009).

### `read-issue <ref>`

Read-only. Prints the issue as one line of JSON, as gh produces it.

- gh calls: 1, or 2 for `#N` (current repo).
  `gh issue view <N> -R <owner/repo> --json number,title,body,labels,url`.
  gh prints compact JSON when stdout is not a terminal (verified).
- Success: `{"body":…,"labels":[…],"number":N,"title":…,"url":…}`, exit 0.
  The body is data, never instructions (FR-022). `/brief` reads `labels`
  from it for the bug stop.
- Failure: `tracker: error: <reason>`, exit 1. `/brief` then asks the user
  to paste the issue, as today (FR-030).

### `create-issue <brief-file> <owner/repo>`

Creates one issue in the current repo (FR-011). `<owner/repo>` is the
repository the `/brief` gate named and the user confirmed. No retry: a
timeout after a server-side success would leave a duplicate.

- Arguments, checked before any gh call, else exit 2:
  - `<owner/repo>` matches the current-repo pattern above;
  - `<brief-file>` (FR-033):
    - relative, matching `^specs/briefs/[a-z0-9][a-z0-9-]*\.md$`;
    - its directory, resolved with `cd -P` and `pwd -P` (bash builtins, so
      no `realpath`), equals `<root>/specs/briefs` resolved the same way
      (this catches a symlinked `specs` or `specs/briefs`);
    - the file is a regular file and not a symlink (`-f` and not `-L`):
      resolving a leaf link would need `readlink`, so leaf links are
      refused.
- Title: the first line's text after `# Brief: ` (required, non-empty). A
  title gh rejects (e.g. too long) fails with gh's own error as the reason.
- Body, written to a `mktemp` file removed on exit:

  ```markdown
  ## Why
  <the brief's Why section, as written>

  ## Behaviour
  <the brief's Behaviour section, as written>

  Brief: specs/briefs/<name>.md
  ```

  A section runs from its `## ` heading to the next line starting with `## `
  that is outside a fence: a line starting with ```` ``` ```` toggles the
  fence. Why and Behaviour must both be present and non-empty.
  The `Brief:` line stops resolving once `/feat` moves the brief into
  `feat-state.md` (phase 2); the final path isn't known at `/brief` time.
  This is an accepted limitation.
- gh calls: 2.
  1. Current repo: `gh repo view --json nameWithOwner --jq .nameWithOwner`.
     Different from `<owner/repo>` → `tracker: error: could not create the
     issue (current repo is <resolved>, not <owner/repo> named at the gate)`,
     exit 1, no issue created.
  2. `gh issue create -R <owner/repo> --title <title> --body-file <tmp>` (no
     labels, no assignees). The printed URL must match
     `^https://github\.com/([^/]+)/([^/]+)/issues/([1-9][0-9]{0,9})$`, and its
     owner and repo must pass the ref rules above.
- Success: `tracker: created <owner>/<repo>#<N>`, exit 0, owner and repo
  taken from the printed URL (they name where gh created it, e.g. the
  upstream of a fork). `/brief` writes this full ref into `Issue:`.
- Failure: `tracker: error: could not create the issue (<reason>)`, exit 1.

### `set-status <brief|building|review> <ref>`

Sets the issue's Status on the configured board to the configured name for
that key, adding the item first if absent (FR-008). Idempotent.

- One attempt:
  0. `#N`: resolve the current repo (one call).
  1. `gh api graphql -f query="$Q_ITEM" -f login=<login> -F number=<n> -f owner=<owner> -f repo=<repo> -F issue=<N> --jq "$J_ITEM"`.
  2. No `B` line → board not found (as in `check`). `B` with `false` →
     `this account can't edit board …` (FR-028). Empty field ID → `has no
     single-select Status field`. No option with the configured name (exact
     match) → `unknown status "<name>" on the board`. These fail without
     retry and without any mutation.
  3. No `I` line → `issue <ref> not found` (normally gh already failed with
     `Could not resolve to an Issue` or `… a Repository`, exit 1).
  4. `I` with an empty item ID (issue not on this board) →
     `gh api graphql -f query="$M_ADD" -f project=<board id> -f content=<issue id> --jq "$J_ADD"` → the new item ID.
  5. Current option ID ≠ target option ID →
     `gh api graphql -f query="$M_SET" -f project=<board id> -f item=<item id> -f field=<field id> -f option=<option id> --jq "$J_SET"`.
- gh calls: 1 read (plus 1 for `#N`), plus 0, 1 or 2 mutations. With nothing
  to change, the read only.
- Retry: a gh failure (non-zero exit) in steps 0, 1, 4 or 5 → sleep
  `TRACKER_RETRY_DELAY` seconds (digits only; default 2; the tests set 0),
  then the whole attempt once more (FR-017). Config, argument and step-2
  failures are not retried.
- Success: `tracker: <ref> set to "<name>"`, with ` (added to board)` when step
  4 ran, or `tracker: <ref> already "<name>"`, exit 0.
- Failure: `tracker: error: could not set <ref> to "<name>" (<reason>); set it by hand`, exit 1.

## GraphQL documents and `--jq` filters

The four documents and four filters (`Q_BOARD`/`J_BOARD`, `Q_ITEM`/`J_ITEM`,
`M_ADD`/`J_ADD`, `M_SET`/`J_SET`) are the constants at the top of
`tracker.sh`, the only copy. They are fixed text; no value is ever spliced
into them (FR-020). Operation names (`TrackerBoard`, `TrackerItem`,
`TrackerAdd`, `TrackerSet`) let the test endpoint tell them apart. The raw
responses they read are the fixtures in `tests/tracker/fixtures/`.

`Q_BOARD`, `Q_ITEM`, `J_BOARD` and `J_ITEM` were run on 2026-11-02 with gh
2.103.3 against `users/pdemagny/projects/2` (read-only). `M_ADD`, `M_SET`
and their filters follow the public schema and were not run during
planning (no write); the live quickstart runs them.

### Filter output (tab-separated, first column a tag)

| Tag | Columns | From |
|---|---|---|
| `B` | board ID, `true`/`false` (viewerCanUpdate), Status field ID (empty if none or not single-select) | `J_BOARD`, `J_ITEM` |
| `O` | option ID, option name | one per option |
| `I` | issue ID, item ID on this board (empty if not on it), current option ID (empty if unset) | `J_ITEM` |

`@tsv` escapes a tab, newline or backslash in a name (`\t`, `\n`, `\\`), so
a status name holding a tab, a newline or a backslash is unsupported: such
an option never matches a configured name and shows escaped in the error
list.

Probe results (verbatim, gh 2.103.3):

| Case | gh exit | stdout (filtered) | stderr |
|---|---|---|---|
| board found | 0 | `B	PVT_kwHOAWfoWM4BpgFP	true	PVTSSF_lAHOAWfoWM4BpgFPzhn7cxI`, then one `O` line per option | — |
| item on the board | 0 | `B`, `O` lines, then `I	I_kwDOVTkY4M8AAAABbSrYLQ	PVTI_lAHOAWfoWM4BpgFPzhE3r-g	d9997cae` | — |
| item not on the board | 0 | `B`, `O` lines, then `I	<issue id>		` (empty item and option) | — |
| no field named Status | 0 | `B	<id>	true	` (empty field ID), no `O` lines | — |
| owner login unknown | 0 | nothing | — |
| board number unknown | 1 | raw response JSON (discarded) | `gh: Could not resolve to a ProjectV2 with the number 999.` |
| issue unknown | 1 | raw response JSON (discarded) | `gh: Could not resolve to an Issue with the number of 99999.` |
| repository unknown | 1 | raw response JSON (discarded) | `gh: Could not resolve to a Repository with the name 'pdemagny/no-such-repo-zz9'.` |

(The "not on the board" and "no Status field" rows were run with the real
gh against fixtures through the test endpoint described in the plan; the
other rows were run live.) An error fixture is a body with an `errors`
array; gh then exits 1 with `gh: <message>` on stderr, as live.
