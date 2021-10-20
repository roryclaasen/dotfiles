Import-Module posh-git
# Import-Module oh-my-posh

$env:POSH_GIT_ENABLED = $true

If ($host.Name -eq 'Visual Studio Code Host') {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
}
