# Azure Cost Estimation

This document describes the cost estimation framework implemented in the CI/CD pipeline for infrastructure changes.

## Overview

The cost estimation framework provides automated cost analysis for Azure infrastructure deployments using two complementary tools:

1. **Azure Cost Estimator (ACE)** - Pre-deployment cost estimation from Bicep templates
2. **azure-cost-cli** - Post-deployment actual cost analysis via Azure Cost Management API

## Features

### Pre-Deployment Cost Estimation

- **Tool**: Azure Cost Estimator (ACE) v1.6.4
- **Purpose**: Estimate costs before deployment based on Bicep templates
- **Timing**: Runs during pull request what-if workflow
- **Output**:
  - Estimated monthly cost in USD
  - Cost breakdown by resource type
  - Markdown summary in PR comments
  - GitHub Actions step summary

### Post-Deployment Cost Analysis

- **Tool**: azure-cost-cli v0.52.0
- **Purpose**: Analyze actual costs after deployment
- **Timing**: Can be run manually or scheduled
- **Output**:
  - Actual costs from Azure Cost Management API
  - Cost comparison with estimates
  - Cost status (within budget, over budget, etc.)

## How It Works

### 1. GitHub Actions Workflow Integration

The cost estimation is integrated into the `infrastructure-whatif.yml` workflow:

```yaml
- name: Install cost estimation tools
  run: ./scripts/ci/install-cost-tools.sh

- name: Cost Estimation for Dev environment
  run: |
    ./scripts/ci/cost-estimate.sh \
      infrastructure/main.bicep \
      infrastructure/dev.bicepparam \
      "${{ secrets.AZURE_SUBSCRIPTION_ID }}"
```

### 2. Pull Request Comments

When you create a PR that modifies infrastructure files, the workflow automatically:

1. Runs what-if preview
2. Estimates deployment costs
3. Checks policy compliance
4. Posts a comprehensive comment with all information

Example PR comment:

```markdown
## 🔍 Infrastructure What-If Preview

### Dev Environment What-If

...what-if output...

### 💰 Cost Estimation

- **Estimated Monthly Cost**: $45.67 USD
- **Resource Breakdown**:
  - App Service Plan: $20.00 USD
  - Key Vault: $5.00 USD
  - Container Registry: $20.67 USD

### 🔒 Policy Compliance

- **Status**: ✅ Compliant
- **Policies Checked**: 12
- **Non-Compliant**: 0
```

## Scripts Reference

### install-cost-tools.sh

Installs ACE and azure-cost-cli in the GitHub Actions runner.

**Usage**:

```bash
./scripts/ci/install-cost-tools.sh
```

**Requirements**:

- wget
- unzip
- .NET SDK (for azure-cost-cli)

### cost-estimate.sh

Estimates deployment costs from Bicep templates using ACE.

**Usage**:

```bash
./scripts/ci/cost-estimate.sh <bicep_file> <params_file> <subscription_id>
```

**Parameters**:

- `bicep_file`: Path to main Bicep template
- `params_file`: Path to Bicep parameters file
- `subscription_id`: Azure subscription ID

**Outputs**:

- `GITHUB_OUTPUT`: `estimated_cost` variable
- `GITHUB_STEP_SUMMARY`: Markdown summary
- `/tmp/cost-summary.md`: Cost summary for PR comments

**Example**:

```bash
./scripts/ci/cost-estimate.sh \
  infrastructure/main.bicep \
  infrastructure/dev.bicepparam \
  "12345678-1234-1234-1234-123456789012"
```

### cost-analysis.sh

Analyzes actual costs from deployed resources using azure-cost-cli.

**Usage**:

```bash
./scripts/ci/cost-analysis.sh <resource_group> <subscription_id> [timeframe]
```

**Parameters**:

- `resource_group`: Azure resource group name
- `subscription_id`: Azure subscription ID
- `timeframe`: (Optional) Cost timeframe - MonthToDate, WeekToDate, Custom (default: MonthToDate)

**Outputs**:

- `GITHUB_OUTPUT`: `actual_cost`, `cost_status` variables
- `GITHUB_STEP_SUMMARY`: Markdown summary with cost details

**Example**:

```bash
./scripts/ci/cost-analysis.sh \
  rg-azure-health-dev \
  "12345678-1234-1234-1234-123456789012" \
  MonthToDate
```

## Configuration

### Azure Subscription ID

The subscription ID is required for cost estimation and is stored as a GitHub secret:

```
AZURE_SUBSCRIPTION_ID
```

### Custom Pricing Data (Optional)

You can create a `cost-config.json` file to provide custom pricing data for ACE:

```json
{
  "customPricing": {
    "regions": {
      "eastus": {
        "compute": {
          "virtualMachines": {
            "Standard_D2s_v3": 0.096
          }
        }
      }
    }
  }
}
```

Place this file in the `infrastructure/` directory, and the cost estimation script will automatically use it.

## Limitations

### ACE (Pre-deployment)

- Cost estimates are approximate and based on Azure pricing data
- Some resources may not have accurate pricing information
- Estimates don't include bandwidth, storage transactions, or usage-based costs
- Custom pricing may be needed for accurate estimates in some regions

### azure-cost-cli (Post-deployment)

- Requires deployed resources to analyze
- Cost data may have up to 24-hour delay
- Requires appropriate Azure RBAC permissions:
  - `Cost Management Reader` or higher on subscription/resource group

## Troubleshooting

### "ACE not found" Error

**Cause**: ACE binary not installed or not in PATH

**Solution**: Run `./scripts/ci/install-cost-tools.sh` first

### "azure-cost-cli command not found"

**Cause**: .NET tool not installed or not in PATH

**Solution**:

```bash
dotnet tool install --global azure-cost-cli --version 0.52.0
export PATH="$PATH:$HOME/.dotnet/tools"
```

### "Cost data not available"

**Cause**: Azure Cost Management data not yet available (24-hour delay) or insufficient permissions

**Solution**:

- Wait 24 hours after deployment
- Verify `Cost Management Reader` role assignment
- Check subscription billing account status

### "Unable to build Bicep file"

**Cause**: Bicep syntax errors or missing parameters

**Solution**:

- Run `az bicep build --file infrastructure/main.bicep` locally
- Fix any syntax errors
- Ensure all required parameters are provided in the `.bicepparam` file

## Best Practices

1. **Review Estimates**: Always review cost estimates in PR comments before merging infrastructure changes
2. **Set Budgets**: Configure Azure Cost Management budgets for alerts
3. **Monitor Trends**: Regularly run cost analysis to track spending trends
4. **Optimize Resources**: Use cost estimates to identify optimization opportunities
5. **Document Decisions**: Document why certain resource SKUs were chosen (cost vs. performance trade-offs)

## References

- [Azure Cost Estimator (ACE)](https://github.com/TheCloudTheory/arm-estimator)
- [azure-cost-cli](https://github.com/mivano/azure-cost-cli)
- [Azure Cost Management](https://docs.microsoft.com/azure/cost-management-billing/)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)

## Related Documentation

- [Policy Testing](POLICY_TESTING.md) - Azure Policy compliance checking
- [GitHub Actions Setup](GITHUB_ACTIONS_SETUP.md) - CI/CD workflow configuration
- [Development Setup](DEVELOPMENT_SETUP.md) - Local development environment
