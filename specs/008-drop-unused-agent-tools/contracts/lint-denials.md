# Contract: the agent-denials lint check

A line of `mise.toml`'s `[tasks.lint] run` list (FR-008).

- **Input**: every `.apm/agents/*.agent.md`; the first line starting with
  `disallowedTools:`; its value split on commas and spaces.
- **Pass**: each file's tokens include exactly `Artifact` and
  `EnterWorktree` (case-sensitive, whole token: `ArtifactComments` does
  not count). Prints nothing.
- **Fail**: one line per missing pair, then a non-zero exit, which fails
  `mise run lint`:

  ```text
  .apm/agents/feat-shipper.agent.md: disallowedTools lacks Artifact
  ```

  A file with no `disallowedTools:` line fails for both tools.
- **Portability**: POSIX `sh`, `awk`/`grep -E`/`tr`; no GNU-only escapes
  (`\b`), so it runs the same on macOS and in CI.
- The task's `description` names the check.
