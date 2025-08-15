
# Rename GitHub Repository Action

This GitHub Action renames a specified GitHub repository using the GitHub API. It returns the result of the rename attempt, indicating success or failure, along with an error message if the operation fails.

## Features
- Renames a GitHub repository by making a PATCH request to the GitHub API.
- Verifies the repository's new name in the API response to confirm the rename.
- Outputs the result of the rename attempt (`success` or `failure`) and an error message if applicable.
- Requires a GitHub token with repository administration permissions for authentication.

## Inputs
| Name               | Description                                              | Required | Default |
|--------------------|----------------------------------------------------------|----------|---------|
| `current-repo-name`| The current name of the repository to rename.            | Yes      | N/A     |
| `new-repo-name`    | The new name for the repository.                         | Yes      | N/A     |
| `token`            | GitHub token with repository administration permissions. | Yes      | N/A     |
| `owner`            | The owner of the repository (user or organization).      | Yes      | N/A     |

## Outputs
| Name           | Description                                         |
|----------------|-----------------------------------------------------|
| `result`       | Result of the rename attempt (`success` or `failure`). |
| `error-message`| Error message if the rename attempt fails.          |

## Usage
1. **Add the Action to Your Workflow**:
   Create or update a workflow file (e.g., `.github/workflows/rename-repo.yml`) in your repository.

2. **Reference the Action**:
   Use the action by referencing the repository and version (e.g., `v1`).

3. **Example Workflow**:
   ```yaml
   name: Rename Repository
   on:
     workflow_dispatch:
       inputs:
         current-repo-name:
           description: 'Current name of the repository to rename'
           required: true
         new-repo-name:
           description: 'New name for the repository'
           required: true
   jobs:
     rename-repo:
       runs-on: ubuntu-latest
       steps:
         - name: Rename Repository
           id: rename
           uses: lee-lott-actions/rename-repo@v1
           with:
             current-repo-name: ${{ github.event.inputs.current-repo-name }}
             new-repo-name: ${{ github.event.inputs.new-repo-name }}
             token: ${{ secrets.GITHUB_TOKEN }}
             owner: ${{ github.repository_owner }}
         - name: Print Result
           run: |
             if [[ "${{ steps.rename.outputs.result }}" == "success" ]]; then
               echo "Repository ${{ github.repository_owner }}/${{ github.event.inputs.current-repo-name }} successfully renamed to ${{ github.event.inputs.new-repo-name }}."
             else
               echo "Error: ${{ steps.rename.outputs.error-message }}"
               exit 1
             fi
