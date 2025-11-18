#!/bin/bash

# Cost Estimation Script for Azure Infrastructure
# Estimates monthly costs before deployment using ACE (Azure Cost Estimator)

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: cost-estimate.sh --environment <env> --location <region> --subscription-id <id> [options]

Options:
  --environment <env>          Deployment environment (dev|staging|prod)
  --location <region>          Azure region for estimation (e.g., eastus)
  --subscription-id <id>       Azure subscription ID (required for ACE)
  --resource-group <name>      Resource group name (for summaries)
  --bicep-file <path>          Path to Bicep template (default: infrastructure/main.bicep)
  --parameters-file <path>     Path to Bicep parameters file
  --summary-path <path>        File to append markdown summary (default: $GITHUB_STEP_SUMMARY if set)
EOF
}

log() { echo "[$(date +'%H:%M:%S')] $*"; }

append_output() {
  local key=$1 value=$2
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    printf '%s=%s\n' "$key" "$value" >>"$GITHUB_OUTPUT"
  fi
}

append_heredoc_output() {
  local key=$1 content=$2
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
      printf '%s<<EOF\n' "$key"
      printf '%s\n' "$content"
      echo "EOF"
    } >>"$GITHUB_OUTPUT"
  fi
}

# Defaults
RESOURCE_GROUP=""
BICEP_FILE="infrastructure/main.bicep"
PARAMETERS_FILE=""
SUMMARY_PATH="${GITHUB_STEP_SUMMARY:-}"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --environment) ENVIRONMENT="$2"; shift 2 ;;
    --location) LOCATION="$2"; shift 2 ;;
    --subscription-id) SUBSCRIPTION_ID="$2"; shift 2 ;;
    --resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
    --bicep-file) BICEP_FILE="$2"; shift 2 ;;
    --parameters-file) PARAMETERS_FILE="$2"; shift 2 ;;
    --summary-path) SUMMARY_PATH="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [ -z "${ENVIRONMENT:-}" ] || [ -z "${LOCATION:-}" ] || [ -z "${SUBSCRIPTION_ID:-}" ]; then
  echo "Missing required arguments." >&2
  usage
  exit 1
fi

log "Starting cost estimation for env=${ENVIRONMENT}, location=${LOCATION}"

# -------------------------------------------------------
# ACE Cost Estimator
# -------------------------------------------------------
log "Running ACE cost estimator..."
log "Transpiling Bicep to ARM template..."
az bicep build \
  --file "$BICEP_FILE" \
  --outfile /tmp/main.json

log "Running ACE estimation..."
set +e
ACE_COST_OUTPUT=$(/tmp/ace/azure-cost-estimator \
  /tmp/main.json \
  "$SUBSCRIPTION_ID" \
  "${RESOURCE_GROUP:-rg-placeholder}" \
  --inline "environment=$ENVIRONMENT" \
  --inline "location=$LOCATION" \
  --currency USD 2>&1)
set -e

echo "$ACE_COST_OUTPUT"

ACE_TOTAL_COST=$(echo "$ACE_COST_OUTPUT" | grep -i "Total cost:" | grep -oP '[\d,]+\.?\d+(?= USD)' | tail -1 || true)
ACE_TOTAL_COST=${ACE_TOTAL_COST:-N/A}

if [ "$ACE_TOTAL_COST" = "N/A" ]; then
  log "Could not extract ACE cost estimate."
else
  log "ACE estimated monthly cost: \$$ACE_TOTAL_COST USD"
fi

# -------------------------------------------------------
# Outputs for GHA
# -------------------------------------------------------
append_output "estimated_cost" "\$$ACE_TOTAL_COST"
append_heredoc_output "cost_details" "$ACE_COST_OUTPUT"

# -------------------------------------------------------
# Summary
# -------------------------------------------------------
if [ -n "$SUMMARY_PATH" ]; then
  {
    echo "## 💰 Pre-Deployment Cost Estimation"
    echo ""
    echo "**Environment:** $ENVIRONMENT"
    [ -n "$RESOURCE_GROUP" ] && echo "**Resource Group:** $RESOURCE_GROUP"
    echo "**Region:** $LOCATION"
    echo ""
    echo "### Estimated Monthly Cost: \`\$$ACE_TOTAL_COST USD/month\`"
    echo ""
    echo "<details>"
    echo "<summary>View detailed cost breakdown</summary>"
    echo ""
    echo '```'
    echo "$ACE_COST_OUTPUT"
    echo '```'
    echo ""
    echo "</details>"
    echo ""
    echo "> **Note:** This is an estimated cost based on Azure's retail pricing. Actual costs may vary based on usage patterns, reserved instances, and enterprise agreements."
    echo ""
    echo "---"
  } >>"$SUMMARY_PATH"
fi

log "Cost estimation completed."
