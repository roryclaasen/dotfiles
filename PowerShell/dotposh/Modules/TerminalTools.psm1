# https://lucyllewy.com/powershell-clickable-hyperlinks/
function Format-Hyperlink {
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Uri] $Uri,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $Label
    )

    if (($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows) -and -not $Env:WT_SESSION) {
        # Fallback for Windows users not inside Windows Terminal
        if ($Label) {
            return "$Label ($Uri)"
        }
        return "$Uri"
    }

    if ($Label) {
        return "`e]8;;$Uri`e\$Label`e]8;;`e\"
    }

    return "$Uri"
}

Export-ModuleMember -Function Format-Hyperlink
