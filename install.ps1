#!/usr/bin/env pwsh
[CmdletBinding(DefaultParameterSetName = "Default")]
param(
    [Parameter(Mandatory = $false, ParameterSetName = "Picky")]
    [switch]$WinGet = $false,

    [Parameter(Mandatory = $false, ParameterSetName = "Picky")]
    [switch]$PSProfile = $false,

    [Parameter(Mandatory = $false, ParameterSetName = "Picky")]
    [switch]$PSRequirements = $false,

    [Parameter(Mandatory = $false, ParameterSetName = "Picky")]
    [switch]$DotFiles = $false,

    [Parameter(Mandatory = $false, ParameterSetName = "Picky")]
    [switch]$GSudo = $false
)

$IsCodespace = $env:CODESPACES -eq $true

function Install-WinGetTools {
    if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
        Write-Warning "[+] Windows Package Manager not installed. Skipping..."
        break;
    }

    Write-Host "[+] Importing Windows Package Manager config..."
    $fileConfig = [System.IO.Path]::Combine($PSScriptRoot, "winget.json")

    $wingetImportOptions = @(
        $fileConfig,
        '--ignore-unavailable',
        '--disable-interactivity',
        '--accept-package-agreements',
        '--accept-source-agreements'
        # '--no-upgrade'
    )

    winget import $wingetImportOptions
}

function Install-PSRequirements {
    Write-Host "[+] Installing PowerShell Requirements..."

    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module PowerShellGet -Force -AllowClobber

    $Requirements = @(
        'posh-git',
        'Terminal-Icons'
        'PSFzf',
        'z',
        'Microsoft.WinGet.Client'
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
    $Target = [System.IO.Path]::Combine($PSScriptRoot, "PowerShell")

    if (Test-Path $Link) {
        $LinkProperties = Get-ItemProperty $Link;
        if (-not $LinkProperties.LinkType) {
            Write-Warning "Powershell Profile directory already exists. Will not overwrite"
        }
        elseif ($LinkProperties.Target -ne $Target) {
            Write-Warning "Powershell Profile link already exists, but points to a different location. Will not overwrite."
        }
    }
    else {
        if ($IsWindows) {
            New-Item -Type Junction -Path $Link -Target $Target
        }
        else {
            New-Item -Type SymbolicLink -Path $Link -Target $Target
        }
    }
}

function Install-DotFiles {
    Write-Host "[+] Setting dotfiles..."

    $Dotfiles = @(
        ".gitconfig",
        ".gitignore_global",
        "p4config.ini"
    )

    if (-not $IsCodespace) {
        $Dotfiles += @(
            ".bash_profile"
        )
    }

    $Dotfiles | Get-ChildItem -Force | Where-Object { -not $_.PSisContainer } | ForEach-Object {
        $Link = [System.IO.Path]::Combine($HOME, $_.Name)
        $Target = $_

        if (Test-Path $Link) {
            $LinkProperties = Get-ItemProperty $Link;
            if (-not $LinkProperties.LinkType) {
                Write-Warning "$Link is not a link. Will not overwrite"
            }
            elseif ($LinkProperties.Target -ne $Target) {
                Write-Warning "$Link link already exists, but points to a different location. Will not overwrite."
            }
        }
        else {
            New-Item -ItemType SymbolicLink -Path $Link -Target $Target | Out-Null
        }
    }
}

function Install-GSudo {
    if ($IsWindows -eq $false) {
        Write-Warning "gsudo is only available on Windows. Skipping..."
        break;
    }

    if (-not (Get-Command "gsudo" -ErrorAction SilentlyContinue)) {
        Write-Warning "[+] Gsudo not installed. If gsudo got installed via Install-WinGetTools it may not yet be available. Skipping..."
        break;
    }

    Write-Host "[+] Configuring gsudo..."
    gsudo config PowerShellLoadProfile true
}

if ($IsWindows) {
    if ($PsCmdlet.ParameterSetName -eq "Picky" -and $WinGet) {
        Install-WinGetTools
    }
}

if ($PsCmdlet.ParameterSetName -eq "Picky" -and $PSProfile) {
    Install-PSProfile
}

if ($PsCmdlet.ParameterSetName -eq "Picky" -and $PSRequirements) {
    Install-PSRequirements
}

if ($PsCmdlet.ParameterSetName -eq "Picky" -and $DotFiles) {
    Install-DotFiles
}

if ($PsCmdlet.ParameterSetName -eq "Picky" -and $GSudo) {
    Install-GSudo
}
