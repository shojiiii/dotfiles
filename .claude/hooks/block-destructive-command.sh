#!/usr/bin/env bash
# Layer 1: deny Bash commands that are destructive regardless of environment
# (local filesystem wipes, irreversible git history rewrites). These have no
# legitimate "it's fine in dev" case, so they are blocked unconditionally.
# Environment-dependent infra mutations (terraform/kubectl/helm/aws/gcloud)
# live in block-prod-mutations.sh instead, gated on a production check.
set -euo pipefail

command_input="$(jq -er '.tool_input.command // empty' 2>/dev/null || true)"

if [[ -z "$command_input" ]]; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"Blocked: the destructive-command guard could not read the Bash command."}}'
  exit 0
fi

patterns=(
  '(^|[;&|[:space:]])(command[[:space:]]+)?(sudo[[:space:]]+)?(/bin/)?(rm|rmdir|unlink)[[:space:]]'
  '(^|[;&|[:space:]])(sudo[[:space:]]+)?(dd|mkfs(\.[[:alnum:]_-]+)?|fdisk|diskutil|wipefs|shred|truncate)[[:space:]]'
  '(^|[;&|[:space:]])find[[:space:]].*-delete([[:space:];&|]|$)'
  '(^|[;&|[:space:]])git[[:space:]].*(reset[[:space:]]+--hard|clean[[:space:]].*(-f|--force)|restore[[:space:]].*--source|checkout[[:space:]]+--|branch[[:space:]]+-D|tag[[:space:]]+-d|push[[:space:]].*(--force|--delete|(^|[[:space:]])-f([[:space:]]|$)))'
  '(^|[;&|[:space:]])(docker|podman)[[:space:]].*(system[[:space:]]+prune|container[[:space:]]+rm|image[[:space:]]+rm|volume[[:space:]]+rm|compose[[:space:]]+down[[:space:]].*-v)'
)

for pattern in "${patterns[@]}"; do
  if [[ "$command_input" =~ $pattern ]]; then
    jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"Blocked by the Layer 1 destructive-command guard (local/irreversible operation). Use an explicit, supervised workflow if this operation is intended."}}'
    exit 0
  fi
done

exit 0
