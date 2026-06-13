# Contract: RCA_RESULT

Returned by the **investigator** role (skill: `systematic-debugging`, phase 2 — strictly
read-only). The orchestrator parses it and writes the `bug.md` RCA section.

## Payload

```
RCA_RESULT:
- root_cause: |
    <one paragraph — the actual defect, its mechanism, why the test fails>
- affected_files:
  - <path relative to code root>
- effort_estimate: trivial | small | medium | large
- scope: single-task | multi-task
- fix_approach: |
    <one paragraph — WHAT changes, at what layer, with what behavior contract. No code.>
- risks: |
    <regressions to test for, related code paths that may also be wrong>
- related_findings: |
    <issues noticed during investigation that are NOT in scope of this fix>
- suspect_commit: <sha if blame points clearly, else "unclear">
- test_gap_notes: <why existing tests didn't catch this, if applicable>
```

## Rules

- Investigation is read-only — no file modifications, no artifact writes.
- `scope: single-task` if effort ∈ {trivial, small}; `multi-task` if effort ∈
  {medium, large} OR the same bug pattern appears in ≥3 files.
- Describe the fix behaviorally, never as code — the implementer produces the code.
- If the root cause is genuinely unclear after a focused investigation, return
  `root_cause: "unclear — see notes"` rather than guessing. Honesty > false confidence.
- No fix is dispatched until the user confirms the RCA at the post-RCA gate.
