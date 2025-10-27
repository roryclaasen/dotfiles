function Get-ConfigFilePath {
    $FileName = "Sandboxes.json"

    $JsonFile = [System.IO.Path]::Combine($PSScriptRoot, $FileName)
    if (Test-Path $JsonFile) {
        return $JsonFile
    }

    return [System.IO.Path]::Combine($env:DOTPOSH, $FileName)
}

function Get-SandboxConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Whether or not to include the default sandbox configuration")]
        [switch]$IncludeRetail
    )

    $DefaultTable = @{}
    if ($IncludeRetail) {
        $DefaultTable += @{ "Retail" = "RETAIL" };
    }

    $JsonFile = Get-ConfigFilePath
    if (Test-Path $JsonFile) {
        return $DefaultTable + (Get-Content $JsonFile -Raw | ConvertFrom-Json -AsHashtable)
    }

    Write-Verbose "No sandbox configuration found. Using default."
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

    $JsonFile = Get-ConfigFilePath
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
        Write-Verbose "Found '$($ExePath.Source)' via Get-Command"
        return $ExePath.Source
    }

    $GDKPath = $env:GameDK
    if (-not [string]::IsNullOrWhiteSpace($GDKPath)) {
        $ExePath = [System.IO.Path]::Combine($GDKPath, "bin", "XblPCSandbox.exe")
        if (Test-Path $ExePath) {
            Write-Verbose "Found '$ExePath' via GameDK environment variable"
            return $ExePath
        }
    }

    try {
        $GDKInstallRoots = Get-ItemProperty -Path "hklm:\software\microsoft\GDK\Installed Roots"
        $GDKPath = $GDKInstallRoots.GDKInstallPath
        if (-not [string]::IsNullOrWhiteSpace($GDKPath)) {
            $ExePath = [System.IO.Path]::Combine($GDKPath, "bin", "XblPCSandbox.exe")
            if (Test-Path $ExePath) {
                Write-Verbose "Found '$ExePath' via registry"
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

            Write-Verbose "Found sandbox via XblPCSandbox.exe"
            return $Sandbox
        }
        catch {
            $XboxLive = Get-ItemProperty -Path hklm:\software\microsoft\XboxLive
            if ($XboxLive.Sandbox) {
                Write-Verbose "Found sandbox in registry"
                return $XboxLive.Sandbox
            }
        }

        Write-Verbose "Unable to get sandbox from XblPCSandbox.exe or registry"
        return "RETAIL"
    }
    else {
        $SandboxMap = Get-SandboxConfig
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
    $SandboxMap = Get-SandboxConfig -IncludeRetail

    $NewSandbox = $Sandbox
    if ($SandboxMap.ContainsKey($Sandbox)) {
        $NewSandbox = $SandboxMap[$Sandbox]
    }

    $CurrentSandbox = Get-Sandbox
    if ($CurrentSandbox -eq $NewSandbox) {
        Write-Host "Already in sandbox $NewSandbox"
        break
    }

    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "You must run this cmdlet as an administrator."
        break
    }

    try {
        $XblPCSandbox = Get-XblPCSandboxCommand
        & $XblPCSandbox $NewSandbox
    }
    catch {
        Write-Host "Switching to Sandbox $NewSandbox"
        if ($NewSandbox -ieq "RETAIL") {
            Remove-ItemProperty -Path "hklm:\software\microsoft\XboxLive" -Name Sandbox
        }
        else {
            Set-ItemProperty -Path "hklm:\software\microsoft\XboxLive" -Name Sandbox -Value $NewSandbox
        }

        function Restart-ServiceFunc {
            param(
                [Parameter(Mandatory = $true)]
                [string]$ServiceName
            )

            $service = Get-Service -Name $ServiceName
            if ($service.Status -eq "Running") {
                Write-Host "Stopping $ServiceName"
                $service | Stop-Service -Force
            }
            Write-Host "Starting $ServiceName"
            $service | Start-Service
        }

        Restart-ServiceFunc "XblAuthManager"
        Restart-ServiceFunc "DiagTrack"
        Restart-ServiceFunc "GamingServices"

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
    $SandboxMap = Get-SandboxConfig
    return $SandboxMap.Keys | Sort-Object -Unique | Where-Object { $_ -like "$stringMatch*" }
}

Register-ArgumentCompleter -CommandName Set-Sandbox -ParameterName Sandbox -ScriptBlock {
    param($commandName, $parameterName, $stringMatch)
    $SandboxMap = Get-SandboxConfig
    return ($SandboxMap.Keys + $SandboxMap.Values) | Sort-Object -Unique | Where-Object { $_ -like "$stringMatch*" }
}

Set-Alias 'sandbox' Set-Sandbox

Export-ModuleMember -Function Get-SandboxConfig
Export-ModuleMember -Function Add-SandboxConfig
Export-ModuleMember -Function Get-Sandbox
Export-ModuleMember -Function Set-Sandbox
Export-ModuleMember -Alias 'sandbox'
