function DFW_CREATE_SYMLINK {
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

function DFW_INSTALL_MODULE {
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

function DFW_FETCH_LATEST {
    Write-Output "[+] Updating Repository..."
    try {
        Set-Location $PSScriptRoot;
        git pull | Out-Null
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        Write-Error "Git not installed?"
    }
}

function DFW_SYMLINK_FILES {
    Write-Output "[+] Setting up symlinks"
    Get-ChildItem -Path $PSScriptRoot -Exclude @(".git", ".editorconfig", "LICENSE", "setup.ps1") |
    ForEach-Object {
        if (!$_.PSisContainer) {
            DFW_CREATE_SYMLINK -File $_ -TargetFolder $HOME
        }
    }
}

function DFW_POWERSHELL_PROFILE {
    Write-Output "[+] Setting up Powershell Profile"

    DFW_INSTALL_MODULE -Name posh-git

    $targetFolder = Split-Path $PROFILE.CurrentUserAllHosts
    Get-ChildItem -Path "$PSScriptRoot/PowerShell" |
    ForEach-Object {
        if (!$_.PSisContainer) {
            DFW_CREATE_SYMLINK -File $_ -TargetFolder $targetFolder
        }
    }
}

function DFW_INSTALL_PROGRAM {
    Param (
        [switch] $Required,
        [switch] $Recomended,
        [switch] $Work,
        [switch] $Upgrade
    )

    if ($Upgrade) { Write-Output "[+] Upgrading programs" }
    else { Write-Output "[+] Installing programs" }

    try {
        winget | Out-Null
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        Write-Error "Winget is not installed!"
        return
    }

    $Programs = @();
    if ($Required) {
        # Not including "Microsoft.WindowsTerminal" as it causes an exit if the script is run on it
        $programs += @("Git.Git", "Notepad++.Notepad++", "ScooterSoftware.BeyondCompare4", "OpenJS.NodeJS")
    }

    if ($Recomended) {
        $programs += @("Microsoft.VisualStudioCode", "Microsoft.Powertoys", "VideoLAN.VLC", "WinDirStat.WinDirStat")
    }

    if ($Work) {
        $programs += @("Perforce.P4V", "SlackTechnologies.Slack")
    }

    foreach ($program in $programs) {
        Write-Output "Processing $program"
        if ($Upgrade) { winget upgrade --id $program --silent }
        else { winget install --id $program --silent }
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
        write-output "1. Setup Everything"
        write-output "2. Fetch Latest"
        write-output "3. Symlink Dotfiles"
        write-output "4. PowerShell Profile"
        write-output "5. Install Required Programs"
        write-output "6. Install Recomended Programs"
        write-output "7. Install Work Programs"
        write-output "8. Upgrade All Programs"
        write-output ""

        $a = Read-Host -prompt "[+] What do you want to do"
        Write-Output ""

        switch ($a) {
            "0" { EXIT }
            "1" {
                DFW_FETCH_LATEST
                DFW_SYMLINK_FILES
                DFW_POWERSHELL_PROFILE
                DFW_INSTALL_PROGRAM -AllPrograms
            }
            "2" { DFW_FETCH_LATEST }
            "3" { DFW_SYMLINK_FILES }
            "4" { DFW_POWERSHELL_PROFILE }
            "5" { DFW_INSTALL_PROGRAM -Required }
            "6" { DFW_INSTALL_PROGRAM -Recomended }
            "7" { DFW_INSTALL_PROGRAM -Work }
            "8" { DFW_INSTALL_PROGRAM -Required -Recomended -Work -Upgrade }
            default { }
        }

        Write-Output ""
    }
}

MAIN
