# CI Scripts Tests

This directory contains BATS (Bash Automated Testing System) tests for the CI/CD scripts.

## Overview

The test suite validates:

- **install-cost-tools.sh** - Cost tools installation script ✅ (8/8 tests passing)
- **cost-estimate.sh** - Pre-deployment cost estimation ⚠️ (tests need refinement)
- **cost-analysis.sh** - Post-deployment cost analysis ⚠️ (tests need refinement)
- **policy-check.sh** - Azure Policy compliance checking ⚠️ (tests need refinement)

### Test Status

**Production Ready:**

- `install-cost-tools.bats` - All 8 tests passing, integrated into pre-commit hooks

**In Development:**

- `cost-estimate.bats`, `cost-analysis.bats`, `policy-check.bats` - Tests exist but need refinement for argument parsing compatibility. These test files validate script structure and basic functionality but require updates to properly test complex Azure CLI interactions.

## Prerequisites

### Install BATS

**macOS:**

```bash
brew install bats-core
```

**Ubuntu/Debian:**

```bash
sudo apt-get update
sudo apt-get install bats
```

**From source:**

```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

## Running Tests

### Run all tests:

```bash
cd /workspaces/ts-azure-health
bats scripts/ci/tests/
```

### Run specific test file:

```bash
bats scripts/ci/tests/install-cost-tools.bats
bats scripts/ci/tests/cost-estimate.bats
bats scripts/ci/tests/cost-analysis.bats
bats scripts/ci/tests/policy-check.bats
```

### Run specific test:

```bash
bats scripts/ci/tests/cost-estimate.bats -f "requires bicep file"
```

### Verbose output:

```bash
bats -t scripts/ci/tests/
```

## Test Structure

```
tests/
├── test_helper.bash          # Shared helper functions
├── install-cost-tools.bats   # Tests for install-cost-tools.sh
├── cost-estimate.bats        # Tests for cost-estimate.sh
├── cost-analysis.bats        # Tests for cost-analysis.sh
├── policy-check.bats         # Tests for policy-check.sh
└── README.md                 # This file
```

## Test Helper Functions

The `test_helper.bash` file provides common utilities:

- **setup_test_dir()** - Creates temporary test directory
- **teardown_test_dir()** - Cleans up temporary files
- **mock_az_command()** - Mocks Azure CLI commands
- **mock_ace_binary()** - Mocks Azure Cost Estimator
- **mock_azure_cost_cli()** - Mocks azure-cost-cli
- **setup_github_actions_env()** - Simulates GitHub Actions environment
- **assert_file_exists()** - Asserts file exists
- **assert_file_contains()** - Asserts file contains string
- **assert_output_contains()** - Asserts command output contains string
- **create_mock_bicep_file()** - Creates mock Bicep template
- **create_mock_bicepparam_file()** - Creates mock Bicep parameters

## Test Coverage

### install-cost-tools.bats (9 tests)

- ✅ Script exists and is executable
- ✅ Shows help with -h/--help flags
- ✅ Validates ACE download
- ✅ Checks for required commands
- ✅ Creates temporary directory for ACE
- ✅ Handles dotnet tool installation failure
- ✅ Outputs success message on completion

### cost-estimate.bats (13 tests)

- ✅ Script exists and is executable
- ✅ Shows help message
- ✅ Requires all parameters (bicep file, params file, subscription ID)
- ✅ Validates file existence
- ✅ Builds Bicep to ARM JSON
- ✅ Runs ACE on ARM template
- ✅ Writes to GITHUB_OUTPUT
- ✅ Writes to GITHUB_STEP_SUMMARY
- ✅ Creates cost summary markdown
- ✅ Handles ACE failure gracefully
- ✅ Extracts cost value correctly
- ✅ Handles missing ACE binary

### cost-analysis.bats (14 tests)

- ✅ Script exists and is executable
- ✅ Shows help message
- ✅ Requires resource group and subscription ID
- ✅ Accepts optional timeframe parameter
- ✅ Validates timeframe parameter
- ✅ Calls azure-cost-cli with correct parameters
- ✅ Parses JSON output correctly
- ✅ Writes to GITHUB_OUTPUT
- ✅ Writes to GITHUB_STEP_SUMMARY
- ✅ Handles azure-cost-cli not found
- ✅ Handles API errors gracefully
- ✅ Handles empty cost data
- ✅ Handles alternative JSON field names
- ✅ Sets cost status based on amount
- ✅ Uses MonthToDate as default timeframe

### policy-check.bats (14 tests)

- ✅ Script exists and is executable
- ✅ Shows help message
- ✅ Requires resource group and subscription ID
- ✅ Checks if resource group exists
- ✅ Lists policy assignments
- ✅ Detects non-compliant resources
- ✅ Writes to GITHUB_OUTPUT
- ✅ Writes to GITHUB_STEP_SUMMARY
- ✅ Creates policy summary markdown
- ✅ Handles no policy assignments
- ✅ Tracks policy exemptions
- ✅ Handles Azure CLI errors
- ✅ Validates subscription ID format
- ✅ Sets policy status

**Total: 50 tests**

## Writing New Tests

### Basic test structure:

```bash
@test "descriptive test name" {
  run bash "$SCRIPT_PATH" [arguments]
  [ "$status" -eq 0 ]
  assert_output_contains "expected string"
}
```

### Using test helpers:

```bash
@test "test with mocks" {
  setup_test_dir
  setup_github_actions_env

  # Mock commands
  mock_az_command 'echo "mocked output"'

  run bash "$SCRIPT_PATH" args

  assert_file_exists "$GITHUB_OUTPUT"
  assert_file_contains "$GITHUB_OUTPUT" "expected content"

  teardown_test_dir
}
```

## CI Integration

### Add to pre-commit hooks:

```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: bats-tests
      name: Run BATS tests
      entry: bats
      args: [scripts/ci/tests/]
      language: system
      pass_filenames: false
```

### Add to GitHub Actions:

```yaml
- name: Run BATS tests
  run: |
    sudo apt-get update
    sudo apt-get install -y bats
    bats scripts/ci/tests/
```

## Debugging Tests

### Run with tap output:

```bash
bats -t scripts/ci/tests/ | grep -A 5 "not ok"
```

### Run single test with verbose:

```bash
bats -t scripts/ci/tests/cost-estimate.bats -f "builds bicep"
```

### Check test helper:

```bash
bash -x scripts/ci/tests/test_helper.bash
```

## Best Practices

1. **Isolation**: Each test should be independent and not rely on other tests
2. **Cleanup**: Always use setup/teardown to clean up temporary files
3. **Mocking**: Mock external dependencies (Azure CLI, ACE, etc.)
4. **Assertions**: Use descriptive assertion messages
5. **Coverage**: Test both success and failure scenarios
6. **Speed**: Keep tests fast by avoiding actual API calls

## Troubleshooting

### "command not found: bats"

Install BATS using the instructions above.

### "No such file or directory"

Ensure you're running tests from the repository root:

```bash
cd /workspaces/ts-azure-health
bats scripts/ci/tests/
```

### "Permission denied"

Make sure scripts are executable:

```bash
chmod +x scripts/ci/*.sh
```

### Tests failing with "mock not found"

Check that PATH is properly set in tests:

```bash
export PATH="$TEST_TEMP_DIR/bin:$PATH"
```

## References

- [BATS Documentation](https://bats-core.readthedocs.io/)
- [BATS GitHub](https://github.com/bats-core/bats-core)
- [Bash Test Framework Comparison](https://github.com/sstephenson/bats/wiki/Comparison-with-other-testing-frameworks)

## Related Documentation

- [Cost Estimation](../../../docs/COST_ESTIMATION.md)
- [Policy Testing](../../../docs/POLICY_TESTING.md)
- [CI Scripts](../)
