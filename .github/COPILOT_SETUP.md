# GitHub Copilot Coding Agent Setup

This document explains the setup required for GitHub Copilot coding agent to work with this repository.

## Firewall Configuration

The Copilot coding agent runs in a sandboxed environment with firewall restrictions. Some operations require access to external resources that are blocked by default.

### Known Blocked Domains

- `aka.ms` - Microsoft's URL shortener, used by:
  - Azure Bicep CLI for downloading modules
  - Azure CLI for telemetry and updates
  - Microsoft documentation links

### Solution: Pre-Firewall Setup Steps

The `.github/workflows/copilot.yml` workflow file contains setup steps that run **before** the firewall is enabled. This allows the agent to:

1. Download and install Azure Bicep CLI
2. Cache Bicep modules
3. Configure Azure CLI (if credentials are available)

### Workflow Configuration

```yaml
# .github/workflows/copilot.yml
steps:
  - name: Setup Azure Bicep CLI
    run: |
      curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
      chmod +x ./bicep
      sudo mv ./bicep /usr/local/bin/bicep
```

## Alternative Solutions

If you have admin access to the repository, you can also:

1. **Add to allowlist**: Go to [Copilot coding agent settings](https://github.com/stuartshay/ts-azure-health/settings/copilot/coding_agent)
2. **Add domains**: 
   - `aka.ms`
   - `github.com/Azure/bicep/*` (for direct downloads)

## Bicep Validation

### During Development

Bicep files are NOT validated during pre-commit hooks to avoid firewall issues. Validation happens:

1. **GitHub Actions**: During infrastructure deployment workflows
2. **Local development**: Using Azure CLI (`az bicep build`)
3. **Manual validation**: Using the Bicep CLI directly

### Validation Commands

```bash
# Validate a Bicep file
bicep build infrastructure/main.bicep

# Validate parameter files
bicep build-params infrastructure/dev.bicepparam --stdout

# What-if deployment (requires Azure login)
az deployment group what-if \
  --resource-group rg-ts-azure-health-dev \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/dev.bicepparam
```

## Troubleshooting

### Error: "DNS block" when running Bicep commands

**Cause**: Copilot coding agent cannot access `aka.ms` after firewall is enabled.

**Solution**: 
1. Ensure `.github/workflows/copilot.yml` exists and is properly configured
2. Bicep CLI should be installed during setup steps
3. Avoid running `bicep build` commands in scripts that the agent executes

### Error: "Unable to download Bicep modules"

**Cause**: Bicep tries to restore modules from online sources.

**Solution**:
1. Pre-cache modules in the setup workflow
2. Use local Bicep modules (in `infrastructure/modules/`)
3. Avoid external module references like `br/public:...`

## Best Practices

1. **Use local modules**: Keep all Bicep modules in `infrastructure/modules/` directory
2. **Cache dependencies**: Use GitHub Actions cache for Bicep modules
3. **Defer validation**: Don't validate Bicep during agent execution; rely on CI/CD workflows
4. **Test workflows**: Ensure setup steps run successfully before agent work begins

## Related Files

- `.github/workflows/copilot.yml` - Setup workflow
- `.github/workflows/infrastructure-deploy.yml` - Deployment with Bicep
- `.github/workflows/infrastructure-whatif.yml` - What-if validation
- `infrastructure/README.md` - Infrastructure documentation
