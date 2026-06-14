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
| `.lifelinerc` (repo root) | Per-project | The setup wizard (`lifecycle setup`, or inline on first `start`) |
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

## 🧹 lint / test — your project's OWN commands

lifeline never imposes a linter or test runner. The setup wizard runs
`detecting-project-tooling`, which reads your repo's own config (package.json scripts,
Makefile, pyproject, Cargo, go.mod, monorepo workspaces, …), proposes the commands it
found, and — after you confirm — writes them to `.lifelinerc` as ordered `lint:`/`test:`
lists. Nothing detected runs until you confirm it (the trust gate for the hard pre-commit
hook). The built-in extension map is a **last-resort fallback**, used only when nothing is
configured *and* the tool happens to be installed (with a loud warning either way).

```yaml
lint:                         # a changed file's SCOPE = its first matching glob;
  - match: "**/*.go"          # then EVERY entry under that exact glob runs → linters CHAIN
    cmd: "make gofmt"
  - match: "**/*.go"
    cmd: "make govet"
  - match: "services/api/**"  # a more-specific scope SHADOWS the catch-all (no inheritance)
    cmd: "golangci-lint run {file}"
test:                         # test is FIRST-MATCH-WINS (one coverage tool per package)
  - match: "services/api/**"
    cmd: "go test ./..."
    coverage: "go test -coverprofile=/tmp/ll ./... && go tool cover -func=/tmp/ll"
  - match: "**"
    cmd: "npm test"
    coverage: "npm test -- --coverage"
```

| Concept | Meaning |
|---|---|
| `match` glob | Bounded subset: `**`, `dir/**`, `**/*.ext`, `*.ext`. A `dir/**` prefix is the per-package (monorepo) scope. Anything fancier is a config error `lifecycle doctor` flags. |
| `{file}` in `cmd` | Run the command **per changed file** (scoped, fast). Absent → a whole-project entrypoint (`npm run lint`), run once when ≥1 changed file matches. |
| `{module}` in `coverage` | Substituted with the changed module/path where the framework needs it (e.g. Python `--cov=`). |
| **lint chains** | All `lint:` entries sharing a byte-identical glob run on a matching file — so gofmt + govet + gosec all execute. |
| **test first-match** | Only the first matching `test:` entry runs (you don't chain coverage tools). |

The orchestrator flattens `lint:` into `<artifact_root>/lint.map` (`glob<TAB>cmd`) so the
bash pre-commit hook reads it without a YAML parser; it's regenerated on every `start` and
`--reconfigure`. Skips (missing binary, unconfigured extension) are **loud** — stderr +
`flow.md` — never silent. Re-run `lifecycle setup` whenever your project's tooling changes.

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

For anything persistent, let the **setup wizard** write `.lifelinerc` — run `lifecycle
setup` (or just `start`, which configures inline the first time). It asks for artifact
location, scope defaults, isolation, autonomy, the advanced knobs, and your project's
`lint`/`test` commands; once complete, later cycles skip it (only scope is asked).
Hand-editing `.lifelinerc` works too; it's just YAML with the same keys as above.

---

See also: **[FAQ → Configuration](FAQ.md#-configuration)** for the common questions, and
**[Architecture](ARCHITECTURE.md)** for where config sits in the system.
