Describe "Rename-Repository" {
	BeforeAll {
		$script:CurrentRepoName = "old-repo"
		$script:NewRepoName = "new-repo"
		$script:Owner = "test-owner"
		$script:Token = "fake-token"
		$script:MockApiUrl  = "http://127.0.0.1:3000"
		. "$PSScriptRoot/../action.ps1"
	}

	BeforeEach {
        $env:GITHUB_OUTPUT = New-TemporaryFile
        $env:MOCK_API = $script:MockApiUrl
    }
	
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Item Env:MOCK_API -ErrorAction SilentlyContinue
    }

	Context "Success Cases" {
		It "unit: Rename-Repository succeeds with HTTP 200 and correct new name" {
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
	}

	Context "Failure Cases" {
		It "unit: Rename-Repository fails when new name does not match" {
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
	}

	Context "HTTP Failure Cases" {
		It "unit: Rename-Repository fails with HTTP 404" {
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
	}

	Context "Parameter Validation Failure Cases" {
		It "unit: Rename-Repository fails with empty CurrentRepoName" {
			Rename-Repository -CurrentRepoName "" -NewRepoName $NewRepoName -Token $Token -Owner $Owner
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Should -Contain "error-message=Missing required parameters: current-repo-name, new-repo-name, token, and owner must be provided."
		}
	
		It "unit: Rename-Repository fails with empty NewRepoName" {
			Rename-Repository -CurrentRepoName $CurrentRepoName -NewRepoName "" -Token $Token -Owner $Owner
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Should -Contain "error-message=Missing required parameters: current-repo-name, new-repo-name, token, and owner must be provided."
		}
	
		It "unit: Rename-Repository fails with empty Token" {
			Rename-Repository -CurrentRepoName $CurrentRepoName -NewRepoName $NewRepoName -Token "" -Owner $Owner
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Should -Contain "error-message=Missing required parameters: current-repo-name, new-repo-name, token, and owner must be provided."
		}
	
		It "unit: Rename-Repository fails with empty Owner" {
			Rename-Repository -CurrentRepoName $CurrentRepoName -NewRepoName $NewRepoName -Token $Token -Owner ""
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Should -Contain "error-message=Missing required parameters: current-repo-name, new-repo-name, token, and owner must be provided."
		}	
	}

	Context "Exception Failure Cases" {
		It "unit: Rename-Repository fails with exception" {
			Mock Invoke-WebRequest { throw "API Error" }
	
			Rename-Repository -CurrentRepoName $CurrentRepoName -NewRepoName $NewRepoName -Token $Token -Owner $Owner
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			($output | Where-Object { $_ -match "^error-message=Error: Failed to rename repository $Owner/$CurrentRepoName\. Exception:" }) |
				Should -Not -BeNullOrEmpty
		}	
	}
}
