@echo off
rem ==============================================================================
rem Lumusitech AI Workspace - Windows setup launcher
rem Wraps setup.ps1 with ExecutionPolicy Bypass (default Windows policy is
rem Restricted) and a friendly error if PowerShell 7 is missing.
rem ==============================================================================
setlocal

where pwsh >nul 2>nul
if errorlevel 1 (
    echo [ERROR] PowerShell 7 ^(pwsh^) was not found in PATH.
    echo.
    echo Install it from https://aka.ms/powershell
    echo or with winget:
    echo     winget install --id Microsoft.PowerShell --exact
    echo.
    echo If you only have Windows PowerShell 5.1, its console looks the same
    echo but is NOT compatible with this script.
    exit /b 1
)

pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
exit /b %errorlevel%
