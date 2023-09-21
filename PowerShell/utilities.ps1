function colors() {
    # output all the colour combinations for text/background
    # https://stackoverflow.com/questions/20541456/list-of-all-colors-available-for-powershell/41954792#41954792
    $colors = [enum]::GetValues([System.ConsoleColor])
    Foreach ($bgcolor in $colors) {
        Foreach ($fgcolor in $colors) { Write-Host "$fgcolor|" -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewLine }
        Write-Host " on $bgcolor"
    }
}

function Get-LineEndings {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Directory = $PWD
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

    $exclude = '\.git|\.vs|node_modules|packages|bin|obj|png|jpg|jpeg|gif|avif|webp|ico|ttf|woff|woff2|eot|svg|zip|rar|7z|gz|tar|bz2|exe|dll|pdb|bak|tmp|cache'
    $output = @()

    $files = Get-ChildItem -Path $Directory -Recurse -File | Where-Object { $_.FullName -notMatch $exclude }
    $files | ForEach-Object {
        $file = $_
        $output += [PSCustomObject]@{
            File = $file
            Type = Get-LineTypeForFile($file)
        }
    }

    Write-Output $output
}

function Set-FilesWriteable
{
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
