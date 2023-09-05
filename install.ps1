function Install-PSRequirements {
    Write-Host "[+] Installing PowerShell Requirements..."

    Install-Module PowerShellGet -Force -AllowClobber

    $Requirements = @(
        'posh-git',
        'Terminal-Icons'
        'PSFzf',
        'z'
    )

    $Requirements | ForEach-Object {
        if (Get-Module -ListAvailable -Name $_) {
            PowerShellGet\Update-Module $_
        }
        else {
            PowerShellGet\Install-Module $_ -Scope CurrentUser -Force
        }
    }
}

function Install-PSProfile {
    Write-Host "[+] Setting PowerShell Profile..."

    $Link = Split-Path $PROFILE.CurrentUserAllHosts
    $Target = Join-Path -Path $PSScriptRoot -ChildPath "PowerShell"

    if (Test-Path $Link) {
        $LinkProperties = Get-ItemProperty $Link;
        if (-not $LinkProperties.LinkType) {
            Write-Warn "Powershell Profile directory already exists. Will not overwrite"
        }
        elseif ($LinkProperties.Target -ne $Target) {
            Write-Warning "Powershell Profile link already exists, but points to a different location. Will not overwrite."
        }
    }
    else {
        New-Item -Type Junction -Path $Link -Target $Target | Out-Null
    }
}

function Install-DotFiles {
    Write-Host "[+] Setting dotfiles..."

    $Dotfiles = @(
        ".bash_profile",
        ".bashrc",
        ".gitconfig",
        ".gitignore_global",
        ".p4config"
    )

    $Dotfiles | Get-ChildItem
    | Where-Object { -not $_.PSisContainer }
    | ForEach-Object {
        $Link = Join-Path -Path $HOME -ChildPath $_.Name
        $Target = Join-Path -Path $PSScriptRoot -ChildPath $_.Name

        if (Test-Path $Link) {
            $LinkProperties = Get-ItemProperty $Link;
            if (-not $LinkProperties.LinkType) {
                Write-Warn "$_.Name is not a link. Will not overwrite"
            }
            elseif ($LinkProperties.Target -ne $Target) {
                Write-Warning "$_.Name link already exists, but points to a different location. Will not overwrite."
            }
        }
        else {
            New-Item -ItemType SymbolicLink -Path $Link -Target $Target | Out-Null
        }
    }
}

function Install-GSudo {
    if ($IsWindows -eq $false)
    {
        Write-Warning "gsudo is only available on Windows. Skipping..."
        break;
    }

    Write-Host "[+] Configuring gsudo..."
    # TODO - Check if sudo is installed
    gsudo config PowerShellLoadProfile true
}

Install-PSRequirements
Install-PSProfile

if ($env:CODESPACES -ne $true) {
    Install-DotFiles
    Install-GSudo
}

