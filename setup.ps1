If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script!"
    Write-Warning "Please re-run this script as an Administrator!"
    Break
}

function InstallModule {
    Param (
        [Parameter(Mandatory = $true)] [string] $Name
    )

    $Decision = $Host.UI.PromptForChoice("$Name Installation", "Do you want to install or update $Name?", @("&Yes", "&No"), 0)
    if ($Decision -eq 0) {
        if (Get-Module -ListAvailable -Name $Name) {
            Write-Host "Module $Name already installed, updating..."
            PowerShellGet\Update-Module $Name
        }
        else {
            Write-Host "Installing module $Name..."
            PowerShellGet\Install-Module $Name -Scope CurrentUser -Force
        }
    }
}

function SetupDotfiles {
    Write-Host "[+] Setting up dotfiles..."
    Get-ChildItem -Path $PSScriptRoot -Exclude @(".gitignore", ".editorconfig", "LICENSE", "README.md", "setup.ps1")
    | Where-Object { -not $_.PSisContainer }
    | ForEach-Object {
        $Path = Join-Path -Path $HOME -ChildPath $_.Name
        $Target = Join-Path -Path $PSScriptRoot -ChildPath $_.Name

        if (Test-Path $Path) {
            if (-not (Get-ItemProperty $Path).LinkType) {
                Write-Warn "File '$Path' already exists and is not a symlink! Move or Remove it to prevent data loss!"
            }
        }
        else {
            New-Item -ItemType SymbolicLink -Path $Path -Target $Target | Out-Null
        }
    }
}

function SetupPowerShell {
    Write-Host "[+] Setting up Powershell Profile..."

    $targetFolder = Split-Path $PROFILE.CurrentUserAllHosts

    if (Test-Path $targetFolder) {
        if (-not (Get-ItemProperty $targetFolder).LinkType) {
            Write-Warn "Profile already exists, unable to link from dotfiles"
        }
    }
    else {
        $sourcePath = Join-Path -Path $PSScriptRoot -ChildPath "PowerShell"

        New-Item -Type Junction -Path $targetFolder -Target $sourcePath | Out-Null
    }

    InstallModule -Name posh-git
    InstallModule -Name Terminal-Icons
}

function SetupSudo {
    # TODO - Check if sudo is installed
    gsudo config PowerShellLoadProfile true
}

SetupDotfiles
SetupPowerShell
SetupSudo
