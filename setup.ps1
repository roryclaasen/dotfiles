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
        Write-Output "Module $Name already installed, updating..."
        PowerShellGet\Update-Module $Name
    }
    else {
        Write-Output "Installing module $Name..."
        PowerShellGet\Install-Module $Name -Scope CurrentUser -Force
    }
}

function DF_FETCH_LATEST {
    Write-Output "[+] Updating Repository..."
    try {
        Set-Location $PSScriptRoot;
        git pull | Out-Null
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        Write-Error "Git not installed?"
    }
}

function DF_SYMLINK_FILES {
    Write-Output "[+] Setting up symlinks"
    Get-ChildItem -Path $PSScriptRoot -Exclude @(".git", ".gitignore", ".editorconfig", "LICENSE", "README.md", "setup.ps1") |
    ForEach-Object {
        if (!$_.PSisContainer) {
            DF_CREATE_SYMLINK -File $_ -TargetFolder $HOME
        }
    }
}

function DF_POWERSHELL_PROFILE {
    Write-Output "[+] Setting up Powershell Profile"

    DF_INSTALL_MODULE -Name posh-git

    $targetFolder = Split-Path $PROFILE.CurrentUserAllHosts
    Get-ChildItem -Path "$PSScriptRoot/PowerShell" |
    ForEach-Object {
        if (!$_.PSisContainer) {
            DF_CREATE_SYMLINK -File $_ -TargetFolder $targetFolder
        }
    }
}

function MAIN {
    write-output ""
    Write-Output "      _       _         __ _ _"
    Write-Output "   __| | ___ | |_      / _(_) | ___  ___"
    Write-Output "  / _\` |/ _ \| __|____| |_| | |/ _ \/ __|"
    Write-Output " | (_| | (_) | ||_____|  _| | |  __/\__ \\"
    Write-Output "  \__,_|\___/ \__|    |_| |_|_|\___||___/"
    Write-Output ""

    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "You do not have Administrator rights to run this script!"
        Write-Warning "Please re-run this script as an Administrator!"
        Break
    }

    while ($true) {
        write-output "0. Exit"
        write-output "1. Fetch Latest"
        write-output "2. Symlink Dotfiles"
        write-output "3. PowerShell Profile"
        write-output ""

        $a = Read-Host -prompt "[+] What do you want to do"
        Write-Output ""

        switch ($a) {
            "0" { EXIT }
            "1" { DF_FETCH_LATEST }
            "2" { DF_SYMLINK_FILES }
            "3" { DF_POWERSHELL_PROFILE }
            default { }
        }

        Write-Output ""
    }
}

MAIN
