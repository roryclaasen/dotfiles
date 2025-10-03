if ($env:PG_ENVIRONMENT -eq 1) {
    # No theme
}
else {
    $PoshTheme = Join-Path -Path $PSScriptRoot -ChildPath "roryclaasen.omp.json"
    if (Test-Path $PoshTheme) {
        oh-my-posh init pwsh --config $PoshTheme | Invoke-Expression
    }
}

if (Get-Module -ListAvailable -Name posh-git) {
    Import-Module -Name posh-git
}

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module -Name Terminal-Icons
}

if ((Get-Module -ListAvailable -Name PSFzf) -And (Get-Command "Fzf.exe" -ErrorAction SilentlyContinue)) {
    Import-Module -Name PSFzf -ArgumentList 'Ctrl+t', 'Ctrl+r'
}

if (Get-Module -ListAvailable -Name z) {
    Import-Module -Name z
}

if (Get-Module -ListAvailable -Name Microsoft.WinGet.Client) {
    Import-Module -Name Microsoft.WinGet.Client
}

if (Get-Module -ListAvailable -Name Microsoft.WinGet.CommandNotFound) {
    Import-Module -Name Microsoft.WinGet.CommandNotFound
}

if (Get-Module -ListAvailable -Name gsudoModule) {
    Import-Module -Name gsudoModule
    Set-Alias 'sudo' 'gsudo'
}

if (Get-Command "fnm.exe" -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd --shell power-shell | Out-String | Invoke-Expression
}
