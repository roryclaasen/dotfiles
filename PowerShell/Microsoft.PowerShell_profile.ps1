if (Test-Path variable:global:RorysProfile) {
    break;
}

$global:RorysProfile = $true

. (Join-Path $PSScriptRoot "terminal.ps1")
. (Join-Path $PSScriptRoot "utilities.ps1")
. (Join-Path $PSScriptRoot "sandbox.ps1")

if ($host.Name -eq 'Visual Studio Code Host') {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
}
