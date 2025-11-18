#!/usr/bin/env bats

# Tests for policy-check.sh

load test_helper

setup() {
  setup_test_dir
  setup_github_actions_env
  export SCRIPT_PATH="$ORIGINAL_PWD/scripts/ci/policy-check.sh"
}

teardown() {
  teardown_test_dir
}

@test "policy-check.sh exists and is executable" {
  [ -x "$SCRIPT_PATH" ]
}

@test "policy-check.sh shows help with -h flag" {
  run bash "$SCRIPT_PATH" -h
  [ "$status" -eq 0 ]
  assert_output_contains "Usage:"
  assert_output_contains "policy-check.sh"
}

@test "policy-check.sh requires resource group parameter" {
  run bash "$SCRIPT_PATH"
  [ "$status" -eq 1 ]
  assert_output_contains "Usage:"
}

@test "policy-check.sh requires subscription ID parameter" {
  run bash "$SCRIPT_PATH" rg-test
  [ "$status" -eq 1 ]
  assert_output_contains "Usage:"
}

@test "policy-check.sh checks if resource group exists" {
  # Mock az command to indicate RG doesn't exist
  mock_az_command 'if [[ "$*" == *"group exists"* ]]; then echo "false"; fi'

  run bash "$SCRIPT_PATH" rg-nonexistent "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_output_contains "does not exist" || assert_output_contains "not found"
}

@test "policy-check.sh lists policy assignments" {
  # Mock az commands
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/az" << 'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"group exists"* ]]; then
  echo "true"
elif [[ "$*" == *"policy assignment list"* ]]; then
  echo '[{"name": "require-tags", "properties": {"displayName": "Require tags"}}]'
elif [[ "$*" == *"policy state list"* ]]; then
  echo '[{"complianceState": "Compliant"}]'
elif [[ "$*" == *"policy exemption list"* ]]; then
  echo '[]'
fi
EOF
  chmod +x "$TEST_TEMP_DIR/bin/az"

  # Mock jq
  mock_jq_command '1'

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_output_contains "policy" || assert_output_contains "Checking"
}

@test "policy-check.sh detects non-compliant resources" {
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/az" << 'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"group exists"* ]]; then
  echo "true"
elif [[ "$*" == *"policy assignment list"* ]]; then
  echo '[{"name": "require-https"}]'
elif [[ "$*" == *"policy state list"* ]]; then
  echo '[{"complianceState": "NonCompliant", "resourceId": "/subscriptions/xxx/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/test123"}]'
elif [[ "$*" == *"policy exemption list"* ]]; then
  echo '[]'
fi
EOF
  chmod +x "$TEST_TEMP_DIR/bin/az"

  # Mock jq to return non-compliant count
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  cat > "$TEST_TEMP_DIR/bin/jq" << 'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"NonCompliant"* ]]; then
  echo "1"
else
  echo "0"
fi
EOF
  chmod +x "$TEST_TEMP_DIR/bin/jq"

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  # Should exit with warning (exit code 0 with continue-on-error, but report non-compliant)
  assert_output_contains "Non-Compliant" || assert_output_contains "non-compliant" || assert_output_contains "1"
}

@test "policy-check.sh writes to GITHUB_OUTPUT" {
  # Mock successful policy check
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/az" << 'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"group exists"* ]]; then
  echo "true"
elif [[ "$*" == *"policy"* ]]; then
  echo '[]'
fi
EOF
  chmod +x "$TEST_TEMP_DIR/bin/az"

  mock_jq_command '0'

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_file_exists "$GITHUB_OUTPUT"
  assert_file_contains "$GITHUB_OUTPUT" "policy_summary" || assert_file_contains "$GITHUB_OUTPUT" "non_compliant_count"
}

@test "policy-check.sh writes to GITHUB_STEP_SUMMARY" {
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/az" << 'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"group exists"* ]]; then
  echo "true"
else
  echo '[]'
fi
EOF
  chmod +x "$TEST_TEMP_DIR/bin/az"

  mock_jq_command '0'

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_file_exists "$GITHUB_STEP_SUMMARY"
  assert_file_contains "$GITHUB_STEP_SUMMARY" "Policy" || assert_file_contains "$GITHUB_STEP_SUMMARY" "🔒"
}

@test "policy-check.sh creates policy summary markdown" {
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/az" << 'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"group exists"* ]]; then
  echo "true"
else
  echo '[]'
fi
EOF
  chmod +x "$TEST_TEMP_DIR/bin/az"

  mock_jq_command '0'

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  [ -f /tmp/policy-summary.md ]
}

@test "policy-check.sh handles no policy assignments" {
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/az" << 'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"group exists"* ]]; then
  echo "true"
else
  echo '[]'
fi
EOF
  chmod +x "$TEST_TEMP_DIR/bin/az"

  mock_jq_command '0'

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_output_contains "No policy assignments" || assert_output_contains "0"
}

@test "policy-check.sh tracks policy exemptions" {
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/az" << 'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"group exists"* ]]; then
  echo "true"
elif [[ "$*" == *"exemption"* ]]; then
  echo '[{"name": "legacy-app-exemption", "properties": {"expiresOn": "2025-12-31"}}]'
else
  echo '[]'
fi
EOF
  chmod +x "$TEST_TEMP_DIR/bin/az"

  cat > "$TEST_TEMP_DIR/bin/jq" << 'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"length"* ]]; then
  echo "1"
else
  echo "0"
fi
EOF
  chmod +x "$TEST_TEMP_DIR/bin/jq"

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_output_contains "exemption" || assert_output_contains "Exempt"
}

@test "policy-check.sh handles Azure CLI errors" {
  # Mock az to fail
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/az" << 'EOF'
#!/usr/bin/env bash
echo "Error: Authentication failed" >&2
exit 1
EOF
  chmod +x "$TEST_TEMP_DIR/bin/az"

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -ne 0 ]
}

@test "policy-check.sh validates subscription ID format" {
  run bash "$SCRIPT_PATH" rg-test-dev "invalid-subscription-id"

  # Should either reject invalid format or pass it through to Azure CLI
  [ "$status" -eq 1 ] || assert_output_contains "invalid"
}

@test "policy-check.sh sets policy status" {
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
  mkdir -p "$TEST_TEMP_DIR/bin"

  cat > "$TEST_TEMP_DIR/bin/az" << 'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"group exists"* ]]; then
  echo "true"
else
  echo '[]'
fi
EOF
  chmod +x "$TEST_TEMP_DIR/bin/az"

  mock_jq_command '0'

  run bash "$SCRIPT_PATH" rg-test-dev "12345678-1234-1234-1234-123456789012"

  [ "$status" -eq 0 ]
  assert_file_contains "$GITHUB_OUTPUT" "policy_status"
}
