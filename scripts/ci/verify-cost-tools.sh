#!/bin/bash
#
# Verify Cost Estimation Tools Installation
# Quick check that ACE and azure-cost-cli are properly installed

set -e

echo "🔍 Verifying cost estimation tools installation..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check ACE
echo "1. Checking Azure Cost Estimator (ACE)..."
ACE_PATH="$HOME/.local/bin/ace/azure-cost-estimator"
if [ -x "$ACE_PATH" ]; then
    VERSION=$("$ACE_PATH" --version 2>&1 || echo "unknown")
    echo -e "${GREEN}✅ ACE installed: $VERSION${NC}"
    echo "   Location: $ACE_PATH"
else
    echo -e "${RED}❌ ACE not found at $ACE_PATH${NC}"
    echo "   Run: ./scripts/ci/install-cost-tools.sh"
    exit 1
fi
echo ""

# Check azure-cost-cli
echo "2. Checking azure-cost-cli..."
export PATH="$HOME/.dotnet/tools:$PATH"
if command -v azure-cost &> /dev/null; then
    echo -e "${GREEN}✅ azure-cost-cli installed${NC}"
    echo "   Location: $(which azure-cost)"
    echo "   Testing connection..."
    if azure-cost --help &> /dev/null; then
        echo -e "${GREEN}   ✓ Command works${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Command runs but may need authentication${NC}"
    fi
else
    echo -e "${RED}❌ azure-cost-cli not found${NC}"
    echo "   Run: dotnet tool install --global azure-cost-cli --version 0.52.0"
    exit 1
fi
echo ""

# Check .NET runtime
echo "3. Checking .NET runtime..."
if command -v dotnet &> /dev/null; then
    echo -e "${GREEN}✅ .NET SDK installed${NC}"
    dotnet --list-runtimes | grep "Microsoft.NETCore.App" | while read -r line; do
        echo "   $line"
    done
else
    echo -e "${RED}❌ .NET SDK not found${NC}"
    exit 1
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ All cost estimation tools are properly installed!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Usage:"
echo "  ACE (pre-deployment):     $ACE_PATH <template.json> <subscription-id>"
echo "  azure-cost-cli (actual):  azure-cost --subscription <id> --resource-group <name>"
echo ""
