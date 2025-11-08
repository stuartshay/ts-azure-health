#!/usr/bin/env bash
#
# Setup Shared Resource Group for CI/CD Infrastructure
# Creates the permanent rg-azure-health-shared resource group for GitHub Actions managed identity.
# This resource group should never be deleted as it contains critical CI/CD infrastructure.
#
# Usage:
#   ./setup-shared-rg.sh
#   ./setup-shared-rg.sh -l westus2
#   ./setup-shared-rg.sh --location eastus
#

set -euo pipefail

# Default values
LOCATION="eastus"
RESOURCE_GROUP="rg-azure-health-shared"

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

Setup shared resource group for CI/CD infrastructure (GitHub Actions managed identity).

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
echo -e "${CYAN}  Setup Shared CI/CD Resource Group${NC}"
echo -e "${CYAN}===========================================================${NC}"
echo -e ""
echo -e "${CYAN}Configuration:${NC}"
echo -e "${GRAY}  Resource Group : $RESOURCE_GROUP${NC}"
echo -e "${GRAY}  Location       : $LOCATION${NC}"
echo -e "${GRAY}  Purpose        : Permanent CI/CD infrastructure${NC}"
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
  RG_INFO=$(az group show --name "$RESOURCE_GROUP" --query "{location:location, tags:tags}" -o json)
  RG_LOCATION=$(echo "$RG_INFO" | jq -r '.location')
  RG_TAGS=$(echo "$RG_INFO" | jq -r '.tags')

  echo -e ""
  echo -e "${GRAY}Existing Resource Group Details:${NC}"
  echo -e "${GRAY}  Location: $RG_LOCATION${NC}"
  echo -e "${GRAY}  Tags: $RG_TAGS${NC}"
  echo -e ""

  # Ask if user wants to update tags
  read -p "$(echo -e ${CYAN}Do you want to update the tags? [y/N]:${NC} )" -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}Updating resource group tags...${NC}"
    az group update \
      --name "$RESOURCE_GROUP" \
      --tags purpose=cicd lifecycle=permanent project=ts-azure-health \
      --output none
    echo -e "${GREEN}[OK] Tags updated${NC}"
  else
    echo -e "${GRAY}No changes made${NC}"
  fi

  exit 0
fi

# Create resource group
echo -e "${CYAN}Creating shared resource group...${NC}"
echo -e "${GRAY}This resource group will contain:${NC}"
echo -e "${GRAY}  - GitHub Actions managed identity (id-github-actions-ts-azure-health)${NC}"
echo -e "${GRAY}  - Federated credentials for OIDC authentication${NC}"
echo -e ""
echo -e "${YELLOW}⚠️  This resource group should NEVER be deleted!${NC}"
echo -e "${GRAY}  Deleting it would break all GitHub Actions CI/CD workflows.${NC}"
echo -e ""

az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags purpose=cicd lifecycle=permanent project=ts-azure-health \
  --output none

if [ $? -eq 0 ]; then
  echo -e "${GREEN}[OK] Resource group created: $RESOURCE_GROUP${NC}"
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
  echo -e ""
  echo -e "${GREEN}===========================================================${NC}"
  echo -e "${GREEN}  Setup Complete!${NC}"
  echo -e "${GREEN}===========================================================${NC}"
  echo -e ""
  echo -e "${CYAN}Next Steps:${NC}"
  echo -e "${GRAY}1. Create the GitHub Actions managed identity in this resource group:${NC}"
  echo -e "${GRAY}   az identity create \\${NC}"
  echo -e "${GRAY}     --name id-github-actions-ts-azure-health \\${NC}"
  echo -e "${GRAY}     --resource-group $RESOURCE_GROUP \\${NC}"
  echo -e "${GRAY}     --location $LOCATION${NC}"
  echo -e ""
  echo -e "${GRAY}2. See docs/GITHUB_ACTIONS_SETUP.md for complete setup instructions${NC}"
  echo -e ""
else
  echo -e "${RED}Error: Failed to create resource group${NC}"
  exit 1
fi
