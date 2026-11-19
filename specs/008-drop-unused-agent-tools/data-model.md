# Data model: Drop unused tools from the feat-* agents' starting context

No data is stored. The "entities" are the agent files' frontmatter and the
hook entries `/feat` setup classifies.

## Agent file (`.apm/agents/<name>.agent.md`)

Frontmatter fields touched: `disallowedTools` (one line, comma-separated).
`skills:` is unchanged. No `model`, `effort`, `tools` or `color` (FR-010).

| Agent                  | `disallowedTools` today          | after                                                   | keeps `Skill` because                              |
| ---------------------- | -------------------------------- | ------------------------------------------------------- | -------------------------------------------------- |
| `feat-brief-reviewer`  | Edit, Write, NotebookEdit, Agent | Edit, Write, NotebookEdit, Agent, Artifact, EnterWorktree, Skill | —                                          |
| `feat-bug-assessor`    | Edit, NotebookEdit, Agent        | Edit, NotebookEdit, Agent, Artifact, EnterWorktree      | loads `speckit-bug-assess` / `speckit-bug-test`    |
| `feat-specifier`       | NotebookEdit, Agent              | NotebookEdit, Agent, Artifact, EnterWorktree, Skill     | —                                                  |
| `feat-planner`         | NotebookEdit, Agent              | NotebookEdit, Agent, Artifact, EnterWorktree, Skill     | —                                                  |
| `feat-design-reviewer` | Edit, Write, NotebookEdit, Agent | Edit, Write, NotebookEdit, Agent, Artifact, EnterWorktree | loads lens skills (`security-and-hardening`)     |
| `feat-tasker`          | NotebookEdit, Agent              | NotebookEdit, Agent, Artifact, EnterWorktree, Skill     | —                                                  |
| `feat-implementer`     | Agent                            | Agent, Artifact, EnterWorktree                          | loads `speckit-bug-fix` in bug mode, runs implement hooks |
| `feat-code-reviewer`   | Edit, Write, NotebookEdit, Agent | Edit, Write, NotebookEdit, Agent, Artifact, EnterWorktree | loads lens skills                                |
| `feat-shipper`         | NotebookEdit, Agent              | NotebookEdit, Agent, Artifact, EnterWorktree, Skill     | —                                                  |

Validation: every row contains `Artifact` and `EnterWorktree` (lint,
FR-008); exactly the five rows with `Skill` (FR-002, read by review and
by quickstart scenario 1). `docs/workflow.md`'s "Denied tools" column is
this "after" column.

## Spec Kit hook entry (`.specify/extensions.yml`)

Read as configuration by `/feat` setup step 4, never executed there.

- `key`: `before_<phase>` / `after_<phase>`.
- `extension`, `command` (dotted, e.g. `speckit.git.commit`),
  `enabled` (absent = true), `optional`, `condition`.

Classification at setup (enabled entries only):

| key phase                                | class                       | outcome                                                           |
| ---------------------------------------- | --------------------------- | ----------------------------------------------------------------- |
| `specify`, `plan`, `tasks`, `analyze`    | **will not run**            | named in the gate with `/<command, dots → hyphens>` (no `command`: extension only); skipped |
| `implement`, branches or commits (git)   | **skipped unless allowed**  | named in the same gate; skipped unless the user allows it         |
| `implement`, other                       | **allowed**                 | no gate on its own; recorded as allowed in the state file         |
| any other key                            | unchanged                   | not named (no `/feat` agent runs those skills)                    |

The gate is hard iff at least one entry is in the first two classes
(on `rebase`: the second class only). The state file's `Allowed Spec Kit
hooks:` line lists the allowed `implement` hooks (plus any the user
allowed at the gate), or `none`.
