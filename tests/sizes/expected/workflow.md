# Workflow

<!-- sizes-start feat-matrix -->

| #  | Phase           | Agent                  | small          | medium          | large           | huge                         |
| -- | --------------- | ---------------------- | -------------- | --------------- | --------------- | ---------------------------- |
| 1  | Brief           | your session           | session        | session         | session         | session, plus capability map |
| 1  | Brief review    | `feat-brief-reviewer`  | haiku · low    | haiku · low     | sonnet · high   | first capability's size      |
| 2  | Specify         | `feat-specifier`       | sonnet · low   | sonnet · medium | opus · high     | —                            |
| 3  | Plan            | `feat-planner`         | opus · xhigh   | opus · xhigh    | opus · max      | —                            |
| 4a | Security design | `feat-design-reviewer` | sonnet · low   | sonnet · medium | opus · medium   | —                            |
| 4b | Cost design     | `feat-design-reviewer` | sonnet · low   | haiku · high    | sonnet · high   | —                            |
| 5  | Tasks           | `feat-tasker`          | sonnet · low   | sonnet · low    | sonnet · medium | —                            |
| 6  | Implement       | `feat-implementer`     | haiku · high   | sonnet · high   | opus · high     | —                            |
| 7a | Correctness     | `feat-code-reviewer`   | sonnet · high  | sonnet · medium | opus · medium   | —                            |
| 7b | Security        | `feat-code-reviewer`   | opus · medium  | sonnet · medium | opus · high     | —                            |
| 8  | Ship            | `feat-shipper`         | haiku · medium | haiku · medium  | haiku · high    | —                            |

<!-- sizes-end feat-matrix -->

Between.

<!-- sizes-start fix-matrix -->

| #  | Phase                 | Agent                | small          | medium         | large         |
| -- | --------------------- | -------------------- | -------------- | -------------- | ------------- |
| 1  | Assess                | `feat-bug-assessor`  | opus · low     | opus · medium  | opus · high   |
| 2  | Fix                   | `feat-implementer`   | haiku · high   | sonnet · high  | opus · high   |
| 3  | Test                  | `feat-bug-assessor`  | sonnet · high  | sonnet · high  | sonnet · high |
| 4a | Correctness (lens 7a) | `feat-code-reviewer` | sonnet · high  | sonnet · low   | opus · medium |
| 4b | Security (lens 7b)    | `feat-code-reviewer` | opus · medium  | haiku · high   | sonnet · max  |
| 4c | Performance (lens 7c) | `feat-code-reviewer` | sonnet · high  | opus · low     | haiku · low   |
| 5  | Ship                  | `feat-shipper`       | haiku · medium | haiku · medium | haiku · high  |

<!-- sizes-end fix-matrix -->

## Agents

<!-- sizes-start agents-table -->

| Agent                  | Phase(s)    | small size                                            | Loads                |
| ---------------------- | ----------- | ----------------------------------------------------- | -------------------- |
| `feat-brief-reviewer`  | 1           | haiku · low                                           | —                    |
| `feat-bug-assessor`    | `/fix` 1, 3 | opus · low (assess), sonnet · high (test)             | `speckit-bug-assess` |
| `feat-specifier`       | 2           | sonnet · low                                          | `speckit-specify`    |
| `feat-planner`         | 3           | opus · xhigh                                          | `speckit-plan`       |
| `feat-design-reviewer` | 4           | sonnet · low                                          | per lens             |
| `feat-tasker`          | 5           | sonnet · low                                          | `speckit-tasks`      |
| `feat-implementer`     | 6           | haiku · high                                          | `speckit-implement`  |
| `feat-code-reviewer`   | 7           | sonnet · high (correctness), opus · medium (security) | per lens             |
| `feat-shipper`         | 8           | haiku · medium                                        | —                    |

<!-- sizes-end agents-table -->

Tail.
