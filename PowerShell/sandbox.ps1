function Get-SavedSandboxConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Wether or not to include the default sandbox configuration")]
        [bool]$IncludeRetail = $true
    )

    $DefaultTable = @{}
    if ($IncludeRetail) {
        $DefaultTable += @{ "Retail" = "Retail" };
    }

    $JsonFile = Join-Path $PSScriptRoot "Sandboxes.json"
    if (Test-Path $JsonFile) {
        return $DefaultTable + (Get-Content $JsonFile -Raw | ConvertFrom-Json -AsHashtable)
    }

    return $DefaultTable
}

function Get-Sandbox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "The sandbox to get to.")]
        [string]$Sandbox
    )

    if ([string]::IsNullOrWhiteSpace($Sandbox)) {
        $XboxLive = Get-ItemProperty -Path hklm:\software\microsoft\XboxLive
        if ($XboxLive.Sandbox) {
            return $XboxLive.Sandbox
        }
        return 'Retail'
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
        [Parameter(Mandatory = $true, HelpMessage = "The sandbox to set to.")]
        [string]$Sandbox
    )

    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "You must run this cmdlet as an administrator."
        Break
    }

    $SandboxMap = Get-SavedSandboxConfig

    $NewSandbox = $Sandbox
    if ($SandboxMap.ContainsKey($Sandbox)) {
        $NewSandbox = $SandboxMap[$Sandbox]
    }

    $CurrentSanbox = Get-Sandbox
    if ($CurrentSanbox -eq $NewSandbox) {
        Write-Host "Already in sandbox $NewSandbox"
        break;
    }

    if ($NewSandbox -eq "Retail") {
        Write-Host "Setting Sandbox to Retail"
        Remove-ItemProperty -Path hklm:\software\microsoft\XboxLive -Name Sandbox
    }
    else {
        Write-Host "Setting Sandbox to $NewSandbox"
        Set-ItemProperty -Path hklm:\software\microsoft\XboxLive -Name Sandbox -Value $NewSandbox
    }

    function Restart-Service {
        param(
            [Parameter(Mandatory = $true)]
            [string]$ServiceName
        )

        Write-Host "Restarting $ServiceName"
        $service = Get-Service -Name $ServiceName
        if ($service.Status -eq 'Running') {
            $service | Stop-Service
        }
        $service | Start-Service
    }

    Restart-Service XblAuthManager
    Restart-Service DiagTrack
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
