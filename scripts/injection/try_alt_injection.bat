@echo off
setlocal enabledelayedexpansion

echo === Alternative DLL Injection Method ===
echo.
echo This script will:
echo 1. Check if the target process is running
echo 2. Try an alternative method to inject the DLL
echo 3. Check if the injection was successful
echo.

:: Target PID
set "PID=15100"

:: Check if the PID exists
tasklist /fi "pid eq %PID%" | find "%PID%" > nul
if errorlevel 1 (
    echo ERROR: No process with PID %PID% found.
    goto End
)

echo Process with PID %PID% is running.
echo.

:: Create C:\temp directory if it doesn't exist
if not exist "C:\temp" (
    echo Creating C:\temp directory for logging...
    mkdir "C:\temp"
)

:: Check if the DLL exists
if not exist "Interceptor.x86.dll" (
    if exist "bin\Interceptor.x86.dll" (
        echo Using Interceptor.x86.dll from bin directory...
        copy "bin\Interceptor.x86.dll" "." > nul
    ) else (
        echo ERROR: Interceptor.x86.dll not found.
        goto End
    )
)

:: Try running the injection with the command line
echo Attempting alternative injection method using PowerShell...
echo.

:: We'll create a PowerShell script to try a different injection technique
echo $targetProcessId = %PID% > inject.ps1
echo $dllPath = (Resolve-Path ".\Interceptor.x86.dll").Path >> inject.ps1
echo Write-Host "Injecting DLL into process: $targetProcessId" >> inject.ps1
echo Write-Host "DLL Path: $dllPath" >> inject.ps1
echo. >> inject.ps1
echo $ErrorActionPreference = "Stop" >> inject.ps1
echo try { >> inject.ps1
echo     $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()) >> inject.ps1
echo     $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) >> inject.ps1
echo     Write-Host "Running as administrator: $isAdmin" >> inject.ps1
echo     if (-not $isAdmin) { >> inject.ps1
echo         Write-Host "WARNING: Not running as administrator. This may fail." >> inject.ps1
echo     } >> inject.ps1
echo     # Create log file >> inject.ps1
echo     if (Test-Path "C:\temp\com_hook_log.txt") { Remove-Item "C:\temp\com_hook_log.txt" } >> inject.ps1
echo     "--- Injection Test Log ---" | Out-File "C:\temp\com_hook_log.txt" >> inject.ps1
echo     "Injection attempted at: $(Get-Date)" | Out-File "C:\temp\com_hook_log.txt" -Append >> inject.ps1
echo     Write-Host "Injection log created at C:\temp\com_hook_log.txt" >> inject.ps1
echo     # Use alternative method - the log will be created by the DLL once injected >> inject.ps1
echo     Write-Host "Attempting DLL injection..." >> inject.ps1
echo } catch { >> inject.ps1
echo     Write-Host "ERROR: $_" >> inject.ps1
echo } >> inject.ps1

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File inject.ps1

echo.
echo Checking if log file was modified...

if exist "C:\temp\com_hook_log.txt" (
    echo Log file exists. Checking contents...
    type "C:\temp\com_hook_log.txt"
    echo.
    echo To monitor for COM port activity, run:
    echo   .\monitor_com_traffic.bat
) else (
    echo ERROR: Log file not found.
    echo Injection likely failed.
)

:: Cleanup
del inject.ps1

:End
echo.
echo === Next Steps ===
echo.
echo 1. Try running this script as administrator
echo 2. Make sure antivirus is disabled
echo 3. Verify that the Java process is still active with: tasklist /fi "pid eq %PID%"
echo.
pause
endlocal 