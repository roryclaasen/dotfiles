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
    Get-ChildItem -Path $PSScriptRoot -Exclude @(".git", "LICENSE", "setup.ps1") |
        ForEach-Object {
            $name = $_.Name
            $source = $_
            $target = "$env:USERPROFILE\$name"
            try {
                if (Test-Path $target) {
                    try {
                        Remove-Item  -Force -Path $target
                    }
                    catch [System.IO.IOException] {
                        Write-Warning "$target exists, skipping..."
                        return
                    }
                }

                New-Item -ItemType HardLink -Path $target -Target $source | Out-Null
            } catch {
                Write-Error "Failed to create symlink $target, skipping..."
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

    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Output ""
        Write-Warning "You do not have Administrator rights to run this script!"
        Write-Warning "Please re-run this script as an Administrator!"
        Break
    }

    while ($true) {
        Write-Output ""
        write-output "0. Exit"
        write-output "1. Run Everything"
        write-output "2. Fetch Latest"
        write-output "3. Setup Symlinks"
        write-output ""

        $a = Read-Host -prompt "[+] What do you want to do"

        switch ($a) {
            "0" { EXIT }
            "1" {
                DFW_FETCH_LATEST
                DFW_SYMLINK_FILES
            }
            "2" { DFW_FETCH_LATEST }
            "3" { DFW_SYMLINK_FILES }
            default { }
        }
    }
}

MAIN
