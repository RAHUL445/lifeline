#!/usr/bin/env bash
# lifeline @run_hook binding (Cursor FULL tier): afterFileEdit hook.
# Logs a warning when the uncommitted diff exceeds the added-lines threshold.
# Cursor's afterFileEdit is informational-only (no agent/user message channel), so this
# appends to .lifeline/hook-warnings.log; the agent-facing reminder remains the
# self-check in implementing-task.

set -euo pipefail

cat >/dev/null || true

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
[[ -z "${REPO_ROOT}" ]] && exit 0

BRANCH=$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [[ ! "${BRANCH}" =~ ^lifeline/ ]]; then
  exit 0
fi

# Threshold from core config (default 500), via the plugin root Cursor exports to hooks.
THRESHOLD=500
PLUGIN_ROOT="${CURSOR_PLUGIN_ROOT:-}"
CONFIG="${PLUGIN_ROOT}/core/config/defaults.yaml"
if [[ -n "${PLUGIN_ROOT}" && -f "${CONFIG}" ]]; then
  PARSED=$(grep -E '^diff_size_warn:' "${CONFIG}" | grep -oE '[0-9]+' || true)
  [[ -n "${PARSED}" ]] && THRESHOLD="${PARSED}"
fi

ADDED=$(git -C "${REPO_ROOT}" diff --stat HEAD 2>/dev/null | tail -1 | grep -oE '[0-9]+ insertions' | grep -oE '[0-9]+' || echo 0)

if [[ ${ADDED:-0} -gt ${THRESHOLD} ]]; then
  # Resolve artifact_root: repo-root .lifelinerc may relocate it (absolute or repo-relative).
  LIFELINE_DIR="${REPO_ROOT}/.lifeline"
  if [[ -f "${REPO_ROOT}/.lifelinerc" ]]; then
    AR=$(grep -E '^artifact_root:' "${REPO_ROOT}/.lifelinerc" 2>/dev/null | head -1 \
      | sed -E 's/^artifact_root:[[:space:]]*//; s/[[:space:]]*#.*$//; s/^["'\'']//; s/["'\'']$//')
    if [[ -n "${AR}" ]]; then
      case "${AR}" in /*) LIFELINE_DIR="${AR}" ;; *) LIFELINE_DIR="${REPO_ROOT}/${AR}" ;; esac
    fi
  fi
  mkdir -p "${LIFELINE_DIR}"
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] diff-size warn: ${ADDED} added lines (threshold ${THRESHOLD}) on ${BRANCH}" \
    >> "${LIFELINE_DIR}/hook-warnings.log"
fi

exit 0
