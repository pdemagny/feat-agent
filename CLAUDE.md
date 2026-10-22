# feat-agents

Two Claude Code skills (`skills/feat-brief/SKILL.md` writes the brief,
`skills/feat/SKILL.md` coordinates the build) and the phase subagents
(`agents/feat-*.md`), distributed on their own. See README.md.

When changing it:
- The size table in `skills/feat/SKILL.md` is the source of truth for model
  and effort, and its `Loads` column lists what each row's agent reads.
  Mirror every change in `docs/workflow.md` (matrix and agents table) and
  keep the agent frontmatter equal to the `small` column. Phase 7 reviewer
  groups live under the table and in `REVIEW_GROUPS` in a cost script (since moved out).
- Adding or removing a third-party skill: update `deps` in `install.sh`, the
  table in `docs/install.md`, and the agent's `skills:` (or the lens in
  `feat-code-reviewer.md`) and the size table's `Loads` column.
- Agent prompts end with a fixed report format; the orchestrator depends on
  it. Change both sides together. `/feat` stays thin: it never reads code
  or edits artifacts; new work goes into an agent, not the coordinator.
- Shell: `shellcheck install.sh` must stay clean.
- a cost script (since moved out) parses SKILL.md's size table (`| <N><a-e> <name> |
  \`feat-x\` | <loads> | model · effort | …`); keep that format or update the
  parser. Run a cost script (since moved out) on a real run
  after changing models, agents or dependencies, and record notable results
  in the cost notes (since moved out). Keep `PRICES` current.
- Record user-visible changes in CHANGELOG.md.
