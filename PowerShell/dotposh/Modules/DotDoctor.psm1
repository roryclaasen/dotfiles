function Invoke-DotDoctor {
    [CmdletBinding()]
    param()

    $results = [System.Collections.Generic.List[object]]::new()
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

    $profileDirectory = Split-Path $PROFILE.CurrentUserAllHosts

    $requiredCommands = @(
        'git',
        'oh-my-posh',
        'winget',
        'gh',
        'dotnet',
        'fnm',
        'fzf',
        'nuke'
    )

    $requiredModules = @(
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

    $results.Add([PSCustomObject]@{
        Category = 'Path'
        Name = 'DOTFILES'
        Status = $(if (Test-Path -LiteralPath $dotfilesPath) { 'OK' } else { 'Missing' })
        Details = $dotfilesPath
    })

    $primaryProfilePathExists = Test-Path -LiteralPath $primaryExpectedProfilePath
    $alternateProfilePathExists = @($expectedProfilePaths | Where-Object { $_ -ne $primaryExpectedProfilePath } | Where-Object { Test-Path -LiteralPath $_ }).Count -gt 0

    $results.Add([PSCustomObject]@{
        Category = 'Path'
        Name = 'Profile dir (' + $PSVersionTable.PSEdition + ')'
        Status = $(if ($primaryProfilePathExists) { 'OK' } elseif ($alternateProfilePathExists) { 'Warning' } else { 'Missing' })
        Details = $primaryExpectedProfilePath
    })

    foreach ($expectedProfilePath in $expectedProfilePaths | Where-Object { $_ -ne $primaryExpectedProfilePath }) {
        $results.Add([PSCustomObject]@{
            Category = 'Path'
            Name = 'Alternate profile dir'
            Status = $(if (Test-Path -LiteralPath $expectedProfilePath) { 'OK' } else { 'Info' })
            Details = $expectedProfilePath
        })
    }

    if (Test-Path -LiteralPath $profileDirectory) {
        $profileDirectoryItem = Get-Item -LiteralPath $profileDirectory -Force
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
            $isExpectedTarget = $expectedProfilePaths -contains $target
        }

        $results.Add([PSCustomObject]@{
            Category = 'Profile'
            Name = 'CurrentUserAllHosts parent'
            Status = $(if ($isExpectedTarget) { 'OK' } elseif ($isLink) { 'Mismatch' } else { 'NotLink' })
            Details = if ($isLink) { "$profileDirectory -> $target" } else { $profileDirectory }
        })
    }
    else {
        $results.Add([PSCustomObject]@{
            Category = 'Profile'
            Name = 'CurrentUserAllHosts parent'
            Status = $(if ($isDesktopEdition -and (Test-Path -LiteralPath ([System.IO.Path]::Combine($dotfilesPath, 'PowerShell')))) { 'Warning' } else { 'Missing' })
            Details = $(if ($isDesktopEdition) { "$profileDirectory (not configured for Desktop profile path)" } else { $profileDirectory })
        })
    }

    $themePath = [System.IO.Path]::Combine($dotfilesPath, 'PowerShell', 'dotposh', 'roryclaasen.omp.json')
    $results.Add([PSCustomObject]@{
        Category = 'Theme'
        Name = 'Oh My Posh theme'
        Status = $(if (Test-Path -LiteralPath $themePath) { 'OK' } else { 'Missing' })
        Details = $themePath
    })

    foreach ($commandName in $requiredCommands) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        $results.Add([PSCustomObject]@{
            Category = 'Command'
            Name = $commandName
            Status = $(if ($null -ne $command) { 'OK' } else { 'Missing' })
            Details = if ($null -ne $command) { $command.Source } else { '' }
        })
    }

    foreach ($moduleName in $requiredModules) {
        $module = Get-Module -ListAvailable -Name $moduleName | Sort-Object Version -Descending | Select-Object -First 1
        $status = if ($null -ne $module) {
            'OK'
        }
        elseif ($isDesktopEdition) {
            'Warning'
        }
        else {
            'Missing'
        }

        $details = if ($null -ne $module) {
            $module.Version.ToString()
        }
        elseif ($isDesktopEdition) {
            'Module not installed for Windows PowerShell (Desktop edition)'
        }
        else {
            ''
        }

        $results.Add([PSCustomObject]@{
            Category = 'Module'
            Name = $moduleName
            Status = $status
            Details = $details
        })
    }

    $okCount = @($results | Where-Object { $_.Status -eq 'OK' }).Count
    $issueCount = @($results | Where-Object { $_.Status -in @('Missing', 'Mismatch', 'NotLink') }).Count
    $warningCount = @($results | Where-Object { $_.Status -eq 'Warning' }).Count

    Write-Host "Dot Doctor: $okCount OK, $warningCount warning(s), $issueCount issue(s)"
    return $results
}

Set-Alias 'dotdoctor' 'Invoke-DotDoctor'
Set-Alias 'dot-doctor' 'Invoke-DotDoctor'

Export-ModuleMember -Function Invoke-DotDoctor
Export-ModuleMember -Alias 'dotdoctor', 'dot-doctor'
