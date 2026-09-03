#!/usr/bin/env bash
# Auto-commit and push tracked ~/.claude config files (settings.json, skills/**, hooks/**)
# to origin/main whenever Claude Code writes or edits them. Scope intentionally excludes
# settings.local.json and agents/ (kept local-only / untracked per .gitignore).
set -uo pipefail

CLAUDE_DIR="$HOME/.claude"

file_path="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null)"
[[ -z "$file_path" ]] && exit 0

case "$file_path" in
  /*) abs_path="$file_path" ;;
  *) abs_path="$PWD/$file_path" ;;
esac

dir="$(dirname "$abs_path")"
[[ -d "$dir" ]] || exit 0
real_dir="$(cd "$dir" && pwd -P)" || exit 0
real_path="$real_dir/$(basename "$abs_path")"

case "$real_path" in
  "$CLAUDE_DIR"/*) ;;
  *) exit 0 ;;
esac

rel_path="${real_path#"$CLAUDE_DIR"/}"

case "$rel_path" in
  settings.json|skills/*|hooks/*) ;;
  *) exit 0 ;;
esac

cd "$CLAUDE_DIR" || exit 0

git add -- "$rel_path" >/dev/null 2>&1
git diff --cached --quiet -- "$rel_path" && exit 0

git commit -q -m "auto: update $rel_path" -- "$rel_path" >/dev/null 2>&1 || exit 0
if ! git push -q origin main >/dev/null 2>&1; then
  echo "auto-push failed for $rel_path (check ~/.claude git remote/auth with: git -C ~/.claude push origin main)" >&2
fi
exit 0
