# Contributing to lifeline

Thanks for looking. 🪢 lifeline is small, opinionated, and built around **one
architectural rule** — get that rule and the rest is easy.

> Working in this repo with Claude Code? [`CLAUDE.md`](CLAUDE.md) is the short version of
> everything below, auto-loaded into context. Read it first.

## The one rule

**Never put harness-specific logic in `core/`.** The methodology lives once, as pure
markdown, speaking 7 abstract primitives (`@dispatch_agent`, `@ask_user`,
`@persist_state`, `@run_hook`, `@tool_set`, `@command_namespace`, `@artifact_root` — see
`core/capability-manifest.yaml`). Anything harness-specific belongs in an adapter.

This grep must return **zero hits**:

```bash
grep -rniE 'claude|cursor|codex|anthropic|\.cursor|CLAUDE_PLUGIN_ROOT' core/
```

If `core/` needs a runtime capability it can't express abstractly, add a primitive to the
manifest first — don't name the harness.

## Project layout

| Path | What it is | Edit it when |
|---|---|---|
| `core/skills/` | The 13 skills — the actual methodology | Changing how a phase behaves |
| `core/commands/lifecycle.md` | The one orchestrated command | Changing phase sequencing/gates |
| `core/contracts/` | Payload schemas roles must return | Changing what a role hands back |
| `core/templates/` | Artifact scaffolds | Changing an artifact's shape |
| `core/config/defaults.yaml` | Every knob | Adding/changing a setting (also update `docs/CONFIGURATION.md`) |
| `adapters/<h>/` | Per-harness bindings | Adding/fixing a harness — the **only** place harness names live |
| `docs/` | User + contributor docs | Anything user-facing changes |

## Common contributions

### Add a harness
One file: `adapters/<h>/adapter.yaml` binding all 7 primitives. Walkthrough in
[`docs/ADDING-A-HARNESS.md`](docs/ADDING-A-HARNESS.md). Agent shells
(`adapters/*/agents/`) are ~15-line thin shells — load a core skill + contract, return the
payload. **Never** put methodology in a shell; that's how tiers fork.

### Change methodology
Edit the relevant `core/skills/*/SKILL.md`. If you add/remove a skill or phase, update
[`core/METHODOLOGY.md`](core/METHODOLOGY.md) (the master index).

### Add/change a config knob
Edit `core/config/defaults.yaml` (keep the inline comment accurate) **and**
[`docs/CONFIGURATION.md`](docs/CONFIGURATION.md).

## Conventions

- **Docs voice** — emoji headings + light jokes are fine; substance stays exact.
- **Versioning** — [SemVer](https://semver.org). Bump `version` in **both**
  `.claude-plugin/marketplace.json` and `.cursor-plugin/marketplace.json` (and the matching
  `plugin.json` files) together, and add a `CHANGELOG.md` entry.
- **Commits** — clear, scoped messages; no AI co-author trailers.
- **Pre-commit gate** — the Claude Code adapter ships a hook that runs a secret-scan + lint
  on `lifeline/*` branches. Don't bypass it casually.

## Before you open a PR

1. Portability grep above returns zero hits.
2. All 7 primitives still bound in every `adapters/*/adapter.yaml`.
3. Docs updated for anything user-facing (config → `CONFIGURATION.md`, skills/phases →
   `METHODOLOGY.md`).
4. `CHANGELOG.md` has an `[Unreleased]` entry describing the change.
5. If you can, run one small task through `lifecycle.md` end to end on your harness — it
   must COMPLETE and produce the full artifact set (degrade, never block).

Questions or ideas? Open an issue. 🛠️
