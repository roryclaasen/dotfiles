if (Get-Module -ListAvailable -Name posh-git) {
    Import-Module posh-git
}

if ($env:PG_ENVIRONMENT -eq 1) {
    # No theme
}
else {
    $PoshTheme = Join-Path -Path $PSScriptRoot -ChildPath "roryclaasen.omp.json"
    if (Test-Path $PoshTheme) {
        oh-my-posh init pwsh --config $PoshTheme | Invoke-Expression
    }
}

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

if ((Get-Module -ListAvailable -Name PSFzf) -And (Get-Command "Fzf.exe" -ErrorAction SilentlyContinue)) {
    Import-Module PSFzf -ArgumentList 'Ctrl+t', 'Ctrl+r'
}

if (Get-Module -ListAvailable -Name z) {
    Import-Module z
}

if (Get-Module -ListAvailable -Name Microsoft.WinGet.Client) {
    Import-Module Microsoft.WinGet.Client
}

if (Get-Module -ListAvailable -Name Microsoft.WinGet.CommandNotFound) {
    Import-Module Microsoft.WinGet.CommandNotFound
}
elseif (Get-Module -ListAvailable -Name WinGetCommandNotFound) {
    Import-Module WinGetCommandNotFound
}
else {
    $ModulePath = "C:\Program Files\PowerToys\WinUI3Apps\..\WinGetCommandNotFound.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath
    }
}

if (Get-Module -ListAvailable -Name gsudoModule) {
    Import-Module gsudoModule
    Set-Alias 'sudo' 'gsudo'
}

if (Get-Module -ListAvailable -Name Az) {
    # Import-Module Az
}

if (Get-Command "fnm.exe" -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd --shell power-shell | Out-String | Invoke-Expression
}
