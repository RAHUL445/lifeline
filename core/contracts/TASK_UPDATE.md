# Contract: TASK_UPDATE

Returned by the **implementer** role (skill: `implementing-task`), one per task. The
orchestrator parses it and appends a formatted section to `task.md` — the role NEVER
writes task.md itself.

## Payload

```
TASK_UPDATE:
- task_id: <id>
- started: <ISO timestamp>
- approach: <name>
- files_changed:
  - "+ path/to/new.py"
  - "~ path/to/modified.go"
  - "- path/to/deleted.php"
- notes: |
    <key decisions, edge cases, open issues>
- status: code-complete | blocked
- blockers: <none | description>
```

## Rules

- `files_changed` prefixes: `+` added, `~` modified, `-` deleted. Paths relative to the
  code root (worktree on FULL tier, repo on degraded).
- `blockers` other than `none` must be surfaced to the user immediately — the wave does
  not advance to testing with an unresolved blocker.
- The orchestrator MUST write the task.md section before dispatching the test run
  (mandatory-writes invariant — see `payload-contracts`).
