if ($env:PG_ENVIRONMENT -eq 1) {
    # No theme
}
else {
    $PoshTheme = [System.IO.Path]::Combine($PSScriptRoot, "roryclaasen.omp.json")
    if (Test-Path $PoshTheme) {
        oh-my-posh init pwsh --config $PoshTheme | Invoke-Expression
    }
}

try { Import-Module -Name posh-git } catch [System.Management.Automation.CommandNotFoundException] { }
try { Import-Module -Name Terminal-Icons } catch [System.Management.Automation.CommandNotFoundException] { }
try { Import-Module -Name PSFzf -ArgumentList 'Ctrl+t', 'Ctrl+r' } catch [System.Management.Automation.CommandNotFoundException] { }
try { Import-Module -Name z } catch [System.Management.Automation.CommandNotFoundException] { }
try { Import-Module -Name Microsoft.WinGet.Client } catch [System.Management.Automation.CommandNotFoundException] { }
try { Import-Module -Name Microsoft.WinGet.CommandNotFound } catch [System.Management.Automation.CommandNotFoundException] { }

try {
    Import-Module -Name gsudoModule
    Set-Alias 'sudo' 'gsudo'
} catch [System.Management.Automation.CommandNotFoundException] { }

if (Get-Command "fnm.exe" -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd --shell power-shell | Out-String | Invoke-Expression
}
