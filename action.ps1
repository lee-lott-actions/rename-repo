function Rename-Repository {
	param(
		[string]$CurrentRepoName,
		[string]$NewRepoName,
		[string]$Token,
		[string]$Owner
	)

	# Validate required inputs
	if ([string]::IsNullOrEmpty($CurrentRepoName) -or
		[string]::IsNullOrEmpty($NewRepoName) -or
		[string]::IsNullOrEmpty($Token) -or
		[string]::IsNullOrEmpty($Owner)) {

		Write-Host "Error: Missing required parameters"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: current-repo-name, new-repo-name, token, and owner must be provided."
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		return
	}

	Write-Host "Attempting to rename repository $Owner/$CurrentRepoName to $NewRepoName"

	# Use MOCK_API if set, otherwise default to GitHub API
	$apiBaseUrl = $env:MOCK_API
	if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }

	$uri = "$apiBaseUrl/repos/$Owner/$CurrentRepoName"

	$headers = @{
		Authorization = "Bearer $Token"
		Accept = "application/vnd.github+json"
		"X-GitHub-Api-Version" = "2026-03-10"
		"Content-Type" = "application/json"
	}

	$body = @{ name = $NewRepoName } | ConvertTo-Json -Compress

	try {
		$response = Invoke-WebRequest -Uri $uri -Method Patch -Headers $headers -Body $body

		if ($response.StatusCode -ne 200) {
			$errorMsg = "Error: Failed to rename repository $Owner/$CurrentRepoName. HTTP Status: $($response.StatusCode)"
			Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
			Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
			Write-Host $errorMsg
			return
		}

		$newName = $null
		try {
			if (-not [string]::IsNullOrEmpty($response.Content)) {
				$json = $response.Content | ConvertFrom-Json
				$newName = $json.name
			}
		} catch {
			$newName = $null
		}

		if ($newName -ne $NewRepoName) {
			$errorMsg = "Error: Failed to rename repository $Owner/$CurrentRepoName. HTTP Status: $($response.StatusCode). New name returned: $newName."
			Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
			Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
			Write-Host $errorMsg
			return
		}

		Write-Host "Repository $Owner/$CurrentRepoName successfully renamed to $NewRepoName"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
	}
	catch {
		$errorMsg = "Error: Failed to rename repository $Owner/$CurrentRepoName. Exception: $($_.Exception.Message)"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
		Write-Host $errorMsg
	}
}
