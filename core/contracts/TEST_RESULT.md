# Contract: TEST_RESULT

Returned by the **test-runner** role, one per wave per attempt. The orchestrator parses
it and appends a wave section to `test_result.md` plus updates the verdict summary table.

## Payload

```
TEST_RESULT:
- wave_id: <id>
- attempt: <n>/<cap>
- started: <ISO>
- command: <exact command>
- framework: <pytest|go|phpunit|npm|cargo>
- exit_code: <n>
- summary: "X passed, Y failed, Z skipped"
- failures:
  - test_id: <test::name or file::line>
    affected_task: <task_id | unknown>
    cause: <one-line failure>
    classification: code-bug | test-bug | flake | env
    excerpt: |
      <relevant lines, max 30>
- verdict: PASS | FAIL
- coverage:
    enabled: true|false        # false if tooling absent — degraded, not a failure
  - file: <changed source file>
    pct: <0-100>
    uncovered_lines: "<ranges, e.g. 41-58>"
    verdict: OK | GAP          # GAP if pct < min_changed_file_pct OR (pct==0 AND fail_on_zero)
- coverage_verdict: OK | GAP
- notes: <env hints, slow tests, anything the orchestrator should know>
```

## Failure classification

- `code-bug` — implementation wrong (most common). Re-dispatch implementer with failure
  summary, then re-run the whole wave.
- `test-bug` — test asserts the wrong thing. Same retry path as code-bug.
- `flake` — intermittent. Test-runner retries internally (max 2) before reporting; if it
  still surfaces, treat as code-bug.
- `env` — dependency/setup issue. Surface to the user IMMEDIATELY via `@ask_user`
  (fix env / skip with override / abort). Never silently skip.

## Coverage rules (the coverage→smoke mechanism)

- Coverage pass runs only when `coverage_check.enabled` and scoped to **changed source
  files only** (from the wave's TASK_UPDATE `files_changed`), never the whole repo.
- Defaults: `min_changed_file_pct: 70`, `fail_on_zero: true`, `scope: changed_files_only`.
- A coverage GAP is **advisory** — it does NOT fail the wave. Tests passing = wave passes.
  GAP lines flow to the merge smoke checklist and the QA_DOC (see `coverage-to-smoke`).
- If coverage tooling is absent or errors: `coverage.enabled: false`, note it, continue.
- **Stated limitation:** line coverage catches *unexecuted* code, not *over-mocking* —
  a line exercised against a mock reads as covered. The manual smoke gate backstops that
  residual; the two layers are complementary.
