@echo off
setlocal

set "SCRIPT_DIR=%~dp0"

:: Check for native binary
set "BINARY=%SCRIPT_DIR%agent-browser-win32-x64.exe"
if exist "%BINARY%" (
    "%BINARY%" %*
    exit /b %errorlevel%
)

:: Fallback: no binary found
echo Error: No binary found for win32-x64 1>&2
echo Run 'npm run build:native' to build for your platform 1>&2
exit /b 1
