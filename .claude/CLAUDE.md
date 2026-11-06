# feat-agent

Three skills (`.apm/skills/brief/SKILL.md` writes the brief,
`.apm/skills/feat/SKILL.md` coordinates the build, `.apm/skills/fix/SKILL.md`
coordinates a bugfix) and the phase subagents
(`.apm/agents/*.agent.md`), distributed three ways from one source, for Claude Code only: an APM
package (`apm.yml`), a Claude Code plugin (`.claude-plugin/`), and
`install.sh` for development. See README.md and docs/install.md.

When changing it:
- The size tables in `.apm/skills/feat/SKILL.md` and `.apm/skills/fix/SKILL.md`
  are the sources of truth for model and effort, and their `Loads` columns
  list what each row's agent reads. Mirror every change of either in
  `docs/workflow.md` (its matrix, the `/fix` section's matrix, and the
  agents table); row 1 (`feat-brief-reviewer`) is also written out in
  `.apm/skills/brief/SKILL.md`, which spawns it.
  Agent frontmatter carries no `model`, `effort`, `tools` or `color`
  (`/feat` and `/fix` pass model and effort per spawn); use `disallowedTools`.
  Reviewer groups (`/feat` phases 4 and 7, `/fix` phase 4) live under each
  table and in `REVIEW_GROUPS` in a cost script (since moved out), keyed by skill.
- The rules `/feat` and `/fix` share live in
  `.apm/skills/feat/references/harness.md`, written with named values that
  each skill's `## Harness values` block fills. Keep `/feat`-only words out
  of it: `mise run lint` greps it.
- Adding or removing a third-party skill: update `dependencies` in
  `apm.yml`, `deps` in `install.sh`, the `npx skills add` line in
  `docs/install.md` and its table, and the agent's `skills:` (or the lens in
  `feat-code-reviewer.md`) and the size table's `Loads` column.
- Agent prompts end with a fixed report format; the orchestrator depends on
  it. Change both sides together. `/feat` and `/fix` stay thin: they never read code
  or edit artifacts; new work goes into an agent, not the coordinator.
- Adding or removing an agent: list it in `.claude-plugin/plugin.json`
  (`agents` is an explicit list).
- `version` in `apm.yml` and `.claude-plugin/plugin.json` must match;
  `mise run release` bumps both (plugin users stay on the version they
  have until it changes).
- Shell: `shellcheck` must stay clean on `install.sh`, the tracker script
  (`.apm/skills/feat/scripts/`) and its bash tests (`tests/tracker/`);
  `mise run lint` runs all three, `mise run test:tracker` the offline tests.
- a cost script (since moved out) parses both size tables (`| <N><a-e> <name> |
  \`feat-x\` | <loads> | model · effort | …`); keep that format or update the
  parser. Run a cost script (since moved out) (`--skill fix` for `/fix`) on a real run
  after changing models, agents or dependencies, and record notable results
  in the cost notes (since moved out). Keep `PRICES` current.
- Record user-visible changes in CHANGELOG.md.
- The roadmap is the GitHub Project https://github.com/users/pdemagny/projects/2:
  one issue per item, label `feat` or `bug`, fields Priority (P1/P2/P3), Size
  (small/medium/large), Status. A PR says `Closes #N`; follow-ups are new
  issues.
- Tools and tasks are in `mise.toml`: `mise run lint` and `mise run
  test:apm` before committing, `mise run release <version>` to release (it
  dates the CHANGELOG's `## Unreleased` section and opens a new one, so
  keep entries there). Bump the tool pins there when you test on newer
  versions.
