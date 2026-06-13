# 🔌 Portability — tiers, bindings, and the one forced tradeoff

## 🎯 The tradeoff, up front

> **Degraded harnesses keep 100% of the methodology and artifacts but lose hard-gate
> enforcement (→ mandatory in-skill self-checks) and parallel wave execution
> (→ sequential). Identical *discipline*, adapted *enforcement & concurrency*.**

That's the entire cost of portability — and it only applies where a harness genuinely
lacks the feature. Claude Code and Cursor (≥ 2.4) both run at FULL tier: hooks
physically block a bad commit and waves run as parallel isolated agents. The degraded
path is the documented fallback — the codex stub, pre-2.4 Cursor, headless/`--print`
sessions, or any new harness bound straight to the manifest degradations. A cycle on any
of them still produces the same artifact set with semantically equivalent content —
spec, plan, task log, reviews, test results with coverage blocks, flow log, changelog,
reviewer doc, QA doc; the orchestrator just runs the gate checks on itself before acting,
one task at a time.

We market discipline, not universal enforcement. Where the harness has hard gates we
bind them; where it doesn't, the cycle completes anyway. **Degrade, never block.** 🛟

## 📊 Tier matrix

| Primitive | Claude Code (FULL) | Cursor ≥ 2.4 (FULL) | Fallback / codex stub (DEGRADED) |
|---|---|---|---|
| `dispatch_agent` | named subagents, parallel per wave | subagents (`.cursor/agents/`), parallel per wave | inline role-skill, sequential |
| `ask_user` | AskUserQuestion widget | interactive Q&A tool | numbered text prompt |
| `persist_state` | state.json + SessionStart auto-surface | state.json + sessionStart hook auto-surface | state.json, re-read on "resume" |
| `run_hook` | real hooks: pre-commit block, post-edit warn, statusline | `.cursor/hooks.json`: pre-commit **deny**, session-start surface, diff-size log (no statusline) | soft in-skill self-checks (logged advisory) |
| `tool_set` | Read/Edit/Bash/Glob/Grep | Cursor read/edit/run/search | harness natives |
| `command_namespace` | `/lifeline:lifecycle` | `/lifeline-lifecycle` (`.cursor/commands/`) | skill invoked by name |
| `artifact_root` | `.lifeline/<scope>/` (worktree-aware) | `.lifeline/<scope>/` | `.lifeline/<scope>/` |

Per-primitive fallbacks live in each `adapter.yaml` (`fallback:` blocks) — a FULL
binding silently degrades to its fallback when the feature is absent in a given session
(e.g. Cursor `--print` has no Q&A tool → numbered text prompt). No drama, no crash.

The startup wizard's **isolation** choice is portable — every tier offers `new branch`
and `current branch`; the `git worktree` option appears only where the adapter advertises
`extras.worktree_isolation` (Claude Code today). The statusline badge stays a
Claude-Code-only extra and never becomes a portable claim.

**Concurrency is also a deliberate knob, not only a tier consequence.** The config
`dispatch_mode` (`auto` | `agent` | `inline`) lets a FULL-tier user *choose* inline
execution — the same warm-context path a degraded harness is forced onto — because
isolated-agent dispatch pays a cold-start cost (re-read skill + contract + files) that
isn't worth it for single-task or trivial/small waves. `auto` (default) picks per
dispatch: a subagent for parallel multi-task waves and large effort, inline otherwise. The choice
changes only latency, token cost, and concurrency — never the methodology or the
artifact set. flow.md records `mode=` and `secs=` per dispatch so the tradeoff is
measurable, not guessed.

## 🛡️ What never degrades

These are pure markdown + artifact mechanics, identical on every tier — no take-backs:

- **Coverage→smoke seeding** — the GAP lines and the smoke checklist are artifact
  content, not capabilities.
- **Handoff docs** — REVIEWER_DOC + QA_DOC are compiled from artifacts.
- **Payload contracts & mandatory writes** — the audit trail (flow.md, changelog.md,
  override audit) is orchestrator behavior, not harness behavior.
- **The methodology itself** — every skill body, checklist, and forbidden-pattern list.

## ✅ Differential verification

The portability claim is testable (acceptance criteria, PRD §15): run one canonical task
through `lifecycle.md` on two harnesses against clean copies of the same repo. PASS =
identical artifact set, semantically equivalent content; divergence permitted ONLY in
enforcement (hard vs soft) and concurrency (parallel vs sequential). A deliberately
over-mocked handler must surface the same coverage-GAP line in both runs' smoke
checklists and QA docs. The capability-absence criterion (§15.3) now runs against the
fallback path — e.g. a headless Cursor session or the codex stub — and must still
complete the cycle.

Cross-harness runtime verification requires live sessions on each harness — it is the
M0 exit gate, run by a human, not something the repo can self-test. (Robots can't grade
their own homework. 🤖)
