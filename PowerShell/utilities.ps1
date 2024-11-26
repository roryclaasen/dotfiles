function colors() {
    [CmdletBinding()]
    # output all the colour combinations for text/background
    # https://stackoverflow.com/questions/20541456/list-of-all-colors-available-for-powershell/41954792#41954792
    $colors = [enum]::GetValues([System.ConsoleColor])
    Foreach ($bgcolor in $colors) {
        Foreach ($fgcolor in $colors) { Write-Host "$fgcolor|" -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewLine }
        Write-Host " on $bgcolor"
    }
}

function Get-LineEndings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Directory = $PWD,
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        [Parameter(Mandatory = $false)]
        [string]$Exclude = '\.git|\.vs|node_modules|packages|bin|obj|png|jpg|jpeg|gif|avif|webp|ico|ttf|woff|woff2|eot|svg|zip|rar|7z|gz|tar|bz2|exe|dll|pdb|bak|tmp|cache'
    )

    function Get-LineTypeForFile($file) {
        try {

            $content = Get-Content -Raw $file
            $lineEndings = [regex]::Matches($content, "\r?\n") | Group-Object -Property Length
            if ($lineEndings.Length -eq 2) {
                return "Mixed CRLF"
            }
            else {
                if ($lineEndings[0].Group[0].Value.Length -eq 2) {
                    return "CRLF"
                }
                else {
                    return "LF"
                }
            }
        }
        catch {
            Write-Warning "Unable to get line endings for $($file.FullName)"
            return "Unknown"
        }
    }

    Write-Host "Getting line endings for files in $Directory"

    $output = @()

    $files = Get-ChildItem -Path $Directory -Recurse:$Recurse.IsPresent -File | Where-Object { $_.FullName -notMatch $Exclude }
    $files | ForEach-Object {
        $file = $_
        $output += [PSCustomObject]@{
            File = $file
            Type = Get-LineTypeForFile($file)
        }
    }

    Write-Output $output
}

function Set-FilesWriteable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Directory = $PWD,
        [Parameter(Mandatory = $false)]
        [switch]$Recurse
    )
    $output = @()

    $files = Get-ChildItem -Path $Directory -File -Recurse:$Recurse.IsPresent | Where-Object { $_.IsReadOnly -eq $true }
    $files | ForEach-Object {
        Set-ItemProperty $_ -Name IsReadOnly -Value $false
        $output += $_
    }

    Write-Output $output
}

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
            $variables += [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::User)
        }

        if ($System) {
            $variables += [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Machine)
        }

        if ($Process) {
            $variables += [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Process)
        }
    }
    else {
        $variables += Get-ChildItem env:*
    }

    return $variables  | Sort-Object name
}

Set-Alias 'Get-Env' 'Get-EnvironmentVariables'
