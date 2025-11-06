#!/usr/bin/env bash
#
# Preview infrastructure changes using Bicep what-if
# Shows what would change without actually deploying.
#
# Usage:
#   ./whatif-bicep.sh
#   ./whatif-bicep.sh -e prod -l westus2
#   ./whatif-bicep.sh --environment dev --location eastus
#

set -euo pipefail

# Default values
ENVIRONMENT="dev"
LOCATION="eastus"

# Color output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly GRAY='\033[0;37m'
readonly NC='\033[0m' # No Color

# Usage information
usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Preview infrastructure changes using Bicep what-if.

Options:
  -e, --environment ENV    Environment: dev, staging, or prod (default: dev)
  -l, --location LOCATION  Azure region for deployment (default: eastus)
  -h, --help              Display this help message

Examples:
  $(basename "$0")
  $(basename "$0") -e prod -l westus2
  $(basename "$0") --environment dev

EOF
  exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -e|--environment)
      ENVIRONMENT="$2"
      shift 2
      ;;
    -l|--location)
      LOCATION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo -e "${RED}Error: Unknown option: $1${NC}"
      usage
      ;;
  esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
  echo -e "${RED}Error: Invalid environment. Must be dev, staging, or prod${NC}"
  exit 1
fi

# Set resource group name based on environment
RESOURCE_GROUP="rg-ts-azure-health-${ENVIRONMENT}"

# Navigate to infrastructure directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/infrastructure"

cd "$INFRA_DIR"

echo -e ""
echo -e "${CYAN}===========================================================${NC}"
echo -e "${CYAN}  TS Azure Health - What-If Preview${NC}"
echo -e "${CYAN}===========================================================${NC}"
echo -e ""
echo -e "${CYAN}Configuration:${NC}"
echo -e "${GRAY}  Resource Group : $RESOURCE_GROUP${NC}"
echo -e "${GRAY}  Location       : $LOCATION${NC}"
echo -e "${GRAY}  Environment    : $ENVIRONMENT${NC}"
echo -e "${GRAY}  Template       : main.bicep${NC}"
echo -e "${GRAY}  Parameters     : ${ENVIRONMENT}.bicepparam${NC}"
echo -e ""

# Check Azure CLI authentication
echo -e "${CYAN}Checking Azure CLI authentication...${NC}"
if ! az account show > /dev/null 2>&1; then
  echo -e "${RED}Error: Not logged in to Azure. Run: az login${NC}"
  exit 1
fi

ACCOUNT_INFO=$(az account show --query "{name:name, user:user.name}" -o json)
ACCOUNT_NAME=$(echo "$ACCOUNT_INFO" | jq -r '.name')
USER_NAME=$(echo "$ACCOUNT_INFO" | jq -r '.user')

echo -e "${GREEN}[OK] Authenticated as: $USER_NAME${NC}"
echo -e "${GRAY}  Subscription: $ACCOUNT_NAME${NC}"
echo -e ""

# Check resource group exists (required for what-if)
echo -e "${CYAN}Checking resource group exists...${NC}"
if ! az group show --name "$RESOURCE_GROUP" > /dev/null 2>&1; then
  echo -e "${YELLOW}Resource group does not exist: $RESOURCE_GROUP${NC}"
  echo -e "${GRAY}Create it first with:${NC}"
  echo -e "${YELLOW}  az group create --name \"$RESOURCE_GROUP\" --location \"$LOCATION\"${NC}"
  echo -e ""
  exit 1
fi
echo -e "${GREEN}[OK] Resource group exists: $RESOURCE_GROUP${NC}"
echo -e ""

# Run what-if
echo -e "${CYAN}Running What-If analysis...${NC}"
echo -e "${GRAY}(This shows what would change if you deployed)${NC}"
echo -e ""

az deployment group what-if \
  --resource-group "$RESOURCE_GROUP" \
  --template-file main.bicep \
  --parameters "${ENVIRONMENT}.bicepparam" \
  --result-format FullResourcePayloads

echo -e ""
echo -e "${GREEN}===========================================================${NC}"
echo -e "${GREEN}  What-If Analysis Complete${NC}"
echo -e "${GREEN}===========================================================${NC}"
echo -e ""
echo -e "${CYAN}Next Steps:${NC}"
echo -e "${GRAY}  To deploy these changes, run:${NC}"
echo -e "${YELLOW}    ./deploy-bicep.sh -e $ENVIRONMENT${NC}"
echo -e ""
