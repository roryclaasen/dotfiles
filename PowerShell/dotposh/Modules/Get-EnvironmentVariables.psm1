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

Set-Alias 'Get-Env' 'Get-EnvironmentVariables'

Export-ModuleMember -Function Get-EnvironmentVariables
Export-ModuleMember -Alias 'Get-Env'
