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
    [switch]$PSOptionalRequirements = $false,

    [Parameter(Mandatory = $false, ParameterSetName = "Picky")]
    [switch]$DotFiles = $false,

    [Parameter(Mandatory = $false, ParameterSetName = "Picky")]
    [switch]$GSudo = $false
)

$IsCodespace = -not [string]::IsNullOrWhiteSpace($env:CODESPACES)

function Ensure-PSGalleryTrusted {
    $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if ($null -eq $repo) {
        Write-Warning "[+] PSGallery repository is not available. Skipping repository policy update."
        return
    }

    if ($repo.InstallationPolicy -ne 'Trusted') {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }
}

function Install-ModuleIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (Get-Module -ListAvailable -Name $Name) {
        Write-Host "[=] PowerShell module '$Name' already installed. Skipping."
        return
    }

    Write-Host "[+] Installing PowerShell module '$Name'..."
    PowerShellGet\Install-Module $Name -Scope CurrentUser -Force
}

function Test-IsPathLinkedToTarget {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$ExpectedTarget
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $item = Get-Item -LiteralPath $Path -Force
    $isLink = -not [string]::IsNullOrWhiteSpace($item.LinkType)
    if (-not $isLink) {
        return $false
    }

    $target = if ($item.Target -is [System.Array]) {
        [string]::Join(', ', $item.Target)
    }
    else {
        [string]$item.Target
    }

    return $target -eq $ExpectedTarget
}

function Test-WinGetPackageInstalled {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageIdentifier
    )

    $output = winget list --id $PackageIdentifier --exact --accept-source-agreements 2>$null
    return $LASTEXITCODE -eq 0 -and ($output -match [regex]::Escape($PackageIdentifier))
}

function Install-WinGetTools {
    if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
        Write-Warning "[+] Windows Package Manager not installed. Skipping..."
        return
    }

    Write-Host "[+] Ensuring Windows Package Manager tools from config..."
    $fileConfig = [System.IO.Path]::Combine($PSScriptRoot, "winget.json")

    if (-not (Test-Path -LiteralPath $fileConfig)) {
        Write-Warning "[+] Missing winget config '$fileConfig'. Skipping..."
        return
    }

    $wingetConfig = Get-Content -LiteralPath $fileConfig -Raw | ConvertFrom-Json
    $packageIds = @($wingetConfig.Sources.Packages.PackageIdentifier | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    foreach ($packageId in $packageIds) {
        if (Test-WinGetPackageInstalled -PackageIdentifier $packageId) {
            Write-Host "[=] WinGet package '$packageId' already installed. Skipping."
            continue
        }

        Write-Host "[+] Installing WinGet package '$packageId'..."
        winget install --id $packageId --exact --disable-interactivity --accept-package-agreements --accept-source-agreements
    }
}

function Install-PSRequirements {
    Write-Host "[+] Installing PowerShell Core Requirements..."

    Ensure-PSGalleryTrusted

    $Requirements = @(
        'posh-git',
        'Terminal-Icons',
        'PSFzf',
        'z',
        'Microsoft.WinGet.Client',
        'Microsoft.WinGet.CommandNotFound',
        'gsudoModule'
    )

    $Requirements | ForEach-Object { Install-ModuleIfMissing -Name $_ }
}

function Install-PSOptionalRequirements {
    Write-Host "[+] Installing PowerShell Optional Requirements..."

    Ensure-PSGalleryTrusted

    $OptionalRequirements = @(
        'DockerCompletion',
        'Microsoft.PowerShell.SecretManagement',
        'Microsoft.PowerShell.SecretStore'
    )

    $OptionalRequirements | ForEach-Object { Install-ModuleIfMissing -Name $_ }

    if (Get-Command dotnet -ErrorAction SilentlyContinue) {
        if (Get-Command nuke -ErrorAction SilentlyContinue) {
            Write-Host "[=] Nuke.GlobalTool already installed. Skipping."
        }
        else {
            Write-Host "[+] Installing Nuke.GlobalTool..."
            dotnet tool install --global Nuke.GlobalTool | Out-Null
        }
    }
    else {
        Write-Warning "[+] dotnet is not installed. Skipping Nuke.GlobalTool install."
    }
}

function Install-PSProfile {
    Write-Host "[+] Setting PowerShell Profile..."

    $Link = Split-Path $PROFILE.CurrentUserAllHosts
    $Target = [System.IO.Path]::Combine($PSScriptRoot, "PowerShell")

    if (Test-Path -LiteralPath $Link) {
        if (Test-IsPathLinkedToTarget -Path $Link -ExpectedTarget $Target) {
            Write-Host "[=] PowerShell profile link already configured. Skipping."
            return
        }

        $LinkProperties = Get-ItemProperty $Link
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
            if (Test-IsPathLinkedToTarget -Path $Link -ExpectedTarget $targetItem.FullName) {
                Write-Host "[=] '$Link' already linked correctly. Skipping."
                continue
            }

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

if ($PSOptionalRequirements) {
    Install-PSOptionalRequirements
}

if ($InstallAll -or $DotFiles) {
    Install-DotFiles
}

if ($IsWindows -and ($InstallAll -or $GSudo)) {
    Install-GSudo
}
