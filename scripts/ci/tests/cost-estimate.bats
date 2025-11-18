#!/usr/bin/env bats

# Tests for cost-estimate.sh

load test_helper

setup() {
  setup_test_dir
  setup_github_actions_env
  export SCRIPT_PATH="$ORIGINAL_PWD/scripts/ci/cost-estimate.sh"
  cd "$TEST_TEMP_DIR"
}

teardown() {
  teardown_test_dir
}

@test "cost-estimate.sh exists and is executable" {
  [ -x "$SCRIPT_PATH" ]
}

@test "cost-estimate.sh shows help with -h flag" {
  run bash "$SCRIPT_PATH" -h
  [ "$status" -eq 0 ]
  assert_output_contains "Usage:"
  assert_output_contains "cost-estimate.sh"
}

@test "cost-estimate.sh requires bicep file parameter" {
  run bash "$SCRIPT_PATH"
  [ "$status" -eq 1 ]
  assert_output_contains "Usage:"
}

@test "cost-estimate.sh requires parameters file parameter" {
  run bash "$SCRIPT_PATH" main.bicep
  [ "$status" -eq 1 ]
  assert_output_contains "Usage:"
}

@test "cost-estimate.sh requires subscription ID parameter" {
  run bash "$SCRIPT_PATH" main.bicep dev.bicepparam
  [ "$status" -eq 1 ]
  assert_output_contains "Usage:"
}

@test "cost-estimate.sh validates bicep file exists" {
  run bash "$SCRIPT_PATH" nonexistent.bicep dev.bicepparam "12345678-1234-1234-1234-123456789012"
  [ "$status" -eq 1 ]
  assert_output_contains "not found" || assert_output_contains "does not exist"
}

@test "cost-estimate.sh validates parameters file exists" {
  create_mock_bicep_file "$TEST_TEMP_DIR/main.bicep"

  run bash "$SCRIPT_PATH" "$TEST_TEMP_DIR/main.bicep" nonexistent.bicepparam "12345678-1234-1234-1234-123456789012"
  [ "$status" -eq 1 ]
  assert_output_contains "not found" || assert_output_contains "does not exist"
}

@test "cost-estimate.sh builds bicep file to ARM JSON" {
  create_mock_bicep_file "$TEST_TEMP_DIR/main.bicep"
  create_mock_bicepparam_file "$TEST_TEMP_DIR/dev.bicepparam"

  # Mock az command
  mock_az_command 'echo "{\"resources\": []}"'

  # Mock ACE
  mock_ace_binary "Total cost: 100.00 USD per month"

  run bash "$SCRIPT_PATH" "$TEST_TEMP_DIR/main.bicep" "$TEST_TEMP_DIR/dev.bicepparam" "12345678-1234-1234-1234-123456789012"

  # Should attempt to build
  assert_output_contains "bicep" || assert_output_contains "Building" || [ "$status" -eq 0 ]
}

@test "cost-estimate.sh runs ACE on ARM template" {
  create_mock_bicep_file "$TEST_TEMP_DIR/main.bicep"
  create_mock_bicepparam_file "$TEST_TEMP_DIR/dev.bicepparam"
  create_mock_arm_json "/tmp/main.json"

  # Mock az bicep build
  mock_az_command 'if [[ "$*" == *"bicep build"* ]]; then cp "'$TEST_TEMP_DIR'/main.bicep" /tmp/main.json; fi'

  # Mock ACE with realistic output
  mock_ace_binary "Total cost: 45.67 USD per month
Storage Account: 20.00 USD
Key Vault: 5.00 USD
App Service: 20.67 USD"

  run bash "$SCRIPT_PATH" "$TEST_TEMP_DIR/main.bicep" "$TEST_TEMP_DIR/dev.bicepparam" "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_output_contains "45.67" || assert_output_contains "cost"
}

@test "cost-estimate.sh writes to GITHUB_OUTPUT" {
  create_mock_bicep_file "$TEST_TEMP_DIR/main.bicep"
  create_mock_bicepparam_file "$TEST_TEMP_DIR/dev.bicepparam"

  # Mock az command
  mock_az_command 'if [[ "$*" == *"bicep build"* ]]; then echo "{}"; fi'

  # Mock ACE
  mock_ace_binary "Total cost: 123.45 USD per month"

  run bash "$SCRIPT_PATH" "$TEST_TEMP_DIR/main.bicep" "$TEST_TEMP_DIR/dev.bicepparam" "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_file_exists "$GITHUB_OUTPUT"
  assert_file_contains "$GITHUB_OUTPUT" "estimated_cost"
}

@test "cost-estimate.sh writes to GITHUB_STEP_SUMMARY" {
  create_mock_bicep_file "$TEST_TEMP_DIR/main.bicep"
  create_mock_bicepparam_file "$TEST_TEMP_DIR/dev.bicepparam"

  # Mock az command
  mock_az_command 'if [[ "$*" == *"bicep build"* ]]; then echo "{}"; fi'

  # Mock ACE
  mock_ace_binary "Total cost: 99.99 USD per month"

  run bash "$SCRIPT_PATH" "$TEST_TEMP_DIR/main.bicep" "$TEST_TEMP_DIR/dev.bicepparam" "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_file_exists "$GITHUB_STEP_SUMMARY"
  assert_file_contains "$GITHUB_STEP_SUMMARY" "Cost Estimation" || assert_file_contains "$GITHUB_STEP_SUMMARY" "💰"
}

@test "cost-estimate.sh creates cost summary markdown file" {
  create_mock_bicep_file "$TEST_TEMP_DIR/main.bicep"
  create_mock_bicepparam_file "$TEST_TEMP_DIR/dev.bicepparam"

  # Mock az command
  mock_az_command 'if [[ "$*" == *"bicep build"* ]]; then echo "{}"; fi'

  # Mock ACE
  mock_ace_binary "Total cost: 50.00 USD per month"

  run bash "$SCRIPT_PATH" "$TEST_TEMP_DIR/main.bicep" "$TEST_TEMP_DIR/dev.bicepparam" "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  [ -f /tmp/cost-summary.md ]
}

@test "cost-estimate.sh handles ACE failure gracefully" {
  create_mock_bicep_file "$TEST_TEMP_DIR/main.bicep"
  create_mock_bicepparam_file "$TEST_TEMP_DIR/dev.bicepparam"

  # Mock az command
  mock_az_command 'if [[ "$*" == *"bicep build"* ]]; then echo "{}"; fi'

  # Mock ACE to fail
  mkdir -p /tmp/ace
  cat > /tmp/ace/azure-cost-estimator << 'EOF'
#!/usr/bin/env bash
echo "Error: Unable to estimate costs" >&2
exit 1
EOF
  chmod +x /tmp/ace/azure-cost-estimator

  run bash "$SCRIPT_PATH" "$TEST_TEMP_DIR/main.bicep" "$TEST_TEMP_DIR/dev.bicepparam" "12345678-1234-1234-1234-123456789012"

  [ "$status" -ne 0 ]
}

@test "cost-estimate.sh extracts cost value correctly" {
  create_mock_bicep_file "$TEST_TEMP_DIR/main.bicep"
  create_mock_bicepparam_file "$TEST_TEMP_DIR/dev.bicepparam"

  # Mock az command
  mock_az_command 'if [[ "$*" == *"bicep build"* ]]; then echo "{}"; fi'

  # Mock ACE with various cost formats
  mock_ace_binary "Total cost: 1,234.56 USD per month"

  run bash "$SCRIPT_PATH" "$TEST_TEMP_DIR/main.bicep" "$TEST_TEMP_DIR/dev.bicepparam" "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_file_contains "$GITHUB_OUTPUT" "1234.56" || assert_file_contains "$GITHUB_OUTPUT" "1,234.56"
}

@test "cost-estimate.sh handles missing ACE binary" {
  create_mock_bicep_file "$TEST_TEMP_DIR/main.bicep"
  create_mock_bicepparam_file "$TEST_TEMP_DIR/dev.bicepparam"

  # Mock az command
  mock_az_command 'if [[ "$*" == *"bicep build"* ]]; then echo "{}"; fi'

  # Don't create ACE binary

  run bash "$SCRIPT_PATH" "$TEST_TEMP_DIR/main.bicep" "$TEST_TEMP_DIR/dev.bicepparam" "12345678-1234-1234-1234-123456789012"

  [ "$status" -ne 0 ]
  assert_output_contains "not found" || assert_output_contains "ACE"
}
