<#
.SYNOPSIS
    Tests whether the current terminal supports ANSI escape sequences.

.DESCRIPTION
    Checks for known terminal environments and flags that indicate support for
    ANSI/VT escape codes (colors, cursor movement, etc.).

.OUTPUTS
    [bool] True if the terminal supports ANSI escape sequences.
#>
function Test-Ansi {
    if ($Host.UI.SupportsVirtualTerminal) {
        return $true
    }

    if ($env:WT_SESSION -or $env:ConEmuANSI -eq 'ON' -or $env:ANSICON) {
        return $true
    }

    if ($env:TERM_PROGRAM -in @('vscode', 'iTerm.app', 'WezTerm', 'Hyper', 'Alacritty')) {
        return $true
    }

    if ($env:COLORTERM -in @('truecolor', '24bit')) {
        return $true
    }

    return $false
}

<#
.SYNOPSIS
    Tests whether the current terminal supports OSC 8 hyperlinks.

.DESCRIPTION
    First checks for general ANSI support via Test-Ansi, then further narrows to
    terminals known to support the OSC 8 hyperlink escape sequence. Not all
    ANSI-capable terminals implement OSC 8.

.OUTPUTS
    [bool] True if the terminal is known to support OSC 8 hyperlinks.
#>
function Test-RichTerminal {
    if (Test-Ansi) {
        # Terminals known to support OSC 8 hyperlinks
        if ($env:WT_SESSION) {
            return $true
        }

        if ($env:TERM_PROGRAM -in @('vscode', 'iTerm.app', 'WezTerm')) {
            return $true
        }
    }

    return $false
}

<#
.SYNOPSIS
    Formats a URI as a clickable hyperlink for supported terminals.

.DESCRIPTION
    Returns an OSC 8 hyperlink escape sequence when running in a rich terminal,
    or a plain text fallback ("Label (URI)") otherwise.

.PARAMETER Uri
    The URI to link to.

.PARAMETER Label
    Optional display text for the hyperlink. If omitted, the URI itself is displayed.

.OUTPUTS
    [string] The formatted hyperlink string.

.LINK
    https://lucyllewy.com/powershell-clickable-hyperlinks/
#>
function Format-Hyperlink {
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Uri] $Uri,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $Label
    )

    if (($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows) -and -not (Test-RichTerminal)) {
        # Fallback for Windows users not inside a rich terminal, or users on PowerShell 5 and below
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

Export-ModuleMember -Function Test-Ansi
Export-ModuleMember -Function Test-RichTerminal
Export-ModuleMember -Function Format-Hyperlink
