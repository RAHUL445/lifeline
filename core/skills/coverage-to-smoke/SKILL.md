---
name: coverage-to-smoke
description: Use when tests pass and you're about to merge, when asked "are we sure this works", "did we test everything", "is this covered", or before opening a PR. Turns per-changed-file coverage gaps into a human smoke checklist so untested paths get exercised before merge. Pure methodology — no harness capabilities required.
---

# Coverage → smoke

Automated tests can pass while the real app is broken: mocked internals, no end-to-end
roundtrip, a save handler that no test ever executes. This skill closes that class of
failure by converting coverage gaps on **changed files** into a checklist a human must
exercise before merge.

Zero capability dependencies — runs identically on every harness.

## Step 1 — coverage pass at test time

After the suite passes for a wave, re-run it with coverage, scoped to the **changed source
files only** (never the whole repo).

**Use the user's command first.** Read the `test:` list from `.lifelinerc` (an ordered
`match`/`cmd`/`coverage` list — see `detecting-project-tooling` and `core/config/defaults.yaml`).
Group the wave's changed files by their first-matching `test:` entry (a path-prefix `match`
like `services/api/**` is per-package; first match wins). For each group, run that entry's
`coverage` command **in the package's directory**, substituting `{module}` with the changed
module/path where the framework needs it. A monorepo therefore produces several coverage
runs — one per touched package — whose results merge into the single `TEST_RESULT` coverage
block. Lifeline never picks a framework when the user has configured one.

**Fallback only when no `test:` entry matches** a changed file — infer from the framework:

| Framework | Coverage command |
|---|---|
| pytest | `pytest --cov=<changed modules> --cov-report=term-missing` |
| go | `go test -coverprofile=/tmp/ll-cov ./...` then `go tool cover -func=/tmp/ll-cov` |
| phpunit | `phpunit --coverage-text` |
| jest/npm | `npm test -- --coverage` |
| cargo | `cargo tarpaulin` (heavy; skip if absent) |

For each changed source file record `pct` + `uncovered_lines`, and a verdict:

- `GAP` if `pct < coverage_check.min_changed_file_pct` (default 70), OR
  `pct == 0` and `coverage_check.fail_on_zero` (default true)
- else `OK`

Emit these inside the `TEST_RESULT` payload's coverage block (see
`core/contracts/TEST_RESULT.md`). If coverage tooling is absent or errors, set
`coverage.enabled: false`, note it, and continue — **never block on coverage**.

## Step 2 — seed the smoke checklist at merge

When merge-discipline reaches the manual smoke gate:

1. Source the cycle's success criteria (spec.md `Success Criteria`, or bug.md expected
   behavior for a debug cycle) as one-line, user-verifiable checks.
2. Scan the latest `test_result.md` for any `verdict: GAP` (and `coverage_verdict: GAP`).
   For each gapped file, **prepend** a checklist line:

   ```
   ⚠ <file> — <pct>% coverage, lines <ranges> untested. Manually exercise this path.
   ```

3. Display the combined checklist under `🔍 Manual smoke — verify before merge:`,
   numbered, each with the concrete action to perform and the run command if known.
4. Prompt via `@ask_user`: `Did you manually verify the above against the running app?`
   - **All verified** → flow.md `phase.merge.smoke.passed verified=<N>`, continue.
   - **Some failed** → flow.md `phase.merge.smoke.failed criterion="<text>"`; re-enter the
     build loop as a correction. Do NOT merge.
   - **Skip (override)** → flow.md `phase.merge.smoke.skip.user_override`; surfaces in the
     override audit.
5. Feed the same GAP lines into the QA_DOC smoke checklist (see `handoff-docs`), so QA
   inherits exactly the paths automation didn't prove.

Record `smoke: passed | skipped | failed` in `@persist_state` for cold-resume idempotency.

## Rules

- A coverage GAP is **advisory** — it never fails a wave. Tests passing = wave passes.
  The GAP's job is to reach a human before merge, not to block the machine.
- Scope is changed files only. Whole-repo coverage is someone else's dashboard.
- **Stated limitation (not a bug):** line coverage catches *unexecuted* code. It does NOT
  catch *over-mocking* — a line that runs against a mock returning canned data reads as
  covered. The manual smoke gate backstops exactly that residual. The two layers are
  complementary, not redundant.
