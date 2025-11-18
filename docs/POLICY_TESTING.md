# Azure Policy Testing

This document describes the Azure Policy compliance checking framework implemented in the CI/CD pipeline.

## Overview

The policy testing framework provides automated compliance checking for Azure resources against Azure Policy assignments. It helps ensure that infrastructure deployments comply with organizational policies before and after deployment.

## Features

- **Pre-deployment Policy Validation**: Check policy compliance before deploying infrastructure
- **Assignment Discovery**: Automatically discover all policy assignments for a resource group
- **Compliance State**: Report on compliant, non-compliant, and exempt resources
- **Exemption Tracking**: Identify and report on policy exemptions
- **GitHub Integration**: Automated reporting in PR comments and workflow summaries

## How It Works

### 1. GitHub Actions Workflow Integration

The policy checking is integrated into the `infrastructure-whatif.yml` workflow:

```yaml
- name: Policy Check for Dev environment
  run: |
    ./scripts/ci/policy-check.sh \
      rg-azure-health-dev \
      "${{ secrets.AZURE_SUBSCRIPTION_ID }}"
```

### 2. Pull Request Comments

When you create a PR that modifies infrastructure files, the workflow automatically:

1. Runs what-if preview
2. Estimates deployment costs
3. **Checks policy compliance**
4. Posts a comprehensive comment with all information

Example policy section in PR comment:

```markdown
### 🔒 Policy Compliance - Dev Environment

**Status**: ⚠️ Non-Compliant

**Summary**:

- Total Policies: 15
- Compliant Resources: 12
- Non-Compliant Resources: 2
- Exempt Resources: 1

**Policy Assignments**:

- ✅ Require tags on resources
- ✅ Allowed resource types
- ⚠️ Require HTTPS for storage accounts (2 non-compliant)
- ✅ Geo-redundant backup enabled

**Non-Compliant Resources**:

1. `/subscriptions/.../resourceGroups/rg-azure-health-dev/providers/Microsoft.Storage/storageAccounts/devst123`

   - Policy: Require HTTPS for storage accounts
   - Reason: HTTPS-only traffic not enabled

2. `/subscriptions/.../resourceGroups/rg-azure-health-dev/providers/Microsoft.Storage/storageAccounts/devst456`
   - Policy: Require HTTPS for storage accounts
   - Reason: HTTPS-only traffic not enabled

**Exemptions**:

- `devkv123` - Key Vault: Legacy application compatibility (expires: 2025-06-01)
```

## Scripts Reference

### policy-check.sh

Checks Azure Policy compliance for a resource group.

**Usage**:

```bash
./scripts/ci/policy-check.sh <resource_group> <subscription_id>
```

**Parameters**:

- `resource_group`: Azure resource group name
- `subscription_id`: Azure subscription ID

**Outputs**:

- `GITHUB_OUTPUT`: `policy_summary`, `non_compliant_count`, `policy_status` variables
- `GITHUB_STEP_SUMMARY`: Markdown summary with policy details
- `/tmp/policy-summary.md`: Policy summary for PR comments

**Exit Codes**:

- `0`: All policies compliant or informational
- `1`: Script error or invalid parameters
- `2`: Non-compliant resources found (warning only, doesn't fail workflow)

**Example**:

```bash
./scripts/ci/policy-check.sh \
  rg-azure-health-dev \
  "12345678-1234-1234-1234-123456789012"
```

## Azure Policy Concepts

### Policy Definitions

A policy definition describes a rule and its effect (e.g., "deny", "audit", "append").

Example: "Storage accounts should use HTTPS-only traffic"

### Policy Assignments

An assignment applies a policy definition to a scope (subscription, resource group, or resource).

### Compliance States

- **Compliant**: Resource meets policy requirements
- **Non-Compliant**: Resource violates policy requirements
- **Exempt**: Resource has an approved exemption
- **Conflict**: Multiple policies with conflicting effects
- **Unknown**: Compliance state not yet evaluated

### Policy Exemptions

Exemptions allow specific resources to bypass policy enforcement, typically for:

- Legacy systems requiring migration time
- Testing/development environments
- Special business requirements

**Best Practice**: Always set an expiration date on exemptions.

## Common Azure Policies

### Security

- **Require HTTPS**: Ensure secure communication for web apps and storage
- **Require TLS 1.2+**: Enforce modern encryption standards
- **Disable public network access**: Prevent exposure of sensitive resources
- **Require Azure AD authentication**: Enforce identity-based access

### Tagging

- **Require tags**: Enforce cost center, owner, environment tags
- **Inherit tags from resource group**: Automatic tag propagation
- **Allowed tag values**: Enforce naming conventions

### Resource Management

- **Allowed resource types**: Restrict deployment to approved services
- **Allowed locations**: Enforce data residency requirements
- **Allowed VM SKUs**: Control compute costs
- **Require diagnostic logs**: Ensure audit trail

### Cost Management

- **Maximum VM size**: Prevent expensive deployments
- **Require budget tags**: Enable cost tracking
- **Geo-redundant backup**: Balance cost and reliability

## Azure RBAC Permissions

The policy checking script requires the following permissions:

### Minimum Required Roles

- **Reader** on the resource group (to list policy assignments)
- **Resource Policy Contributor** or **Owner** (to view policy compliance state)

### Alternative: Custom Role

Create a custom role with these permissions:

```json
{
  "Name": "Policy Compliance Reader",
  "Description": "Can read policy assignments and compliance state",
  "Actions": [
    "Microsoft.Authorization/policyAssignments/read",
    "Microsoft.PolicyInsights/policyStates/*/read",
    "Microsoft.Authorization/policyExemptions/read"
  ],
  "NotActions": [],
  "AssignableScopes": ["/subscriptions/{subscription-id}"]
}
```

## Configuration

### GitHub Secrets

Required secrets for policy checking:

```
AZURE_SUBSCRIPTION_ID    # Azure subscription ID
AZURE_CLIENT_ID         # Service principal client ID
AZURE_TENANT_ID         # Azure AD tenant ID
```

### Service Principal Setup

The service principal must have appropriate permissions:

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-policy-checker" \
  --role "Reader" \
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-azure-health-dev

# Grant Policy Insights Reader role
az role assignment create \
  --assignee {service-principal-app-id} \
  --role "Resource Policy Contributor" \
  --scope /subscriptions/{subscription-id}/resourceGroups/rg-azure-health-dev
```

## Workflow Behavior

### Continue on Error

The policy check step uses `continue-on-error: true` to prevent workflow failures:

```yaml
- name: Policy Check for Dev environment
  continue-on-error: true
  run: ./scripts/ci/policy-check.sh ...
```

**Why?**:

- Policy violations should be **warnings**, not blockers
- Allows visibility into compliance issues without blocking deployments
- Team can review and address issues in subsequent PRs

### Enforcement Mode

To enforce policy compliance (fail on violations), modify the script exit code handling:

```bash
# In policy-check.sh, change exit code:
if [ "$NON_COMPLIANT_COUNT" -gt 0 ]; then
  exit 1  # Fail workflow
fi
```

And remove `continue-on-error` from the workflow step.

## Troubleshooting

### "Resource group not found"

**Cause**: Resource group doesn't exist yet

**Solution**: Policy checks run only if resource group exists; this is expected for new environments

### "No policy assignments found"

**Cause**: No policies assigned at resource group or subscription level

**Solution**:

- Verify policy assignments: `az policy assignment list --resource-group {rg-name}`
- Check subscription-level policies
- This is informational; not an error

### "Forbidden" or "Authorization failed"

**Cause**: Insufficient permissions to read policy state

**Solution**:

- Verify service principal has `Reader` + `Resource Policy Contributor` roles
- Check role assignment scope includes the resource group
- Verify secrets are correctly configured

### "Policy state not available"

**Cause**: Resources recently deployed; compliance not yet evaluated

**Solution**:

- Wait 5-15 minutes for Azure Policy evaluation
- Manually trigger evaluation: `az policy state trigger-scan`

### "Exemption expired"

**Cause**: Policy exemption has passed its expiration date

**Solution**:

- Review if exemption is still needed
- If yes, extend exemption: `az policy exemption update`
- If no, remediate the non-compliant resource

## Best Practices

### 1. Review Policy Compliance in PRs

Always review the policy compliance section before merging infrastructure changes:

```markdown
⚠️ Non-Compliant: 2 resources

- Review violations
- Determine if exemption needed
- Document decision in PR
```

### 2. Create Exemptions When Needed

For legitimate exceptions, create documented exemptions:

```bash
az policy exemption create \
  --name "legacy-app-https-exemption" \
  --policy-assignment "{assignment-id}" \
  --resource-group "rg-azure-health-dev" \
  --exemption-category "Waiver" \
  --expires-on "2025-12-31" \
  --description "Legacy app requires HTTP during migration period"
```

### 3. Set Expiration Dates

Always set expiration dates on exemptions to trigger review:

```bash
--expires-on "2025-06-01"
```

### 4. Use Initiative Assignments

Group related policies into initiatives (policy sets):

```bash
az policy set-definition create \
  --name "security-baseline" \
  --definitions @policy-set.json
```

### 5. Test Policies in Dev First

- Assign new policies to dev environments first
- Use "audit" mode before "deny" mode
- Monitor compliance for 30 days
- Remediate issues before enforcing

### 6. Monitor Compliance Trends

Track compliance over time:

```bash
az policy state list \
  --resource-group "rg-azure-health-dev" \
  --from "2025-01-01T00:00:00Z"
```

### 7. Automate Remediation

For simple violations, use remediation tasks:

```bash
az policy remediation create \
  --name "remediate-https" \
  --policy-assignment "{assignment-id}" \
  --resource-group "rg-azure-health-dev"
```

## Policy Lifecycle

### 1. Define Phase

Define organizational requirements:

- Security standards
- Compliance requirements (HIPAA, PCI-DSS, SOC 2)
- Cost controls
- Tagging conventions

### 2. Implement Phase

Create and assign policies:

- Start with built-in Azure policies
- Create custom policies for specific needs
- Assign at appropriate scope

### 3. Audit Phase

Monitor compliance without enforcement:

- Use "audit" effect
- Review compliance reports
- Identify patterns of violations

### 4. Enforce Phase

Transition to enforcement:

- Change effect to "deny" or "deployIfNotExists"
- Communicate changes to teams
- Provide remediation guidance

### 5. Review Phase

Regularly review policies:

- Remove obsolete policies
- Update policies for new Azure features
- Review exemptions

## Integration with Other Tools

### Azure DevOps

Export policy compliance to Azure DevOps:

```bash
az policy state list \
  --output json > policy-compliance.json
```

### Azure Security Center

Policy compliance integrates with Security Center:

- Regulatory compliance dashboard
- Secure score
- Recommendations

### Azure Monitor

Create alerts for policy violations:

```bash
az monitor metrics alert create \
  --name "policy-violation-alert" \
  --resource-group "rg-azure-health-dev" \
  --condition "NonCompliantResources > 0"
```

## References

- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [Built-in Policy Definitions](https://docs.microsoft.com/azure/governance/policy/samples/built-in-policies)
- [Policy Effects](https://docs.microsoft.com/azure/governance/policy/concepts/effects)
- [Policy Exemptions](https://docs.microsoft.com/azure/governance/policy/concepts/exemption-structure)
- [Azure Policy CLI](https://docs.microsoft.com/cli/azure/policy)

## Related Documentation

- [Cost Estimation](COST_ESTIMATION.md) - Azure cost estimation framework
- [GitHub Actions Setup](GITHUB_ACTIONS_SETUP.md) - CI/CD workflow configuration
- [Development Setup](DEVELOPMENT_SETUP.md) - Local development environment
