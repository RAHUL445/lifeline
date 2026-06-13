---
name: planning-waves
description: Use when a spec exists and work needs structure - "plan this", "break into tasks", "how should we implement". Produces 2-3 implementation approaches with architectures, then breaks the chosen approach into dependency-ordered parallel wave groups with effort labels.
---

# Planning in waves

Convert a spec into an actionable plan. Two stages with a human approach-pick between
them. Delegable role: **architect** — `@dispatch_agent` on FULL tier, inline otherwise.

## Stage 1 — approaches + per-approach architectures

1. Read `spec.md`. Internalize goals + constraints.
2. Inspect the repo briefly: language, framework, existing patterns. Search minimally.
3. Generate **2–3 approaches**, each with: ID (A/B/C), name, 2–4 sentence summary,
   concrete pros and cons/risks, effort (S/M/L), and its own architecture sub-section
   (components, data flow, public interfaces, external deps, key trade-offs vs the
   other approaches).
4. Write to `plan.md` (template `core/templates/plan.md.tmpl`): Approaches table +
   Architecture sections. Leave Tasks/Subtasks empty.
5. Orchestrator surfaces the approaches and runs the pick gate via `@ask_user`
   (`Pick approach`), then marks the chosen row, updates frontmatter and
   `@persist_state.chosen_approach`.

## Stage 2 — tasks + subtasks for the chosen approach

1. Use the chosen approach's architecture as the design baseline.
2. Break work into **epics → tasks → subtasks**. Per task: ID, title, concrete file
   paths, deps (task IDs), test approach, **wave group** (W1, W2, …), status `[ ]`.
3. Wave grouping rules:
   - Tasks in the same wave have all deps satisfied by earlier waves.
   - Tasks touching the same file never share a wave (merge conflicts).
   - Maximize parallelism within dependency order. On FULL tier a wave's tasks run as
     parallel dispatches; on degraded tiers the same waves run sequentially — grouping
     stays identical either way.
4. Label each subtask's effort: `trivial` (<20 LOC, single file, no design — routable to
   a small model) | `small` (1–2 files, <100 LOC, mechanical) | `medium` (multi-file,
   <300 LOC, some design) | `large` (cross-cutting, significant design).
5. Fill the Dependencies + Risks table.
6. Orchestrator surfaces task/wave counts and runs the plan gate (`Approve plan?`).

## Rules

- Be specific. "Add caching layer" is too vague; "add Redis cache TTL=60s in
  `get_user_profile`" is right.
- Trade-offs concrete, not hedged — name what each approach gives up.
- Effort labels honest — the label drives both model routing AND review depth
  (`four-lens-review` scales to it). Downgrading to trivial to save tokens buys a
  too-shallow review later.
- Tasks ordered by dependency, not importance.
