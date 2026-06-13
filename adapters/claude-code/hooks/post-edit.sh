#!/usr/bin/env bash
# lifeline @run_hook binding (FULL tier): PostToolUse hook on Write|Edit.
# Warns when the uncommitted diff exceeds the configured added-lines threshold.
# Degraded harnesses replace this with the self-check in implementing-task.

set -euo pipefail

INPUT=$(cat)

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
[[ -z "${REPO_ROOT}" ]] && exit 0

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [[ ! "${BRANCH}" =~ ^lifeline/ ]]; then
  exit 0
fi

# Threshold from core config (default 500)
THRESHOLD=500
CONFIG="${CLAUDE_PLUGIN_ROOT:-}/core/config/defaults.yaml"
if [[ -f "${CONFIG}" ]]; then
  PARSED=$(grep -E '^diff_size_warn:' "${CONFIG}" | grep -oE '[0-9]+' || true)
  [[ -n "${PARSED}" ]] && THRESHOLD="${PARSED}"
fi

ADDED=$(git diff --stat HEAD 2>/dev/null | tail -1 | grep -oE '[0-9]+ insertions' | grep -oE '[0-9]+' || echo 0)

if [[ ${ADDED:-0} -gt ${THRESHOLD} ]]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "lifeline warning: uncommitted diff has ${ADDED} added lines (threshold ${THRESHOLD}). Consider splitting the task."
  }
}
EOF
fi

exit 0
