 #!/bin/bash

rename_repo() {
  local current_repo_name="$1"
  local new_repo_name="$2"
  local token="$3"
  local owner="$4"

  if [ -z "$current_repo_name" ] || [ -z "$new_repo_name" ] || [ -z "$token" ] || [ -z "$owner" ]; then
    echo "Error: Missing required parameters"
    echo "error-message=Missing required parameters: current-repo-name, new-repo-name, token, and owner must be provided." >> "$GITHUB_OUTPUT"
    echo "result=failure" >> "$GITHUB_OUTPUT"
    return
  fi

  echo "Attempting to rename repository $owner/$current_repo_name to $new_repo_name"

  # Use MOCK_API if set, otherwise default to GitHub API
  local api_base_url="${MOCK_API:-https://api.github.com}"

  RESPONSE=$(curl -s -o response.json -w "%{http_code}" \
    -X PATCH \
    -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json" \
    "$api_base_url/repos/$owner/$current_repo_name" \
    -d "{\"name\": \"$new_repo_name\"}")

  new_name=$(jq -r .name response.json)

  if [ "$RESPONSE" -eq 200 ] && [ "$new_name" == "$new_repo_name" ]; then
    echo "Repository $owner/$current_repo_name successfully renamed to $new_repo_name"
    echo "result=success" >> "$GITHUB_OUTPUT"
  else
    echo "Error: Failed to rename repository $owner/$current_repo_name"
    echo "error-message=Failed to rename repository $owner/$current_repo_name. HTTP Status: $RESPONSE" >> "$GITHUB_OUTPUT"
    echo "result=failure" >> "$GITHUB_OUTPUT"
  fi

  rm -f response.json
}
