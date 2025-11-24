# CI/CD Scripts

This directory contains CI/CD helper scripts for cost estimation and policy compliance checking.

## Scripts

### Cost Estimation Tools

#### `install-cost-tools.sh`

Installs Azure cost estimation tools for CI/CD pipelines.

**Installs:**

- Azure Cost Estimator (ACE) v1.6.4 - Pre-deployment cost estimation
- azure-cost-cli v0.52.0 - Post-deployment cost analysis

**Usage:**

```bash
./scripts/ci/install-cost-tools.sh
```

**Requirements:**

- wget, unzip
- .NET SDK (for azure-cost-cli)

---

#### `cost-estimate.sh`

Pre-deployment cost estimation from Bicep templates using ACE.

**Usage:**

```bash
./scripts/ci/cost-estimate.sh <bicep_file> <params_file> <subscription_id>
```

**Example:**

```bash
./scripts/ci/cost-estimate.sh \
  infrastructure/main.bicep \
  infrastructure/dev.bicepparam \
  "12345678-1234-1234-1234-123456789012"
```

**Outputs:**

- Estimated monthly costs in USD
- Resource-level cost breakdown
- GitHub Actions outputs and summaries

---

#### `cost-analysis.sh`

Post-deployment actual cost analysis using Azure Cost Management API.

**Usage:**

```bash
./scripts/ci/cost-analysis.sh <resource_group> <subscription_id> [timeframe]
```

**Example:**

```bash
./scripts/ci/cost-analysis.sh \
  rg-azure-health-dev \
  "12345678-1234-1234-1234-123456789012" \
  MonthToDate
```

**Timeframes:**

- `MonthToDate` (default)
- `WeekToDate`
- `Custom`

---

### Policy Compliance

#### `policy-check.sh`

Azure Policy compliance checking for resource groups.

**Usage:**

```bash
./scripts/ci/policy-check.sh <resource_group> <subscription_id>
```

**Example:**

```bash
./scripts/ci/policy-check.sh \
  rg-azure-health-dev \
  "12345678-1234-1234-1234-123456789012"
```

**Checks:**

- Policy assignments
- Compliance state
- Policy exemptions
- Non-compliant resources

---

### Verification

#### `verify-cost-tools.sh`

Verifies that cost estimation tools are properly installed.

**Usage:**

```bash
./scripts/ci/verify-cost-tools.sh
```

**Checks:**

- ACE installation and version
- azure-cost-cli installation
- .NET runtime availability

**Example output:**

```
🔍 Verifying cost estimation tools installation...

1. Checking Azure Cost Estimator (ACE)...
✅ ACE installed: 1.6.4+386fcdd9a45653ae9a5ca395e78e65f23f8d4397
   Location: /home/node/.local/bin/ace/azure-cost-estimator

2. Checking azure-cost-cli...
✅ azure-cost-cli installed
   Location: /home/node/.dotnet/tools/azure-cost

3. Checking .NET runtime...
✅ .NET SDK installed
   Microsoft.NETCore.App 9.0.11
   Microsoft.NETCore.App 10.0.0

✅ All cost estimation tools are properly installed!
```

---

## DevContainer Setup

Cost tools are automatically installed when the DevContainer is created via `.devcontainer/postCreate.sh`.

**What gets installed:**

1. **ACE (Azure Cost Estimator)**
   - Downloaded to `~/.local/bin/ace/`
   - Added to PATH in `.bashrc` and `.zshrc`
   - Version: 1.6.4

2. **azure-cost-cli**
   - Installed via .NET global tool
   - Requires .NET 9 runtime (auto-installed)
   - Version: 0.52.0

3. **.NET 9 Runtime**
   - Required for azure-cost-cli
   - Installed alongside .NET 10 SDK

**Verify installation:**

```bash
./scripts/ci/verify-cost-tools.sh
```

---

## Testing

BATS tests are available in `scripts/ci/tests/`.

**Run all tests:**

```bash
bats scripts/ci/tests/
```

**Run specific test:**

```bash
bats scripts/ci/tests/cost-estimate.bats
```

See [scripts/ci/tests/README.md](tests/README.md) for detailed test documentation.

---

## GitHub Actions Integration

These scripts are integrated into `.github/workflows/infrastructure-whatif.yml`:

```yaml
- name: Install cost estimation tools
  run: ./scripts/ci/install-cost-tools.sh

- name: Cost Estimation for Dev environment
  run: |
    ./scripts/ci/cost-estimate.sh \
      infrastructure/main.bicep \
      infrastructure/dev.bicepparam \
      "${{ secrets.AZURE_SUBSCRIPTION_ID }}"

- name: Policy Check for Dev environment
  run: |
    ./scripts/ci/policy-check.sh \
      rg-azure-health-dev \
      "${{ secrets.AZURE_SUBSCRIPTION_ID }}"
```

---

## Documentation

- [Cost Estimation Guide](../../docs/COST_ESTIMATION.md) - Complete cost estimation framework documentation
- [Policy Testing Guide](../../docs/POLICY_TESTING.md) - Azure Policy compliance framework documentation
- [GitHub Actions Setup](../../docs/GITHUB_ACTIONS_SETUP.md) - CI/CD pipeline configuration

---

## Troubleshooting

### ACE not found

```bash
# Reinstall ACE
ACE_VERSION="1.6.4"
ACE_INSTALL_DIR="$HOME/.local/bin/ace"
mkdir -p "$ACE_INSTALL_DIR"
wget "https://github.com/TheCloudTheory/arm-estimator/releases/download/${ACE_VERSION}/linux-x64.zip" -O /tmp/ace.zip
unzip /tmp/ace.zip -d "$ACE_INSTALL_DIR"
chmod +x "$ACE_INSTALL_DIR/azure-cost-estimator"
```

### azure-cost-cli not working

```bash
# Check .NET 9 runtime
dotnet --list-runtimes | grep "9.0"

# Reinstall azure-cost-cli
dotnet tool uninstall --global azure-cost-cli
dotnet tool install --global azure-cost-cli --version 0.52.0

# Add to PATH
export PATH="$HOME/.dotnet/tools:$PATH"
```

### .NET 9 runtime missing

```bash
# Install .NET 9 runtime
wget https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh
chmod +x /tmp/dotnet-install.sh
sudo /tmp/dotnet-install.sh --channel 9.0 --runtime dotnet --install-dir /usr/share/dotnet
```

---

## References

- [Azure Cost Estimator (ACE)](https://github.com/TheCloudTheory/arm-estimator)
- [azure-cost-cli](https://github.com/mivano/azure-cost-cli)
- [Azure Cost Management](https://docs.microsoft.com/azure/cost-management-billing/)
- [Azure Policy](https://docs.microsoft.com/azure/governance/policy/)
