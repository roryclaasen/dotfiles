function colors() {
    # output all the colour combinations for text/background
    # https://stackoverflow.com/questions/20541456/list-of-all-colors-available-for-powershell/41954792#41954792
    $colors = [enum]::GetValues([System.ConsoleColor])
    Foreach ($bgcolor in $colors) {
        Foreach ($fgcolor in $colors) { Write-Host "$fgcolor|" -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewLine }
        Write-Host " on $bgcolor"
    }
}
