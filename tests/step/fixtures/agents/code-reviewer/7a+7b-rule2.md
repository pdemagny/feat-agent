Bugs (7a):
- off-by-one on the last page — at: src/a.sh:3-5 — fix: use <= — confidence: medium — rec: apply
- the last page drops an item — at: src/a.sh:4 — fix: use <= — confidence: medium — rec: apply
- off-by-one in the count — at: src/a.sh:9 — fix: use <= — confidence: medium — rec: apply
Spec (7a): none
Standards (7a):
- judgement: Mysterious name — standard: smell baseline — at: src/a.sh:1 — fix: rename n to count — rec: skip (one-letter loop names are the house style)
Acceptance criteria (7a):
- AC-1 the last page holds the last item — met
Security (7b): none
Accepted design findings built (7b): none
Dismissed: none
Wrote:
- @REPORT@
