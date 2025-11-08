#!/usr/bin/env bash
#
# Setup Shared Key Vault for All Environments
# Creates a centralized Key Vault in rg-azure-health-shared for dev/staging/prod secrets.
# This Key Vault persists across environment destroys and avoids soft-delete conflicts.
#
# Usage:
#   ./setup-shared-keyvault.sh
#   ./setup-shared-keyvault.sh -l westus2
#

set -euo pipefail

# Default values
LOCATION="eastus"
RESOURCE_GROUP="rg-azure-health-shared"
KEY_VAULT_NAME="kv-tsazurehealth"

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

Setup shared Key Vault for all environments (dev, staging, prod).

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
echo -e "${CYAN}  Setup Shared Key Vault${NC}"
echo -e "${CYAN}===========================================================${NC}"
echo -e ""
echo -e "${CYAN}Configuration:${NC}"
echo -e "${GRAY}  Key Vault Name : $KEY_VAULT_NAME${NC}"
echo -e "${GRAY}  Resource Group : $RESOURCE_GROUP${NC}"
echo -e "${GRAY}  Location       : $LOCATION${NC}"
echo -e "${GRAY}  Purpose        : Centralized secrets for all environments${NC}"
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

# Check if resource group exists
echo -e "${CYAN}Checking if resource group exists...${NC}"
if ! az group show --name "$RESOURCE_GROUP" > /dev/null 2>&1; then
  echo -e "${RED}Error: Resource group does not exist: $RESOURCE_GROUP${NC}"
  echo -e "${GRAY}Run ./setup-shared-rg.sh first to create it.${NC}"
  exit 1
fi
echo -e "${GREEN}[OK] Resource group exists${NC}"
echo -e ""

# Check if Key Vault already exists
echo -e "${CYAN}Checking if Key Vault exists...${NC}"
if az keyvault show --name "$KEY_VAULT_NAME" > /dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  Key Vault already exists: $KEY_VAULT_NAME${NC}"
  
  # Show existing Key Vault details
  KV_INFO=$(az keyvault show --name "$KEY_VAULT_NAME" --query "{location:location, properties:{enableRbacAuthorization:properties.enableRbacAuthorization, publicNetworkAccess:properties.publicNetworkAccess}, tags:tags}" -o json)
  
  echo -e ""
  echo -e "${GRAY}Existing Key Vault Details:${NC}"
  echo "$KV_INFO" | jq '.'
  echo -e ""
  echo -e "${GREEN}Key Vault is already configured and ready to use.${NC}"
  exit 0
fi

# Check if Key Vault is soft-deleted
echo -e "${CYAN}Checking for soft-deleted Key Vault...${NC}"
DELETED_KV=$(az keyvault list-deleted --query "[?name=='$KEY_VAULT_NAME'].name" -o tsv)

if [ -n "$DELETED_KV" ]; then
  echo -e "${YELLOW}⚠️  Key Vault exists in soft-deleted state${NC}"
  echo -e ""
  
  read -p "$(echo -e ${CYAN}Do you want to recover or purge it? [recover/purge/cancel]:${NC} )" -r REPLY
  echo

  case "$REPLY" in
    recover|r)
      echo -e "${CYAN}Recovering soft-deleted Key Vault...${NC}"
      az keyvault recover --name "$KEY_VAULT_NAME" --location "$LOCATION" --output none
      echo -e "${GREEN}[OK] Key Vault recovered${NC}"
      
      # Update tags
      echo -e "${CYAN}Updating tags...${NC}"
      az keyvault update \
        --name "$KEY_VAULT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --set tags.purpose=shared-secrets tags.lifecycle=permanent tags.project=ts-azure-health \
        --output none
      echo -e "${GREEN}[OK] Tags updated${NC}"
      ;;
    purge|p)
      echo -e "${CYAN}Purging soft-deleted Key Vault...${NC}"
      az keyvault purge --name "$KEY_VAULT_NAME" --location "$LOCATION"
      echo -e "${GREEN}[OK] Key Vault purged${NC}"
      echo -e ""
      echo -e "${CYAN}Creating new Key Vault...${NC}"
      # Continue to creation below
      ;;
    *)
      echo -e "${GRAY}Operation cancelled${NC}"
      exit 0
      ;;
  esac
fi

# Create Key Vault if it doesn't exist (and wasn't recovered)
if ! az keyvault show --name "$KEY_VAULT_NAME" > /dev/null 2>&1; then
  echo -e "${CYAN}Creating shared Key Vault...${NC}"
  echo -e "${GRAY}This Key Vault will:${NC}"
  echo -e "${GRAY}  - Store secrets for all environments (dev, staging, prod)${NC}"
  echo -e "${GRAY}  - Use RBAC authorization (no access policies)${NC}"
  echo -e "${GRAY}  - Persist across environment destroys${NC}"
  echo -e "${GRAY}  - Have soft-delete enabled (90 day retention)${NC}"
  echo -e ""

  az keyvault create \
    --name "$KEY_VAULT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --enable-rbac-authorization true \
    --enabled-for-deployment false \
    --enabled-for-template-deployment false \
    --enabled-for-disk-encryption false \
    --public-network-access Enabled \
    --tags purpose=shared-secrets lifecycle=permanent project=ts-azure-health \
    --output none

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}[OK] Key Vault created: $KEY_VAULT_NAME${NC}"
  else
    echo -e "${RED}Error: Failed to create Key Vault${NC}"
    exit 1
  fi
fi

echo -e ""

# Verify and show details
echo -e "${CYAN}Verifying Key Vault...${NC}"
KV_DETAILS=$(az keyvault show --name "$KEY_VAULT_NAME" --output json)

echo -e "${GREEN}[OK] Key Vault verified${NC}"
echo -e ""
echo -e "${CYAN}===========================================================${NC}"
echo -e "${CYAN}  Key Vault Details${NC}"
echo -e "${CYAN}===========================================================${NC}"
echo -e ""
echo "$KV_DETAILS" | jq '{
  name: .name,
  resourceGroup: .resourceGroup,
  location: .location,
  vaultUri: .properties.vaultUri,
  enableRbacAuthorization: .properties.enableRbacAuthorization,
  publicNetworkAccess: .properties.publicNetworkAccess,
  tags: .tags
}'
echo -e ""
echo -e "${GREEN}===========================================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}===========================================================${NC}"
echo -e ""
echo -e "${CYAN}Next Steps:${NC}"
echo -e "${GRAY}1. Grant environment managed identities access to Key Vault:${NC}"
echo -e "${GRAY}   - This will be done automatically by the infrastructure workflows${NC}"
echo -e "${GRAY}   - Each environment's managed identity gets 'Key Vault Secrets User' role${NC}"
echo -e ""
echo -e "${GRAY}2. Update infrastructure/main.bicep to reference this shared Key Vault${NC}"
echo -e "${GRAY}   - Remove Key Vault resource definition${NC}"
echo -e "${GRAY}   - Add existing Key Vault reference${NC}"
echo -e ""
echo -e "${GRAY}3. Add secrets to the Key Vault as needed${NC}"
echo -e ""
