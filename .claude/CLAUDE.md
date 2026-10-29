# feat-agents

Two skills (`.apm/skills/feat-brief/SKILL.md` writes the brief,
`.apm/skills/feat/SKILL.md` coordinates the build) and the phase subagents
(`.apm/agents/*.agent.md`), distributed three ways from one source, for Claude Code only: an APM
package (`apm.yml`), a Claude Code plugin (`.claude-plugin/`), and
`install.sh` for development. See README.md and docs/install.md.

When changing it:
- The size table in `.apm/skills/feat/SKILL.md` is the source of truth for model
  and effort, and its `Loads` column lists what each row's agent reads.
  Mirror every change in `docs/workflow.md` (matrix and agents table);
  row 1 (`feat-brief-reviewer`) is also written out in
  `.apm/skills/feat-brief/SKILL.md`, which spawns it.
  Agent frontmatter carries no `model`, `effort`, `tools` or `color`
  (`/feat` passes model and effort per spawn); use `disallowedTools`. Phase 4 and 7
  reviewer groups live under the table and in `REVIEW_GROUPS` in a cost script (since moved out).
- Adding or removing a third-party skill: update `dependencies` in
  `apm.yml`, `deps` in `install.sh`, the `npx skills add` line in
  `docs/install.md` and its table, and the agent's `skills:` (or the lens in
  `feat-code-reviewer.md`) and the size table's `Loads` column.
- Agent prompts end with a fixed report format; the orchestrator depends on
  it. Change both sides together. `/feat` stays thin: it never reads code
  or edits artifacts; new work goes into an agent, not the coordinator.
- Adding or removing an agent: list it in `.claude-plugin/plugin.json`
  (`agents` is an explicit list).
- `version` in `apm.yml` and `.claude-plugin/plugin.json` must match;
  `mise run release` bumps both (plugin users stay on the version they
  have until it changes).
- Shell: `shellcheck install.sh` must stay clean.
- a cost script (since moved out) parses SKILL.md's size table (`| <N><a-e> <name> |
  \`feat-x\` | <loads> | model · effort | …`); keep that format or update the
  parser. Run a cost script (since moved out) on a real run
  after changing models, agents or dependencies, and record notable results
  in the cost notes (since moved out). Keep `PRICES` current.
- Record user-visible changes in CHANGELOG.md.
- Tools and tasks are in `mise.toml`: `mise run lint` and `mise run
  test:apm` before committing, `mise run release <version>` to release (it
  needs the CHANGELOG section first). Bump the tool pins there when you test
  on newer versions.
