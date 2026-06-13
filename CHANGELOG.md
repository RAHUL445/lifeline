# Changelog

All notable changes to lifeline are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning is [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_Nothing yet._

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

[Unreleased]: https://github.com/RAHUL445/lifeline/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/RAHUL445/lifeline/releases/tag/v0.5.0
