#!/usr/bin/env bash
#
# Deploy Azure infrastructure using Bicep template
# Creates resource group and deploys all resources using Azure Bicep IaC.
# More reliable than imperative scripts - declarative and idempotent.
#
# Usage:
#   ./deploy-bicep.sh
#   ./deploy-bicep.sh -e prod -l westus2
#   ./deploy-bicep.sh --environment dev --location eastus
#

set -euo pipefail

# Default values
ENVIRONMENT="dev"
LOCATION="eastus"
WHATIF=false

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

Deploy Azure infrastructure using Bicep template.

Options:
  -e, --environment ENV    Environment: dev, staging, or prod (default: dev)
  -l, --location LOCATION  Azure region for deployment (default: eastus)
  -w, --whatif            Preview changes without deploying
  -h, --help              Display this help message

Examples:
  $(basename "$0")
  $(basename "$0") -e prod -l westus2
  $(basename "$0") --environment dev --whatif

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
    -w|--whatif)
      WHATIF=true
      shift
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
if [ "${ENVIRONMENT}" = "prod" ]; then
  RESOURCE_GROUP="rg-azure-health"
else
  RESOURCE_GROUP="rg-azure-health-${ENVIRONMENT}"
fi

# Navigate to infrastructure directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/infrastructure"

cd "$INFRA_DIR"

echo -e ""
echo -e "${CYAN}===========================================================${NC}"
echo -e "${CYAN}  TS Azure Health - Bicep Deployment${NC}"
echo -e "${CYAN}===========================================================${NC}"
echo -e ""
echo -e "${CYAN}Configuration:${NC}"
echo -e "${GRAY}  Resource Group : $RESOURCE_GROUP${NC}"
echo -e "${GRAY}  Location       : $LOCATION${NC}"
echo -e "${GRAY}  Environment    : $ENVIRONMENT${NC}"
echo -e "${GRAY}  Template       : main.bicep${NC}"
echo -e "${GRAY}  Parameters     : ${ENVIRONMENT}.bicepparam${NC}"

if [ "$WHATIF" = true ]; then
  echo -e "${YELLOW}  Mode           : What-If (preview only)${NC}"
fi

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

# Create resource group
echo -e "${CYAN}Creating resource group...${NC}"
if az group show --name "$RESOURCE_GROUP" > /dev/null 2>&1; then
  echo -e "${GREEN}[OK] Resource group exists: $RESOURCE_GROUP${NC}"
else
  az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --tags environment="$ENVIRONMENT" project=ts-azure-health \
    --output none
  echo -e "${GREEN}[OK] Created resource group: $RESOURCE_GROUP${NC}"
fi
echo -e ""

# Deploy Bicep template
if [ "$WHATIF" = true ]; then
  echo -e "${CYAN}Running What-If analysis...${NC}"
  az deployment group what-if \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters "${ENVIRONMENT}.bicepparam"
else
  echo -e "${CYAN}Deploying Bicep template...${NC}"
  echo -e "${GRAY}(This may take 3-5 minutes)${NC}"
  echo -e ""

  DEPLOYMENT_OUTPUT=$(az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters "${ENVIRONMENT}.bicepparam" \
    --output json)

  if [ $? -eq 0 ]; then
    echo -e ""
    echo -e "${GREEN}===========================================================${NC}"
    echo -e "${GREEN}  Deployment Successful!${NC}"
    echo -e "${GREEN}===========================================================${NC}"
    echo -e ""

    # Extract outputs
    CONTAINER_APP_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.containerAppName.value')
    CONTAINER_APP_URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.containerAppUrl.value')
    KEY_VAULT_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.keyVaultName.value')
    MANAGED_IDENTITY_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.managedIdentityName.value')
    RG_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.resourceGroupName.value')

    echo -e "${CYAN}Deployed Resources:${NC}"
    echo -e "${GRAY}  Resource Group      : $RG_NAME${NC}"
    echo -e "${GRAY}  Container App       : $CONTAINER_APP_NAME${NC}"
    echo -e "${GRAY}  Container App URL   : $CONTAINER_APP_URL${NC}"
    echo -e "${GRAY}  Key Vault           : $KEY_VAULT_NAME${NC}"
    echo -e "${GRAY}  Managed Identity    : $MANAGED_IDENTITY_NAME${NC}"
    echo -e ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo -e "${GRAY}  1. Deploy frontend code using GitHub Actions workflow${NC}"
    echo -e ""
    echo -e "${GRAY}  2. Verify the deployment:${NC}"
    echo -e "${YELLOW}     az containerapp show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP${NC}"
    echo -e ""
    echo -e "${GRAY}  3. View logs:${NC}"
    echo -e "${YELLOW}     az containerapp logs show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --follow${NC}"
    echo -e ""
  else
    echo -e "${RED}Error: Deployment failed. Check the output above for details.${NC}"
    exit 1
  fi
fi
