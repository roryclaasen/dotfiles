# Encoding UTF8
# -----------------------------------------------------------------------------------------

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Tls12
# -----------------------------------------------------------------------------------------

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Environment Variables
# -----------------------------------------------------------------------------------------

$env:DOTFILES = [System.IO.Path]::Combine($HOME, "dotfiles")
$env:DOTPOSH = [System.IO.Path]::Combine($PSScriptRoot, "dotposh")
$env:POSH_THEME = [System.IO.Path]::Combine($env:DOTPOSH, "roryclaasen.omp.json")

# Oh My Posh
# -----------------------------------------------------------------------------------------
$LazyLoadOhMyPosh = $false

# Asynchronous Processes (Boost PowerShell performance)
# Original idea is from: https://matt.kotsenas.com/posts/pwsh-profiling-async-startup
# -----------------------------------------------------------------------------------------

function prompt {
    # oh-my-posh will override this prompt, however because we're loading it async we want to communicate that the
    # real prompt is still loading.
    # "[async]:: $($executionContext.SessionState.Path.CurrentLocation) :: $(Get-Date -Format "HH:mm tt") $('❯' * ($nestedPromptLevel + 1)) "

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

    $prefix = "[async]::"
    if ($principal.IsInRole($adminRole)) { $prefix = "[async][admin]::" }

    $body = 'PS ' + $PWD.path
    $suffix = $(if ($NestedPromptLevel -ge 1) { '❯❯ ' }) + '❯ '
    $time = $(Get-Date -Format "HH:mm tt")

    "${prefix}${body} ${time} ${suffix}"
}

# Load modules asynchronously to reduce shell startup time
[System.Collections.Queue]$__initQueue = @(
    {
        # Oh My Posh
        if ([Environment]::GetCommandLineArgs().Contains("-NonInteractive")) {
            return
        }

        if ($env:PG_ENVIRONMENT -eq 1) {
            return
        }

        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
            oh-my-posh init pwsh --config $env:POSH_THEME | Invoke-Expression
        }
    },
    {
        # gsudo module
        try { Import-Module -Name gsudoModule } catch [System.Management.Automation.CommandNotFoundException] { }
    },
    {
        # Posh Git
        try { Import-Module -Name posh-git } catch [System.Management.Automation.CommandNotFoundException] { }
    },
    {
        # Terminal Icons
        try { Import-Module -Name Terminal-Icons } catch [System.Management.Automation.CommandNotFoundException] { }
    },
    {
        # Fzf
        if (Get-Command "Fzf.exe" -ErrorAction SilentlyContinue) {
            try { Import-Module -Name PSFzf -ArgumentList 'Ctrl+t', 'Ctrl+r' } catch [System.Management.Automation.CommandNotFoundException] { }
        }
    },
    {
        # z
        try { Import-Module -Name z } catch [System.Management.Automation.CommandNotFoundException] { }
    },
    {
        # WinGet
        try { Import-Module -Name Microsoft.WinGet.Client } catch [System.Management.Automation.CommandNotFoundException] { }
        try { Import-Module -Name Microsoft.WinGet.CommandNotFound } catch [System.Management.Automation.CommandNotFoundException] { }
    },
    {
        # Fast Node Manager
        if (Get-Command "fnm.exe" -ErrorAction SilentlyContinue) {
            fnm env --use-on-cd --shell power-shell | Out-String | Invoke-Expression
        }
    },
    {
        # Secret Management
        try { Import-Module -Name Microsoft.PowerShell.SecretManagement } catch [System.Management.Automation.CommandNotFoundException] { }
        try { Import-Module -Name Microsoft.PowerShell.SecretStore } catch [System.Management.Automation.CommandNotFoundException] { }
    },
    {
        # GitHub CLI
        if (Get-Command gh -ErrorAction SilentlyContinue) {
            # gh completion
            Invoke-Expression -Command $(gh completion -s powershell | Out-String)
        }
    }
)

Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -SupportEvent -Action {
    if ($__initQueue.Count -gt 0) {
        & $__initQueue.Dequeue()
    }
    else {
        Unregister-Event -SubscriptionId $EventSubscriber.SubscriptionId -Force
        Remove-Variable -Name '__initQueue' -Scope Global -Force

        if ($LazyLoadOhMyPosh) {
            [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
        }
    }
}

# Initialize Oh My Posh
# -----------------------------------------------------------------------------------------
if (-not $LazyLoadOhMyPosh) {
    # The first item in the initialization queue is Oh My Posh
    & $__initQueue.Dequeue()
}

# DOTPOSH Configuration + Custom Modules
# -----------------------------------------------------------------------------------------
foreach ($module in $((Get-ChildItem -Path "$env:DOTPOSH\Modules\*" -Include *.psm1).FullName )) {
    Import-Module "$module" -Global
}
foreach ($file in $((Get-ChildItem -Path "$env:DOTPOSH\Config\*" -Include *.ps1).FullName)) {
    . "$file"
}
