# /feat state: soft spec gate, with the spec summary at the design gate

- Branch: soft-spec-gate Worktree: /home/pierre/Projects/feat-agent/.claude/worktrees/brief-soft-spec-gate
- Size: small
- Agents: specifier a4217177ddc56e5b2, planner a628add7bf414985e, tasker afead892a875aae98 (for SendMessage)
- Current phase: 8 Ship
- Conventions: conventional commits `type(scope): msg`, one logical change per commit, no co-author; only the shipper commits (phase 8). `feat` subjects become CHANGELOG entries (write for users); never edit CHANGELOG.md, version lines or `.release-please-manifest.json`. Size tables in `.apm/skills/feat/SKILL.md` / `.apm/skills/fix/SKILL.md` are the source of truth; mirror gate/size changes in `docs/workflow.md`. `.apm/skills/feat/references/harness.md` holds shared /feat+/fix rules, no /feat-only words (`mise run lint` greps it). `/feat` stays thin (never reads code, never edits artifacts). Agent prompts end with a fixed report format the orchestrator depends on. Checks: `mise run lint` and `mise run test:apm`. Never name the user's private project anywhere. Shell zsh; `rm/cp/mv` are `-i` aliases: use `command rm -f` etc. The branch carries a pushed brief commit (629d4d9, adds specs/briefs/soft-spec-gate.md); drop it when shipping.
- Allowed Spec Kit hooks: none (no hooks enabled)
- Map: none
- Issue: #6

## Brief

# Brief: soft spec gate, with the spec summary at the design gate
- Size: small — ~12 tasks expected: gate rules in one skill, the planner's amend mode, and three docs; no new agent, service or dependency
- Short name: soft-spec-gate
- Issue: #6

## Why
The spec gate (phase 2 of `/feat`) always stops, but it is mostly a formality for the user. Across 75 `/feat` runs on a private project, the spec was approved as written ("ok") in about 54; most of the others were answers to open clarification markers or to the specifier's assumptions, and only a handful changed the spec. The plan and design review gate (phases 3 and 4), soft on paper for small and medium, stopped in about 72 of the 75, because the reviewers nearly always report findings. So the user stops at the spec for nothing, then stops again a few minutes later, and learns to approve without reading.

## Today
Phase 2 is a hard gate at every size: stories and requirements, open `[NEEDS CLARIFICATION]` markers with recommended answers, the specifier's assumptions and unchecked checklist items, and it is "the only place questions are asked". Answers and edits go to `feat-specifier` in amend mode. The plan and design review gate (one gate for phases 3 and 4 on small and medium; separate hard gates for 3 and 4 on large) shows the 4c paraphrase, the approach, assumptions and findings.

## Behaviour
- Phase 2 is hard only when the spec has open `[NEEDS CLARIFICATION]` markers, when the specifier reports a blocker, or on a size increase (the existing rule for any phase). The same rule applies at every size, large included.
- Otherwise phase 2 is soft: a one-line report, and the run goes on to the plan. The spec summary, the specifier's assumptions with their recommendations and the unchecked checklist items are written into the state file's Log, so the next gate can show them, including after `/feat resume`.
- When phase 2 was soft, the next gate opens with the spec summary: stories and requirements in a few lines, the specifier's assumptions with their recommendations, and the unchecked checklist items with the question whether to proceed. That gate is the plan and design review gate on small and medium, and the phase 3 plan gate on large. When phase 2 was hard, that gate is as today.
- The specifier's assumptions and the checklist question move with the summary: their answers are given at that gate, and "ok" accepts the recommendations.
- After a soft phase 2, unchecked checklist items make the plan and design review gate hard: they are a question for the user, answered before tasks.
- When phase 2 was soft and the plan and design review gate would be soft too (no finding needs the user, no unchecked checklist item), the run reports the spec summary in the soft gate's report and continues; the specifier's assumptions are accepted at their recommendations and logged.
- A spec change asked at that gate (an assumption overturned, a requirement reworded) goes to `feat-planner` in the same amend pass as the accepted findings, which writes it into spec.md and plan.md. On large, a spec change asked at the phase 3 gate goes to `feat-planner` in amend mode right away, and the design reviewers then read the updated spec and plan. A change big enough to rewrite stories is "back to 2", which works at any gate already.
- The state file logs whether phase 2 was soft or hard, so the next gate (and `/feat resume`) knows to show the summary.

## Out of scope
- `/fix`: it has no spec gate.
- Changing when the plan and design review gate is hard.
- The workflow diagrams in the README and docs (updated separately after this ships).

## Alternatives rejected
- Never stop at phase 2, even with open markers, and carry the recommended answers to the design gate — the planner and up to three design reviewers would build on an answer the user may reject, and overturning it means re-planning and reviewing again.
- Keep the spec gate always hard for large features — phase 3 is already a hard gate right after it, so the summary can open that gate; one rule for every size is simpler.
- Make the design gate hard whenever phase 2 was soft, so the user always sees the spec before tasks — if the specifier found nothing to ask and the reviewers found nothing to flag, the spec is probably fine; the user still sees it in the soft report and the PR.
- Send spec changes asked at the design gate to `feat-specifier`, then the planner — an extra spawn (~36k tokens before any work), and the planner has to follow anyway.

## Acceptance
- A spec with no open markers goes from phase 2 to the plan without stopping, with a one-line report and a Log line saying the gate was soft.
- A spec with open markers stops at phase 2 as today, and the next gate is as today.
- After a soft phase 2, the plan and design review gate (small, medium) or the phase 3 gate (large) shows the spec summary, the assumptions and the checklist question before the paraphrase and the findings.
- After a soft phase 2 and a soft design gate, the soft report contains the spec summary, the assumptions are logged as accepted, and the run continues.
- After a soft phase 2 with unchecked checklist items, the plan and design review gate is hard and asks whether to proceed.
- A spec with open markers or a specifier blocker stops at phase 2.
- A spec change asked at the design gate reaches `feat-planner` with the accepted findings, and is written into spec.md; on large, one asked at the phase 3 gate reaches `feat-planner` before the design review.
- `/feat resume` after a soft phase 2 shows the spec summary at the next gate, from the state file.
- The phases-and-gates table and sections 2–4 of `.apm/skills/feat/SKILL.md`, `docs/workflow.md` (phases at a glance, the "Hard gates" row, phase details), `docs/usage.md`, the `speckit-implement` row of `docs/design.md` (which says the checklist is asked at the phase 2 gate), and the README's sentence on gates say the same thing.
- `mise run lint` and `mise run test:apm` pass.

## Constraints / decisions already made
- `/feat` stays thin: it never reads code or edits artifacts; the spec summary comes from the specifier's report, as today, and is kept in the state file for the next gate.
- `feat-planner`'s amend mode already covers "the user's edits at a gate" and writes into spec.md and plan.md: its prompt needs at most one phrase naming spec changes alongside findings, and its report format stays as it is.
- Shared rules in `.apm/skills/feat/references/harness.md` stay free of `/feat`-only words (`mise run lint` greps it); the size-increase rule there already applies to phase 2.
- CHANGELOG.md is generated from commit subjects: write the `feat` subject for users.

## Log

- [x] 0 Setup — no Spec Kit hooks; board users/pdemagny/projects/2; #6 set to "In progress"; branch renamed worktree-brief-soft-spec-gate → soft-spec-gate
- [x] 2 Specify — hard gate (current rules); approved as written; assumptions 1–5 accepted (user: "ok"). spec.md: 7 stories, FR-001–FR-018, no markers, checklist all checked
- [x] 3 Plan — plan.md + research/data-model/contracts/gates.md/quickstart; touches feat SKILL.md (artifact owners, table rows 2–4, sections 2–5), feat-planner amend clause, docs/workflow.md, usage.md, design.md, README gate sentence; no deps, constitution pass, no blocker/size trigger; 8 assumptions all needs user: no (soft/hard as word on phase 2 Log line + summary sub-bullets; blocker = no spec written or brief unspecifiable; artifact owners lists spec changes at plan/design gate under planner; large: phase 4 starts right after the amend)
- [x] 4 Design review — hard gate (3+4); accepted D1(a) drop size increase from phase 2 rule (size caught at 3 and 5; "anything surprising" covers specifier remarks), D2 testable blocker, D3 latest phase 2 line decides, D4 summary gate Log line records assumptions+checklist fate, D5 multiline greps in quickstart Q3/Q4, D6 large phase 4 notes plan amended, D7 note under Hard gates row, D8 single planner clause; planner assumptions accepted as recommended (user: "ok")
- [x] 4 Design review amend (planner) — D1–D8 written (spec FR-019 blocker test, FR-020 latest phase 2 line, FR-021 gate Log line records assumptions/checklist, FR-022 large amended-plan note; quickstart Q3/Q4 multiline, Q4b, Q6b, L6); D7 note placed under "Phases at a glance"; summary gate closes on its own [x] line (4 on small/medium, 3 on large); no blocker/size trigger
- [x] 5 Tasks — soft; 22 tasks (small fits ≤30; plan est. ~12, split per story); US1 T001–T003 (T001 setup), US2 T004, US3 T005–T008, US4 T009, US5 T010–T013, US6 T014, US7 T015–T018 + polish T019–T022 (T021 lint+test:apm); 1 MEDIUM fixed by tasker (T014 target); no open findings; no unchecked checklist items
- [x] 6 Implement — US1 (T001–T003): SKILL.md table row 2 + section 2 Gate/Hard/Soft; lint, test:apm pass
- [x] 6 Implement — US2 (T004): section 2 blocker test, size remark = surprising, hard Log line, latest phase 2 line decides; lint, test:apm pass
- [x] 6 Implement — US3 (T005–T008): table rows 3–4, sections 3/4 spec block + checklist hard trigger + Log-line sentence + large amended-plan note, section 5 wording; lint, test:apm pass; section 4 Log sentence split (tidy in US4); table rows wider than padding (cosmetic)
- [x] 6 Implement — US4 (T009): section 4 soft+soft case; section 4 Log sentence made verbatim; lint, test:apm pass
- [x] 6 Implement — US5 (T010–T013): planner amend clause (report unchanged), artifact owners, sections 3/4 spec-change routing; lint, test:apm pass
- [x] 6 Implement — US6 (T014): resume paragraph end of section 2, *Resume search* points to it; lint, test:apm pass
- [x] 6 Implement — US7 + polish (T015–T022): docs/workflow.md, usage.md, design.md, README gate sentence; SKILL.md table re-padded; Q3/Q4/Q4b/Q1/Q6/Q7 pass; lint, test:apm pass; private-name grep 0; soft gate
- [x] 7 Code review — #6 set to "In review"; diff base a31d5b0 (release 0.9.0; local main is stale), `git diff a31d5b0`, 15 files; 7c+7d+7e reported: P1 table padding, C1–C9 (~-21 lines), R1–R8 (R9 keep); 7a+7b: B1 workflow.md:37 'first stop is 3/4 gate' false when 3/4 soft (FR-009), note: multi-line soft Log entry untested at runtime; no sec, no spec gaps, no hard std; std judgement = rewraps (folded into R6/R7). Picked (user: "ok"): B1, C1–C4, C6, C7 partial (keep soft-report-carries-summary), C8, P1, R1–R8; rejected C5 (keeps the 'later phases don't stop to ask' principle), C9 (planner clause is the exact D8 sentence the user approved; rewrap only). Fixes applied: all picked; P1 table width 250 → 200 (= a31d5b0); size table verified unchanged; lint, test:apm, Q checks, private-name grep pass. Note: FR-021 says the Log-line sentence verbatim in §3 and §4; C2 states it once in §2 Soft covering both (mention in PR).
- [ ] 8 Ship
