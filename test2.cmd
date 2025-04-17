@echo off
SETLOCAL
title Winget Batch Auto Installer v1.3 - 2025 Edition
color 1B

::=================================================
:: Display Header
::=================================================
echo.
type soreal.txt
echo.

::=================================================
:: Check for Administrator Privileges
::=================================================
>nul 2>&1 "%SystemRoot%\system32\cacls.exe" "%SystemRoot%\system32\config\system"
if %errorlevel% NEQ 0 (
    echo [ERROR] Please run this script as Administrator.
    pause
    exit /b
)

::=================================================
:: Disable UAC (requires reboot to fully take effect)
::=================================================
echo [INFO] Disabling User Account Control (UAC)...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1
echo [OK] UAC disabled (a reboot is recommended).
echo [INFO] You may need to log off/log back in for changes to take effect.
timeout /t 5 /nobreak >nul


::=================================================
:: Uninstall Bloatware via Winget
::=================================================
echo [INFO] Uninstalling default bloatware...
powershell -NoProfile -Command "winget uninstall --id 'McAfee.wps'"
powershell -NoProfile -Command "winget uninstall --id 'Microsoft.MicrosoftOfficeHub_8wekyb3d8bbwe'"
echo [OK] Bloatware removed (check Control Panel to verify).
echo [INFO] You may need to log off/log back in for changes to take effect.
timeout /t 5 /nobreak >nul


::=================================================
:: Create Installation Directory
::=================================================
set "installDir=C:\_install"
if not exist "%installDir%" (
    echo [INFO] Creating directory %installDir%...
    mkdir "%installDir%"
    echo [OK] Directory created.
) else (
    echo [INFO] Directory already exists: %installDir%
)

::=================================================
:: Copy Required Files
::=================================================
:: Copy JSON file
if exist "installed-apps.json" (
    echo [INFO] Copying installed-apps.json to %installDir%...
    copy installed-apps.json "%installDir%" >nul
    echo [OK] File copied.
) else (
    echo [ERROR] installed-apps.json not found in the current directory.
    pause
    exit /b
)

:: Copy SetUserFTA.exe
if exist "SetUserFTA.exe" (
    echo [INFO] Copying SetUserFTA.exe to %installDir%...
    copy SetUserFTA.exe "%installDir%" >nul
    echo [OK] File copied.
) else (
    echo [ERROR] SetUserFTA.exe not found in the current directory.
    pause
    exit /b
)

::=================================================
:: Winget Actions (Update/Import) This is commented due to testing at the monent (but this code does work)
::=================================================
:: Uncomment below to perform import
:: echo [INFO] Starting Winget import...
:: powershell -NoProfile -Command "winget import -i '%installDir%\installed-apps.json'"
:: echo [OK] Import complete.

echo [INFO] Checking for app updates via Winget...
powershell -NoProfile -Command "winget update"
echo [OK] Updates checked.

::=================================================
:: File Associations (Manual Registry Method)
::=================================================
:: Adobe Acrobat for PDFs
echo [INFO] Setting default apps for PDF...

set "adobePath=C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
set "progId=AcroExch.Document"

if not exist "%adobePath%" (
    echo [ERROR] Adobe Reader not found at: %adobePath%
    pause
    exit /b
)

reg add "HKCU\Software\Classes\.pdf" /ve /d "%progId%" /f
reg add "HKCU\Software\Classes\%progId%\shell\open\command" /ve /d "\"%adobePath%\" \"%%1\"" /f
reg add "HKCU\Software\Classes\%progId%\DefaultIcon" /ve /d "\"%adobePath%\",1" /f
echo [OK] Default app for PDF set to Adobe Acrobat.
timeout /t 5 /nobreak >nul


:: Outlook for MAILTO and .MSG
echo [INFO] Setting Outlook as default for MAILTO and MSG files...

set "outlookPath=C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"

if not exist "%outlookPath%" (
    echo [ERROR] Outlook not found at: %outlookPath%
    pause
    exit /b
)

:: MAILTO
reg add "HKCU\Software\Classes\mailto" /ve /d "Outlook.URL.mailto.15" /f
reg add "HKCU\Software\Classes\mailto\shell\open\command" /ve /d "\"%outlookPath%\" /c ipm.note /m \"%%1\"" /f

:: .MSG
reg add "HKCU\Software\Classes\.msg" /ve /d "Outlook.File.msg" /f
reg add "HKCU\Software\Classes\Outlook.File.msg\shell\open\command" /ve /d "\"%outlookPath%\" \"%%1\"" /f
reg add "HKCU\Software\Classes\Outlook.File.msg\DefaultIcon" /ve /d "\"%outlookPath%\",1" /f

echo [OK] Registry entries for default apps have been set.
echo [INFO] You may need to log off/log back in for changes to take effect.
timeout /t 5 /nobreak >nul


::=================================================
:: Enforce File Type Associations with SetUserFTA
::=================================================
echo [INFO] Enforcing file type associations with SetUserFTA...

:: Adobe Acrobat
powershell -NoProfile -Command ".\SetUserFTA.exe .pdf AcroExch.Document.DC"

:: Outlook
powershell -NoProfile -Command ".\SetUserFTA.exe .msg Outlook.File.msg"
powershell -NoProfile -Command ".\SetUserFTA.exe mailto Outlook.URL.mailto.15"
powershell -NoProfile -Command ".\SetUserFTA.exe .eml Outlook.File.eml"
powershell -NoProfile -Command ".\SetUserFTA.exe .emlx Outlook.File.emlx"

:: Chrome
powershell -NoProfile -Command ".\SetUserFTA.exe .http Google.Chrome"
powershell -NoProfile -Command ".\SetUserFTA.exe .https Google.Chrome"
powershell -NoProfile -Command ".\SetUserFTA.exe .url Google.Chrome"

echo [OK] File type associations have been set.
echo [INFO] You may need to log off/log back in for changes to take effect.
echo [NOTE] For enforcement issues, consult SetUserFTA documentation.
timeout /t 5 /nobreak >nul


::=================================================
:: Set Time Zone to South Africa Standard Time (SAST)
::=================================================
echo [INFO] Setting time zone to South Africa Standard Time...
tzutil /s "South Africa Standard Time"
echo [OK] Time zone set to SAST (UTC+2).
echo [INFO] You may need to log off/log back in for changes to take effect.
timeout /t 5 /nobreak >nul


::=================================================
:: Display Current Time Zone
::=================================================
echo [INFO] Displaying current time zone...
for /f "tokens=*" %%a in ('tzutil /g') do set timezone=%%a
echo [INFO] Current system time zone: %timezone%
echo [OK] Time zone displayed.
echo [INFO] You may need to log off/log back in for changes to take effect.
timeout /t 5 /nobreak >nul


::=================================================
:: Disable Fast Startup (Hiberboot)
::=================================================
echo [INFO] Disabling Fast Startup...

::=================================================
:: Set HiberbootEnabled to 0 to disable Fast Startup
::=================================================
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f
echo [OK] Fast Startup has been disabled.
timeout /t 5 /nobreak >nul


::=================================================
:: Set Power Plan to Balanced
::=================================================
echo [INFO] Setting power plan to Balanced...
powercfg -setactive SCHEME_BALANCED

:: Optional: Uncomment for High Performance or Ultimate Performance
:: powercfg -setactive SCHEME_MIN
:: powercfg -setactive SCHEME_MAX

echo [OK] Power plan set.
timeout /t 5 /nobreak >nul


::=================================================
:: Disable Windows Telemetry
::=================================================
echo [INFO] Disabling Windows Telemetry...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
timeout /t 5 /nobreak >nul

echo [OK] Windows Telemetry disabled.
echo [INFO] You may need to log off/log back in for changes to take effect.
timeout /t 5 /nobreak >nul


::=================================================
:: Disable Cortana
::=================================================
echo [INFO] Disabling Cortana...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f
echo [OK] Cortana disabled.
timeout /t 5 /nobreak >nul


::=================================================
:: Disable Windows Spotlight    
::=================================================
echo [INFO] Disabling Windows Spotlight...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f
echo [OK] Windows Spotlight disabled.
timeout /t 5 /nobreak >nul


::=================================================
:: Set Explorer to open "This PC" instead of Quick Access
::=================================================
echo [INFO] Setting Explorer to open "This PC" instead of Quick Access...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 1 /f
echo [OK] Explorer settings updated.
timeout /t 5 /nobreak >nul


::=================================================
:: Show Hidden Files and File Extensions
::=================================================
echo [INFO] Showing hidden files and file extensions...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f
echo [OK] Hidden files and file extensions are now visible.
timeout /t 5 /nobreak >nul


::=================================================
:: Set Windows to Dark Mode
::=================================================
echo [INFO] Setting Windows to Dark Mode...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f
echo [OK] Windows set to Dark Mode.
timeout /t 5 /nobreak >nul

::=================================================
:: Set Computer Name
::=================================================
:: Prompt for the new PC name
set /p NewName=Enter the new PC name: 

:: Show current name
for /f %%i in ('hostname') do set CurrentName=%%i

echo.
echo Current PC Name: %CurrentName%
echo New PC Name: %NewName%

:: Confirm
set /p confirm=Do you want to rename the PC to "%NewName%" and restart? (Y/N): 
if /i not "%confirm%"=="Y" (
    echo Operation cancelled.
    goto :eof
)

:: Rename using PowerShell
powershell -Command "Rename-Computer -NewName '%NewName%' -Force -Restart"

if %errorlevel%==0 (
    echo Rename command issued. Restarting...
) else (
    echo [ERROR] Failed to issue rename command.
    echo [INFO] Make sure you are running as Administrator.
)

::=================================================
:: Create Shortcuts on Desktop and Pin to Start/Taskbar
::=================================================
echo [INFO] Creating shortcuts on desktop and pinning to Start/Taskbar...

:: Get current user's desktop path
for /f "tokens=2,*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop 2^>nul') do set desktop=%%b

:: Define Office App Paths (adjust if Office is installed elsewhere)
set "wordPath=%ProgramFiles%\Microsoft Office\root\Office16\WINWORD.EXE"
set "excelPath=%ProgramFiles%\Microsoft Office\root\Office16\EXCEL.EXE"
set "outlookPath=%ProgramFiles%\Microsoft Office\root\Office16\OUTLOOK.EXE"

:: Special folder paths
set "thisPCPath=explorer.exe"
set "thisPCArgs=::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
set "userFolderPath=explorer.exe"
set "userFolderArgs=%USERPROFILE%"

:: Create shortcuts on desktop
call :CreateShortcut "Word" "%wordPath%"
call :CreateShortcut "Excel" "%excelPath%"
call :CreateShortcut "Outlook" "%outlookPath%"
call :CreateShortcutWithArgs "This PC" "%thisPCPath%" "%thisPCArgs%"
call :CreateShortcutWithArgs "User Folder" "%userFolderPath%" "%userFolderArgs%"

:: Pin shortcuts to Start and Taskbar (using PowerShell)
powershell -ExecutionPolicy Bypass -Command "& {
    $apps = @('Word', 'Excel', 'Outlook', 'This PC', 'User Folder')
    foreach ($app in $apps) {
        $shortcut = \"$env:USERPROFILE\Desktop\$app.lnk\"
        if (Test-Path $shortcut) {
            $shell = New-Object -ComObject Shell.Application
            $folder = $shell.Namespace((Split-Path $shortcut))
            $item = $folder.ParseName((Split-Path $shortcut -Leaf))
            $verbStart = $item.Verbs() | Where-Object { $_.Name -match 'Pin to Start' }
            $verbTaskbar = $item.Verbs() | Where-Object { $_.Name -match 'Pin to taskbar' }
            if ($verbStart) { $verbStart.DoIt() }
            if ($verbTaskbar) { $verbTaskbar.DoIt() }
        }
    }
}"


if %errorlevel% neq 0 (
    echo Failed to pin shortcuts to Start and Taskbar.
    echo [ERROR] Pinning failed.
    pause
    exit /b 1
) else (
    echo [OK] Shortcuts created and pinned to Start and Taskbar.
    echo [INFO] Shortcuts created and pin attempts made.
)

pause
exit /b

:CreateShortcut
set "shortcutName=%~1"
set "targetPath=%~2"

:: Use PowerShell to create the shortcut
powershell -ExecutionPolicy Bypass -Command ^
"$WshShell = New-Object -ComObject WScript.Shell; ^
$Shortcut = $WshShell.CreateShortcut('%desktop%\%shortcutName%.lnk'); ^
$Shortcut.TargetPath = '%targetPath%'; ^
$Shortcut.Save()"
exit /b

:CreateShortcutWithArgs
set "shortcutName=%~1"
set "targetPath=%~2"
set "arguments=%~3"
set "shortcutPath=%desktop%\%shortcutName%.lnk"

:: Use PowerShell to create the shortcut with arguments
powershell -ExecutionPolicy Bypass -Command ^
"$WshShell = New-Object -ComObject WScript.Shell; ^
$Shortcut = $WshShell.CreateShortcut('%shortcutPath%'); ^
$Shortcut.TargetPath = '%targetPath%'; ^
$Shortcut.Arguments = '%arguments%'; ^
$Shortcut.Save()"


::=========================================
:: Check if OS is Windows 11 (required for Widgets, etc.)
::=========================================
for /f "tokens=4-5 delims=. " %%i in ('ver') do set "ver_major=%%i" & set "ver_minor=%%j"
if %ver_major% LSS 10 (
    echo [INFO] This script is intended for Windows 10/11 only...
    pause
    exit /b
)

::=========================================
:: Disable Task View Button
::=========================================
echo [INFO] Disabling Task View button...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f

::=========================================
:: Disable Widgets Button (Windows 11 only)
::=========================================
echo [INFO] Disabling Widgets button...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f

::=========================================
:: Set Taskbar Search to "Search Box Only"
:: Values:
::   0 = Hidden
::   1 = Search icon only
::   2 = Search box
::   3 = Search (depends on Windows version)
::=========================================
echo [INFO] Setting Search to 'Search Box Only'...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 1 /f

::=========================================
:: Align Taskbar to Center (Windows 11)
:: Values:
::   0 = Left
::   1 = Center
::=========================================
echo [INFO] Aligning Taskbar to Center...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f

::=========================================
:: Restart Explorer to apply changes
::=========================================
echo [INFO] Restarting Explorer to apply changes...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe

echo [OK] Taskbar tweaks applied successfully.


::=================================================
:: Open Windows Update Settings, Start Windows Update service
::=================================================
setlocal EnableDelayedExpansion

:: ================================
:: Advanced Windows Update Script (No Logging)
:: ================================
:: List of necessary services
set "services=wuauserv bits cryptsvc"

:: Start required services
for %%S in (%services%) do (
    sc query %%S | find /i "RUNNING" >nul
    if errorlevel 1 (
        echo [INFO] Starting service: %%S
        net start %%S >nul 2>&1
    ) else (
        echo [INFO] Service %%S is already running
    )
)

:: Trigger Windows Update scan (Windows 10/11)
where usoclient >nul 2>&1
if %errorlevel%==0 (
    echo [INFO] Triggering Windows Update scan...
    usoclient StartScan >nul 2>&1
) else (
    echo [INFO] Usoclient not found. Manual check may be required.
)

:: Open Windows Update settings
start ms-settings:windowsupdate

echo [INFO] Windows Update process started.

pause

exit /b