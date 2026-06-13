# ⚙️ Configuration reference

Every knob lifeline reads, where it lives, and what it does. The shipped defaults are
sensible — most people never touch this file. But when you want to bend the workflow,
this is the dial board. 🎛️

## 🧭 Where settings come from (precedence)

Three layers, highest wins:

```
flag  >  .lifelinerc  >  core/config/defaults.yaml
```

| Layer | Scope | Who writes it |
|---|---|---|
| `core/config/defaults.yaml` | Plugin-wide baseline (portable, read on every harness) | Ships with lifeline — don't edit; override below |
| `.lifelinerc` (repo root) | Per-project | The setup wizard, from your answers ("use last settings?") |
| Flags (e.g. `--auto`, `--retry-cap=N`) | One invocation | You, at the command line |

`.lifelinerc` is committed when its `artifact_root` is repo-relative (shareable with the
team) and auto-gitignored when it's an absolute path (machine-specific — nobody else cares
about your `/Users/you/...`). 🔐

> All of this lives in `core/config/defaults.yaml`. It's plain commented YAML — reading
> the file itself is a fine substitute for reading this page. This is just the annotated
> tour. 🗺️

## 🔁 Cycle behavior

| Key | Default | What it does |
|---|---|---|
| `retry_cap` | `3` | Test/review retry attempts per wave before lifeline stops and asks you. Override per run with `--retry-cap=N`. |
| `autonomy` | `gated` | `gated` = pause at spec, plan, and merge. `auto` = pause at merge only (or pass `--auto`). |
| `isolation` | `branch` | Startup-wizard default. `worktree` (FULL tier only) · `branch` (new `lifeline/<scope>` in place) · `current` (no new branch). ⚠️ The hard pre-commit gate keys on the `lifeline/*` branch prefix, so `current` makes that gate inert — the tdd-discipline self-check still runs. |
| `diff_size_warn` | `500` | Added-lines threshold that trips the post-edit "this diff is chunky" reminder / self-check. |
| `artifact_root` | `.lifeline` | Cycle artifacts live at `<artifact_root>/<scope>/`. A repo-root `.lifelinerc` can point this at an in-repo path or an absolute path outside the repo. |

## 🚦 dispatch_mode — the perf/cost dial

`dispatch_mode` (default `auto`) controls *how* roles execute. It changes latency, token
cost, and concurrency — **never** the methodology or the artifacts. Same payloads, same
files, every mode.

| Mode | Behavior | Best for |
|---|---|---|
| `agent` | Isolated context per role (parallel where the adapter supports it). Each dispatch pays a cold-start: re-read skill + contract + files. | Parallel multi-task waves, large-effort tasks (context stays clean). |
| `inline` | Role's skill runs in the current warm context. No cold-start. A first-class choice, not just a degradation. | Single-task / trivial-small / sequential work — cheaper and faster. |
| `auto` | Per dispatch: `agent` when a wave has ≥ 2 independent tasks **or** effort is large; `inline` otherwise. | Letting lifeline decide. (Recommended.) |

`flow.md` records `mode=` and `secs=` per dispatch, so you can *measure* the tradeoff
instead of guessing. On a degraded tier (no native agent) it's always `inline`. 🤷

## 🔎 Review

Single effort-scaled four-lens review — fixed shape, no reviewer-mode toggles (knobs
invite drift).

```yaml
review:
  lenses: [logic, architecture, security, performance]   # always all four
  block_on:
    logic: [blocker, major]
    architecture: [blocker]
    security: [critical, high]
    performance: [critical]
  depth_by_effort:        # see core/contracts/REVIEW_FINDINGS.md
    trivial: light
    small: light
    medium: standard
    large: deep
```

- **`lenses`** — always all four. Not a menu.
- **`block_on`** — which severities, per lens, block the gate. A `security: high` blocks; a
  `performance: high` doesn't (only `critical` does). Tune to taste.
- **`depth_by_effort`** — review depth scales with the task's effort label. A trivial task
  gets a light pass; a large task gets a deep design-level review.

## 🧪 Coverage → smoke

The marquee mechanism (see `core/skills/coverage-to-smoke/SKILL.md`). Passing tests aren't
proof; this turns coverage gaps into a human checklist.

```yaml
coverage_check:
  enabled: true
  min_changed_file_pct: 70
  fail_on_zero: true
  scope: changed_files_only   # never whole-repo

manual_smoke_gate: true
```

| Key | Default | What it does |
|---|---|---|
| `coverage_check.enabled` | `true` | Master switch for the coverage pass. |
| `min_changed_file_pct` | `70` | Advisory floor for changed-file coverage. Below it → flagged, not blocked. |
| `fail_on_zero` | `true` | A changed file with **zero** coverage is the loud case — it always surfaces. |
| `scope` | `changed_files_only` | Coverage is always measured on changed files, never the whole repo. |
| `manual_smoke_gate` | `true` | Human verifies success criteria + GAP paths before merge. The backstop line coverage can't provide. |

## 🤖 Model routing

`@dispatch_agent` emits a `model_hint`; each harness maps the hint to its own model names.
Harnesses without model selection just ignore it.

```yaml
model_routing:
  trivial: small
  small: default
  medium: default
  large: default
```

## ✍️ Commit format

```yaml
commit_format:
  subject_template: "[{scope}] {type}({wave_id}): {subject}"
  include_task_list: true
  include_cycle_id: true
  default_type: feat
  type_map:
    new_feature: feat
    bugfix: fix
    refactor: refactor
    docs: docs
    test: test
    chore: chore
```

- **`subject_template`** — placeholders `{scope}`, `{type}`, `{wave_id}`, `{subject}`.
- **`include_task_list` / `include_cycle_id`** — whether the commit body lists the wave's
  tasks and the cycle id (traceability back to the artifact trail).
- **`type_map`** — maps lifeline's internal change kinds to your commit-type vocabulary.

## 📄 Overriding in practice

```bash
# one-off: run unattended, allow more retries
/lifeline:lifecycle start --auto --retry-cap=5
```

For anything persistent, let the **setup wizard** write `.lifelinerc` — it asks for
artifact location, scope defaults, isolation, autonomy, and the advanced knobs, then
offers "use last settings?" next cycle. Hand-editing `.lifelinerc` works too; it's just
YAML with the same keys as above.

---

See also: **[FAQ → Configuration](FAQ.md#-configuration)** for the common questions, and
**[Architecture](ARCHITECTURE.md)** for where config sits in the system.
