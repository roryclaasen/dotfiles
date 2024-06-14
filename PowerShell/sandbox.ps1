function Get-SandboxConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Whether or not to include the default sandbox configuration")]
        [bool]$IncludeRetail = $true
    )

    $DefaultTable = @{}
    if ($IncludeRetail) {
        $DefaultTable += @{ "Retail" = "RETAIL" };
    }

    $JsonFile = Join-Path $PSScriptRoot "Sandboxes.json"
    if (Test-Path $JsonFile) {
        return $DefaultTable + (Get-Content $JsonFile -Raw | ConvertFrom-Json -AsHashtable)
    }

    return $DefaultTable
}

function Add-SandboxConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The title name.")]
        [string]$Name,
        [Parameter(Mandatory = $true, HelpMessage = "The sandbox id.")]
        [string]$Sandbox
    )

    $JsonFile = Join-Path $PSScriptRoot "Sandboxes.json"
    if (Test-Path $JsonFile) {
        $SandboxMap = Get-Content $JsonFile -Raw | ConvertFrom-Json -AsHashtable
    }
    else {
        $SandboxMap = @{}
    }

    $SandboxMap[$Name] = $Sandbox
    $SandboxMap | ConvertTo-Json | Set-Content $JsonFile
}

function Get-XblPCSandboxCommand {
    $ExePath = Get-Command XblPCSandbox.exe -ErrorAction SilentlyContinue
    if ($ExePath) {
        return $ExePath.Source
    }

    $GDKPath = $env:GameDK
    if (-not [string]::IsNullOrWhiteSpace($GDKPath)) {
        $ExePath = Join-Path $GDKPath "bin\XblPCSandbox.exe"
        if (Test-Path $ExePath) {
            return $ExePath
        }
    }

    try {
        $GDKInstallRoots = Get-ItemProperty -Path 'hklm:\software\microsoft\GDK\Installed Roots'
        $GDKPath = $GDKInstallRoots.GDKInstallPath
        if (-not [string]::IsNullOrWhiteSpace($GDKPath)) {
            $ExePath = Join-Path $GDKPath "bin\XblPCSandbox.exe"
            if (Test-Path $ExePath) {
                return $ExePath
            }
        }
    }
    catch {
    }

    throw "Unable to find XblPCSandbox.exe"
}

function Get-Sandbox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "If provided, the sandbox to fetch from the saved config.")]
        [string]$Sandbox
    )

    if ([string]::IsNullOrWhiteSpace($Sandbox)) {
        try {
            $XblPCSandbox = Get-XblPCSandboxCommand
            $Sandbox = (& $XblPCSandbox "/get") | Select-String -Pattern "Sandbox: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value }
            if ([string]::IsNullOrWhiteSpace($Sandbox)) {
                throw "Unable to get sandbox from XblPCSandbox.exe"
            }
            return $Sandbox
        }
        catch {
            $XboxLive = Get-ItemProperty -Path hklm:\software\microsoft\XboxLive
            if ($XboxLive.Sandbox) {
                return $XboxLive.Sandbox
            }
        }

        return "RETAIL"
    }
    else {
        $SandboxMap = Get-SavedSandboxConfig -IncludeRetail $false
        if ($SandboxMap.ContainsKey($Sandbox)) {
            return $SandboxMap[$Sandbox]
        }
    }

    throw "Unknown sandbox '$Sandbox'"
}

function Set-Sandbox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The sandbox to switch to.")]
        [string]$Sandbox
    )

    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "You must run this cmdlet as an administrator."
        Break
    }

    $SandboxMap = Get-SandboxConfig

    $NewSandbox = $Sandbox
    if ($SandboxMap.ContainsKey($Sandbox)) {
        $NewSandbox = $SandboxMap[$Sandbox]
    }

    $CurrentSanbox = Get-Sandbox
    if ($CurrentSanbox -eq $NewSandbox) {
        Write-Host "Already in sandbox $NewSandbox"
        break;
    }

    try {
        $XblPCSandbox = Get-XblPCSandboxCommand
        & $XblPCSandbox $NewSandbox
    }
    catch {
        Write-Host "Switching to Sandbox $NewSandbox"
        if ($NewSandbox -ieq "RETAIL") {
            Remove-ItemProperty -Path hklm:\software\microsoft\XboxLive -Name Sandbox
        }
        else {
            Set-ItemProperty -Path hklm:\software\microsoft\XboxLive -Name Sandbox -Value $NewSandbox
        }

        function Restart-ServiceFunc {
            param(
                [Parameter(Mandatory = $true)]
                [string]$ServiceName
            )

            $service = Get-Service -Name $ServiceName
            if ($service.Status -eq 'Running') {
                Write-Host "Stopping $ServiceName"
                $service | Stop-Service -Force
            }
            Write-Host "Starting $ServiceName"
            $service | Start-Service
        }

        Restart-ServiceFunc XblAuthManager
        Restart-ServiceFunc DiagTrack
        Restart-ServiceFunc GamingServices

        Write-Host "Resetting Windows Store cache"

        $isStoreClosed = $Null -eq (Get-Process -Name "WinStore.App" -ErrorAction SilentlyContinue)
        $wsresetProcess = Start-Process -FilePath "wsreset.exe" -PassThru -WindowStyle Hidden
        $wsresetProcess.WaitForExit()

        # wsreset opens the windows store; close it if there were no instances open before reset
        if ($isStoreClosed) {
            Get-Process -Name "WinStore.App" -ErrorAction SilentlyContinue | Stop-Process -Force
        }

        Write-Host "Reset Windows Store cache"
    }
}

Register-ArgumentCompleter -CommandName Get-Sandbox -ParameterName Sandbox -ScriptBlock {
    param($commandName, $parameterName, $stringMatch)
    $SandboxMap = Get-SavedSandboxConfig -IncludeRetail $false
    return $SandboxMap.Keys | Sort-Object -Unique | Where-Object { $_ -like "$stringMatch*" }
}

Register-ArgumentCompleter -CommandName Set-Sandbox -ParameterName Sandbox -ScriptBlock {
    param($commandName, $parameterName, $stringMatch)
    $SandboxMap = Get-SavedSandboxConfig
    return ($SandboxMap.Keys + $SandboxMap.Values) | Sort-Object -Unique | Where-Object { $_ -like "$stringMatch*" }
}

Set-Alias -Name sandbox -Value Set-Sandbox
