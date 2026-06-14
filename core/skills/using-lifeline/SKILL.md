---
name: using-lifeline
description: Use on first contact with lifeline - "what can lifeline do", "how do I start a cycle", "what is lifeline", or when unsure which lifeline skill applies. Discovery map of the skills, the command, and when each fires.
---

# Using lifeline

lifeline is an auditable, coverage-honest development lifecycle that runs on any harness
with an adapter and hands off to humans at merge. Two ways in:

## 1. Ambient (no command needed)

Say what you're doing; the matching skill fires:

| You say… | Skill that fires |
|---|---|
| "let's build…", "new feature", "spec this" | `spec-discipline` |
| "plan this", "break into tasks" | `planning-waves` |
| "implement", writing/changing code | `tdd-discipline` + `implementing-task` |
| "review this", post-implementation | `four-lens-review` |
| "are we sure this works?", tests just passed | `coverage-to-smoke` |
| "bug", "broken", "regression" | `systematic-debugging` |
| "merge", "open PR", "ship it" | `merge-discipline` (→ `handoff-docs`) |
| "continue", "resume", "where was I" | `resuming-a-cycle` |

Each skill is complete on its own — you can use just the review, or just the debug lane.

## 2. Orchestrated (the full gated cycle)

Invoke the lifecycle command per your harness's `@command_namespace` binding (a slash
command where the harness has them, otherwise "run the lifeline lifecycle" by name):

```
lifecycle start            # spec → plan → build → review → test → merge, with gates
lifecycle debug <desc>     # reproduce → RCA → fix → verify → merge
lifecycle continue|status|abort
lifecycle doctor           # read-only adapter health check (primitives bound? files wired?)
lifecycle guide            # print this map and stop (no cycle)
```

`start` opens a short setup wizard first: storage location (in-repo `.lifeline/` or an
absolute path elsewhere; commit vs gitignore), scope, isolation (git worktree where the
adapter supports it, else a new `lifeline/<scope>` branch or the current branch),
autonomy (gated/auto), then optional advanced settings (retry-cap, coverage threshold,
and dispatch mode — `auto`/`agent`/`inline`, the perf/cost knob for how roles run).
Choices persist to a repo-root `.lifelinerc`. Once it is complete the wizard is skipped
entirely on later cycles (only scope is asked) — re-run it any time with
`lifecycle start --reconfigure`.

The command sequences the SAME skills with persisted state (`.lifeline/<scope>/`),
approval gates, structured payloads, and the full artifact trail — so the cycle survives
session death and every decision is on the record.

## What you get that's different

- **Coverage→smoke:** changed-file coverage gaps become a human smoke checklist at merge
  — the "152 tests pass but the mocked handler was never exercised" class gets caught.
- **Handoff docs:** merge emits a REVIEWER_DOC (code-visible, detailed) and a QA_DOC
  (blackbox flow + test cases).
- **Audit trail:** flow.md logs every gate, retry, verdict, and override; overrides
  resurface at merge.
- **Portable:** identical methodology on every adapted harness; only enforcement
  (hard vs soft gates) and concurrency (parallel vs sequential) vary. Concurrency is
  also a deliberate knob — `dispatch_mode` trades agent isolation against inline
  warm-context speed. See `docs/PORTABILITY.md`.
