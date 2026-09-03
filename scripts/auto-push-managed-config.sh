#!/usr/bin/env bash
# Synchronize the explicitly managed Claude Code files and mise.toml to main.
# The script intentionally never stages unrelated working-tree changes.
set -euo pipefail

DOTFILES_DIR="/Users/tshoji/dotfiles"
LOCK_DIR="$DOTFILES_DIR/.git/auto-push-managed-config.lock"
PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

mkdir "$LOCK_DIR" 2>/dev/null || exit 0
trap 'rmdir "$LOCK_DIR"' EXIT

cd "$DOTFILES_DIR"
[[ "$(git branch --show-current)" == "main" ]] || exit 0

managed_paths=(
  .claude/.gitignore
  .claude/settings.json
  .claude/skills
  .claude/hooks
  mise.toml
)

git add -- "${managed_paths[@]}"
git diff --cached --quiet -- "${managed_paths[@]}" && exit 0

# Scan only added lines. The patterns are deliberately high-confidence so
# documentation that merely mentions a credential type does not block updates.
added_lines="$(git diff --cached --no-color --unified=0 -- "${managed_paths[@]}" | rg '^\\+' | rg -v '^\\+\\+\\+' || true)"
if printf '%s\\n' "$added_lines" | rg -q -i \
  -e '-----BEGIN ([A-Z0-9 ]+ )?PRIVATE KEY-----' \
  -e '\\b(AKIA|ASIA)[A-Z0-9]{16}\\b' \
  -e '\\bAIza[0-9A-Za-z_-]{35}\\b' \
  -e '\\bgh[pousr]_[A-Za-z0-9_]{20,}\\b' \
  -e '\\bgithub_pat_[A-Za-z0-9_]{20,}\\b' \
  -e '\\bglpat-[A-Za-z0-9_-]{20,}\\b' \
  -e '\\bsk_(live|test)_[0-9A-Za-z]{16,}\\b' \
  -e '\\bxox[baprs]-[0-9A-Za-z-]{20,}\\b'; then
  echo "auto-push stopped: a possible credential was found in the staged change" >&2
  exit 1
fi

git commit -m "auto: synchronize Claude settings and mise" -- "${managed_paths[@]}"
git push origin main
