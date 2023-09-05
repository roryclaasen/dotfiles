if (Test-Path variable:global:RorysProfile) {
    break;
}

$global:RorysProfile = $true

. (Join-Path $PSScriptRoot "terminal.ps1")
. (Join-Path $PSScriptRoot "utilities.ps1")
. (Join-Path $PSScriptRoot "sandbox.ps1")


if (Get-Module -ListAvailable -Name gsudoModule) {
    Import-Module gsudoModule
    Set-Alias 'sudo' 'gsudo'
}

if ($host.Name -eq 'Visual Studio Code Host') {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
}
