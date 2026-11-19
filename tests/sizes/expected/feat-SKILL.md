# feat

Before.

<!-- sizes-start feat-table -->

| Phase              | Agent                  | Loads                          | small          | medium          | large           |
| ------------------ | ---------------------- | ------------------------------ | -------------- | --------------- | --------------- |
| 1 Brief review     | `feat-brief-reviewer`  | —                              | haiku · low    | haiku · low     | sonnet · high   |
| 2 Specify          | `feat-specifier`       | speckit-specify                | sonnet · low   | sonnet · medium | opus · high     |
| 3 Plan             | `feat-planner`         | speckit-plan                   | opus · xhigh   | opus · xhigh    | opus · max      |
| 4a Security design | `feat-design-reviewer` | security-and-hardening         | sonnet · low   | sonnet · medium | opus · medium   |
| 4b Cost design     | `feat-design-reviewer` | —                              | sonnet · low   | haiku · high    | sonnet · high   |
| 5 Tasks            | `feat-tasker`          | speckit-tasks, speckit-analyze | sonnet · low   | sonnet · low    | sonnet · medium |
| 6 Implement        | `feat-implementer`     | speckit-implement              | haiku · high   | sonnet · high   | opus · high     |
| 7a Correctness     | `feat-code-reviewer`   | —                              | sonnet · high  | sonnet · medium | opus · medium   |
| 7b Security        | `feat-code-reviewer`   | security-and-hardening         | opus · medium  | sonnet · medium | opus · high     |
| 8 Ship             | `feat-shipper`         | —                              | haiku · medium | haiku · medium  | haiku · high    |

<!-- sizes-end feat-table -->

After.
