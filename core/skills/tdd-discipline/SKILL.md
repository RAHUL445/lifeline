---
name: tdd-discipline
description: Use whenever writing or changing code - "implement", "add", "fix", "refactor". Test-first discipline (RED-GREEN-REFACTOR) plus the pre-commit verdict self-check that keeps failing code out of commits even on harnesses without hooks.
---

# TDD discipline

Test-first, always. The implementer follows this inside every task; it also fires
ambiently whenever code changes outside a formal cycle.

## RED — write the failing test first

1. Before touching production code, write (or extend) a test asserting the INTENDED
   behavior. Run it. It must FAIL — for the right reason (the assertion, not a typo).
2. A test that passes immediately proves nothing changed-worthy; rethink the assertion.
3. Keep it minimal: set up only what's needed to express the behavior.

## GREEN — make it pass

4. Write the simplest production code that makes the test pass. No speculative
   generality, no features beyond the assertion.
5. Run the test. PASS required before moving on.

## REFACTOR — clean up under green

6. With tests green, improve names, structure, duplication. Re-run after each change.
7. Never refactor and change behavior in the same step.

## The verdict self-check (soft pre-commit gate)

Before ANY commit, re-read the latest test verdict for the work being committed
(`test_result.md` in a cycle; the last test run otherwise):

- Verdict `PASS` → commit may proceed.
- Verdict `FAIL` or missing → ABORT the commit and return to the retry loop. Announce:
  `Cannot commit — latest test verdict is <FAIL|missing>.`

On FULL-tier harnesses a real pre-commit hook enforces this check mechanically
(`@run_hook`); on degraded harnesses THIS self-check IS the gate — it is mandatory,
not advisory, and skipping it is a correctness bug. Either way, log the outcome to
flow.md.

## Forbidden patterns

- ❌ Committing with the latest test verdict FAIL or unknown.
- ❌ Weakening an assertion to make a test pass.
- ❌ Marking work done with "expected failure" annotations to dodge a retry.
- ❌ Deleting a failing test instead of fixing the code (unless the test is provably
  wrong — that's a `test-bug` classification, fixed as such and logged).
