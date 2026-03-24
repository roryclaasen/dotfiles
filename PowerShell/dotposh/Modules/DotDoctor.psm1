function New-DotDoctorResult {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Status,
        [Parameter(Mandatory = $false)]
        [string]$Details = ''
    )

    return [PSCustomObject]@{
        Category = $Category
        Name = $Name
        Status = $Status
        Details = $Details
    }
}

function Get-DotDoctorContext {
    $isDesktopEdition = $PSVersionTable.PSEdition -eq 'Desktop'
    $dotfilesPath = if ([string]::IsNullOrWhiteSpace($env:DOTFILES)) {
        [System.IO.Path]::Combine($HOME, 'dotfiles')
    }
    else {
        $env:DOTFILES
    }

    $expectedProfilePaths = @(
        [System.IO.Path]::Combine($dotfilesPath, 'PowerShell'),
        [System.IO.Path]::Combine($dotfilesPath, 'WindowsPowerShell')
    ) | Select-Object -Unique

    $primaryExpectedProfilePath = if ($isDesktopEdition) {
        [System.IO.Path]::Combine($dotfilesPath, 'WindowsPowerShell')
    }
    else {
        [System.IO.Path]::Combine($dotfilesPath, 'PowerShell')
    }

    return [PSCustomObject]@{
        IsDesktopEdition = $isDesktopEdition
        DotfilesPath = $dotfilesPath
        ExpectedProfilePaths = $expectedProfilePaths
        PrimaryExpectedProfilePath = $primaryExpectedProfilePath
        ProfileDirectory = Split-Path $PROFILE.CurrentUserAllHosts
        ThemePath = [System.IO.Path]::Combine($dotfilesPath, 'PowerShell', 'dotposh', 'roryclaasen.omp.json')
        RequiredCommands = @(
            'git',
            'oh-my-posh',
            'winget',
            'gh',
            'dotnet',
            'dotnet-suggest',
            'fnm',
            'fzf',
            'nuke'
        )
        RequiredModules = @(
            'posh-git',
            'Terminal-Icons',
            'PSFzf',
            'z',
            'Microsoft.WinGet.Client',
            'Microsoft.WinGet.CommandNotFound',
            'gsudoModule',
            'DockerCompletion',
            'Microsoft.PowerShell.SecretManagement',
            'Microsoft.PowerShell.SecretStore'
        )
    }
}

function Add-DotDoctorPathChecks {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]]$Results,
        [Parameter(Mandatory = $true)]
        [object]$Context
    )

    $Results.Add((New-DotDoctorResult -Category 'Path' -Name 'DOTFILES' -Status $(if (Test-Path -LiteralPath $Context.DotfilesPath) { 'OK' } else { 'Missing' }) -Details $Context.DotfilesPath))

    $primaryProfilePathExists = Test-Path -LiteralPath $Context.PrimaryExpectedProfilePath
    $alternateProfilePathExists = @($Context.ExpectedProfilePaths | Where-Object { $_ -ne $Context.PrimaryExpectedProfilePath } | Where-Object { Test-Path -LiteralPath $_ }).Count -gt 0

    $Results.Add((New-DotDoctorResult -Category 'Path' -Name ('Profile dir (' + $PSVersionTable.PSEdition + ')') -Status $(if ($primaryProfilePathExists) { 'OK' } elseif ($alternateProfilePathExists) { 'Warning' } else { 'Missing' }) -Details $Context.PrimaryExpectedProfilePath))

    foreach ($expectedProfilePath in $Context.ExpectedProfilePaths | Where-Object { $_ -ne $Context.PrimaryExpectedProfilePath }) {
        $Results.Add((New-DotDoctorResult -Category 'Path' -Name 'Alternate profile dir' -Status $(if (Test-Path -LiteralPath $expectedProfilePath) { 'OK' } else { 'Info' }) -Details $expectedProfilePath))
    }
}

function Add-DotDoctorProfileCheck {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]]$Results,
        [Parameter(Mandatory = $true)]
        [object]$Context
    )

    if (Test-Path -LiteralPath $Context.ProfileDirectory) {
        $profileDirectoryItem = Get-Item -LiteralPath $Context.ProfileDirectory -Force
        $isLink = -not [string]::IsNullOrWhiteSpace($profileDirectoryItem.LinkType)
        $target = if ($isLink) {
            if ($profileDirectoryItem.Target -is [System.Array]) {
                [string]::Join(', ', $profileDirectoryItem.Target)
            }
            else {
                [string]$profileDirectoryItem.Target
            }
        }
        else {
            ''
        }

        $isExpectedTarget = $false
        if ($isLink) {
            $isExpectedTarget = $Context.ExpectedProfilePaths -contains $target
        }

        $status = if ($isExpectedTarget) { 'OK' } elseif ($isLink) { 'Mismatch' } else { 'NotLink' }
        $details = if ($isLink) { "$($Context.ProfileDirectory) -> $target" } else { $Context.ProfileDirectory }

        $Results.Add((New-DotDoctorResult -Category 'Profile' -Name 'CurrentUserAllHosts parent' -Status $status -Details $details))
        return
    }

    $status = if ($Context.IsDesktopEdition -and (Test-Path -LiteralPath ([System.IO.Path]::Combine($Context.DotfilesPath, 'PowerShell')))) { 'Warning' } else { 'Missing' }
    $details = if ($Context.IsDesktopEdition) {
        "$($Context.ProfileDirectory) (not configured for Desktop profile path)"
    }
    else {
        $Context.ProfileDirectory
    }

    $Results.Add((New-DotDoctorResult -Category 'Profile' -Name 'CurrentUserAllHosts parent' -Status $status -Details $details))
}

function Add-DotDoctorThemeCheck {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]]$Results,
        [Parameter(Mandatory = $true)]
        [object]$Context
    )

    $Results.Add((New-DotDoctorResult -Category 'Theme' -Name 'Oh My Posh theme' -Status $(if (Test-Path -LiteralPath $Context.ThemePath) { 'OK' } else { 'Missing' }) -Details $Context.ThemePath))
}

function Add-DotDoctorCommandChecks {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]]$Results,
        [Parameter(Mandatory = $true)]
        [object]$Context
    )

    foreach ($commandName in $Context.RequiredCommands) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        $Results.Add((New-DotDoctorResult -Category 'Command' -Name $commandName -Status $(if ($null -ne $command) { 'OK' } else { 'Missing' }) -Details $(if ($null -ne $command) { $command.Source } else { '' })))
    }
}

function Add-DotDoctorModuleChecks {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]]$Results,
        [Parameter(Mandatory = $true)]
        [object]$Context
    )

    foreach ($moduleName in $Context.RequiredModules) {
        $module = Get-Module -ListAvailable -Name $moduleName | Sort-Object Version -Descending | Select-Object -First 1
        $status = if ($null -ne $module) {
            'OK'
        }
        elseif ($Context.IsDesktopEdition) {
            'Warning'
        }
        else {
            'Missing'
        }

        $details = if ($null -ne $module) {
            $module.Version.ToString()
        }
        elseif ($Context.IsDesktopEdition) {
            'Module not installed for Windows PowerShell (Desktop edition)'
        }
        else {
            ''
        }

        $Results.Add((New-DotDoctorResult -Category 'Module' -Name $moduleName -Status $status -Details $details))
    }
}

function Format-DotDoctorStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Status,

        [Parameter(Mandatory = $false)]
        [string]$Label
    )

    $text = if ($Label) { $Label } else { $Status }

    if (-not (Test-Ansi)) {
        return $text
    }

    switch ($Status) {
        'Missing' { return "`e[31m$text`e[0m" }
        'Mismatch' { return "`e[31m$text`e[0m" }
        'NotLink' { return "`e[31m$text`e[0m" }
        'Warning' { return "`e[33m$text`e[0m" }
        default { return $text }
    }
}

function Write-DotDoctorSummary {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]]$Results
    )

    $okCount = @($Results | Where-Object { $_.Status -eq 'OK' }).Count
    $issueCount = @($Results | Where-Object { $_.Status -in @('Missing', 'Mismatch', 'NotLink') }).Count
    $warningCount = @($Results | Where-Object { $_.Status -eq 'Warning' }).Count

    $warningText = Format-DotDoctorStatus -Status 'Warning' -Label "$warningCount warning(s)"
    $issueText = Format-DotDoctorStatus -Status 'Missing' -Label "$issueCount issue(s)"

    Write-Host "Dot Doctor: $okCount OK, $warningText, $issueText"
}

function Invoke-DotDoctor {
    [CmdletBinding()]
    param()

    $results = [System.Collections.Generic.List[object]]::new()
    $context = Get-DotDoctorContext

    Add-DotDoctorPathChecks -Results $results -Context $context
    Add-DotDoctorProfileCheck -Results $results -Context $context
    Add-DotDoctorThemeCheck -Results $results -Context $context
    Add-DotDoctorCommandChecks -Results $results -Context $context
    Add-DotDoctorModuleChecks -Results $results -Context $context

    Write-DotDoctorSummary -Results $results

    foreach ($result in $results) {
        $result.Status = Format-DotDoctorStatus -Status $result.Status
    }

    return $results
}

Set-Alias 'dotdoctor' 'Invoke-DotDoctor'
Set-Alias 'dot-doctor' 'Invoke-DotDoctor'

Export-ModuleMember -Function Invoke-DotDoctor
Export-ModuleMember -Alias 'dotdoctor', 'dot-doctor'
