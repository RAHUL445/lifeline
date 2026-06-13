# 🔧 Adding a harness ≈ one adapter.yaml

A new harness never touches `core/`. Minimum viable adapter = one file binding all seven
primitives. The Codex stub (`adapters/codex/adapter.yaml`) is the living example — copy
it and rename. Steal shamelessly. 🦝

## 🪢 Step 1 — bind the seven primitives

For each primitive in `core/capability-manifest.yaml`, decide:

| Primitive | Ask yourself | Native binding | Else (degraded) |
|---|---|---|---|
| `dispatch_agent` | Can it run an isolated sub-context and return text? | name the feature, set `concurrency: parallel` if true | inline + sequential |
| `ask_user` | Is there an options widget? | name it | numbered text prompt (copy `adapters/cursor/prompt-conventions.md`) |
| `persist_state` | Anything beyond a file? | hooks/auto-reload extras | `state.json` in artifact_root, re-read on resume |
| `run_hook` | Can it deterministically intercept tool calls / lifecycle events? | wire hooks | soft self-checks (already in the skills — bind and note `enforcement: soft`) |
| `tool_set` | — | map read/write/exec/search to native names | if no exec: test-runner asks the user to run and paste |
| `command_namespace` | Slash commands / registered prompts? | register `core/commands/lifecycle.md` | invoke by name as a skill/rule |
| `artifact_root` | — | usually `.lifeline/<scope>/` | same |

Set `tier: FULL` only if `dispatch_agent`, `ask_user`, and `run_hook` are all native.
Otherwise `DEGRADED` — which is fine; that's most harnesses. No shame in it. 🤷

## 🎁 Step 2 — optional extras

- **Prompt conventions** — if `ask_user` degrades, ship a `prompt-conventions.md` so
  text gates render consistently (reuse the Cursor one's format and gate stems).
- **Hooks** — if the harness has them, port the three wired in
  `adapters/claude-code/hooks/hooks.json` (pre-commit gate, post-edit warn, session-start
  surfacing). `adapters/cursor/hooks/` shows the same gates ported to a different hook
  schema (stdin JSON in, `permission: deny` out). A statusline badge is a separate
  Claude-Code-only extra (wired via `plugin.json`, not a hook event) — skip it elsewhere.
- **Agent shells** — if `dispatch_agent` is native, write thin shells per role: load the
  core skill + contract, return the payload. ~15 lines each; NEVER methodology. (A shell
  with methodology in it is how the tiers fork — don't be that person.)
  Examples: `adapters/claude-code/agents/`, `adapters/cursor/agents/`.

## ✅ Step 3 — verify

1. **Static:** every manifest primitive appears in your `bindings:`. No core file edited.
2. **Runtime:** run one small task through `lifecycle.md` end to end. It must COMPLETE
   (acceptance criterion 3 — degrade, never block) and produce the full artifact set
   including reviewer_doc.md + qa_doc.md.
3. **Differential (gold standard):** same task on Claude Code; diff the artifact sets.
   Divergence allowed only in enforcement and concurrency. See `docs/PORTABILITY.md`.
