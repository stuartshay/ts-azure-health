#!/usr/bin/env bash

# BATS test helper functions for CI scripts testing

# Setup function to create temporary test directory
setup_test_dir() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_TEMP_DIR
  export ORIGINAL_PWD="$PWD"
}

# Teardown function to cleanup temporary directory
teardown_test_dir() {
  if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
  if [ -n "$ORIGINAL_PWD" ]; then
    cd "$ORIGINAL_PWD" || true
  fi
}

# Mock az command for testing
mock_az_command() {
  local mock_script="$1"
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/az" << EOF
#!/usr/bin/env bash
$mock_script
EOF
  chmod +x "$TEST_TEMP_DIR/bin/az"
}

# Mock ACE binary for testing
mock_ace_binary() {
  local mock_output="$1"
  mkdir -p "$TEST_TEMP_DIR/ace"

  cat > "$TEST_TEMP_DIR/ace/azure-cost-estimator" << EOF
#!/usr/bin/env bash
echo "$mock_output"
EOF
  chmod +x "$TEST_TEMP_DIR/ace/azure-cost-estimator"
}

# Mock azure-cost-cli for testing
mock_azure_cost_cli() {
  local mock_output="$1"
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/azure-cost" << EOF
#!/usr/bin/env bash
echo '$mock_output'
EOF
  chmod +x "$TEST_TEMP_DIR/bin/azure-cost"
}

# Mock jq command for testing
mock_jq_command() {
  local mock_output="$1"
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/jq" << EOF
#!/usr/bin/env bash
echo '$mock_output'
EOF
  chmod +x "$TEST_TEMP_DIR/bin/jq"
}

# Create mock GitHub Actions environment
setup_github_actions_env() {
  export GITHUB_OUTPUT="$TEST_TEMP_DIR/github_output.txt"
  export GITHUB_STEP_SUMMARY="$TEST_TEMP_DIR/github_summary.md"
  touch "$GITHUB_OUTPUT"
  touch "$GITHUB_STEP_SUMMARY"
}

# Assert file exists
assert_file_exists() {
  local file="$1"
  [ -f "$file" ] || {
    echo "Expected file does not exist: $file"
    return 1
  }
}

# Assert file contains string
assert_file_contains() {
  local file="$1"
  local search_string="$2"
  grep -q "$search_string" "$file" || {
    echo "File $file does not contain expected string: $search_string"
    echo "File contents:"
    cat "$file"
    return 1
  }
}

# Assert command output contains string
assert_output_contains() {
  local search_string="$1"
  # shellcheck disable=SC2154
  echo "$output" | grep -q "$search_string" || {
    echo "Output does not contain expected string: $search_string"
    echo "Actual output:"
    # shellcheck disable=SC2154
    echo "$output"
    return 1
  }
}

# Create mock Bicep file
create_mock_bicep_file() {
  local file_path="$1"
  mkdir -p "$(dirname "$file_path")"

  cat > "$file_path" << 'EOF'
param location string = 'eastus'
param environment string = 'dev'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'testst${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

output storageAccountId string = storageAccount.id
EOF
}

# Create mock Bicep parameters file
create_mock_bicepparam_file() {
  local file_path="$1"
  mkdir -p "$(dirname "$file_path")"

  cat > "$file_path" << 'EOF'
using './main.bicep'

param location = 'eastus'
param environment = 'dev'
EOF
}

# Create mock ARM JSON file
create_mock_arm_json() {
  local file_path="$1"
  mkdir -p "$(dirname "$file_path")"

  cat > "$file_path" << 'EOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": {
      "type": "string",
      "defaultValue": "eastus"
    }
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2021-09-01",
      "name": "testst123",
      "location": "[parameters('location')]",
      "sku": {
        "name": "Standard_LRS"
      },
      "kind": "StorageV2"
    }
  ]
}
EOF
}
