function DF_CREATE_SYMLINK {
    Param (
        [Parameter(Mandatory = $true)] [System.IO.FileSystemInfo] $File,
        [Parameter(Mandatory = $true)] [string] $TargetFolder
    )

    $name = $File.Name
    $target = "$TargetFolder\$name"

    try {
        if (Test-Path $target) {
            try {
                Remove-Item -Force -Path $target
            }
            catch [System.IO.IOException] {
                Write-Warning "$target exists, skipping..."
                return
            }
        }

        New-Item -ItemType HardLink -Path $target -Target $File.FullName | Out-Null
    }
    catch {
        Write-Error "Failed to create symlink $target, skipping..."
    }
}

function DF_INSTALL_MODULE {
    Param (
        [Parameter(Mandatory = $true)] [string] $Name
    )

    if (Get-Module -ListAvailable -Name $Name) {
        Write-Host "Module $Name already installed, updating..."
        PowerShellGet\Update-Module $Name
    }
    else {
        Write-Host "Installing module $Name..."
        PowerShellGet\Install-Module $Name -Scope CurrentUser -Force
    }
}

function DF_SYMLINK_FILES {
    Write-Host "[+] Setting up symlinks"
    Get-ChildItem -Path $PSScriptRoot -Exclude @(".git", ".gitignore", ".editorconfig", "LICENSE", "README.md", "setup.ps1") |
    ForEach-Object {
        if (!$_.PSisContainer) {
            DF_CREATE_SYMLINK -File $_ -TargetFolder $HOME
        }
    }
}

function DF_POWERSHELL_PROFILE {
    Write-Host "[+] Setting up Powershell Profile"

    $targetFolder = Split-Path $PROFILE.CurrentUserAllHosts

    if (Test-Path $targetFolder) {
        Write-Host "Profile already exists, unable to link from dotfiles"
    } else {
        Write-Host "Creating profile folder"
        $sourcePath = Join-Path -Path $PSScriptRoot -ChildPath "PowerShell"

        New-Item -Type Junction -Path $targetFolder -Target $sourcePath | Out-Null
    }

    $PoshGitDecision = $Host.UI.PromptForChoice("Posh-Git", "Do you want to install or update Posh-Git?", @("&Yes", "&No"), 0)
    if ($PoshGitDecision -eq 0) {
        DF_INSTALL_MODULE -Name posh-git
    }
}

function MAIN {
    Write-Host ""
    Write-Host "      _       _         __ _ _"
    Write-Host "   __| | ___ | |_      / _(_) | ___  ___"
    Write-Host "  / _\` |/ _ \| __|____| |_| | |/ _ \/ __|"
    Write-Host " | (_| | (_) | ||_____|  _| | |  __/\__ \\"
    Write-Host "  \__,_|\___/ \__|    |_| |_|_|\___||___/"
    Write-Host ""

    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "You do not have Administrator rights to run this script!"
        Write-Warning "Please re-run this script as an Administrator!"
        Break
    }

    while ($true) {
        Write-Host "0. Exit"
        Write-Host "1. Symlink Dotfiles"
        Write-Host "2. PowerShell Profile"
        Write-Host ""

        $a = Read-Host -prompt "[+] What do you want to do"
        Write-Host ""

        switch ($a) {
            "0" { EXIT }
            "1" { DF_SYMLINK_FILES }
            "2" { DF_POWERSHELL_PROFILE }
            default { }
        }

        Write-Host ""
    }
}

MAIN
