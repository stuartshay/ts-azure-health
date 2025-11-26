#!/usr/bin/env bash
#
# Setup Development Resource Group
# Creates rg-azure-health-dev with CanNotDelete lock to prevent accidental deletion.
# This resource group is shared with pwsh-azure-health project.
#
# Usage:
#   ./setup-dev-rg.sh
#   ./setup-dev-rg.sh -l westus2
#

set -euo pipefail

# Default values
LOCATION="eastus"
RESOURCE_GROUP="rg-azure-health-dev"

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

Setup development resource group with lock protection.

Options:
  -l, --location LOCATION    Azure region for deployment (default: eastus)
  -h, --help                Display this help message

Example:
  $(basename "$0")
  $(basename "$0") --location westus2

EOF
  exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
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

echo -e ""
echo -e "${CYAN}===========================================================${NC}"
echo -e "${CYAN}  Setup Development Resource Group${NC}"
echo -e "${CYAN}===========================================================${NC}"
echo -e ""
echo -e "${CYAN}Configuration:${NC}"
echo -e "${GRAY}  Resource Group : $RESOURCE_GROUP${NC}"
echo -e "${GRAY}  Location       : $LOCATION${NC}"
echo -e "${GRAY}  Purpose        : Shared development environment${NC}"
echo -e "${GRAY}  Shared With    : pwsh-azure-health, ts-azure-health${NC}"
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

# Check if resource group already exists
echo -e "${CYAN}Checking if resource group exists...${NC}"
if az group show --name "$RESOURCE_GROUP" > /dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  Resource group already exists: $RESOURCE_GROUP${NC}"

  # Show existing resource group details
  RG_INFO=$(az group show --name "$RESOURCE_GROUP" --query "{location:location, provisioningState:properties.provisioningState, tags:tags}" -o json)

  echo -e ""
  echo -e "${GRAY}Existing Resource Group Details:${NC}"
  echo "$RG_INFO" | jq '.'
  echo -e ""
else
  # Create resource group
  echo -e "${CYAN}Creating resource group...${NC}"
  echo -e "${GRAY}This resource group will:${NC}"
  echo -e "${GRAY}  - Host resources for dev environment${NC}"
  echo -e "${GRAY}  - Be shared with pwsh-azure-health project${NC}"
  echo -e "${GRAY}  - Have lock protection to prevent accidental deletion${NC}"
  echo -e ""

  az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --tags environment=dev lifecycle=persistent project=ts-azure-health shared=true \
    --output none

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}[OK] Resource group created: $RESOURCE_GROUP${NC}"
  else
    echo -e "${RED}Error: Failed to create resource group${NC}"
    exit 1
  fi
  echo -e ""
fi

# Add resource lock to prevent accidental deletion
echo -e "${CYAN}Adding resource lock (CanNotDelete)...${NC}"
LOCK_EXISTS=$(az lock list --resource-group "$RESOURCE_GROUP" --query "[?level=='CanNotDelete'].name" -o tsv)

if [ -n "$LOCK_EXISTS" ]; then
  echo -e "${YELLOW}⚠️  CanNotDelete lock already exists: $LOCK_EXISTS${NC}"
else
  az lock create \
    --name "DoNotDeleteDevResourceGroup" \
    --lock-type CanNotDelete \
    --resource-group "$RESOURCE_GROUP" \
    --notes "Protects shared dev resource group from accidental deletion. Shared with pwsh-azure-health. Remove lock before deleting." \
    --output none

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}[OK] Resource lock applied: DoNotDeleteDevResourceGroup${NC}"
    echo -e "${GRAY}  This resource group cannot be deleted unless the lock is removed first.${NC}"
  else
    echo -e "${RED}Error: Failed to create resource lock${NC}"
    exit 1
  fi
fi

echo -e ""

# Verify and show details
echo -e "${CYAN}Verifying resource group...${NC}"
RG_DETAILS=$(az group show --name "$RESOURCE_GROUP" --output json)

echo -e "${GREEN}[OK] Resource group verified${NC}"
echo -e ""
echo -e "${CYAN}===========================================================${NC}"
echo -e "${CYAN}  Resource Group Details${NC}"
echo -e "${CYAN}===========================================================${NC}"
echo -e ""
echo "$RG_DETAILS" | jq '{
  name: .name,
  location: .location,
  provisioningState: .properties.provisioningState,
  tags: .tags
}'

# Show lock details
echo -e ""
echo -e "${CYAN}Resource Locks:${NC}"
az lock list --resource-group "$RESOURCE_GROUP" --output table

echo -e ""
echo -e "${GREEN}===========================================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}===========================================================${NC}"
echo -e ""
echo -e "${CYAN}Next Steps:${NC}"
echo -e "${GRAY}1. Deploy infrastructure to this resource group using:${NC}"
echo -e "${GRAY}   gh workflow run infrastructure-deploy.yml -f environment=dev${NC}"
echo -e ""
echo -e "${GRAY}2. Resources from multiple projects can coexist in this group:${NC}"
echo -e "${GRAY}   - ts-azure-health: Tagged with project=ts-azure-health${NC}"
echo -e "${GRAY}   - pwsh-azure-health: Tagged with project=pwsh-azure-health${NC}"
echo -e ""
echo -e "${GRAY}3. Destroy workflow will only delete ts-azure-health resources${NC}"
echo -e ""
