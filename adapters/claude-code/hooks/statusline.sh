#!/usr/bin/env bash
# lifeline @run_hook binding (FULL tier): statusline badge.
# Shows [ll: <scope> · <phase>] while a cycle is active. Clears when state.json is removed.

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
[[ -z "${REPO_ROOT}" ]] && exit 0

# Resolve artifact_root: repo-root .lifelinerc may relocate it (absolute or repo-relative).
LIFELINE_DIR="${REPO_ROOT}/.lifeline"
if [[ -f "${REPO_ROOT}/.lifelinerc" ]]; then
  AR=$(grep -E '^artifact_root:' "${REPO_ROOT}/.lifelinerc" 2>/dev/null | head -1 \
    | sed -E 's/^artifact_root:[[:space:]]*//; s/[[:space:]]*#.*$//; s/^["'\'']//; s/["'\'']$//')
  if [[ -n "${AR}" ]]; then
    case "${AR}" in /*) LIFELINE_DIR="${AR}" ;; *) LIFELINE_DIR="${REPO_ROOT}/${AR}" ;; esac
  fi
fi
[[ ! -d "${LIFELINE_DIR}" ]] && exit 0

STATE=$(find "${LIFELINE_DIR}" -maxdepth 2 -name 'state.json' -type f 2>/dev/null | head -1)
[[ -z "${STATE}" ]] && exit 0

SCOPE=$(basename "$(dirname "${STATE}")")
PHASE="?"
if command -v jq >/dev/null; then
  PHASE=$(jq -r '.phase // "?"' "${STATE}" 2>/dev/null || echo "?")
fi

printf '[ll: %s · %s]' "${SCOPE}" "${PHASE}"
