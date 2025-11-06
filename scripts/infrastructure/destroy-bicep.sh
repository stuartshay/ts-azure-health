#!/usr/bin/env bash
#
# Destroy Azure infrastructure
# Deletes the entire resource group and all resources within it.
#
# Usage:
#   ./destroy-bicep.sh
#   ./destroy-bicep.sh -e prod
#   ./destroy-bicep.sh --environment dev
#

set -euo pipefail

# Default values
ENVIRONMENT="dev"

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

Destroy Azure infrastructure by deleting the resource group.

Options:
  -e, --environment ENV    Environment: dev, staging, or prod (default: dev)
  -h, --help              Display this help message

Examples:
  $(basename "$0")
  $(basename "$0") -e prod
  $(basename "$0") --environment dev

WARNING: This will delete ALL resources in the resource group!

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

echo -e ""
echo -e "${RED}===========================================================${NC}"
echo -e "${RED}  TS Azure Health - Infrastructure Destruction${NC}"
echo -e "${RED}===========================================================${NC}"
echo -e ""
echo -e "${CYAN}Configuration:${NC}"
echo -e "${GRAY}  Resource Group : $RESOURCE_GROUP${NC}"
echo -e "${GRAY}  Environment    : $ENVIRONMENT${NC}"
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
if ! az group exists --name "$RESOURCE_GROUP" > /dev/null 2>&1; then
  echo -e "${YELLOW}Resource group does not exist: $RESOURCE_GROUP${NC}"
  echo -e "${GRAY}Nothing to delete.${NC}"
  exit 0
fi

echo -e "${GREEN}[OK] Resource group exists: $RESOURCE_GROUP${NC}"
echo -e ""

# List resources
echo -e "${CYAN}Resources to be deleted:${NC}"
az resource list --resource-group "$RESOURCE_GROUP" --output table
echo -e ""

# Confirmation prompt
echo -e "${YELLOW}⚠️  WARNING: This will delete ALL resources in $RESOURCE_GROUP${NC}"
echo -e "${YELLOW}⚠️  This action cannot be undone!${NC}"
echo -e ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
  echo -e "${GRAY}Deletion cancelled.${NC}"
  exit 0
fi

# Delete resource group
echo -e "${CYAN}Deleting resource group: $RESOURCE_GROUP${NC}"
echo -e "${GRAY}(This may take several minutes)${NC}"
echo -e ""

az group delete \
  --name "$RESOURCE_GROUP" \
  --yes \
  --no-wait

echo -e ""
echo -e "${GREEN}===========================================================${NC}"
echo -e "${GREEN}  Resource Group Deletion Initiated${NC}"
echo -e "${GREEN}===========================================================${NC}"
echo -e ""
echo -e "${GRAY}Resource group: $RESOURCE_GROUP${NC}"
echo -e ""
echo -e "${YELLOW}Note: Deletion is asynchronous and may take several minutes to complete.${NC}"
echo -e ""
echo -e "${CYAN}To check deletion status:${NC}"
echo -e "${GRAY}  az group show --name $RESOURCE_GROUP${NC}"
echo -e ""
