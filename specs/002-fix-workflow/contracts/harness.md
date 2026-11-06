# Contract: the shared harness reference

File: `.apm/skills/feat/references/harness.md`. Read by `/feat` and `/fix`
before their setup. It holds the rules both follow; each SKILL.md declares
the values the rules refer to. Text moved from `feat/SKILL.md` keeps its
wording; only /feat-specific nouns become the named values below.

## Sections the harness holds (moved from feat/SKILL.md)

| Section | From feat/SKILL.md | Generalised as |
|---|---|---|
| You are a thin orchestrator | "You are a thin orchestrator" (all bullets), "Subagents don't see this conversation…", spawning with `model` and `effort`, missing agent → inline, "A subagent's report is an input…" | "edit anything but the state file"; "one exception, the tracker script" → "the tracker script and the commands the skill lists"; "Read the brief and the state file … spec.md or plan.md" → the skill's artifacts the orchestrator reads; "the feature dir" → the skill's artifact-dir noun; "(from step 0)" → "(from setup)"; the spawn example `feat-planner` / `feat-agent:feat-planner` → `feat-<name>` / `feat-agent:feat-<name>`; "the brief's 'Alternatives rejected'" → the skill's reviewer context; artifact owners, continued agents and spawn rules come from the skill's values |
| Gates | hard/soft semantics, "Size changes", "back to N / skip N / size <s> / stop", gate message shape, "Link artifacts…" | the size-trigger examples, the phases that can't be skipped, the logged gate commands and the building move on "back to N" come from the skill's values |
| State file | the template and the logging rules | header `# /<skill> state: <title>`; the input section, the `Size`, `Agents`, `Current phase` and `Map` lines, the location and when it is created are the skill's |
| Board moves | the whole "Board moves" paragraph | the tracker path, the issue ref, the moments and "before <the state file is created>" are the skill's values |
| Resume | the whole "`/feat resume`" paragraph | `/<skill> resume`; the search scope, the board-check step and the done markers are the skill's values; entering a sibling worktree added |

Stays in `feat/SKILL.md`: frontmatter, intro, size table, reviewer groups,
phases-and-gates table, setup and the phase sections.

## Values each SKILL.md declares

A block headed `## Harness values`, right after the line that says to read
the harness:

| Value | /feat | /fix |
|---|---|---|
| Skill | `feat` | `fix` |
| Harness path | `<this skill's base dir>/references/harness.md` | `<this skill's base dir>/../feat/references/harness.md` |
| Missing harness | n/a (same dir) | stop: "/fix needs feat-agent's `feat` skill (references/harness.md); install or update feat-agent" |
| Artifact dir (noun, path) | "feature dir", `specs/<short-name>/` | "bug dir", `.specify/bugs/<slug>/` |
| State file | `specs/<short-name>/feat-state.md`, created in phase 2; renamed to `specs/<NNN>-<short-name>/` by the shipper | `.specify/bugs/<slug>/feat-state.md`, created at setup step 7 |
| Title / input section | `# /feat state: <feature title>`, `## Brief` (copied from the brief file) | `# /fix state: <bug title>`, `## Report` (the argument as given) |
| `Size:` line | `small \| medium \| large` | `not set \| small \| medium \| large` |
| `Agents:` line | `<specifier\|planner\|tasker> <agent id>, … (for SendMessage)` | `none (every spawn is fresh)` |
| `Map:` line | `<map path and id, if any>` | `none` |
| `Current phase:` values | `<N> <name>`, `done (PR #N)` | `<N> <name>` (0–5), `done (shipping)`, `done (PR #N)` (local copy only), `done (not a bug)`, `done (invalid)` |
| Done marker (resume skips) | `Current phase:` starts with `done` | `Current phase:` starts with `done`, except a `done (shipping)` run whose branch `fix-<slug>` has no upstream (`git for-each-ref --format='%(upstream)' refs/heads/fix-<slug>` empty) |
| Artifacts the orchestrator reads | the brief and the state file; spec.md or plan.md only to quote a line the user must decide on | the state file; assessment.md, fix.md or test.md only to quote a line the user must decide on |
| Commands the orchestrator may run besides the tracker | git for the worktree and the diff | git for the worktree and the diff; `gh issue view <ref> --json number,title,url`; `gh api repos/<o>/<r>/issues/<N> --jq .author_association`; `gh repo view --json nameWithOwner,visibility`; `git ls-remote --heads origin fix-<slug>`; `git for-each-ref --format='%(upstream)' refs/heads/fix-<slug>` |
| Artifact owners at gates | specifier: spec.md; planner: plan.md and accepted design findings; tasker: tasks.md; implementer: code | assessor: assessment.md (re-assess, "back to 1"); implementer: code and fix.md |
| Agents that may be continued | specifier, planner, tasker (SendMessage while warm); implementer always fresh, one per story and one for fixes | none: every spawn is fresh |
| Context handed to reviewers | the rejected findings and the brief's "Alternatives rejected" | the rejected findings and the assessment's remediation alternatives not chosen (`**Alternatives**` of Proposed Remediation) |
| Size triggers | the planner's size trigger (phase 3), the task count (phase 5) | the assess gate's proposed size (phase 1); deviations from the assessment (phase 2): propose one size step up (small → medium, medium → large; large stays large), options "back to 1" (re-assess) or "go on with size <s>" |
| Phases that can't be skipped | none | 1, 2, 3 ("skip 1", "skip 2", "skip 3" are refused) |
| Logged gate commands | "skip N" (with the reason), "size <s>" | "skip N" (with the reason), "size <s>", and every "back to N" as a `back to N` Log line |
| Tracker script | `<this skill's base dir>/scripts/tracker.sh` | `<this skill's base dir>/../feat/scripts/tracker.sh` |
| Board-check step (also run first by resume) | Setup step 5 | Setup step 6 |
| Building move | setup; resume in 2–6; "back to N" (2–6) from 7 or 8 | after the assess gate passes (right away for an existing issue, after creation for a new one); resume in 1–3 once that gate has passed; "back to N" (1–3) from 4 or 5 |
| Review move | phase 7 starts; resume in 7–8 | phase 4 starts; resume in 4–5 |
| Issue ref | `Issue:` line (the brief's, then the state file's) | `Issue:` line of the state file |
| Before the state file exists, `[!]` lines wait until | phase 2 creates it | setup step 7 creates it |
| Resume search | most recent `specs/*/feat-state.md` in this checkout, not done | `.specify/bugs/*/feat-state.md` in this checkout and every path of `git worktree list --porcelain`, without the done marker; one → resume (EnterWorktree with `path` when it is another worktree), several → ask |

## Invariants

- Neither skill restates a harness rule; a rule needed by one skill only
  stays in that skill.
- The harness names no phase number, agent or path of its own; it names
  the values above. Checkable: `harness.md` contains none of `specifier`,
  `planner`, `tasker`, `spec.md`, `brief`, `phase [0-9]`, `/feat`
  (case-insensitive). `mise run lint` runs
  `! grep -Eiq 'specifier|planner|tasker|spec\.md|brief|phase [0-9]|/feat' .apm/skills/feat/references/harness.md`.
- `/feat`'s observable behaviour (phases, gates, state file, board moves,
  resume) is unchanged (FR-027): the values in its column are the words the
  harness text had before the move.
