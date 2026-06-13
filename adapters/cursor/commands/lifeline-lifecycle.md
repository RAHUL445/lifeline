# lifeline lifecycle

Run the lifeline lifecycle orchestrator.

- Plugin root: `${CURSOR_PLUGIN_ROOT}` — resolve every plugin path from there.
- Read `${CURSOR_PLUGIN_ROOT}/core/commands/lifecycle.md` and execute it with the arguments
  that follow this command (`start | continue | status | abort | debug <description> |
  guide`, flags `--auto`, `--retry-cap=N`). No arguments → `start`.
- Bind every `@primitive` per `${CURSOR_PLUGIN_ROOT}/adapters/cursor/adapter.yaml`
  (subagents for `@dispatch_agent`, the interactive Q&A tool for `@ask_user`, hooks for
  `@run_hook`); use each binding's documented fallback when the native feature is
  unavailable in this session.
- Artifacts live in `.lifeline/<scope>/` in this repository.
