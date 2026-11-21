Mode: assess
Assessment: @TOP@/specs/x/assessment.md
Slug: ok
Verdict: valid
Is a bug: yes
Several bugs: no
Reasoning: a token reaches the log
Report author: OWNER
Title: Token logged
Symptom: the token shows in the log
Root cause: a debug line
Confidence: medium
Severity: high
Files in scope: src/auth.sh
Remediations: 2
Preferred remediation: drop the line
Alternatives: mask it
Reproduction: not reproduced
Reproduction detail: no credentials here
Would run: none
Public behaviour change: no
Risk area: security, data
Performance bug: yes
Open questions:
- keep the debug flag? — recommended: no
Proposed size: medium — security
Sections: ok
Skipped hooks: none
Wrote:
- @TOP@/specs/x/assessment.md
- @REPORT@
