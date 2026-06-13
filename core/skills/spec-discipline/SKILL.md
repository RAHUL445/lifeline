---
name: spec-discipline
description: Use when starting new work - "let's build", "new feature", "from scratch", "spec this", "write a PRD", or any raw idea that needs requirements before code. Turns raw intent into a structured, testable spec through clarifying questions. Never hides ambiguity.
---

# Spec discipline

Turn raw intent into a clear, testable specification before any planning or code.
Delegable role: **spec-writer** — on FULL tier dispatched via `@dispatch_agent`; on
degraded tiers run this body inline. Either way the output is identical.

## Process

1. Read the raw input (free-form description, PRD fragment, bullets) carefully.
2. Identify gaps. Ask 3–7 high-leverage clarifying questions via `@ask_user`, focused on:
   - Goals vs non-goals
   - Users / stakeholders
   - Success criteria (measurable)
   - Constraints (performance, security, compliance, scale)
   - Integration points (existing systems, APIs, data sources)
   - Failure modes the user cares about
3. Synthesize answers into `spec.md` (template `core/templates/spec.md.tmpl`):
   - **Goal** — one sentence
   - **Background** — why now
   - **Users / stakeholders**
   - **Functional requirements** — bulleted, atomic, testable
   - **Non-functional requirements** — perf / security / scale / compliance
   - **Out of scope** — explicit non-goals
   - **Open questions** — anything still unresolved (don't hide these)
   - **Success criteria** — how we know it's done
4. Return the `SPEC_SUMMARY` payload (`core/contracts/SPEC_SUMMARY.md`).
5. The orchestrator then resolves each open question via `@ask_user`, edits the resolved
   decisions into the relevant spec sections, empties the Open questions section, and
   runs the approval gate: `Approve spec, request changes, or abort?`

## Rules

- Don't invent requirements not implied by the input or answers. Unsure → Open Question.
- One assertion per functional-requirement bullet — atomic and testable. These become
  the QA_DOC's test cases at merge, so a vague requirement now is an untestable case later.
- No implementation details — those belong to planning.
- Success criteria must be user-verifiable: they seed the merge smoke checklist
  (see `coverage-to-smoke`).
