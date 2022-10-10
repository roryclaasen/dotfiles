$DefaultProfile = Join-Path -Path $PSScriptRoot -ChildPath "profile.ps1"
if (Test-path $DefaultProfile) {
    . $DefaultProfile
}
