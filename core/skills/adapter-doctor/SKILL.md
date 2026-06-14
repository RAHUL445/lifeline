---
name: adapter-doctor
description: Use to statically check a lifeline harness adapter — "is my adapter healthy", "lifeline doctor", "are all primitives bound", before relying on a fresh or edited adapter. Read-only diagnostic; reports binding + file-wiring status without running a cycle.
---

# Adapter doctor

A read-only health check for a harness adapter. Answers "is this adapter correct?"
*without* running a full cycle and watching what breaks — the only check available before
this. Reads files only: writes nothing, starts no cycle, touches no git or state.

Run it after writing or editing an `adapter.yaml`, after a lifeline upgrade, or any time a
cycle behaves unexpectedly and you want to rule the adapter out.

## Inputs

- `core/capability-manifest.yaml` — the 7 required primitives and each one's documented
  degradation.
- The **active** adapter's `adapter.yaml` (the same one the lifecycle command resolves for
  this harness). If more than one adapter is present and the active one is ambiguous, check
  each and label the report per adapter.

## Checks

Run both tiers. Neither blocks — `doctor` only reports.

### Tier 1 — bindings

For each of the 7 manifest primitives (`dispatch_agent`, `ask_user`, `persist_state`,
`run_hook`, `tool_set`, `command_namespace`, `artifact_root`):

- **bound (native)** — present in the adapter's `bindings` with `binding: native`.
- **bound (degraded)** — present with a non-native binding; the manifest defines a
  degradation for it, so the cycle still completes (soft gate / sequential / fallback).
- **missing** — absent from `bindings` entirely. This is the real defect: a primitive the
  core may call with nothing behind it.
- **no fallback** — present but neither native nor backed by a manifest degradation —
  flag it; on a degraded path this primitive has undefined behavior.

Also report the adapter's declared `tier` and whether it matches what the bindings imply
(all-native ⇒ FULL; any degraded ⇒ DEGRADED). A mismatch is a warning, not an error.

### Tier 2 — file wiring

For every file path the adapter *itself* declares (never a hardcoded harness path — read
the paths out of `adapter.yaml`), confirm the file exists and is non-empty:

- agent/role shells the `dispatch_agent` binding points at (one per role the core defines:
  spec-writer, architect, implementer, test-runner, reviewer, reproducer, investigator) —
  report any role with no shell file.
- the hooks manifest and each hook script the `run_hook` binding names (and that scripts
  are executable, where the platform expresses that).
- the command file the `command_namespace` binding names.

A binding that says `native` but whose backing file is missing is the highest-value catch
here — `adapter.yaml` claims a capability the harness can't actually deliver. Report it
loudly.

## Report

Plain-text, human-first. No exit code — this is a report, not a CI gate.

```
lifeline doctor — adapter: <harness>   tier: <declared> (<implied>)

bindings
  dispatch_agent      native     ✓
  ask_user            native     ✓
  persist_state       native     ✓
  run_hook            native     ✓
  tool_set            native     ✓
  command_namespace   native     ✓
  artifact_root       native     ✓
  → 7/7 bound

wiring
  agents/   7/7 role shells present
  hooks/    hooks.json + 4 scripts present, executable
  command   present
  → ok

warnings
  (none)
```

When something is off, replace the clean line with the specific finding, e.g.:

```
  run_hook            native     ✗ declared native but hooks/hooks.json not found
  agents/   6/7 role shells present — missing: reviewer
  tier mismatch: declared FULL but ask_user is degraded
```

End with a one-line summary: `healthy` (all bound, all wired), or
`N warning(s) — see above`. Keep it terse; the report is the payload.

## Portability

This skill names no harness. It discovers what to check by reading the manifest (which
primitives must exist) and the active `adapter.yaml` (which files that adapter claims).
The role-name list above is the core's own contract set, not a harness detail. Adding a
new harness needs no change here — point doctor at its `adapter.yaml`.
