@echo off
title Winget Batch Auto Installer - 2025 Edition
color 0A

:: Display header 

echo.
type soreal.txt
echo.

:: Confirm admin privileges
>nul 2>&1 "%SystemRoot%\system32\cacls.exe" "%SystemRoot%\system32\config\system"
if %errorlevel% NEQ 0 (
    echo [ERROR] Please run this script as Administrator.
    pause
    exit /b
)

:: Disable UAC (will require reboot to take full effect)
echo [INFO] Disabling User Account Control (UAC)...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] UAC disabled (a reboot is recommended).

:: Create installation folder
set "installDir=C:\_install"
if not exist "%installDir%" (
    echo [INFO] Creating directory %installDir%...
    mkdir "%installDir%"
    echo [OK] Directory created.
) else (
    echo [INFO] Directory already exists: %installDir%
)

:: Copy JSON file
if exist "installed-apps.json" (
    echo [INFO] Copying installed-apps.json to %installDir%...
    copy installed-apps.json c:\_install >nul
    echo [OK] File copied.
) else (
    echo [ERROR] installed-apps.json not found in the current directory.
    pause
    exit /b
)

:: Run Winget import
echo [INFO] Starting Winget import...
powershell -NoProfile -Command "winget import -i '%installDir%\installed-apps.json'"
echo [OK] Import complete.

:: Run Winget update
echo [INFO] Checking for app updates via Winget...
powershell -NoProfile -Command "winget update"
echo [OK] Updates checked.

pause
