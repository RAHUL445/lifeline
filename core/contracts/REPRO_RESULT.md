# Contract: REPRO_RESULT

Returned by the **reproducer** role (skill: `systematic-debugging`, phase 1). The
orchestrator parses it and writes the `bug.md` Description + Reproduction sections —
the role never writes artifacts.

## Payload

```
REPRO_RESULT:
- bug_summary: <one-line>
- test_path: <path relative to code root>
- test_id: <pytest::name | go::TestName | etc.>
- command: <exact shell command to run just this test>
- failure_excerpt: |
    <stderr / traceback, ≤30 lines>
- expected_behavior: <one line — what the test asserts>
- actual_behavior: <one line — what the code does instead>
- mode_used: from-description | from-existing-test | both
- notes: <reasoning, edge cases considered, limitations>
```

## Rules

- The role modifies TEST FILES ONLY — never production code, never artifacts.
- The test must be deterministic: no timing flakes, no unseeded random data.
- The orchestrator verifies the repro by running `command` itself and confirming a
  non-zero exit before the post-repro gate. A passing test means the bug was not
  captured — refine or abort, never proceed.
