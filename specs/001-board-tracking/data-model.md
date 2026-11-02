# Data model: Board tracking

Nothing is stored by the script; it reads the config and the board on every
call and prints one line. The shapes are defined once, elsewhere:

- Tracker config (`.feat-agent.yml`): FR-002–FR-004, FR-019;
  [contracts/feat-agent-yml.md](contracts/feat-agent-yml.md).
- Issue reference and current repo: FR-015, FR-029;
  [contracts/tracker-cli.md](contracts/tracker-cli.md#common-behaviour).
- Created issue: FR-011, FR-031, FR-033; `create-issue` in
  [contracts/tracker-cli.md](contracts/tracker-cli.md).
- Board lookup (`B`/`O`/`I` lines): FR-004, FR-028;
  [contracts/tracker-cli.md](contracts/tracker-cli.md#filter-output-tab-separated-first-column-a-tag).
- Moves and their moments: FR-010, FR-012–FR-014; the moments table in
  `docs/workflow.md`.
- Move failure record (`[!]` Log lines): FR-017, FR-032; plan.md's `/feat`
  section.
