#!/usr/bin/env bats

# Tests for install-cost-tools.sh
# Simple validation tests that don't require actual downloads

load test_helper

setup() {
  setup_test_dir
  export SCRIPT_PATH="$ORIGINAL_PWD/scripts/ci/install-cost-tools.sh"
}

teardown() {
  teardown_test_dir
}

@test "install-cost-tools.sh exists and is executable" {
  [ -x "$SCRIPT_PATH" ]
}

@test "script uses ACE_VERSION environment variable" {
  run grep -q 'ACE_VERSION.*1.6.4' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "script uses AZURE_COST_VERSION environment variable" {
  run grep -q 'AZURE_COST_VERSION.*0.52.0' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "script downloads ACE from GitHub releases" {
  run grep -q 'TheCloudTheory/arm-estimator/releases' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "script installs azure-cost-cli via dotnet tool" {
  run grep -q 'dotnet tool install.*azure-cost-cli' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "script adds dotnet tools to PATH" {
  run grep -q '\.dotnet/tools' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "script makes ACE binary executable" {
  run grep -q 'chmod +x.*azure-cost-estimator' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}

@test "script outputs success messages" {
  run grep -q 'installed successfully' "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
}
