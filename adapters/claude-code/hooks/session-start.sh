#!/usr/bin/env bash
# lifeline @persist_state binding extra (FULL tier): SessionStart hook.
# Two jobs:
#   1. Surface any pending cycle (state.json under .lifeline/<scope>/) so cold resume
#      needs no user memory.
#   2. First contact in a repo (no pending cycle, not welcomed yet): emit a one-time
#      quick-start guide. Marker lives in a per-user cache so a repo never gets a stray
#      .lifeline dir just for opening a session.
# Degraded harnesses rely on the resuming-a-cycle / using-lifeline skills instead.

set -euo pipefail

emit() { # $1 = additionalContext string
  if command -v jq >/dev/null; then
    jq -n --arg c "$1" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
  else
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$1"
  fi
}

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
[[ -z "${REPO_ROOT}" ]] && exit 0

# Resolve artifact_root: repo-root .lifelinerc may relocate it (absolute or repo-relative).
resolve_artifact_root() {
  local rc="${REPO_ROOT}/.lifelinerc" ar=".lifeline"
  if [[ -f "${rc}" ]]; then
    local v
    v=$(grep -E '^artifact_root:' "${rc}" 2>/dev/null | head -1 \
      | sed -E 's/^artifact_root:[[:space:]]*//; s/[[:space:]]*#.*$//; s/^["'\'']//; s/["'\'']$//')
    [[ -n "${v}" ]] && ar="${v}"
  fi
  case "${ar}" in
    /*) printf '%s' "${ar}" ;;
    *)  printf '%s/%s' "${REPO_ROOT}" "${ar}" ;;
  esac
}
LIFELINE_DIR="$(resolve_artifact_root)"

ACTIVE_SCOPES=()
if [[ -d "${LIFELINE_DIR}" ]]; then
  while IFS= read -r state_file; do
    scope_name=$(basename "$(dirname "${state_file}")")
    phase="unknown"
    if command -v jq >/dev/null; then
      phase=$(jq -r '.phase // "unknown"' "${state_file}" 2>/dev/null || echo "unknown")
    fi
    ACTIVE_SCOPES+=("${scope_name}:${phase}")
  done < <(find "${LIFELINE_DIR}" -maxdepth 2 -name 'state.json' -type f 2>/dev/null)
fi

# 1. Pending cycle wins — always surface it (every session, no marker).
if [[ ${#ACTIVE_SCOPES[@]} -gt 0 ]]; then
  emit "lifeline: active cycle(s) pending — ${ACTIVE_SCOPES[*]}. Run /lifeline:lifecycle continue to resume, or /lifeline:lifecycle status for details."
  exit 0
fi

# 2. No pending cycle: one-time quick-start guide, keyed per repo in a user cache.
CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/lifeline/welcomed"
REPO_KEY=$(printf '%s' "${REPO_ROOT}" | cksum | cut -d' ' -f1)
MARKER="${CACHE_DIR}/${REPO_KEY}"
[[ -f "${MARKER}" ]] && exit 0
mkdir -p "${CACHE_DIR}" 2>/dev/null && : > "${MARKER}" 2>/dev/null || exit 0

emit "lifeline ready in this repo. Auditable, coverage-honest lifecycle: spec → plan → build → review → test → merge (+ debug lane). Start the orchestrated cycle with /lifeline:lifecycle start, or just say what you're doing (\"let's build X\", \"review this\", \"bug: …\") to fire the matching skill ambiently. Resume anytime with /lifeline:lifecycle continue. Full map: /lifeline:lifecycle guide."
exit 0
