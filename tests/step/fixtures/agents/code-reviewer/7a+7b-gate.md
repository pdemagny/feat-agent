Bugs (7a):
- off-by-one on the last page — at: src/a.sh:3 — fix: use <= — confidence: high — rec: apply
Spec (7a):
- scope creep: a --verbose flag — spec: "FR-001 prints the page" — at: src/a.sh:40-44 — fix: drop the flag — rec: user (the user may want it)
Standards (7a): none
Acceptance criteria (7a):
- AC-1 the last page holds the last item — not met (it drops it)
- AC-2 an empty list prints nothing — untested
Security (7b): none
Accepted design findings built (7b): none
Dismissed: none
Wrote:
- @REPORT@
