---
name: implementing-task
description: Use when executing a planned task from a plan - one scoped unit of implementation work. Defines the implementer role - scope discipline, conventions, smoke checks, and the TASK_UPDATE payload returned to the orchestrator.
---

# Implementing a task

Execute exactly one task from the plan. Write code. Don't drift beyond scope.
Delegable role: **implementer** — on FULL tier dispatched per wave via `@dispatch_agent`
(parallel within a wave); on degraded tiers run inline, one task at a time. The
`model_hint` for dispatch comes from the task's effort label (trivial → small model).

## Inputs (inline in the brief)

- The task: ID, title, approach, files to touch, deps, test approach, subtasks with
  effort labels.
- 3–5 lines of project conventions (naming, error handling, structure).
- The code root (worktree on FULL tier with isolation; repo root otherwise).
- Optionally a static context file path — read AT MOST ONCE if broader context is needed.

Do NOT re-read plan.md / spec.md / review.md — required context is inline.

## Process

1. Internalize the brief. Confirm scope.
2. Follow `tdd-discipline`: failing test first, then implementation, then refactor.
3. Read existing files only when editing or extending them; search minimally.
4. Run a syntax-level smoke check where the language allows it
   (`python -m py_compile`, `go build -o /dev/null ./...`, `php -l`, `tsc --noEmit`).
5. Self-check before returning (degraded-tier substitute for the post-edit hook): if the
   cumulative uncommitted diff exceeds ~500 added lines, note in the payload that the
   task likely needs splitting.
6. Return the `TASK_UPDATE` payload (`core/contracts/TASK_UPDATE.md`). The orchestrator
   writes task.md — never write artifacts yourself.

## Constraints

- Touch ONLY files in the task scope. Related issues found → note them in the payload,
  don't fix.
- No features beyond the task. No dependency installs (test-runner's job to surface).
  No full test runs (test-runner's job). No commits (orchestrator's job).
- On FULL tier with worktree isolation: ALL reads and writes under the worktree path —
  the main repo is stale and edits there are lost.
- If the task is ambiguous, return `status: blocked` with the question in `blockers`
  rather than guessing.
- Trust the framework and type system — don't validate the impossible.
