Import-Module posh-git
$env:POSH_GIT_ENABLED = $true

if ((Get-Command "oh-my-posh")) {
    $GitPromptSettings.BeforeStatus.ForegroundColor = [ConsoleColor]::DarkGray
    $GitPromptSettings.DelimStatus.ForegroundColor = [ConsoleColor]::DarkGray
    $GitPromptSettings.AfterStatus.ForegroundColor = [ConsoleColor]::DarkGray

    $PoshTheme = Join-Path -Path $PSScriptRoot -ChildPath "roryclaasen.omp.json"
    if (Test-Path $PoshTheme) {
        oh-my-posh init pwsh --config $PoshTheme | Invoke-Expression
    }
}

If ($host.Name -eq 'Visual Studio Code Host') {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
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
