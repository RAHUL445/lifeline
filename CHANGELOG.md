# Changelog

All notable changes to lifeline are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning is [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_Nothing yet._

## [1.2.0] — 2026-06-14

### Added

- **User-defined lint & test commands.** Lifeline no longer imposes a fixed tool map. The
  setup wizard runs a new `detecting-project-tooling` skill that inspects the repo's OWN
  config (package.json scripts, Makefile, pyproject, Cargo.toml, monorepo workspaces, …),
  proposes the commands it found, and — after the user confirms — stores them as ordered
  `lint:`/`test:` lists in `.lifelinerc`. A path-prefix `match` is per-package, so
  **monorepos with different languages per package** get the right command for each. A
  `{file}` token runs the command per changed file (scoped); its absence means a
  whole-project entrypoint (`npm run lint`) run once. The built-in tool map is now a
  last-resort fallback only.
- **`lifecycle setup`** — a dedicated, cycle-free front door that configures a project
  once: runs the setup wizard (including the new tooling detection) and writes
  `.lifelinerc` + `lint.map`, then stops without starting a cycle. Skips the per-cycle
  scope question; re-run it any time the project's tooling changes. `start` still
  self-configures inline when `setup` was never run (and now prints a one-line tip
  pointing at it), so the zero-config path is unchanged.
- `adapter-doctor` now reports configured `lint:`/`test:` commands and whether each
  command's binary is installed.

### Changed

- The pre-commit `@run_hook` (both adapters) reads a flattened `<artifact_root>/lint.map`
  instead of a hardcoded extension switch — no YAML parsing in bash. Skips are now **loud**
  (stderr + `flow.md`), never silent: a missing binary or an unconfigured extension is
  reported, not swallowed. `coverage-to-smoke` reads `test:` first and groups changed files
  by package for per-package coverage runs.

### Fixed

- **Chained linters silently dropped.** The pre-commit hook matched a changed file against
  `lint.map` first-match-wins and stopped, so a file type with several linters (e.g. Go with
  `make gofmt` + `make govet` + `make gosec`, all under `**/*.go`) ran only the first — the
  rest never executed and nothing said so. The hook now resolves a file's *scope* (its first,
  most-specific matching glob) and then runs EVERY command sharing that exact glob, so all
  linters in a scope chain. A more-specific scope (`serviceA/**`) still shadows a general one
  (`**/*.go`) with no inheritance. `test` stays first-match-wins (one coverage tool per
  package). `detecting-project-tooling` now emits per-package globs when packages have their
  own config instead of one repo-wide extension glob.
- **ESLint flat-config silent skip.** The pre-commit hook gated lint on a `.eslintrc*` glob,
  so repos using flat config (`eslint.config.js`) were skipped even with ESLint installed.
  The fallback path now runs `eslint {file}` and lets the tool resolve its own config.

## [1.1.0] — 2026-06-14

### Added

- **`lifecycle doctor`** — a read-only adapter health check (new portable `adapter-doctor`
  skill). Reports which of the 7 manifest primitives are bound / degraded / missing, and
  whether the adapter's declared agent, hook, and command files actually exist — without
  running a cycle. Catches "adapter.yaml says native but the backing file is gone" before
  it surfaces mid-run.

### Changed

- **Setup wizard now asks once.** A complete `.lifelinerc` skips the wizard entirely on
  later cycles (only per-cycle scope is asked) instead of prompting "use last settings?"
  every run. An incomplete `.lifelinerc` re-asks only the missing keys; `--reconfigure`
  forces the full wizard with current values as defaults. New `schema_version` key lets a
  future required-key addition re-ask only the new keys.

## [1.0.0] — 2026-06-14

Stable release — public surface (install commands, `/lifeline:lifecycle` interface,
`.lifelinerc` knobs) is now a committed contract under semver. 🪢

### Added

- **Demo** — `docs/demo-4x.gif`, a real Claude Code lifeline cycle recorded live with
  asciinema, embedded in the README.

### Changed

- Promoted from `0.x` (pre-stable) to `1.0.0`. No behavioral change from `0.5.0`; this
  release declares the public interface stable.

## [0.5.0] — 2026-06-13

First public release. 🪢

### Added

- **Full gated dev lifecycle** — spec → plan → build → review → test → merge, each phase
  producing a durable artifact (`spec.md`, `plan.md`, `task.md`, `review.md`,
  `test_result.md`, `reviewer_doc.md`, `qa_doc.md`).
- **Debug lane** — reproduce → RCA → fix → verify, with the reproduction confirmed before
  any fix.
- **Coverage → smoke seeding** — changed-file coverage measured each cycle; every gap
  becomes a line in a human smoke checklist at merge (advisory, never silent).
- **Reviewer + QA handoff docs** — `reviewer_doc.md` (code-visible) and `qa_doc.md`
  (blackbox) emitted at merge.
- **Auditable trail** — append-only `flow.md` records every gate, retry, verdict, and
  override; overrides resurface at the merge gate.
- **Two entry paths, one methodology** — ambient (skills auto-trigger on intent) and
  orchestrated (`/lifeline:lifecycle` with persisted state + cold resume).
- **Portable core** — 13 skills, the lifecycle command, payload contracts, and templates
  as pure markdown speaking 7 abstract primitives; zero harness names in `core/`.
- **Adapters** — Claude Code (FULL, plugin), Cursor (FULL, ≥ 2.4: parallel subagents,
  native Q&A, hard hook gates), and a one-file Codex stub as the degraded-tier proof.
- **Config surface** — `core/config/defaults.yaml` with per-repo `.lifelinerc` and
  per-invocation flag overrides (see `docs/CONFIGURATION.md`).
- **Docs** — Getting Started, Configuration, FAQ, Architecture, Portability,
  Adding-a-harness, plus the methodology master index.

[Unreleased]: https://github.com/RAHUL445/lifeline/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/RAHUL445/lifeline/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/RAHUL445/lifeline/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/RAHUL445/lifeline/compare/v0.5.0...v1.0.0
[0.5.0]: https://github.com/RAHUL445/lifeline/releases/tag/v0.5.0
