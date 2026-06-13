# ❓ FAQ

Common questions, troubleshooting, and the differences between harnesses. New here? Start
with [GETTING-STARTED](GETTING-STARTED.md).

---

## 🌐 General

### What is lifeline, in one sentence?
A portable, auditable development lifecycle — spec → plan → build → review → test → merge,
plus a debug lane — that runs on any harness with an adapter and produces the same
artifacts and reviewer/QA handoff docs everywhere.

### How is it different from just asking the agent to "build a feature"?
Three things you don't get from an ad-hoc prompt:
1. **Coverage→smoke seeding.** Passing tests aren't proof — code can be over-mocked so the
   real path never runs. lifeline measures coverage on your *changed* files and turns each
   gap into a line on a human smoke checklist. Advisory, never blocking, but never silent.
2. **Reviewer + QA handoff docs.** Merge emits a code-visible reviewer doc and a blackbox
   QA doc, both compiled from the cycle's artifacts.
3. **An auditable trail.** Every gate, retry, verdict, and override is recorded in an
   append-only `flow.md`; overrides resurface at merge.

### Do I have to use the command? 
Nope. 🙅 The skills auto-trigger on intent ("let's build…", "review this", "bug…") — that's
*ambient* mode, and each skill works standalone. The `/lifeline:lifecycle` command is the
*orchestrated* path that sequences the same skills with gates, persisted state, and the
full artifact trail. Same logic underneath either way.

### Is it language- or framework-specific?
No. The methodology core is markdown and tool-agnostic. Coverage measurement uses
whatever your project already has; lifeline reads the result rather than imposing a
runner. Bring your own stack. 🥡

---

## 🎚️ Tiers & harnesses

### What's the difference between FULL and DEGRADED tier?
Same methodology, same artifacts on both. The only differences:

| | FULL (Claude Code, Cursor ≥ 2.4) | DEGRADED (headless, pre-2.4 Cursor, codex stub) |
|---|---|---|
| Gates | hard hook enforcement (e.g. commit physically blocked) | mandatory in-skill self-checks, logged advisory |
| Waves | parallel isolated role dispatch | sequential |
| Questions | native widget / Q&A tool | numbered text prompt |

That's the *entire* tradeoff. A cycle completes on every tier. See [PORTABILITY](PORTABILITY.md).

### Which harnesses are supported today?
- **Claude Code** — FULL tier (plugin install).
- **Cursor ≥ 2.5** — FULL tier, installed from the plugin marketplace (import this repo).
- **Cursor without the plugin system / headless `--print`** — DEGRADED fallback, automatic.
- **codex** — a one-file stub, kept as the degraded-tier reference.
- **Any other harness** — write one `adapter.yaml`; see [ADDING-A-HARNESS](ADDING-A-HARNESS.md).

### How does a session "know" which tier it's on?
Each binding in the adapter has a `fallback:` block. A FULL binding silently degrades to
its fallback when the feature is absent in that session — e.g. a Cursor `--print` run has
no Q&A tool, so gates fall back to numbered text prompts automatically. No toggle, no
ceremony. 🪄

---

## ⚙️ Configuration

> Common questions below. For the **complete knob-by-knob reference** (every key in
> `core/config/defaults.yaml`, override precedence, examples), see
> **[Configuration](CONFIGURATION.md)**. 🎛️

### What is `dispatch_mode`?
How roles execute: `auto` (default) | `agent` | `inline`.
- **`agent`** — each role runs in an isolated context (parallel where the adapter
  supports it). Wins on parallel multi-task waves and large-effort tasks (context stays
  clean), but each dispatch pays a cold-start cost: re-reading the skill, contract, and
  files.
- **`inline`** — the role's skill runs in the current warm context. No cold-start;
  cheaper and faster for single-task, trivial/small, or sequential work. A first-class
  choice, not just a degradation.
- **`auto`** — decides per dispatch: `agent` when a wave has ≥ 2 independent tasks or the
  effort is large; `inline` otherwise.

It changes only latency, token cost, and concurrency — never the methodology or the
artifacts. `flow.md` records `mode=` and `secs=` per dispatch so you can measure the
tradeoff instead of guessing. On a degraded tier it's a no-op (always inline).

### What's `.lifelinerc`?
A repo-root YAML file the wizard writes with your choices (artifact location, scope
defaults, isolation, autonomy, advanced settings). The next cycle offers "use last
settings?". It's committed when the artifact path is relative (shareable) and gitignored
when it's an absolute path (machine-specific, nobody else cares about your `/Users/you/...`).

### Where do artifacts go, and can I keep them out of git?
Default: `.lifeline/<scope>/` at the repo root. The wizard lets you relocate them to an
absolute path elsewhere, and choose commit vs gitignore for in-repo storage. The shipped
`.gitignore` already excludes `.lifeline/` by default.

### Can I run unattended?
Yes — choose *auto* autonomy (or pass `--auto`). It runs through phases, stopping only on
a hard gate or a genuinely blocking question. `--retry-cap=N` bounds retries. Go get
coffee. ☕

---

## 🔬 Review & coverage

### Why only one review per task?
Because more knobs invite drift. lifeline does exactly one review per task, always all
four lenses (logic, architecture, security, performance), with depth scaled to the task's
effort label — a trivial task gets a light pass, a large task gets a deep design-level
review. No reviewer-mode settings to tune.

### Why advisory coverage instead of a hard threshold?
Line coverage can't see over-mocking — a handler can show 100% covered while its real
side effect is mocked away. A hard threshold creates false confidence. 🎭 lifeline surfaces
each changed-file gap and routes it to a human smoke checklist and the QA doc instead, so
the gap is exercised by a person, not rubber-stamped by a number.

### What if I disagree with a gate?
Override it. Overrides are legal and expected — but they're logged to `flow.md`,
resurface at the merge gate, and appear in the reviewer doc's override audit. Visible, not
blocked. (We remember, but we don't nag.)

---

## 🔧 Troubleshooting

### The slash command doesn't autocomplete.
- **Claude Code:** confirm the plugin installed (`/plugin`) and try `/lifeline:lifecycle
  guide`. Reinstall with the two `/plugin` commands if needed.
- **Cursor:** confirm the lifeline plugin is installed (Settings › Plugins) and the
  marketplace re-indexed your latest push; the `/lifeline-lifecycle` command comes from the
  plugin. As a fallback, say "run the lifeline lifecycle start" — it's also available as a
  skill by name.

### "cycle pending" never surfaces on resume.
That auto-surfacing is the session-start hook (FULL tier). On a degraded tier just run
`/lifeline:lifecycle continue` (or `status`) — state is always in
`.lifeline/<scope>/state.json` regardless of tier.

### A commit was blocked by the pre-commit hook.
Working as designed on FULL tier: the hook scans for secrets and lints on `lifeline/*`
branches. Fix the flagged content. (The gate is intentional — it is not a bug. It just
saved you from committing that API key. 🔐)

### Gates show as plain numbered text instead of a widget.
You're on a fallback path (headless `--print` or pre-2.4 Cursor). The numbered-text prompt
is the documented `ask_user` fallback — methodology and artifacts are unchanged. Less
shiny, same brain.

### Roles run one at a time even though I expected parallel.
Check `dispatch_mode` and the wave: `auto` only dispatches in parallel when a wave has
≥ 2 independent tasks. Single-task waves run inline by design. On a degraded tier all
waves are sequential regardless.

### I want to start over.
`/lifeline:lifecycle abort` stops the cycle cleanly. Delete `.lifeline/<scope>/` to remove
its artifacts, then `start` again. Fresh slate. 🧹

---

## 📖 More

- Hands-on walkthrough → [GETTING-STARTED](GETTING-STARTED.md)
- Tiers & bindings in depth → [PORTABILITY](PORTABILITY.md)
- Architecture → [ARCHITECTURE](ARCHITECTURE.md)
- Add a harness → [ADDING-A-HARNESS](ADDING-A-HARNESS.md)
