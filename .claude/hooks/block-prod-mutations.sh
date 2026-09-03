#!/usr/bin/env bash
# Layer 2: deny infra-mutation commands (terraform/tofu, kubectl, helm, aws,
# gcloud/gsutil) ONLY when the active workspace/context/profile/project name
# looks like production (case-insensitive "prod" substring match).
#
# Design tradeoff (intentional, per team decision): this is fail-OPEN by
# design. If the environment can't be determined, or its name doesn't
# contain "prod", the command is NOT blocked here — it falls through to the
# normal permissions.allow/ask/deny rules in settings.json. This keeps
# day-to-day dev/staging work unobstructed; only a clearly-named production
# target gets hard-blocked with no prompt. A misnamed or unnamed production
# environment (e.g. a context called "main-cluster") will NOT be caught by
# this heuristic — that is the accepted cost of the naming-convention
# approach (vs. an explicit allowlist of prod account/project/context IDs).
set -uo pipefail

command_input="$(jq -er '.tool_input.command // empty' 2>/dev/null || true)"
[[ -z "$command_input" ]] && exit 0

contains_prod() {
  local s="${1,,}"
  [[ -n "$s" && "$s" == *prod* ]]
}

deny() {
  jq -n --arg reason "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
}

# --- terraform / tofu: apply|destroy ---------------------------------------
if [[ "$command_input" =~ (^|[;\&\|[:space:]])(terraform|tofu)[[:space:]].*(apply|destroy)([[:space:]]|$) ]]; then
  ctx=""
  if [[ "$command_input" =~ -{1,2}(workspace|var-file)[=[:space:]]+([^[:space:]]+) ]]; then
    ctx="${BASH_REMATCH[2]}"
  fi
  [[ -z "$ctx" ]] && ctx="${TF_WORKSPACE:-}"
  [[ -z "$ctx" ]] && ctx="$(timeout 3 terraform workspace show 2>/dev/null || true)"
  if contains_prod "$ctx"; then
    deny "Blocked by the Layer 2 production guard: terraform/tofu apply|destroy targets workspace '$ctx', which looks like production."
  fi
fi

# --- kubectl: apply|delete|patch|scale|drain --------------------------------
if [[ "$command_input" =~ (^|[;\&\|[:space:]])kubectl[[:space:]].*(apply|delete|patch|scale|drain)([[:space:]]|$) ]]; then
  ctx=""
  if [[ "$command_input" =~ -{1,2}context[=[:space:]]+([^[:space:]]+) ]]; then
    ctx="${BASH_REMATCH[1]}"
  fi
  [[ -z "$ctx" ]] && ctx="$(timeout 3 kubectl config current-context 2>/dev/null || true)"
  if contains_prod "$ctx"; then
    deny "Blocked by the Layer 2 production guard: kubectl mutation targets context '$ctx', which looks like production."
  fi
fi

# --- helm: install|upgrade|uninstall|delete ---------------------------------
if [[ "$command_input" =~ (^|[;\&\|[:space:]])helm[[:space:]].*(install|upgrade|uninstall|delete)([[:space:]]|$) ]]; then
  ctx=""
  if [[ "$command_input" =~ -{1,2}kube-context[=[:space:]]+([^[:space:]]+) ]]; then
    ctx="${BASH_REMATCH[1]}"
  fi
  [[ -z "$ctx" ]] && ctx="$(timeout 3 kubectl config current-context 2>/dev/null || true)"
  if contains_prod "$ctx"; then
    deny "Blocked by the Layer 2 production guard: helm mutation targets context '$ctx', which looks like production."
  fi
fi

# --- aws: delete|terminate|destroy verbs ------------------------------------
if [[ "$command_input" =~ (^|[;\&\|[:space:]])aws[[:space:]] ]] && [[ "$command_input" =~ (delete|terminate|destroy)[[:alnum:]_-]*([[:space:]]|$) ]]; then
  ctx=""
  if [[ "$command_input" =~ -{1,2}profile[=[:space:]]+([^[:space:]]+) ]]; then
    ctx="${BASH_REMATCH[1]}"
  fi
  [[ -z "$ctx" ]] && ctx="${AWS_PROFILE:-${AWS_VAULT:-${AWS_DEFAULT_PROFILE:-}}}"
  if contains_prod "$ctx"; then
    deny "Blocked by the Layer 2 production guard: aws mutation uses profile '$ctx', which looks like production."
  fi
fi

# --- gcloud / gsutil: delete|destroy verbs, storage rm -----------------------
if [[ "$command_input" =~ (^|[;\&\|[:space:]])(gcloud|gsutil)[[:space:]] ]] && \
   [[ "$command_input" =~ ((delete|destroy)([[:space:]]|$)|storage[[:space:]]+rm[[:space:]]|^gsutil[[:space:]].*rm[[:space:]]) ]]; then
  ctx=""
  if [[ "$command_input" =~ -{1,2}project[=[:space:]]+([^[:space:]]+) ]]; then
    ctx="${BASH_REMATCH[1]}"
  fi
  [[ -z "$ctx" ]] && ctx="${CLOUDSDK_CORE_PROJECT:-}"
  [[ -z "$ctx" ]] && ctx="$(timeout 3 gcloud config get-value project 2>/dev/null || true)"
  if contains_prod "$ctx"; then
    deny "Blocked by the Layer 2 production guard: gcloud/gsutil mutation targets project '$ctx', which looks like production."
  fi
fi

exit 0
