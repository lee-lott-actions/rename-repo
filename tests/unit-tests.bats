#!/usr/bin/env bats

# Load the Bash script containing the rename_repo function
load ../action.sh

# Mock the curl command to simulate API responses
mock_curl() {
  local http_code=$1
  local response_file=$2
  echo "$http_code"
  cat "$response_file" > response.json
}

# Mock jq command to extract values from JSON
mock_jq() {
  local key=$1
  local file=$2
  if [ "$key" = ".name" ]; then
    local value=$(cat "$file" | grep -oP '(?<="name": ")[^"]*' || echo "null")
    echo "$value"
  elif [ "$key" = ".message" ]; then
    cat "$file" | grep -oP '(?<="message": ")[^"]*'
  else
    echo ""
  fi
}

# Setup function to run before each test
setup() {
  export GITHUB_OUTPUT=$(mktemp)
}

# Teardown function to clean up after each test
teardown() {
  cat "$GITHUB_OUTPUT"
  rm -f response.json mock_response.json "$GITHUB_OUTPUT"
}

@test "rename_repo succeeds with HTTP 200 and correct new name" {
  echo '{"name": "new-repo"}' > mock_response.json

  curl() {
    mock_curl "200" mock_response.json
  }
  export -f curl

  jq() {
    local flag="$1"
    local field="$2"
    local file="$3"
    if [ "$flag" = "-r" ]; then
      mock_jq "$field" "$file"
    else
      mock_jq "$flag" "$field"
    fi
  }
  export -f jq

  run rename_repo "old-repo" "new-repo" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=success" ]
}

@test "rename_repo fails with HTTP 404" {
  echo '{"message": "Repository not found"}' > mock_response.json

  curl() {
    mock_curl "404" mock_response.json
  }
  export -f curl

  jq() {
    local flag="$1"
    local field="$2"
    local file="$3"
    if [ "$flag" = "-r" ]; then
      mock_jq "$field" "$file"
    else
      mock_jq "$flag" "$field"
    fi
  }
  export -f jq

  run rename_repo "old-repo" "new-repo" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Failed to rename repository test-owner/old-repo. HTTP Status: 404" ]
}

@test "rename_repo fails when new name does not match" {
  echo '{"name": "wrong-repo"}' > mock_response.json

  curl() {
    mock_curl "200" mock_response.json
  }
  export -f curl

  jq() {
    local flag="$1"
    local field="$2"
    local file="$3"
    if [ "$flag" = "-r" ]; then
      mock_jq "$field" "$file"
    else
      mock_jq "$flag" "$field"
    fi
  }
  export -f jq

  run rename_repo "old-repo" "new-repo" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Failed to rename repository test-owner/old-repo. HTTP Status: 200" ]
}

@test "rename_repo fails with empty current_repo_name" {
  run rename_repo "" "new-repo" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Missing required parameters: current-repo-name, new-repo-name, token, and owner must be provided." ]
}

@test "rename_repo fails with empty new_repo_name" {
  run rename_repo "old-repo" "" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Missing required parameters: current-repo-name, new-repo-name, token, and owner must be provided." ]
}

@test "rename_repo fails with empty token" {
  run rename_repo "old-repo" "new-repo" "" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Missing required parameters: current-repo-name, new-repo-name, token, and owner must be provided." ]
}

@test "rename_repo fails with empty owner" {
  run rename_repo "old-repo" "new-repo" "fake-token" ""

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Missing required parameters: current-repo-name, new-repo-name, token, and owner must be provided." ]
}
