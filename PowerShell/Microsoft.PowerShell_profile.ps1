. (Join-Path $PSScriptRoot "terminal.ps1")
. (Join-Path $PSScriptRoot "utilities.ps1")
. (Join-Path $PSScriptRoot "sandbox.ps1")

if ($host.Name -eq 'Visual Studio Code Host') {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
}

function Invoke-ProfileReload {
    @(
        $Profile.AllUsersAllHosts,
        $Profile.AllUsersCurrentHost,
        $Profile.CurrentUserAllHosts,
        $Profile.CurrentUserCurrentHost
    ) | ForEach-Object {
        if (Test-Path $_) {
            Write-Verbose "Running $_"
            . $_
        }
    }
}

Set-Alias "Reload-Profile" Invoke-ProfileReload
