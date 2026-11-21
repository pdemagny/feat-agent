Bugs (7a):
- off-by-one on the last page — at: src/a.sh:3 — fix: use <= — confidence: high — rec: apply
Spec (7a): none
Standards (7a): none
Acceptance criteria (7a): none
Security (7b): none
Accepted design findings built (7b): none
Performance (7c):
- the page count is recomputed per item — at: src/a.sh:10-12 — fix: compute it once — unmeasured (no benchmark in the repo) — verify with: time bash src/a.sh — guard: none — rec: skip (lists stay short)
Dismissed: none
Wrote:
- @REPORT@
