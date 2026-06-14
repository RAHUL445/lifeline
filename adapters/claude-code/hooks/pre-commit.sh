#!/usr/bin/env bash
# lifeline @run_hook binding (FULL tier): PreToolUse hook on Bash.
# Intercepts `git commit` on a lifeline/* branch. Runs secret scan + lint as a hard gate.
# Lint commands are USER-DEFINED: the orchestrator flattens .lifelinerc `lint:` into
# <artifact_root>/lint.map (glob<TAB>cmd) and this hook runs them — no YAML parsing in bash.
# Built-in map is last-resort fallback only. Skips are LOUD (stderr + flow.md), never silent.
# Degraded harnesses replace this with the mandatory self-check in tdd-discipline.

set -euo pipefail

INPUT=$(cat)

CMD=$(echo "${INPUT}" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

if ! echo "${CMD}" | grep -qE '\bgit\s+commit\b'; then
  exit 0
fi

CWD=$(echo "${INPUT}" | jq -r '.tool_input.cwd // empty' 2>/dev/null || pwd)
[[ -z "${CWD}" ]] && CWD=$(pwd)
# symbolic-ref also resolves an unborn branch (first commit of a cycle)
BRANCH=$(git -C "${CWD}" symbolic-ref --short HEAD 2>/dev/null || git -C "${CWD}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [[ ! "${BRANCH}" =~ ^lifeline/ ]]; then
  exit 0
fi

FAILURES=()
WARNS=()
WHOLE_CMDS=()

# --- resolve artifact_root + lint.map ----------------------------------------
ARTIFACT_ROOT=".lifeline"
if [[ -f "${CWD}/.lifelinerc" ]]; then
  RC_AR=$(grep -E '^[[:space:]]*artifact_root:' "${CWD}/.lifelinerc" 2>/dev/null | head -1 \
    | sed -E 's/^[^:]*:[[:space:]]*//; s/[[:space:]]*$//; s/^["'\'']//; s/["'\'']$//' || echo "")
  [[ -n "${RC_AR}" ]] && ARTIFACT_ROOT="${RC_AR}"
fi
case "${ARTIFACT_ROOT}" in
  /*) ARTIFACT_DIR="${ARTIFACT_ROOT}" ;;
  *)  ARTIFACT_DIR="${CWD}/${ARTIFACT_ROOT}" ;;
esac
LINT_MAP="${ARTIFACT_DIR}/lint.map"

# --- glob subset matcher: ** , dir/** , **/*.ext , *.ext ---------------------
glob_match() {
  local f="$1" g="$2" ext prefix
  case "$g" in
    '**')      return 0 ;;
    '**/*.'*)  ext="${g##*.}"; [[ "$f" == *."$ext" ]] && return 0 ;;
    *'/**')    prefix="${g%/**}"; [[ "$f" == "$prefix"/* ]] && return 0 ;;
    '*.'*)     ext="${g#*.}"; [[ "$f" == *."$ext" && "$f" != */* ]] && return 0 ;;
  esac
  return 1
}

# --- apply a resolved command to a file --------------------------------------
remember_whole() {
  local c="$1" x
  for x in "${WHOLE_CMDS[@]:-}"; do [[ "$x" == "$c" ]] && return; done
  WHOLE_CMDS+=("$c")
}

apply_cmd() {
  local f="$1" cmd="$2" bin qf run
  bin="${cmd%% *}"
  if ! command -v "${bin}" >/dev/null 2>&1; then
    WARNS+=("lint skipped: '${bin}' not installed (for ${f})")
    return
  fi
  if [[ "${cmd}" == *'{file}'* ]]; then
    printf -v qf '%q' "${f}"
    run="${cmd//\{file\}/${qf}}"
    (cd "${CWD}" && eval "${run}" >/dev/null 2>&1) || FAILURES+=("lint: ${f} (${bin})")
  else
    remember_whole "${cmd}"   # whole-project entrypoint — run once, after the loop
  fi
}

# --- built-in fallback (last resort; eslint has NO root-config guard) ---------
fallback_lint() {
  local f="$1"
  case "$f" in
    *.py)  apply_cmd "$f" "ruff check {file}" ;;
    *.go)
      if command -v gofmt >/dev/null 2>&1; then
        [[ -n "$(cd "${CWD}" && gofmt -l "$f" 2>/dev/null)" ]] && FAILURES+=("gofmt: $f not formatted")
      else
        WARNS+=("lint skipped: 'gofmt' not installed (for $f)")
      fi ;;
    *.php) apply_cmd "$f" "phpcs {file}" ;;
    *.js|*.jsx|*.ts|*.tsx) apply_cmd "$f" "eslint {file}" ;;   # flat config honored
    *)     WARNS+=("no lint command configured for ${f} (.${f##*.})") ;;
  esac
  return 0
}

# --- lint one changed file: scope = first matching glob, run ALL its cmds -----
# Two passes over lint.map. Pass 1: the first (highest-priority, most-specific)
# matching glob picks the file's SCOPE. Pass 2: run EVERY command whose glob is
# byte-identical to that scope — so gofmt+govet+gosec under one `**/*.go` all run
# (chaining), while a more-specific `serviceA/**` scope shadows the catch-all
# (no inheritance: a file gets its scope's commands only). Contracts both rely on:
# (1) same group = byte-identical glob string; (2) specific globs ordered first.
lint_file() {
  local f="$1" glob cmd scope=""
  if [[ -f "${LINT_MAP}" ]]; then
    while IFS=$'\t' read -r glob cmd; do
      [[ -z "${glob}" || "${glob}" == \#* ]] && continue
      if glob_match "${f}" "${glob}"; then scope="${glob}"; break; fi
    done < "${LINT_MAP}"
    if [[ -n "${scope}" ]]; then
      while IFS=$'\t' read -r glob cmd; do
        [[ "${glob}" == "${scope}" ]] && apply_cmd "${f}" "${cmd}"
      done < "${LINT_MAP}"
      return 0
    fi
  fi
  fallback_lint "${f}"
  return 0
}

# --- secret scan over staged diff --------------------------------------------
SECRETS=$(git -C "${CWD}" diff --cached | grep -iE '(api[_-]?key|secret|password|token|aws_(access|secret)|private[_-]?key|bearer\s+[a-z0-9]{20,})' || true)
if [[ -n "${SECRETS}" ]]; then
  FAILURES+=("secret-scan: potential secret(s) in staged diff")
fi

# --- lint each changed file --------------------------------------------------
CHANGED=$(git -C "${CWD}" diff --cached --name-only)
while IFS= read -r f; do
  [[ -z "${f}" ]] && continue
  lint_file "${f}"
done <<< "${CHANGED}"

# --- run deferred whole-project commands once --------------------------------
for c in "${WHOLE_CMDS[@]:-}"; do
  [[ -z "${c}" ]] && continue
  bin="${c%% *}"
  if ! command -v "${bin}" >/dev/null 2>&1; then
    WARNS+=("lint skipped: '${bin}' not installed (project command)")
    continue
  fi
  (cd "${CWD}" && eval "${c}" >/dev/null 2>&1) || FAILURES+=("lint: project command '${c}'")
done

# --- LOUD advisory for every skip (stderr always; flow.md best-effort) -------
if [[ ${#WARNS[@]} -gt 0 ]]; then
  {
    echo "lifeline lint advisory (commit not blocked by these):"
    printf '  - %s\n' "${WARNS[@]}"
  } >&2
  FM=$(ls -t "${ARTIFACT_DIR}"/*/flow.md 2>/dev/null | head -1 || true)
  if [[ -n "${FM}" ]]; then
    TS=$(date +%Y-%m-%dT%H:%M:%S 2>/dev/null || echo "")
    for w in "${WARNS[@]}"; do echo "[${TS}] precommit.lint.advisory ${w}" >> "${FM}"; done
  fi
fi

# --- hard gate on failures ---------------------------------------------------
if [[ ${#FAILURES[@]} -gt 0 ]]; then
  cat <<EOF
{
  "decision": "block",
  "reason": "lifeline pre-commit gate failed:\n$(printf '  - %s\n' "${FAILURES[@]}")\n\nFix and re-commit, or bypass with a manual git commit outside the session."
}
EOF
  exit 0
fi

exit 0
