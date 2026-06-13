# Contract: SPEC_SUMMARY

Returned by the **spec-writer** role (skill: `spec-discipline`) after filling `spec.md`.
The orchestrator uses `open_questions` to drive resolution via `@ask_user` before the
spec approval gate, then updates spec.md frontmatter `status` post-gate.

## Payload

```
SPEC_SUMMARY:
- goal: <one sentence>
- functional_req_count: <N>
- open_questions_count: <M>
- open_questions:
  - <Q1>
  - <Q2>
```

## Rules

- The role writes `spec.md` directly (the one direct-write exception; all other roles
  return payloads only). The summary mirrors, never replaces, the file.
- Do NOT collapse unresolved opens by guessing — preserve them in spec.md's
  "Open questions" section AND list them here so the orchestrator surfaces each for
  resolution before the plan phase.
- Functional requirements are atomic and testable — one assertion per bullet.
