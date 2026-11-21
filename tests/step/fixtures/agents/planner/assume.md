Plan: @TOP@/specs/x/plan.md (+ research.md)
Approach: one script; tests beside it.
Touches:
- scripts/step.sh
New dependencies or services: none
Constitution check: violations
- V. Standard library only — a parser needs a module
Assumptions:
- tabs never in paths — why: call lines — recommendation: refuse them — needs user: no
- one retry — why: cost — recommendation: one — needs user: yes
- bash 3.2 — why: macOS — recommendation: keep — needs user: no
- no jq — why: install — recommendation: keep — needs user: yes
Blockers: none
Size trigger: service — a new daemon
Skipped hooks: none
Wrote:
- @TOP@/specs/x/plan.md
- @REPORT@
