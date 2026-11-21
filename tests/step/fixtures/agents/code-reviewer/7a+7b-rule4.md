Bugs (7a):
- the cursor never resets — at: src/a.sh:12 — fix: reset it per page — confidence: high — rec: skip (rare in practice)
- an empty list crashes — at: src/a.sh:20 — fix: return early — confidence: high — rec: skip
- a slow path on huge lists — at: src/a.sh:30 — fix: cache the length — confidence: medium — rec: skip (no such lists)
Spec (7a): none
Standards (7a): none
Acceptance criteria (7a): none
Security (7b): none
Accepted design findings built (7b): none
Dismissed: none
Wrote:
- @REPORT@
