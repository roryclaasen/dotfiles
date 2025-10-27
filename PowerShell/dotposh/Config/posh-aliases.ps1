# Common Locations
function dotfiles { Set-Location $env:DOTFILES }
function home { Set-Location $env:USERPROFILE }
function docs { Set-Location $env:USERPROFILE\Documents }
function desktop { Set-Location $env:USERPROFILE\Desktop }
function downloads { Set-Location $env:USERPROFILE\Downloads }
function HKLM { Set-Location HKLM: }
function HKCU { Set-Location HKCU: }


# Network
function flushdns { ipconfig /flushdns }
function displaydns { ipconfig /displaydns }
function chrome { Start-Process chrome }
function edge { Start-Process microsoft-edge: }


# PowerShell reload /restart
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
Set-Alias "reload" Invoke-ProfileReload


# Gsudo
Set-Alias 'sudo' 'gsudo'


# Windows System
function paths { $env:PATH -Split ';' }
function envs { Get-ChildItem Env: }
function profiles { Get-PSProfile { $_.exists -eq "True" } | Format-List }


# Terminal
function colors {
    # output all the colour combinations for text/background
    # https://stackoverflow.com/questions/20541456/list-of-all-colors-available-for-powershell/41954792#41954792
    $colors = [enum]::GetValues([System.ConsoleColor])
    Foreach ($bgcolor in $colors) {
        Foreach ($fgcolor in $colors) { Write-Host "$fgcolor|" -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewLine }
        Write-Host " on $bgcolor"
    }
}
