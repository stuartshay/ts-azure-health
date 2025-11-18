#!/usr/bin/env bash

#!/bin/bash

# Azure Policy Compliance Check Script
# Queries Azure Policy assignments and exemptions for a resource group

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: policy-check.sh --resource-group <name> --subscription-id <id> [options]

Options:
  --resource-group <name>   Resource group to check (required)
  --subscription-id <id>    Azure subscription ID (required)
  --summary-path <path>     File to append markdown summary (default: $GITHUB_STEP_SUMMARY if set)
EOF
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
SUMMARY_PATH="${GITHUB_STEP_SUMMARY:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
    --subscription-id) SUBSCRIPTION_ID="$2"; shift 2 ;;
    --summary-path) SUMMARY_PATH="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [ -z "${RESOURCE_GROUP:-}" ] || [ -z "${SUBSCRIPTION_ID:-}" ]; then
  echo "Missing required arguments." >&2
  usage
  exit 1
fi

echo "🛡️  Checking Azure Policy compliance..."
echo ""

# Check if resource group exists
if ! az group show --name "$RESOURCE_GROUP" --subscription "$SUBSCRIPTION_ID" >/dev/null 2>&1; then
  echo "⚠️  Resource group $RESOURCE_GROUP does not exist yet."

  if [ -n "$SUMMARY_PATH" ]; then
    {
      echo "## 🛡️ Policy Compliance Check"
      echo ""
      echo "**Resource Group:** \`$RESOURCE_GROUP\`"
      echo ""
      echo "⚠️  **Resource group does not exist yet.** Policy compliance will be checked after deployment."
      echo ""
      echo "---"
    } >>"$SUMMARY_PATH"
  fi
  exit 0
fi

# Get policy assignments
echo "Fetching policy assignments..."
POLICY_ASSIGNMENTS=$(az policy assignment list \
  --resource-group "$RESOURCE_GROUP" \
  --query "[].{name:name, displayName:displayName, policyDefinitionId:policyDefinitionId, enforcementMode:enforcementMode}" \
  -o json 2>/dev/null || echo '[]')

ASSIGNMENT_COUNT=$(echo "$POLICY_ASSIGNMENTS" | jq 'length')

# Get policy states (compliance)
echo "Fetching policy compliance states..."
POLICY_STATES=$(az policy state list \
  --resource-group "$RESOURCE_GROUP" \
  --query "[].{policyAssignmentName:policyAssignmentName, complianceState:complianceState, resourceType:resourceType, resourceLocation:resourceLocation}" \
  -o json 2>/dev/null || echo '[]')

# Get policy exemptions
echo "Fetching policy exemptions..."
POLICY_EXEMPTIONS=$(az policy exemption list \
  --resource-group "$RESOURCE_GROUP" \
  --query "[].{name:name, displayName:displayName, exemptionCategory:exemptionCategory, expiresOn:expiresOn, policyAssignmentId:policyAssignmentId}" \
  -o json 2>/dev/null || echo '[]')

EXEMPTION_COUNT=$(echo "$POLICY_EXEMPTIONS" | jq 'length')

# Count non-compliant resources
NON_COMPLIANT_COUNT=$(echo "$POLICY_STATES" | jq '[.[] | select(.complianceState == "NonCompliant")] | length')

echo ""
echo "📊 Policy Summary:"
echo "  Policy Assignments: $ASSIGNMENT_COUNT"
echo "  Non-Compliant Resources: $NON_COMPLIANT_COUNT"
echo "  Active Exemptions: $EXEMPTION_COUNT"
echo ""

# Generate markdown summary
if [ -n "$SUMMARY_PATH" ]; then
  {
    echo "## 🛡️ Policy Compliance Preview"
    echo ""
    echo "**Resource Group:** \`$RESOURCE_GROUP\`"
    echo ""

    # Policy Assignments
    echo "### Policy Assignments ($ASSIGNMENT_COUNT)"
    echo ""
    if [ "$ASSIGNMENT_COUNT" -gt 0 ]; then
      echo "$POLICY_ASSIGNMENTS" | jq -r '.[] | "- **\(.displayName // .name)**\n  - Policy: `\(.policyDefinitionId | split("/") | .[-1])`\n  - Enforcement: \(.enforcementMode)"'
    else
      echo "_No policy assignments found._"
    fi
    echo ""

    # Compliance Status
    if [ "$NON_COMPLIANT_COUNT" -gt 0 ]; then
      echo "### ⚠️ Non-Compliant Resources ($NON_COMPLIANT_COUNT)"
      echo ""
      echo "$POLICY_STATES" | jq -r '[.[] | select(.complianceState == "NonCompliant")] | group_by(.policyAssignmentName) | .[] | "- **\(.[0].policyAssignmentName)**\n" + (. | map("  - \(.resourceType) (\(.resourceLocation))") | join("\n"))'
      echo ""
    else
      echo "### ✅ Compliance Status"
      echo ""
      echo "All resources are compliant with assigned policies."
      echo ""
    fi

    # Exemptions
    if [ "$EXEMPTION_COUNT" -gt 0 ]; then
      echo "### Policy Exemptions ($EXEMPTION_COUNT)"
      echo ""
      echo "$POLICY_EXEMPTIONS" | jq -r '.[] | "- 🛡️ **\(.displayName // .name)**\n  - Category: \(.exemptionCategory)\n  - Expires: \(.expiresOn // "No expiration")"'
      echo ""
    fi

    # Guidance
    echo "### 📖 Policy Guidance"
    echo ""
    if [ "$NON_COMPLIANT_COUNT" -gt 0 ]; then
      echo "**Action Required:**"
      echo "- Review non-compliant resources listed above"
      echo "- Update infrastructure to comply with policies, or"
      echo "- Request policy exemptions for development/testing"
    else
      echo "✅ All resources comply with organizational policies."
    fi
    echo ""
    echo "---"
  } >>"$SUMMARY_PATH"
fi

# Store in GitHub output
append_heredoc_output "policy_summary" "$(cat <<EOF
Policy Assignments: $ASSIGNMENT_COUNT
Non-Compliant: $NON_COMPLIANT_COUNT
Exemptions: $EXEMPTION_COUNT
EOF
)"

echo "Policy compliance check completed."
