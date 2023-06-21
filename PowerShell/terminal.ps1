$HasPoshGit = $false

if (Get-Module -ListAvailable -Name posh-git) {
    Import-Module posh-git
    $HasPoshGit = $true
}

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

if ((Get-Command "oh-my-posh")) {
    $GitPromptSettings.BeforeStatus.ForegroundColor = [ConsoleColor]::DarkGray
    $GitPromptSettings.DelimStatus.ForegroundColor = [ConsoleColor]::DarkGray
    $GitPromptSettings.AfterStatus.ForegroundColor = [ConsoleColor]::DarkGray
    $GitPromptSettings.BeforeStatus.Text = [string]::Empty;

    $PoshTheme = Join-Path -Path $PSScriptRoot -ChildPath "roryclaasen.omp.json"
    if (Test-Path $PoshTheme) {
        oh-my-posh init pwsh --config $PoshTheme | Invoke-Expression
    }

    if ($HasPoshGit) {
        function Set-PoshGitStatus {
            $global:GitStatus = Get-GitStatus
            if ($global:GitStatus) {
                $env:POSH_GIT_STRING = (Write-GitStatus -Status $global:GitStatus).trim()
            }
            else {
                $env:POSH_GIT_STRING = $null
            }
        }

        New-Alias -Name 'Set-PoshContext' -Value 'Set-PoshGitStatus' -Scope Global -Force
    }
}
elseif ($HasPoshGit) {
    $env:POSH_GIT_ENABLED = $true
}
