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

Export-ModuleMember -Function Get-LineEndings
Export-ModuleMember -Function Set-FilesWriteable
