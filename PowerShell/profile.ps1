Import-Module posh-git

If ($host.Name -eq 'Visual Studio Code Host') {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
}
