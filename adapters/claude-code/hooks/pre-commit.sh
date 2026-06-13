#!/usr/bin/env bash
# lifeline @run_hook binding (FULL tier): PreToolUse hook on Bash.
# Intercepts `git commit` on a lifeline/* branch. Runs secret scan + lint as a hard gate.
# Degraded harnesses replace this with the mandatory self-check in tdd-discipline.

set -euo pipefail

INPUT=$(cat)

CMD=$(echo "${INPUT}" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

if ! echo "${CMD}" | grep -qE '\bgit\s+commit\b'; then
  exit 0
fi

CWD=$(echo "${INPUT}" | jq -r '.tool_input.cwd // empty' 2>/dev/null || pwd)
# symbolic-ref also resolves an unborn branch (first commit of a cycle)
BRANCH=$(git -C "${CWD}" symbolic-ref --short HEAD 2>/dev/null || git -C "${CWD}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [[ ! "${BRANCH}" =~ ^lifeline/ ]]; then
  exit 0
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
  cat <<EOF
{
  "decision": "block",
  "reason": "lifeline pre-commit gate failed:\n$(printf '  - %s\n' "${FAILURES[@]}")\n\nFix and re-commit, or bypass with a manual git commit outside the session."
}
EOF
  exit 0
fi

exit 0
