function Get-EnvironmentVariables {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = "Picky")]
        [switch]$User,

        [Parameter(Mandatory = $false, ParameterSetName = "Picky")]
        [switch]$System,

        [Parameter(Mandatory = $false, ParameterSetName = "Picky")]
        [switch]$Process
    )

    $variables = @()
    if ($PsCmdlet.ParameterSetName -eq "Picky") {
        if ($User) {
            $variables += [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::User).GetEnumerator()
        }

        if ($System) {
            $variables += [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Machine).GetEnumerator()
        }

        if ($Process) {
            $variables += [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Process).GetEnumerator()
        }
    }
    else {
        $variables += Get-ChildItem env:*
    }

    return $variables  | Sort-Object Name
}

function Test-EnvironmentVariablePaths {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = "Picky")]
        [switch]$User,

        [Parameter(Mandatory = $false, ParameterSetName = "Picky")]
        [switch]$System,

        [Parameter(Mandatory = $false, ParameterSetName = "Picky")]
        [switch]$Process,

        [Parameter(Mandatory = $false)]
        [switch]$MissingOnly
    )

    $getParams = @{}
    if ($PsCmdlet.ParameterSetName -eq "Picky") {
        if ($User) { $getParams.User = $true }
        if ($System) { $getParams.System = $true }
        if ($Process) { $getParams.Process = $true }
    }

    $excludeNames = @('IGCCSVC_DB');

    $results = foreach ($variable in Get-EnvironmentVariables @getParams) {
        $value = $variable.Value
        if ([string]::IsNullOrWhiteSpace($value)) { continue }

        foreach ($entry in $value.Split([System.IO.Path]::PathSeparator)) {
            $path = $entry.Trim().Trim('"')
            if ([string]::IsNullOrWhiteSpace($path)) { continue }
            if ($excludeNames -contains $variable.Name) { continue }
            if ($path -notmatch '[\\/]') { continue }

            $expanded = [System.Environment]::ExpandEnvironmentVariables($path)
            $exists = Test-Path -LiteralPath $expanded -PathType Container

            [PSCustomObject]@{
                Name   = $variable.Name
                Path   = $path
                Exists = [bool]$exists
            }
        }
    }

    if ($MissingOnly) {
        return $results | Where-Object { -not $_.Exists }
    }

    return $results
}

Set-Alias 'Get-Env' 'Get-EnvironmentVariables'
Set-Alias 'Test-EnvPaths' 'Test-EnvironmentVariablePaths'

Export-ModuleMember -Function Get-EnvironmentVariables, Test-EnvironmentVariablePaths
Export-ModuleMember -Alias 'Get-Env', 'Test-EnvPaths'
