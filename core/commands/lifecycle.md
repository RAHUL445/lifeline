---
name: lifeline-lifecycle
description: Drive the full lifeline lifecycle (spec → plan → build → review → test → merge, plus a debug lane) with approval gates, structured payloads, coverage-honest testing, and reviewer/QA handoff docs. Portable - speaks only @primitives bound by the active harness adapter.
argument-hint: "[start|continue|status|abort|debug|guide] [--auto] [--retry-cap=N]"
---

# lifecycle

You are the lifeline orchestrator. This command speaks ONLY the abstract primitives from
`core/capability-manifest.yaml` — `@dispatch_agent`, `@ask_user`, `@persist_state`,
`@run_hook`, `@tool_set`, `@command_namespace`, `@artifact_root`. Resolve the active
harness's `adapters/<harness>/adapter.yaml` FIRST and bind every primitive to its native
feature or documented degradation. Degrade, never block: the cycle must complete on any
adapter. If a binding is degraded, note it once in flow.md (e.g.
`enforcement.advisory harness=<h>`).

All methodology lives in `core/skills/` — this command sequences those skills and owns
state + artifact writes. It never re-states methodology (the same skills also fire
ambiently without this command; drift between the two paths is a bug).

## Arguments

- `start` (default) — new cycle from the user's intent
- `continue` — resume via the `resuming-a-cycle` skill
- `status` / `abort` — per `resuming-a-cycle`
- `debug` — bug-fix lane (see Debug lane below)
- `guide` (also bare invocation with `--help`) — print the `using-lifeline` discovery
  map (entry modes, ambient triggers, what each artifact is) and stop. No cycle started.
- `--auto` — skip gates except pre-merge
- `--retry-cap=N` — override `config retry_cap` (default 3)

Load configuration from `core/config/defaults.yaml`, merged with flags.

If the argument is `guide` (or the invocation is bare with `--help`): run the
`using-lifeline` skill to print the discovery map and STOP — do not detect git, write
state, or start a cycle.

## Step 1 — setup

1. Detect git: repo root, current branch, commit count. No git → tell the user and stop.
   Zero commits → create an empty bootstrap commit.

2. **Resolve config.** Read `core/config/defaults.yaml`, then the repo-root `.lifelinerc`
   if present (per-project overrides: `artifact_root`, `isolation`, `autonomy`,
   `retry_cap`, `coverage_min`, `committed`, `dispatch_mode`), then flags. Precedence:
   flag > `.lifelinerc` > `defaults.yaml`. This sets `@artifact_root` for the whole run —
   it may point inside the repo (`.lifeline`, default) or to an absolute path elsewhere.
   It also sets `dispatch_mode` (`auto` | `agent` | `inline`) — how every
   `@dispatch_agent` below runs (see **Dispatch mode** after Step 2).

3. **Setup wizard.** If `.lifelinerc` exists, FIRST `@ask_user`:
   `Use last settings (location=<…> isolation=<…> autonomy=<…> dispatch=<…>)?` → reuse / reconfigure.
   On reuse, skip to step 4 with those values (scope is still asked — it's per-cycle).
   Otherwise ask, in order (one gate each; recommended option first; flags pre-answer and
   skip a question — `--auto` answers autonomy, `--retry-cap` answers retry-cap):

   a. **Storage location** — `@ask_user`: `in-repo .lifeline/ (recommended)` /
      `outside repo`. On `outside repo`, `@ask_user` for an absolute path (default
      `~/lifeline-artifacts/<repo-name>/`). Set `@artifact_root` accordingly.
   b. **Version control** — asked ONLY for an in-repo location: `commit (shared audit
      trail, recommended)` / `gitignore (local only)`. On `gitignore`, append
      `<artifact_root>/` to the repo `.gitignore` (create if absent). Record `committed`.
      An outside-repo location is untracked by nature → skip this question, `committed=false`.
   c. **Scope** — `@ask_user` (current branch / project name / custom). Sanitize.
      Set `ARTIFACTS = @artifact_root/<scope>/`. Existing scope → `@ask_user`: resume /
      restart (archive prior to `ARTIFACTS/archive/<ISO>/`) / new scope.
   d. **Isolation** — `@ask_user`. Options depend on whether the adapter advertises
      `extras.worktree_isolation`. If yes: `git worktree (isolated, recommended)` /
      `new branch in place` / `current branch (no new branch)`. If no (degraded):
      `new branch in place (recommended)` / `current branch` — the worktree option is
      hidden; methodology is identical either way. Record the choice as `isolation`
      (`worktree` | `branch` | `current`).
   e. **Autonomy** — `@ask_user`: `gated (recommended)` / `auto`. (`auto` = pause at
      pre-merge only.)
   f. **Advanced?** — `@ask_user`: `defaults (recommended)` / `customize`. On customize,
      ask retry-cap and coverage threshold (`coverage_check.min_changed_file_pct`,
      0 disables the gate), then dispatch mode (g); else keep config values.
   g. **Dispatch mode** (advanced only — `auto` otherwise) — `@ask_user`:
      `auto (recommended)` / `agent` / `inline`. `auto` = agent for parallel
      multi-task waves and large effort, inline otherwise; `agent` = always isolated
      (parallel where supported); `inline` = always warm-context (faster/cheaper on
      small sequential work). Record as `dispatch_mode`. (Degraded tiers run inline
      regardless of this choice.)

   **Write `.lifelinerc`** at the repo root with the resolved set (`artifact_root`,
   `isolation`, `autonomy`, `retry_cap`, `coverage_min`, `committed`, `dispatch_mode`).
   Git rule for the
   pointer itself: if `artifact_root` is repo-relative, the `.lifelinerc` is portable —
   leave it tracked (it carries no machine paths). If `artifact_root` is an absolute path,
   it is machine-specific — append `.lifelinerc` to `.gitignore` so it never leaks to
   teammates. Hooks and the `resuming-a-cycle` skill read `.lifelinerc` regardless of its
   git status (it is on disk either way).

4. **Apply isolation.** `worktree` → create a worktree on branch `lifeline/<scope>`
   (FULL-tier extra). `branch` → `git checkout -b lifeline/<scope>` in place.
   `current` → stay on the current branch (the pre-commit `@run_hook` gate keys on the
   `lifeline/*` prefix, so on `current` the hard gate is inert — note this once in
   flow.md and rely on the `tdd-discipline` self-check). Methodology is unchanged across
   all three.

5. Generate `cycle_id`. Instantiate `core/templates/*.md.tmpl` into `ARTIFACTS`
   (spec, plan, task, review, test_result, flow, changelog — bug instead of spec for
   debug), substituting `{{SCOPE}} {{DATE}} {{CYCLE_ID}} {{PHASE}}` and stripping each
   template's end-of-file authoring-hint block.
6. `@persist_state` init: `{scope, phase: "spec"|"repro", mode, cycle_id, isolation,
   dispatch_mode, chosen_approach: "", active_task: null, wave_attempts: {},
   wave_overrides: [], smoke: null}`.
7. flow.md: `[<ISO>] cycle.start scope=<scope> isolation=<isolation> autonomy=<mode> dispatch=<dispatch_mode>`.

## Step 2 — phase loop

Per phase: run the phase's core skill → persist returned payloads per the
`payload-contracts` skill (MANDATORY writes — a payload that isn't persisted before
advancing is data loss) → update `@persist_state.phase` → append flow.md event → if
gated, `@ask_user`.

**Dispatch mode (applies to every `@dispatch_agent` below).** Resolve per the config
`dispatch_mode`:
- `agent` — dispatch as an isolated agent (parallel where the adapter's
  `dispatch_agent.concurrency` is `parallel`; sequential otherwise).
- `inline` — run the role's skill in the current context, sequentially. Same payload,
  same persistence — identical to the degraded-tier path, chosen deliberately.
- `auto` — per dispatch: **agent** when the wave has ≥2 independent tasks (parallel
  wall-clock win) OR the task's effort is `large` (context isolation); **inline**
  otherwise (single-task waves, `trivial`/`small` effort, and the single-role spec /
  plan / reviewer / reproducer / investigator dispatches).

On a degraded adapter (no native agent) every dispatch is inline regardless — the
`dispatch_mode` choice is a no-op there, not an error.

**Timing.** Wrap each dispatch: capture an ISO start, and on completion append
`[<ISO>] agent.<role>.done task=<id> mode=<agent|inline> secs=<elapsed>` to flow.md
(elapsed = whole seconds). This makes a dispatch-mode A/B (same task, `agent` vs
`inline`) a direct flow.md read — the empirical check on whether agent overhead is
worth it for a given workload.

### Phase: spec

`@dispatch_agent(spec-writer)` running the `spec-discipline` skill (inline on degraded
tiers — same everywhere a dispatch appears below). Surface the SPEC_SUMMARY; resolve
each open question via `@ask_user` and edit resolutions into spec.md; then the approval
gate: `Approve spec, request changes, or abort?` On approve: frontmatter
`status: approved`, flow.md `phase.spec.gate.approved`.

### Phase: plan

Two-stage per the `planning-waves` skill. Stage 1: `@dispatch_agent(architect)` →
approaches + architectures → `@ask_user` `Pick approach` → record in plan.md +
`@persist_state.chosen_approach`. Stage 2: re-dispatch architect with the choice →
tasks/waves/efforts/deps → surface counts → `@ask_user` `Approve plan?`.

### Phase: build (wave loop)

For each wave W (next unchecked group in plan.md, dependency order):

1. `@persist_state.phase = "build:wave-<W>"`, `active_task = <ids>`. Capture the wave's
   start ref. flow.md `wave.<W>.start tasks=<ids>`.
2. **Dispatch implementers** — `@dispatch_agent(implementer)` per task, `model_hint`
   from effort, per the **Dispatch mode** rule above. `agent` (or `auto` with ≥2
   tasks / large effort) on a parallel-capable adapter → all of the wave's tasks in
   parallel; `inline` (or `auto` single-task) or a degraded adapter → sequential, same
   wave order. Each runs `implementing-task` + `tdd-discipline`.
3. **Persist** each TASK_UPDATE → task.md (before any testing). Blockers surface
   immediately.
4. **Test** — `@dispatch_agent(test-runner)` once per wave: test paths from the wave's
   TASK_UPDATEs, task_file_map for failure attribution, attempt from
   `wave_attempts[<W>]`. Persist TEST_RESULT → test_result.md (including the coverage
   block — see `coverage-to-smoke` step 1). On FAIL: classification handling + retry
   loop per `payload-contracts`; at retry cap, `@ask_user`.
5. **Review** — ONE `@dispatch_agent(reviewer)` per task running `four-lens-review`
   (all four lenses, depth from effort). Persist REVIEW_FINDINGS → review.md. On
   REQUEST_CHANGES: blocker loop per the skill (re-implement → re-test wave →
   re-review) until APPROVE or cap.
6. **Commit** — pre-commit verdict check per `tdd-discipline` (hard via `@run_hook` on
   FULL tier; the mandatory self-check otherwise): latest test verdict PASS and review
   APPROVE, else ABORT the commit and re-enter the loop. Commit with the
   `merge-discipline` format. Mark wave tasks `[x]` in plan.md; append the wave's
   code-change block to changelog.md; flow.md `wave.<W>.done commit=<sha>`.
7. More unchecked tasks → next wave.

### Phase: merge

Run the `merge-discipline` skill end to end: pre-merge invariant → override audit →
manual smoke gate (seeded by `coverage-to-smoke` step 2) → `handoff-docs`
(reviewer_doc.md + qa_doc.md) → gate display → `@ask_user` branch action → commit
format → close-out (flow.md `cycle.end`, clear `@persist_state`).

## Debug lane (`lifecycle debug <description>`)

Same setup (mode=debug, initial phase `repro`, bug.md instead of spec.md), then:

1. **Reproduce** — `@ask_user` input mode (description / failing test path / both);
   `@dispatch_agent(reproducer)` per `systematic-debugging` phase 1 → persist
   REPRO_RESULT → bug.md; orchestrator verifies the repro command fails. Gate 1:
   `Does this test correctly capture the bug?` (proceed / refine / abort).
2. **RCA** — pre-fetch recent git log + the test file; `@dispatch_agent(investigator)`
   (read-only) → persist RCA_RESULT → bug.md. Gate 2: `Root cause confirmed?`.
3. **Fix** — scope from RCA: single-task → one implementer then the wave loop's
   test/review/commit steps (wave `W1`); multi-task → architect stage 2 ("Direct fix
   per RCA"), then the full wave loop. The repro test MUST be in the test paths of the
   wave touching the affected files, and must be verified absent from the final
   failures list. flow.md `phase.test.done bug_test_passed=true`.
4. **Merge** — `merge-discipline` with commit type forced `fix` + debug body extras.

## Error handling

On any unhandled error: write current phase + error context to `@persist_state`,
surface to the user. Never lose state — `continue` must always work afterward.
