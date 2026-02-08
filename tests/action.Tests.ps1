BeforeAll {
	$script:CurrentRepoName = "old-repo"
	$script:NewRepoName = "new-repo"
	$script:Owner = "test-owner"
	$script:Token = "fake-token"

	. "$PSScriptRoot/../action.ps1"
}

Describe "Rename-Repository" {
	BeforeEach {
		$env:GITHUB_OUTPUT = [System.IO.Path]::GetTempFileName()
	}

	AfterEach {
		if (Test-Path $env:GITHUB_OUTPUT) {
			Remove-Item $env:GITHUB_OUTPUT -Force
		}
	}

	It "rename_repo succeeds with HTTP 200 and correct new name" {
		Mock Invoke-WebRequest {
			[PSCustomObject]@{
				StatusCode = 200
				Content    = '{"name": "new-repo"}'
			}
		}

		Rename-Repository -CurrentRepoName $CurrentRepoName -NewRepoName $NewRepoName -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=success"
	}

	It "rename_repo fails with HTTP 404" {
		Mock Invoke-WebRequest {
			[PSCustomObject]@{
				StatusCode = 404
				Content    = '{"message": "Repository not found"}'
			}
		}

		Rename-Repository -CurrentRepoName $CurrentRepoName -NewRepoName $NewRepoName -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"

		# Function writes: "Error: Failed to rename repository owner/repo. HTTP Status: <code>"
		($output | Where-Object { $_ -match "^error-message=Error: Failed to rename repository $Owner/$CurrentRepoName\. HTTP Status: 404" }) |
			Should -Not -BeNullOrEmpty
	}

	It "rename_repo fails when new name does not match" {
		Mock Invoke-WebRequest {
			[PSCustomObject]@{
				StatusCode = 200
				Content    = '{"name": "wrong-repo"}'
			}
		}

		Rename-Repository -CurrentRepoName $CurrentRepoName -NewRepoName $NewRepoName -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"

		# StatusCode is 200 but returned name doesn't match requested new name
		($output | Where-Object { $_ -match "^error-message=Error: Failed to rename repository $Owner/$CurrentRepoName\. HTTP Status: 200" }) |
			Should -Not -BeNullOrEmpty
	}

	It "rename_repo fails with empty current_repo_name" {
		Rename-Repository -CurrentRepoName "" -NewRepoName $NewRepoName -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: current-repo-name, new-repo-name, token, and owner must be provided."
	}

	It "rename_repo fails with empty new_repo_name" {
		Rename-Repository -CurrentRepoName $CurrentRepoName -NewRepoName "" -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: current-repo-name, new-repo-name, token, and owner must be provided."
	}

	It "rename_repo fails with empty token" {
		Rename-Repository -CurrentRepoName $CurrentRepoName -NewRepoName $NewRepoName -Token "" -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: current-repo-name, new-repo-name, token, and owner must be provided."
	}

	It "rename_repo fails with empty owner" {
		Rename-Repository -CurrentRepoName $CurrentRepoName -NewRepoName $NewRepoName -Token $Token -Owner ""

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Should -Contain "error-message=Missing required parameters: current-repo-name, new-repo-name, token, and owner must be provided."
	}

	It "writes result=failure and error-message on exception (catch block)" {
		Mock Invoke-WebRequest { throw "API Error" }

		Rename-Repository -CurrentRepoName $CurrentRepoName -NewRepoName $NewRepoName -Token $Token -Owner $Owner

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		($output | Where-Object { $_ -match "^error-message=Error: Failed to rename repository $Owner/$CurrentRepoName\. Exception:" }) |
			Should -Not -BeNullOrEmpty
	}
}