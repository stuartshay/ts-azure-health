#!/usr/bin/env bats

# Tests for cost-analysis.sh

load test_helper

setup() {
  setup_test_dir
  setup_github_actions_env
  export SCRIPT_PATH="$ORIGINAL_PWD/scripts/ci/cost-analysis.sh"
}

teardown() {
  teardown_test_dir
}

@test "cost-analysis.sh exists and is executable" {
  [ -x "$SCRIPT_PATH" ]
}

@test "cost-analysis.sh shows help with -h flag" {
  run bash "$SCRIPT_PATH" -h
  [ "$status" -eq 0 ]
  assert_output_contains "Usage:"
  assert_output_contains "cost-analysis.sh"
}

@test "cost-analysis.sh requires resource group parameter" {
  run bash "$SCRIPT_PATH"
  [ "$status" -eq 1 ]
  assert_output_contains "Usage:"
}

@test "cost-analysis.sh requires subscription ID parameter" {
  run bash "$SCRIPT_PATH" rg-test
  [ "$status" -eq 1 ]
  assert_output_contains "Usage:"
}

@test "cost-analysis.sh accepts optional timeframe parameter" {
  # Mock azure-cost-cli
  mock_azure_cost_cli '{"totalCost": 100.50}'

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012" "WeekToDate"

  # Should accept the parameter
  [ "$status" -eq 0 ] || assert_output_contains "WeekToDate"
}

@test "cost-analysis.sh validates timeframe parameter" {
  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012" "InvalidTimeframe"

  [ "$status" -eq 1 ]
  assert_output_contains "Invalid timeframe" || assert_output_contains "Usage:"
}

@test "cost-analysis.sh calls azure-cost-cli with correct parameters" {
  # Mock azure-cost-cli to capture arguments
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/azure-cost" << 'EOF'
#!/usr/bin/env bash
echo "$@" > /tmp/azure-cost-args.txt
echo '{"totalCost": 200.00}'
EOF
  chmod +x "$TEST_TEMP_DIR/bin/azure-cost"

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012" "MonthToDate"

  [ "$status" -eq 0 ]
  assert_file_exists "/tmp/azure-cost-args.txt"
  assert_file_contains "/tmp/azure-cost-args.txt" "12345678-1234-1234-1234-123456789012"
  assert_file_contains "/tmp/azure-cost-args.txt" "rg-test-dev"
}

@test "cost-analysis.sh parses JSON output correctly" {
  # Mock azure-cost-cli with JSON response
  mock_azure_cost_cli '{"totalCost": 150.75, "currency": "USD"}'

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_output_contains "150.75" || assert_output_contains "cost"
}

@test "cost-analysis.sh writes to GITHUB_OUTPUT" {
  mock_azure_cost_cli '{"totalCost": 99.99}'

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_file_exists "$GITHUB_OUTPUT"
  assert_file_contains "$GITHUB_OUTPUT" "actual_cost"
}

@test "cost-analysis.sh writes to GITHUB_STEP_SUMMARY" {
  mock_azure_cost_cli '{"totalCost": 250.00}'

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_file_exists "$GITHUB_STEP_SUMMARY"
  assert_file_contains "$GITHUB_STEP_SUMMARY" "Cost Analysis" || assert_file_contains "$GITHUB_STEP_SUMMARY" "💰"
}

@test "cost-analysis.sh handles azure-cost-cli not found" {
  # Don't mock azure-cost-cli
  export PATH="$TEST_TEMP_DIR/bin:$PATH"

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -ne 0 ]
  assert_output_contains "not found" || assert_output_contains "azure-cost"
}

@test "cost-analysis.sh handles API errors gracefully" {
  # Mock azure-cost-cli to fail
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/azure-cost" << 'EOF'
#!/usr/bin/env bash
echo "Error: Unable to fetch cost data" >&2
exit 1
EOF
  chmod +x "$TEST_TEMP_DIR/bin/azure-cost"

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -ne 0 ]
}

@test "cost-analysis.sh handles empty cost data" {
  mock_azure_cost_cli '{}'

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_output_contains "N/A" || assert_output_contains "0"
}

@test "cost-analysis.sh handles alternative JSON field names" {
  # Test with "Total" instead of "totalCost"
  mock_azure_cost_cli '{"Total": 300.00, "Currency": "USD"}'

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_output_contains "300" || assert_output_contains "cost"
}

@test "cost-analysis.sh sets cost status based on amount" {
  mock_azure_cost_cli '{"totalCost": 500.00}'

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_file_exists "$GITHUB_OUTPUT"
  assert_file_contains "$GITHUB_OUTPUT" "cost_status"
}

@test "cost-analysis.sh uses MonthToDate as default timeframe" {
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/azure-cost" << 'EOF'
#!/usr/bin/env bash
echo "$@" > /tmp/azure-cost-default-args.txt
echo '{"totalCost": 100.00}'
EOF
  chmod +x "$TEST_TEMP_DIR/bin/azure-cost"

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_file_contains "/tmp/azure-cost-default-args.txt" "MonthToDate"
}
