---
name: merge-discipline
description: Use when a cycle's work is complete and ready to land - "merge", "open PR", "ship it", "we're done". Pre-merge invariant (completeness + correctness), override audit, manual smoke gate, handoff docs, then the branch action.
---

# Merge discipline

The end-of-cycle gate. Nothing lands until the artifact trail is complete, every verdict
is green (or explicitly overridden ON THE RECORD), a human has smoked the real app, and
the handoff docs exist.

## 1. Pre-merge invariant

**Completeness** — for every wave in plan.md: task.md has a section per task, review.md
has a review block per task, test_result.md has a wave section, changelog.md has a wave
section. Backfill any gap from accumulated payloads before proceeding; log
`phase.merge.invariant.backfill files=<list>` to flow.md.

**Correctness (HARD BLOCK)** — every wave's latest test verdict is PASS; every review's
overall verdict is APPROVE. Any failure blocks the gate → `@ask_user`: resume cycle at
that wave / force-merge (logs `merge.force.user_override waves=<list>`) / abort.

**Override audit** — read `@persist_state.wave_overrides` + scan flow.md for
`*.skip.user_override` events. Surface the count in the gate display; if > 0, the FIRST
branch-action option must be "Review override log" so the user reconsiders before merging.

On all clear: flow.md `phase.merge.invariant.passed`; `@persist_state.phase = merge`.

## 2. Manual smoke gate

Run the `coverage-to-smoke` skill, step 2: success criteria + coverage-GAP lines →
numbered checklist → `@ask_user` verification. Outcomes: passed (continue) / failed
(re-enter build loop as a correction — do NOT merge) / skipped-with-override (logged,
joins the override audit). On degraded tiers this prompt is the numbered-text fallback;
the gate itself never disappears.

## 3. Handoff docs

Run the `handoff-docs` skill → `reviewer_doc.md` + `qa_doc.md` in `@artifact_root`.
Offer to attach them to the PR body at the branch action.

## 4. Gate display + branch action

```
✅ Cycle complete — all tasks done.

Scope: <scope>
Tasks: N completed (M files changed)
Tests: <last summary>
Reviews: N task reviews, all four lenses
Coverage gaps: <count> (in smoke checklist + QA doc)
Overrides: <count>            ← only shown if > 0
Handoff: reviewer_doc.md + qa_doc.md written

What now?
```

`@ask_user` options, in order: (0, conditional) Review override log → print events,
return here · (1) New branch + push + open PR (offer handoff docs as PR body) ·
(2) New branch, local only · (3) Merge into existing branch · (4) Rebase onto existing
branch · (5) Keep open — decide later (`phase = merge:deferred`) · (6) Discard.

## 5. Commit format

Subject `[<scope>] <type>(<wave_id>): <subject>` (≤50 chars); body lists task IDs +
titles; trailer `cycle: <cycle_id>`. Type from spec intent via config `type_map`; forced
`fix` for debug cycles, which also add body lines: `Root cause: <one line>` /
`Affected: <files>` / `Repro test: <path>`.

## 6. Close out

flow.md `cycle.end status=<success|aborted> action=<...>`; clear `@persist_state`
(except `merge:deferred`, which keeps state so `continue` re-enters this gate
idempotently — recheck invariants briefly on re-entry).

## Forbidden patterns

- ❌ Merging with a FAIL verdict or REQUEST_CHANGES review absent an explicit, logged
  user override.
- ❌ Skipping the smoke gate silently — only `@ask_user` override skips it, and it's
  logged.
- ❌ Shipping without reviewer_doc.md + qa_doc.md.
- ❌ Hiding overrides from the gate display.
