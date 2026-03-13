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

$IsCodespace = -not [string]::IsNullOrWhiteSpace($env:CODESPACES)

function Install-WinGetTools {
    if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
        Write-Warning "[+] Windows Package Manager not installed. Skipping..."
        return
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
        'Terminal-Icons',
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

    foreach ($dotfile in $Dotfiles) {
        $Target = [System.IO.Path]::Combine($PSScriptRoot, $dotfile)
        if (-not (Test-Path -LiteralPath $Target)) {
            Write-Warning "Missing dotfile target '$Target'. Skipping."
            continue
        }

        $targetItem = Get-Item -LiteralPath $Target -Force
        $Link = [System.IO.Path]::Combine($HOME, $targetItem.Name)

        if (Test-Path $Link) {
            $LinkProperties = Get-ItemProperty $Link;
            if (-not $LinkProperties.LinkType) {
                Write-Warning "$Link is not a link. Will not overwrite"
            }
            elseif ($LinkProperties.Target -ne $targetItem.FullName) {
                Write-Warning "$Link link already exists, but points to a different location. Will not overwrite."
            }
        }
        else {
            New-Item -ItemType SymbolicLink -Path $Link -Target $targetItem.FullName | Out-Null
        }
    }
}

function Install-GSudo {
    if ($IsWindows -eq $false) {
        Write-Warning "gsudo is only available on Windows. Skipping..."
        return
    }

    if (-not (Get-Command "gsudo" -ErrorAction SilentlyContinue)) {
        Write-Warning "[+] Gsudo not installed. If gsudo got installed via Install-WinGetTools it may not yet be available. Skipping..."
        return
    }

    Write-Host "[+] Configuring gsudo..."
    gsudo config PowerShellLoadProfile true
}

$InstallAll = $PsCmdlet.ParameterSetName -ne "Picky"

if ($IsWindows -and ($InstallAll -or $WinGet)) {
    Install-WinGetTools
}

if ($InstallAll -or $PSProfile) {
    Install-PSProfile
}

if ($InstallAll -or $PSRequirements) {
    Install-PSRequirements
}

if ($InstallAll -or $DotFiles) {
    Install-DotFiles
}

if ($IsWindows -and ($InstallAll -or $GSudo)) {
    Install-GSudo
}
