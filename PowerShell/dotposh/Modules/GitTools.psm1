function Get-GitWorktree {
    [CmdletBinding()]
    param()

    $output = git worktree list --porcelain 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $output) {
        return @()
    }

    $worktrees = @()
    $current = $null
    foreach ($line in $output) {
        if ($line -match '^worktree (.+)$') {
            if ($current) { $worktrees += $current }
            $current = [PSCustomObject]@{
                Path   = $Matches[1]
                Name   = Split-Path -Leaf $Matches[1]
                Branch = $null
                Head   = $null
                Bare   = $false
                Detached = $false
            }
        }
        elseif ($current) {
            if ($line -match '^HEAD (.+)$') {
                $current.Head = $Matches[1]
            }
            elseif ($line -match '^branch (.+)$') {
                $current.Branch = ($Matches[1] -replace '^refs/heads/', '')
            }
            elseif ($line -eq 'bare') {
                $current.Bare = $true
            }
            elseif ($line -eq 'detached') {
                $current.Detached = $true
            }
        }
    }
    if ($current) { $worktrees += $current }
    return $worktrees
}

function Set-Worktree {
    [CmdletBinding()]
    [Alias('cd_worktree', 'cd_wt', 'wt')]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Name
    )

    $worktrees = Get-GitWorktree
    if (-not $worktrees -or $worktrees.Count -eq 0) {
        Write-Warning "No git worktrees found. Are you inside a git repository?"
        return
    }

    if (-not $Name) {
        $worktrees | Format-Table -AutoSize Name, Branch, Path
        return
    }

    # Exact match on name, branch, or path
    $match = $worktrees | Where-Object {
        $_.Name -eq $Name -or $_.Branch -eq $Name -or $_.Path -eq $Name
    } | Select-Object -First 1

    # Fall back to wildcard match
    if (-not $match) {
        $match = $worktrees | Where-Object {
            $_.Name -like "*$Name*" -or $_.Branch -like "*$Name*"
        } | Select-Object -First 1
    }

    if (-not $match) {
        Write-Error "No git worktree matching '$Name' found."
        return
    }

    Set-Location -LiteralPath $match.Path
}

Register-ArgumentCompleter -CommandName Set-Worktree, cd_worktree, cd_wt, wt -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $worktrees = Get-GitWorktree
    if (-not $worktrees) { return }

    $candidates = foreach ($wt in $worktrees) {
        if ($wt.Name) { $wt.Name }
        if ($wt.Branch -and $wt.Branch -ne $wt.Name) { $wt.Branch }
    }

    $candidates |
        Select-Object -Unique |
        Where-Object { $_ -like "$wordToComplete*" } |
        Sort-Object |
        ForEach-Object {
            $value = if ($_ -match '\s') { "'$_'" } else { $_ }
            [System.Management.Automation.CompletionResult]::new(
                $value,
                $_,
                'ParameterValue',
                $_
            )
        }
}


Export-ModuleMember -Function Get-GitWorktree
Export-ModuleMember -Function Set-Worktree
Export-ModuleMember -Alias cd_worktree
Export-ModuleMember -Alias cd_wt
Export-ModuleMember -Alias wt

# Exporting 'wt' as an alias where overrides the 'wt' command to open a new Windows Terminal
