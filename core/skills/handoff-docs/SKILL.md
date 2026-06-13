---
name: handoff-docs
description: Use when opening a PR, publishing, handing work to a human reviewer or QA team, or when a cycle reaches merge. Generates two structured handoff documents from cycle artifacts - a REVIEWER_DOC (code-visible, detailed change explanation) and a QA_DOC (blackbox flow + test cases). Pure methodology - no harness capabilities required.
---

# Handoff docs

At merge, the cycle's artifacts (spec, plan, task log, diff, test results, review
findings) contain everything a human reviewer or QA engineer needs — but scattered.
This skill compiles them into two purpose-built documents. Zero capability dependencies —
runs identically on every harness.

## When

Invoked by `merge-discipline` after the smoke gate, before the branch action. Also fires
standalone when the user says "open PR", "publish", or "hand this off".

## Inputs (all from `@artifact_root`)

`spec.md` (or `bug.md`), `plan.md`, `task.md`, `review.md`, `test_result.md`,
`changelog.md`, the cycle diff, and the smoke checklist produced by `coverage-to-smoke`.

## Output 1 — REVIEWER_DOC (`reviewer_doc.md`)

Audience: a human reviewer **who can see the code**. Explain the changes in detail,
structured. Schema in `core/contracts/REVIEWER_DOC.md`; template
`core/templates/reviewer_doc.md.tmpl`. Sections:

1. **Summary** — what changed and why, one paragraph.
2. **Changes by wave/file** — file → what changed → why, each mapped to the spec
   requirement (or RCA item) it satisfies. Pull from `changelog.md` + `task.md` notes.
3. **Design decisions** — every non-trivial choice, the alternatives rejected, and why.
   Pull from `plan.md` chosen approach + task notes.
4. **Risk areas** — the parts most likely to be wrong; what the reviewer should
   scrutinize first.
5. **Review findings & resolutions** — each finding from `review.md` with how it was
   resolved, plus the override audit (anything skipped under user override, verbatim
   from flow.md).
6. **Test & coverage summary** — suite verdicts, and the coverage GAP lines verbatim.

## Output 2 — QA_DOC (`qa_doc.md`)

Audience: a QA engineer for whom the code is a **blackbox**. Explain flow + test cases,
structured. No implementation detail — no file names, no function names, no architecture.
Schema in `core/contracts/QA_DOC.md`; template `core/templates/qa_doc.md.tmpl`. Sections:

1. **Feature flow** — user action → expected result, step by step.
2. **Preconditions & setup** — environment, accounts, test data needed.
3. **Test cases** — numbered; each = steps + expected result. Cover the happy path,
   edge cases, and negative cases. Derive from spec functional requirements + success
   criteria; one test case minimum per functional requirement.
4. **Smoke checklist** — seeded verbatim from the coverage GAP lines: the untested paths
   a human must exercise. This is the coverage→smoke handoff landing in QA's lap.
5. **Known limitations / out of scope** — from spec non-goals + review notes.

## Rules

- Write both docs to `@artifact_root`. Offer (via `@ask_user` at the branch action) to
  attach them to the PR body.
- REVIEWER_DOC may reference code freely; QA_DOC must never. If a QA step can't be
  expressed without naming code, the step is wrong — rewrite it as observable behavior.
- Don't invent test cases beyond what spec + diff support; if a flow is unclear, say so
  in Known limitations rather than guessing.
- Every coverage GAP line MUST appear in both docs (REVIEWER_DOC §6, QA_DOC §4). A gap
  that vanishes between test and handoff defeats the entire mechanism.
