. ([System.IO.Path]::Combine($PSScriptRoot, "terminal.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "utilities.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "sandbox.ps1"))

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
