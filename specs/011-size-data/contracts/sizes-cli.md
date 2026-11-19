# Contract: `docs/diagrams/sizes.py`

Python 3.11+, standard library only, always run as `python3 -I`. Not
shipped (it lives outside `.apm/`). Replaces `docs/diagrams/models.py`.

## Usage

```text
python3 -I docs/diagrams/sizes.py [--root DIR] [--check | --d2]
```

| Form      | Does                                                                                     | stdout                     | Exit |
| --------- | ---------------------------------------------------------------------------------------- | -------------------------- | ---- |
| (none)    | rewrites every marked region from the JSON; writes only changed files, nothing on error | `updated <path>` per file written | 0 or 2 |
| `--check` | compares every marked region with a fresh generation; writes nothing                     | nothing                    | 0, 1 or 2 |
| `--d2`    | prints the D2 source of `docs/img/models.svg` (reads only the JSON)                      | the D2 source              | 0 or 2 |

`--root DIR`: the tree holding `.apm/skills/feat/sizes.json` and the four
target files; default the repository the script sits in (two levels up).
Paths in messages are relative to it.

## Messages (stderr)

| Case                                   | Message                                                                                | Exit |
| -------------------------------------- | -------------------------------------------------------------------------------------- | ---- |
| drift (`--check`), one line per file   | `<path>: differs from .apm/skills/feat/sizes.json; run mise run diagrams`              | 1    |
| marker absent                          | `sizes.py: <path>: marker <name>: missing`                                             | 2    |
| one half only, or end before start     | `sizes.py: <path>: marker <name>: unpaired`                                            | 2    |
| a half twice or more                   | `sizes.py: <path>: marker <name>: duplicated`                                          | 2    |
| a name the file should not hold        | `sizes.py: <path>: marker <name>: unknown`                                             | 2    |
| agents table line, agent with no row   | `sizes.py: docs/workflow.md: agents table: <agent> has no row in sizes.json`           | 2    |
| row agent with no agents-table line    | `sizes.py: docs/workflow.md: agents table: no line for <agent>`                        | 2    |
| bad agents table (cells, headers)      | `sizes.py: docs/workflow.md: agents table: <what>`                                     | 2    |
| bad JSON or schema (FR-020: a `label` outside `[A-Za-z0-9 ,()`/-]+`; an `agent` or `loads` entry not matching `^[a-z0-9-]+$`; an unknown key at the top level, in a skill or in a row) | `sizes.py: .apm/skills/feat/sizes.json: <where>: <what>`, `<where>` the field's path (e.g. `feat.rows[3].label`) | 2    |

Every marker error is reported in both write and check modes, for every
file, before anything is written: a lost marker never passes the check.

## Where it runs

- `mise run diagrams`: `sizes.py` (write), then `d2` on `gates.d2` and
  `chain.d2`, then `sizes.py --d2 | d2 … - docs/img/models.svg`.
- `mise run lint`: `py_compile` and the Python 3.11 `ast` check on it, and
  `python3 -I docs/diagrams/sizes.py --check`.
- `mise run test:sizes` (`tests/sizes/run.sh`): every form against
  fixtures under `--root`.
