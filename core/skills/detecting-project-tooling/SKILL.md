---
name: detecting-project-tooling
description: Use at lifeline setup, or when asked "what lint/test commands will lifeline run", "detect my project tooling", "configure lint for this repo". Inspects the repo's OWN config to propose the user's lint/test/coverage commands instead of imposing built-in tool choices.
---

# Detecting project tooling

Lifeline does not pick linters or test runners. It **detects what the project already
uses, proposes it, and runs the user's own commands.** This skill is the detect-and-propose
half; the wizard confirms with the user and persists to `.lifelinerc`, and the orchestrator
flattens the lint commands to `.lifeline/lint.map` for the pre-commit hook.

Nothing detected here runs until the user confirms it (the trust gate — an auto-read
`package.json` script is untrusted shell until approved).

## What to read (read-only; presence + parse)

| Signal | Look for | Yields |
|---|---|---|
| Node | `package.json` → `scripts` (`lint`, `lint:*`, `test`, `coverage`, `test:cov`) | lint/test/coverage cmds (`npm run <script>`) |
| Node monorepo | `workspaces` in `package.json`, `pnpm-workspace.yaml`, `nx.json`, `turbo.json`, `lerna.json` | per-package paths |
| Make/just | `Makefile` / `justfile` → `lint`, `test` targets | `make lint` / `just test` |
| Python | `pyproject.toml` / `setup.cfg` / `tox.ini` → `[tool.ruff|black|flake8|pytest]` | the configured linter + `pytest` |
| Ruby | `.rubocop.yml`, `Gemfile` (rubocop/rspec) | `rubocop {file}`, `rspec` |
| Rust | `Cargo.toml` (+ `[workspace]` for monorepo) | `cargo clippy`, `cargo test` |
| Go | `go.mod`, `go.work` (monorepo) | `go test ./...`; golangci-lint if `.golangci.yml` |
| pre-commit | `.pre-commit-config.yaml` → hook ids | the declared linters |

Best-effort. If a language shows no config, propose the built-in fallback **only if its
tool is installed**, else leave it unset with a loud note. Never invent a tool the project
shows no sign of.

## How to propose

Produce an ordered `lint:` and `test:` list (the `.lifelinerc` schema). The two have
DIFFERENT matching rules — get them right:

- **`lint` chains.** A changed file's scope = its first (most-specific) matching glob; then
  EVERY `lint` entry sharing that exact glob runs. So a project with three linters on Go
  files (gofmt, govet, gosec) is three entries under one identical `**/*.go` glob — all run.
- **`test` is first-match-wins.** One coverage tool per package; the first matching entry
  wins, the rest are skipped.

Order specific package paths before generic extensions in both.

```yaml
lint:
  - match: "**/*.go"             # one scope, three linters → all three run (chaining)
    cmd: "make gofmt"
  - match: "**/*.go"
    cmd: "make govet"
  - match: "**/*.go"
    cmd: "make gosec"
  - match: "services/api/**"     # more-specific scope → a file here picks THIS, not **/*.go
    cmd: "golangci-lint run {file}"
  - match: "**/*.ts"
    cmd: "eslint {file}"         # {file} present → run per changed file (scoped)
test:
  - match: "services/api/**"
    cmd: "go test ./..."
    coverage: "go test -coverprofile=/tmp/ll ./... && go tool cover -func=/tmp/ll"
  - match: "**"
    cmd: "npm test"
    coverage: "npm test -- --coverage"   # no {file} → whole-project, run once
```

- `{file}` in `cmd` → per-changed-file execution (scoped, fast). Absent → whole-project
  entrypoint (`npm run lint`), run once when ≥1 changed file matches.
- `{module}` in a coverage cmd → substituted with the changed module/path where the
  framework needs it (e.g. Python `--cov=`).
- **Monorepo with per-package tooling** → emit a per-package path-prefix `match`
  (`serviceA/**`) for each package whose lint/test commands differ, NOT one repo-wide
  `**/*.ext`. A repo-wide glob collapses every package onto the same command — only correct
  when one root config (a single root `Makefile`, one `.golangci.yml`) genuinely governs all
  packages. When a package has its own `Makefile`/config, give it its own scope. No separate
  `packages:` block — a path glob IS the per-package scope.
- **Two grouping contracts you MUST honor:** (1) entries meant to chain share a
  BYTE-IDENTICAL glob string (`serviceA/**` ≠ `serviceA/**/`); (2) most-specific scope wins
  with NO inheritance — a file gets its scope's commands only, so if a specific package
  should also run a shared linter, repeat that command under the package's glob.

## Glob subset (bounded — same set the hook and grouping honor)

Support EXACTLY: `**` (everything), `dir/**` (path prefix), `**/*.ext` (extension anywhere),
`*.ext` (extension at repo root). No brace expansion, no `?`. Propose only these; anything
fancier is a config error `adapter-doctor` will flag.

## Output

Hand the wizard the proposed `lint:`/`test:` lists plus a one-line provenance per entry
("from package.json scripts.lint", "Cargo.toml workspace member", "built-in fallback —
ruff installed"). The wizard shows them, the user confirms/edits, and the confirmed set is
written to `.lifelinerc`. Detection that found nothing must say so loudly, not silently
emit an empty config.
