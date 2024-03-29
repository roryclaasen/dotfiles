#!/usr/bin/env bash

echo "it ran" > ~/foo.txt

# If in a Codespace, install oh-my-posh
if [ -v CODESPACES ]
then
    curl -s https://ohmyposh.dev/install.sh | sudo bash -s
fi

# If PowerShell isn't installed, install PowerShell
if ! command -v pwsh &> /dev/null
then
    wget -O - https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/install-powershell.sh | bash -s
fi

pwsh -nologo -noprofile -command ./install.ps1
