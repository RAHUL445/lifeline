# Contract: REVIEW_FINDINGS

Returned by the **reviewer** role (skill: `four-lens-review`) — exactly ONE review per
task, always covering all four lenses, with depth scaled to task effort. The orchestrator
parses the JSON and appends a review block to `review.md` plus updates the verdict table.

## Payload (JSON, no prose wrapper)

```json
{
  "task_id": "<id>",
  "effort": "trivial | small | medium | large",
  "depth": "light | standard | deep",
  "verdict": "APPROVE | REQUEST_CHANGES",
  "lenses": {
    "logic": {
      "verdict": "APPROVE | REQUEST_CHANGES",
      "findings": [
        {"severity": "blocker|major|minor|nit", "location": "file:line", "issue": "...", "fix": "..."}
      ]
    },
    "architecture": {
      "verdict": "APPROVE | REQUEST_CHANGES",
      "findings": [
        {"severity": "blocker|major|minor|nit", "location": "file:line", "issue": "...", "fix": "..."}
      ]
    },
    "security": {
      "verdict": "APPROVE | REQUEST_CHANGES",
      "findings": [
        {"severity": "critical|high|medium|low|info", "location": "file:line", "issue": "...", "fix": "..."}
      ]
    },
    "performance": {
      "verdict": "APPROVE | REQUEST_CHANGES",
      "findings": [
        {"severity": "critical|major|minor|nit", "location": "file:line", "issue": "...", "fix": "..."}
      ]
    }
  },
  "notes": "<overall>"
}
```

## Verdict rules

Per-lens REQUEST_CHANGES triggers:

| Lens | Blocking severities |
|---|---|
| logic | blocker, major |
| architecture | blocker |
| security | critical, high |
| performance | critical |

Overall verdict: REQUEST_CHANGES if ANY lens requests changes; else APPROVE.

## Depth scaling (effort → depth)

| Effort | Depth | Meaning |
|---|---|---|
| trivial, small | light | One pass per lens over the diff; APPROVE quickly if sound; don't manufacture findings. |
| medium | standard | Per-lens checklists applied to the diff; read surrounding context where the diff touches it. |
| large | deep | Checklists + read the changed files whole; trace data flow across the diff boundary; question the design, not just the lines. |

All four lenses ALWAYS run — depth varies, coverage of lenses does not. A lens that is
genuinely inapplicable (e.g. performance on a doc change) emits empty findings + APPROVE.
