---
name: writing-lifeline-skills
description: Use when authoring or extending lifeline itself - adding a skill, a contract, or an adapter. The portability rules that keep core/ runnable on every harness.
---

# Writing lifeline skills

The whole architecture rests on one property: **everything under `core/` runs on every
harness unchanged.** Break it in one file and lifeline collapses into per-harness forks.

## The portability rules (non-negotiable for core/)

1. **No harness primitives by name.** Never write `AskUserQuestion`, `subagent`,
   `hooks.json`, `Bash`, or any other harness-specific term in `core/`. Use the
   `@primitive` names from `capability-manifest.yaml`: `@dispatch_agent`, `@ask_user`,
   `@persist_state`, `@run_hook`, `@tool_set`, `@command_namespace`, `@artifact_root`.
   Generic tool verbs (read/write/exec/search) are fine — `@tool_set` maps them.
   (Framework-specific *shell commands* like `pytest --cov` are fine — they depend on
   the target repo, not the harness.)
2. **Every capability use has a degradation story.** If your skill needs a primitive,
   the manifest's degradation must produce an acceptable (if slower/softer) result. If
   it can't degrade, the feature belongs in an adapter's `extras`, not in core.
3. **Knowledge → skill; runtime capability → primitive.** Discipline, checklists,
   processes, schemas: portable markdown. Spawning processes, blocking tool calls,
   rendering widgets, durable state: a primitive, bound per adapter.
4. **Methodology lives exactly once.** Agents (FULL-tier shells under each adapter's
   `agents/` directory) only load a core skill + contract and return the payload. Never
   put methodology in a shell, the command, or an adapter — the command sequences skills;
   it doesn't restate them.

## Adding a skill

1. `core/skills/<name>/SKILL.md` with frontmatter `name` + `description`.
2. The description is the auto-trigger surface — make it keyword-rich: the user phrases
   that should fire it, the situations, the synonyms. Harnesses match on it.
3. Body = the methodology. If the skill delegates, name the role and the contract, and
   say what inline-degraded execution looks like.
4. If it returns a payload, add `core/contracts/<PAYLOAD>.md` and a row to the
   `payload-contracts` table.
5. Run the portability check: search your new files for harness-specific terms
   (rule 1's list). Zero hits allowed. (The only core files permitted to contain those
   terms are `capability-manifest.yaml` — which defines the degradations — and this
   skill, which must quote them to forbid them.)

## Adding a harness

One file: `adapters/<harness>/adapter.yaml` binding all seven primitives (native or
degraded). Optional: prompt conventions, hooks, agent shells. See
`docs/ADDING-A-HARNESS.md`. A stub that binds everything to degradations is legal and
must still complete a cycle — that's acceptance criterion 4.
