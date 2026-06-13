---
name: payload-contracts
description: Reference skill loaded by other lifeline skills and the lifecycle command - the payload schemas roles return, the mandatory artifact writes the orchestrator performs, and the retry/override invariants. Not user-triggered.
---

# Payload contracts & mandatory writes

The architecture in one rule: **roles return payloads; the orchestrator writes
artifacts.** A role that writes artifacts directly (spec-writer's spec.md is the one
legacy exception) or an orchestrator that drops a payload is broken.

## The contracts

| Payload | Returned by | Schema | Orchestrator writes |
|---|---|---|---|
| SPEC_SUMMARY | spec-writer | `core/contracts/SPEC_SUMMARY.md` | spec.md frontmatter post-gate (role wrote body) |
| TASK_UPDATE | implementer (per task) | `core/contracts/TASK_UPDATE.md` | task.md section + `last_updated` |
| TEST_RESULT | test-runner (per wave per attempt) | `core/contracts/TEST_RESULT.md` | test_result.md wave section + verdict table |
| REVIEW_FINDINGS | reviewer (per task) | `core/contracts/REVIEW_FINDINGS.md` | review.md block + verdict table |
| REPRO_RESULT | reproducer (debug) | `core/contracts/REPRO_RESULT.md` | bug.md Description + Reproduction |
| RCA_RESULT | investigator (debug) | `core/contracts/RCA_RESULT.md` | bug.md RCA section |
| REVIEWER_DOC / QA_DOC | handoff-docs (inline skill) | `core/contracts/{REVIEWER_DOC,QA_DOC}.md` | reviewer_doc.md / qa_doc.md |

Plus two orchestrator-only artifacts: **flow.md** (append-only event log — every phase,
gate, dispatch, retry, verdict, override gets one line) and **changelog.md** (code-change
blocks at wave end). Never mix the two.

## Mandatory writes (NOT optional, NOT skippable under token pressure)

Every payload persists to its artifact BEFORE the cycle advances. Checkpoints:

- **Before testing a wave:** task.md has a section for every wave task.
- **Before committing a wave:** test_result.md latest verdict PASS; review.md overall
  APPROVE. Otherwise ABORT the commit and re-enter the retry loop.
- **Before the merge gate:** every wave covered in task.md / review.md /
  test_result.md / changelog.md. Backfill from accumulated payloads, log the backfill.

These writes are the persistent record of the cycle — identical on every harness, which
is what makes a FULL-tier run and a DEGRADED-tier run diff-comparable.

## Retry & override invariants

- A wave cannot advance with verdict FAIL. Classification drives the response
  (see TEST_RESULT): code-bug/test-bug → re-dispatch implementer + re-test wave;
  flake → handled inside test-runner; env → surface to the user immediately.
- Attempt counter lives in `@persist_state.wave_attempts[<wave_id>]` and survives cold
  resume. At `retry_cap` (default 3): `@ask_user` retry / skip-with-override / abort.
- Every override appends to flow.md AND `@persist_state.wave_overrides`. Overrides are
  never silent — they resurface in the merge gate's override audit and REVIEWER_DOC §5.

## Forbidden patterns (correctness bugs, not optimizations)

- ❌ Advancing past a payload without persisting it.
- ❌ Marking a wave done while its latest test verdict is FAIL.
- ❌ "Expected gap — no retry" annotations to dodge the retry loop.
- ❌ Silently skipping env failures.
- ❌ Logging code changes to flow.md or events to changelog.md.
