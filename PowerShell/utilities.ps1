function colors() {
    # output all the colour combinations for text/background
    # https://stackoverflow.com/questions/20541456/list-of-all-colors-available-for-powershell/41954792#41954792
    $colors = [enum]::GetValues([System.ConsoleColor])
    Foreach ($bgcolor in $colors) {
        Foreach ($fgcolor in $colors) { Write-Host "$fgcolor|" -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewLine }
        Write-Host " on $bgcolor"
    }
}

function Check-LineEndings {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Directory = $PWD
    )

    Write-Host "Checking line endings in $Directory"

    $files = Get-ChildItem -Path $Directory -Recurse -File
    $files | ForEach-Object {
        $file = $_
        $type = ('LF', 'CRLF')[([regex]::Matches($(Get-Content -Ra $file), "\r?\n") | Group-Object -P Length).Group[0].Value.Length - 1]
        Write-Host "$file - $type" -ForegroundColor ([ConsoleColor]::Green)
    }
}
