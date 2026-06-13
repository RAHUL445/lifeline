---
name: systematic-debugging
description: Use when something is broken - "bug", "regression", "fails when", "worked yesterday", "error in production". Four gated phases - reproduce as a failing test, root-cause before any fix, fix with TDD, verify the repro passes. No fix until the RCA is confirmed.
---

# Systematic debugging

Bugs die in four phases, in order, with gates between them. The cardinal rule: **no fix
until the root cause is confirmed.** Patching symptoms without an RCA is how the same
bug ships three times.

Delegable roles: **reproducer** (phase 1) and **investigator** (phase 2) —
`@dispatch_agent` on FULL tier, inline otherwise.

## Phase 1 — Reproduce

Capture the bug as a deterministic failing test. Input modes: from a description (write
a minimal test asserting the INTENDED behavior, confirm it fails for the right reason),
from an existing failing test (run it, characterize it), or both.

- Test files only — never production code.
- Deterministic: no timing flakes, no unseeded randomness.
- If the test passes, the bug was NOT captured — rethink the assertion (max 2 attempts),
  then ask for more detail rather than guessing.
- Return `REPRO_RESULT` (`core/contracts/REPRO_RESULT.md`); the orchestrator writes
  bug.md and independently re-runs the command to confirm non-zero exit.

**Gate 1** (`@ask_user`): "Does this test correctly capture the bug?" — proceed /
refine with a hint / abort.

## Phase 2 — Root-cause (read-only)

1. Read the failing test; internalize what it asserts.
2. Read the traceback; find the deepest frame in production code.
3. Read the suspect file(s); locate the defective line(s).
4. Search related symbols — callers, similar patterns elsewhere (same bug in ≥3 files →
   multi-task scope), recent refactors.
5. `git blame` the suspect lines; a recent commit raises regression likelihood.
6. Classify effort (trivial/small/medium/large) and scope (single-task/multi-task).
7. Describe the fix BEHAVIORALLY — what changes at what layer, no code.
8. Return `RCA_RESULT` (`core/contracts/RCA_RESULT.md`).

Look for the bug, not for problems — side observations go to `related_findings`,
advisory only. Unclear after a focused pass → say "unclear", don't guess.

**Gate 2** (`@ask_user`): "Root cause confirmed?" — approve / refine / abort.

## Phase 3 — Fix

Scope from the RCA: single-task → one implementer pass (`implementing-task` +
`tdd-discipline`) as wave W1; multi-task → plan the fix into waves (`planning-waves`
stage 2, approach "Direct fix per RCA") and run the build loop.

The repro test MUST be in the test paths of the wave touching the affected files.

## Phase 4 — Verify

Wave tests pass AND the repro test specifically passes (its test_id absent from the
failures list — assert this explicitly, log `bug_test_passed=true` to flow.md). Then
review (`four-lens-review`) and merge (`merge-discipline`, commit type forced `fix`,
body lines: root cause / affected files / repro test).

## Forbidden patterns

- ❌ Fixing before Gate 2 approves the RCA.
- ❌ A "repro" that never failed.
- ❌ Deleting or weakening the repro test to get to green.
- ❌ Closing without the repro test verified passing.
