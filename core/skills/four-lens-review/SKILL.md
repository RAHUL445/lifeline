---
name: four-lens-review
description: Use when reviewing code - "review this", after implementation, before merge. ONE review per task, ALWAYS all four lenses (logic, architecture, security, performance), with depth scaled to the task's effort label. Returns structured REVIEW_FINDINGS.
---

# Four-lens review

Exactly **one review per task**. It always walks **all four lenses**; what scales with
the task is **depth**, never lens coverage. There is no combined-vs-specialized choice
to make. Delegable role: **reviewer** — `@dispatch_agent` on FULL tier, inline otherwise.

## Depth from effort

| Task effort | Depth | Behavior |
|---|---|---|
| trivial, small | light | One pass per lens over the diff. APPROVE quickly if sound — don't manufacture findings. |
| medium | standard | Apply each lens checklist to the diff; read surrounding context where the diff touches it. |
| large | deep | Checklists + read changed files whole; trace data flow across the diff boundary; question the design, not just the lines. |

## The four lenses

### 1. Logic (bug sleuth)
Boundaries (0, -1, len, len+1, empty, max) · null/None/undefined handling · concurrency
(race, deadlock, unbounded queue) · time/TZ/DST/epoch · type coercion · resource leaks ·
off-by-one (`<` vs `<=`) · idempotency/retry/cancellation · error paths (swallowed
exceptions) · branch coverage of new tests.

### 2. Architecture (guardian)
Layer-boundary violations · premature or missing abstractions · coupling · cohesion ·
drift from existing patterns · state management (global/singleton/shared mutable) ·
API surface (minimal vs leaking).

### 3. Security (gatekeeper)
Secrets in the diff · injection (SQL, shell, eval) · authn/authz checks · sensitive data
exposure/PII in logs · XXE/SSRF/path traversal · access control/IDOR · unsafe
deserialization · new deps with known CVE patterns.

### 4. Performance (optimizer)
Avoidable O(n²) · DB N+1, missing index, unbounded result sets · sequential network I/O,
missing timeouts · memory (full-collection loads, leaks) · hot-path allocations · locks
held across I/O · blocking calls in async context.

## Inputs

The diff (inline — do not re-fetch), the task's plan row, the relevant spec requirements,
and the code root for context reads. On FULL tier with worktree isolation, ALL context
reads use worktree-prefixed absolute paths — main-repo code is stale and yields
false positives.

## Output

Return ONLY the `REVIEW_FINDINGS` JSON (`core/contracts/REVIEW_FINDINGS.md`).
The orchestrator writes review.md.

Per-lens blocking severities: logic{blocker, major} · architecture{blocker} ·
security{critical, high} · performance{critical}. Overall = REQUEST_CHANGES if any lens
blocks.

## On REQUEST_CHANGES (orchestrator side)

Consolidate blocking findings, re-dispatch the implementer with them inline, re-run
tests for the wave, then re-run THIS review (same single-review, four-lens shape).
Repeat until APPROVE or `retry_cap`; at the cap, `@ask_user`: retry once more / skip
with override (logged to flow.md + override audit) / abort.

## Rules

- Findings terse — one line each: severity, file:line, issue, fix.
- A lens with nothing applicable emits empty findings + APPROVE; it never gets skipped.
- Never write files. JSON return only.
