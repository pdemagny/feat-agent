Performance (7c):
- the page count is recomputed per item — at: src/a.sh:10-12 — fix: compute it once — measured: bash bench.sh, 120 ms — verify with: bash bench.sh — guard: none — rec: apply
Cuts (7d):
- delete: the paging helper nobody calls — at: src/a.sh:8-14 — fix: nothing — rec: apply
net: -7 lines possible
Readability (7e):
- rename p to page — at: src/a.sh:11 — fix: rename it — why: says what it holds — rec: apply
Dismissed: none
Wrote:
- @REPORT@
