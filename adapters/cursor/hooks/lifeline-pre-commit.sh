#!/usr/bin/env bash
# lifeline @run_hook binding (Cursor FULL tier): beforeShellExecution hook.
# Intercepts `git commit` on a lifeline/* branch. Runs secret scan + lint as a hard gate
# (permission=deny). Fallback harnesses replace this with the mandatory self-check in
# tdd-discipline. Input/output schema: https://cursor.com/docs/hooks

set -euo pipefail

allow() { echo '{"permission":"allow"}'; exit 0; }

command -v jq >/dev/null || allow

INPUT=$(cat)
CMD=$(echo "${INPUT}" | jq -r '.command // empty' 2>/dev/null || echo "")

if ! echo "${CMD}" | grep -qE '\bgit\s+commit\b'; then
  allow
fi

CWD=$(echo "${INPUT}" | jq -r '.cwd // empty' 2>/dev/null)
[[ -z "${CWD}" ]] && CWD=$(pwd)
# symbolic-ref also resolves an unborn branch (first commit of a cycle)
BRANCH=$(git -C "${CWD}" symbolic-ref --short HEAD 2>/dev/null || git -C "${CWD}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [[ ! "${BRANCH}" =~ ^lifeline/ ]]; then
  allow
fi

FAILURES=()

# Secret scan over staged diff
SECRETS=$(git -C "${CWD}" diff --cached | grep -iE '(api[_-]?key|secret|password|token|aws_(access|secret)|private[_-]?key|bearer\s+[a-z0-9]{20,})' || true)
if [[ -n "${SECRETS}" ]]; then
  FAILURES+=("secret-scan: potential secret(s) in staged diff")
fi

# Lint changed files by extension (only when the linter is installed)
CHANGED=$(git -C "${CWD}" diff --cached --name-only)
while IFS= read -r f; do
  [[ -z "${f}" ]] && continue
  case "${f}" in
    *.py)
      if command -v ruff >/dev/null; then
        (cd "${CWD}" && ruff check "${f}" >/dev/null 2>&1) || FAILURES+=("ruff: ${f}")
      fi
      ;;
    *.go)
      if command -v gofmt >/dev/null; then
        [[ -n "$(cd "${CWD}" && gofmt -l "${f}" 2>/dev/null)" ]] && FAILURES+=("gofmt: ${f} not formatted")
      fi
      ;;
    *.php)
      if command -v phpcs >/dev/null; then
        (cd "${CWD}" && phpcs "${f}" >/dev/null 2>&1) || FAILURES+=("phpcs: ${f}")
      fi
      ;;
    *.js|*.jsx|*.ts|*.tsx)
      if command -v eslint >/dev/null && compgen -G "${CWD}/.eslintrc*" >/dev/null; then
        (cd "${CWD}" && eslint "${f}" >/dev/null 2>&1) || FAILURES+=("eslint: ${f}")
      fi
      ;;
  esac
done <<< "${CHANGED}"

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  REASON="lifeline pre-commit gate failed: $(printf '%s; ' "${FAILURES[@]}")Fix and re-commit, or bypass with a manual git commit outside the session."
  jq -n --arg msg "${REASON}" '{permission:"deny", agent_message:$msg, user_message:$msg}'
  exit 0
fi

allow
