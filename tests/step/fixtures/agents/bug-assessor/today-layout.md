Mode: assess
Assessment: @TOP@/specs/x/assessment.md
Slug: ok
Verdict: valid
Is a bug: yes
Several bugs: no
Reasoning: plain off-by-one
Report author: OWNER
Title: Off-by-one on the last page
Symptom: the last item is missing
Root cause: < instead of <=
Confidence: high
Severity: medium
Files in scope: src/page.sh
Remediations: 1
Preferred remediation: use <=
Alternatives: none
Reproduction: reproduced
Reproduction detail: bash tests/page.sh
Would run: none
Public behaviour change: no
Risk area: none
Performance bug: no
Open questions: none
Proposed size: small — one line, high confidence, no risk area
Sections: ok
Skipped hooks: none
Wrote:
@TOP@/specs/x/assessment.md
@REPORT@
