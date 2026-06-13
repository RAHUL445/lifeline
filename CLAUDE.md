# CLAUDE.md

Guidance for Claude Code (and any agent) working **on the lifeline codebase itself**.
This is contributor guidance, not user docs — for usage see README + docs/.

## What this repo is

lifeline = a portable, multi-harness dev-lifecycle plugin. The methodology lives once in
`core/` as pure markdown; each harness gets a thin `adapter.yaml` binding. "Degrade,
never block."

## The one rule that matters

**Never put harness-specific logic in `core/`.** `core/` speaks only 7 abstract
`@primitives` (see `core/capability-manifest.yaml`). Runtime calls appear as
`@dispatch_agent`, `@ask_user`, `@persist_state`, `@run_hook`, `@tool_set`,
`@command_namespace`, `@artifact_root` — never a concrete tool/feature name.

Portability invariant — this grep must return **zero hits** in `core/`:

    grep -rniE 'claude|cursor|codex|anthropic|\.cursor|CLAUDE_PLUGIN_ROOT' core/

If you need a capability `core/` can't express abstractly, add a primitive to the
manifest first — don't leak the harness name.

## Layout

```
core/                  portable methodology — markdown only, edit here for behavior changes
├── skills/            13 skills (the actual methodology)
├── commands/          lifecycle.md — the one orchestrated command
├── contracts/         payload schemas roles must return
├── templates/         artifact scaffolds
├── config/defaults.yaml   every knob (see docs/CONFIGURATION.md)
└── METHODOLOGY.md     master index
adapters/              per-harness bindings — ONLY place harness names appear
├── claude-code/       FULL tier (plugin)
├── cursor/            FULL tier (≥2.4)
└── codex/             one-file degraded stub (the portability proof — keep it minimal)
docs/                  user + contributor docs
```

## Adding / changing a harness

One file: `adapters/<h>/adapter.yaml` binds all 7 primitives. See
`docs/ADDING-A-HARNESS.md`. Agent shells (`adapters/*/agents/`) are ~15-line thin shells:
load core skill + contract, return payload. **Never** put methodology in a shell — that's
how tiers fork.

## Conventions

- **Commits**: author `Rahul Pandey <rahul.pan8991@gmail.com>`, no AI co-author trailer.
  Pre-commit hook runs a secret-scan + lint gate (intentional — don't bypass casually;
  `git -c core.hooksPath=/dev/null` only when the gate is provably a false positive).
- **PRD.md / todo.txt**: local-only, gitignored — never commit.
- **Versioning**: bump `version` in both `.claude-plugin/marketplace.json` and
  `.cursor-plugin/marketplace.json` together; keep them in sync.
- **Docs voice**: emoji headings + light jokes; substance stays exact.

## Before committing

1. Portability grep above is clean.
2. All 7 primitives still bound in every `adapters/*/adapter.yaml`.
3. Touched a knob? Update `core/config/defaults.yaml` comment + `docs/CONFIGURATION.md`.
4. Touched the skill set / phases? Update `core/METHODOLOGY.md` index.
