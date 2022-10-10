if (Test-Path variable:global:RorysProfile) {
    break;
}

$global:RorysProfile = $True

Import-Module posh-git

if ((Get-Command "oh-my-posh")) {
    $GitPromptSettings.BeforeStatus.ForegroundColor = [ConsoleColor]::DarkGray
    $GitPromptSettings.DelimStatus.ForegroundColor = [ConsoleColor]::DarkGray
    $GitPromptSettings.AfterStatus.ForegroundColor = [ConsoleColor]::DarkGray

    $PoshTheme = Join-Path -Path $PSScriptRoot -ChildPath "roryclaasen.omp.json"
    if (Test-Path $PoshTheme) {
        oh-my-posh init pwsh --config $PoshTheme | Invoke-Expression
    }

    function Set-PoshGitStatus {
        $global:GitStatus = Get-GitStatus
        if ($global:GitStatus) {
            $env:POSH_GIT_STRING = (Write-GitStatus -Status $global:GitStatus).trim()
        }
        else {
            $env:POSH_GIT_STRING = $null
        }
    }
    New-Alias -Name 'Set-PoshContext' -Value 'Set-PoshGitStatus' -Scope Global -Force
}
else {
    $env:POSH_GIT_ENABLED = $true
}

if ($host.Name -eq 'Visual Studio Code Host') {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
}


$LocalProfile = Join-Path -Path $PSScriptRoot -ChildPath "local.profile.ps1"
if (Test-path $LocalProfile) {
    . $LocalProfile
}

function colors() {
    # output all the colour combinations for text/background
    # https://stackoverflow.com/questions/20541456/list-of-all-colors-available-for-powershell/41954792#41954792
    $colors = [enum]::GetValues([System.ConsoleColor])
    Foreach ($bgcolor in $colors) {
        Foreach ($fgcolor in $colors) { Write-Host "$fgcolor|" -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewLine }
        Write-Host " on $bgcolor"
    }
}

Try {
    $SudoModule = Get-Command gsudoModule.psd1
    Import-Module $SudoModule.Source
}
Catch {
}
