---
name: resuming-a-cycle
description: Use when the user says "continue", "resume", "where was I", "pick up where we left off", or a session starts with an unfinished lifeline cycle. Reads persisted state and jumps to the recorded phase without losing context.
---

# Resuming a cycle

A lifeline cycle survives session death by design: state lives in `@persist_state`
(state.json under `@artifact_root`), progress lives in the artifacts, and history lives
in flow.md. Resume = read those three, jump to the recorded phase.

## Process

1. **Find state.** Resolve `@artifact_root` first — read the repo-root `.lifelinerc`
   (`artifact_root:` key) if present, else default `.lifeline`. Scan
   `<artifact_root>/*/state.json` for scopes with live state. Multiple → `@ask_user`
   which scope. None → say nothing is pending, offer a fresh start.
2. **Read state.json:** `scope, phase, mode, cycle_id, isolation, dispatch_mode,
   chosen_approach, active_task, wave_attempts, wave_overrides, smoke`. `dispatch_mode`
   (missing → `auto`) carries the cycle's agent/inline choice forward, so resumed
   waves dispatch the same way the cycle started. Re-enter the recorded workspace:
   `isolation=worktree` → `cd` into the `lifeline/<scope>` worktree (recreate it on the
   existing branch if the dir is gone); `isolation=branch` → `git checkout lifeline/<scope>`;
   `isolation=current` → stay put. Mismatched/missing field → treat as `branch`.
3. **Cross-check artifacts** (state can lag a crash by one step): the latest flow.md
   events and the artifact for the recorded phase. If artifacts are AHEAD of state.json
   (e.g. a review block exists but phase still says build), trust the artifacts, fix
   state.json, log `resume.state.corrected` to flow.md.
4. **Jump to phase:**
   - `spec` / `plan` — re-enter that phase's skill at its last incomplete step.
   - `build:wave-<id>` — re-enter the wave loop at that wave; recompute the wave's
     start ref as the last commit's parent on the cycle branch; `wave_attempts`
     carries over (the retry cap doesn't reset on resume).
   - `merge` / `merge:deferred` — re-enter merge-discipline; invariants recheck briefly
     (idempotent).
5. Announce in one line where the cycle stands before acting:
   `Resuming <scope> at <phase> (attempt <n>/<cap> on wave <id>).`

## Tier note

On FULL tier a session-start hook surfaces pending cycles automatically. On degraded
tiers nothing fires — this skill is the resume path, triggered by the user's
"continue"/"resume". Same state file, same jump table, no methodology difference.

## `status` and `abort`

- `status`: print scope, phase, active task, cycle id, last 5 flow.md events. Stop.
- `abort`: confirm via `@ask_user`; clean up (remove the worktree if `isolation=worktree`),
  keep artifacts, clear state, log `cycle.end status=aborted`.
