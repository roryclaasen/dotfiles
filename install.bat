@ECHO OFF

WHERE pwsh >nul 2>nul
if (%ERRORLEVEL%) == (0) (
    pwsh -ExecutionPolicy ByPass -NoLogo -NoProfile "%~dp0install.ps1" %*
) else (
    powershell -ExecutionPolicy ByPass -NoLogo -NoProfile "%~dp0install.ps1" %*
)

