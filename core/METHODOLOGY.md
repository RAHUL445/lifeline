# lifeline methodology — master index

lifeline is an auditable, coverage-honest development lifecycle that runs on any harness
with an adapter, and hands off to humans at merge. Everything under `core/` is portable
markdown; runtime capabilities appear only as `@primitives`
(see `capability-manifest.yaml`), bound per harness in `adapters/<h>/adapter.yaml`.

## The lifecycle

```
spec → plan → build (waves) → review → test → merge
                         └─ debug lane: reproduce → RCA → fix → verify ─┘
```

Two entry paths, one methodology (no duplicated logic):

- **Ambient** — the skills below auto-trigger on intent ("let's build…", "review this",
  "bug…"). Each skill is complete on its own.
- **Orchestrated** — `commands/lifecycle.md` sequences the same skills with gates,
  persisted state, and the full artifact trail.

## Skills

| Phase | Skill | What it owns |
|---|---|---|
| Discover | `using-lifeline` | What lifeline can do; how to start |
| Spec | `spec-discipline` | Raw intent → testable spec; open questions never hidden |
| Plan | `planning-waves` | 2–3 approaches; dependency-ordered parallel waves; effort labels |
| Build | `tdd-discipline` | RED-GREEN-REFACTOR + the pre-commit verdict self-check |
| Build | `implementing-task` | Scoped execution of one task; TASK_UPDATE payload |
| Review | `four-lens-review` | ONE review per task, all 4 lenses, depth from effort |
| Test/Merge | `coverage-to-smoke` | Changed-file coverage gaps → human smoke checklist |
| Merge | `merge-discipline` | Pre-merge invariant, override audit, smoke gate, branch action |
| Merge | `handoff-docs` | REVIEWER_DOC (code-visible) + QA_DOC (blackbox) |
| Debug | `systematic-debugging` | reproduce → RCA (gated) → fix → verify |
| Cross | `payload-contracts` | Payload schemas, mandatory writes, retry/override invariants |
| Cross | `resuming-a-cycle` | Cold resume from persisted state |
| Meta | `writing-lifeline-skills` | Extending lifeline without breaking portability |

## The principles

1. **Roles return payloads; the orchestrator writes artifacts.** Every dispatch ends in
   a structured payload (`contracts/`) persisted before the cycle advances.
2. **Degrade, never block.** Every capability has a documented fallback. Degraded tiers
   keep 100% of methodology and artifacts; they lose hard-gate enforcement (→ mandatory
   self-checks) and parallelism (→ sequential waves). That is the whole tradeoff.
3. **Coverage-honest.** Tests passing is necessary, not sufficient. Changed-file coverage
   gaps are surfaced — advisory, never blocking — and routed to a human smoke gate and
   the QA doc. Line coverage can't see over-mocking; the smoke gate backstops that.
4. **Auditable.** flow.md records every gate, retry, verdict, and override. Overrides are
   legal but never silent — they resurface at merge and in the reviewer doc.
5. **Human handoff is part of the lifecycle.** A cycle isn't done at green tests; it's
   done when a reviewer and a QA engineer can each pick up a purpose-built document.

## Artifacts (per scope, in `@artifact_root/<scope>/`)

spec.md (or bug.md) · plan.md · task.md · review.md · test_result.md · flow.md ·
changelog.md · state.json · reviewer_doc.md · qa_doc.md
