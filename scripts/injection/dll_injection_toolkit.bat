@echo off
title DLL Injection Toolkit for COM Port Monitoring
color 0A

:: Check if running as administrator
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if %errorlevel% neq 0 (
    echo Administrator privileges not detected!
    echo.
    echo Please run this script as Administrator for best results.
    echo Right-click the script and select "Run as administrator".
    echo.
    pause
    goto menu
)

:menu
cls
echo ===========================================================
echo              DLL Injection Toolkit for COM Port
echo ===========================================================
echo.
echo This toolkit provides multiple methods to inject the 
echo Interceptor DLL for monitoring COM port communications.
echo.
echo Target Process: javaw.exe (PID determined dynamically)
echo Target DLL: Interceptor.x86.dll
echo Log File: C:\temp\com_hook_log.txt
echo.
echo Available Options:
echo ----------------------------------------------------------
echo  1. Process Verification (Check target process architecture)
echo  2. Enhanced DLL Injection (Detailed logging)
echo  3. Process Explorer Injection (GUI method)
echo  4. Lightweight C# Injector (Alternative approach)
echo  5. Check Injection Status
echo  6. Monitor COM Port Traffic
echo  0. Exit
echo ----------------------------------------------------------
echo.
set /p choice=Enter your choice (0-6): 
echo.

if "%choice%"=="1" goto verify_process
if "%choice%"=="2" goto enhanced_injection 
if "%choice%"=="3" goto procexp_injection
if "%choice%"=="4" goto lightweight_injection
if "%choice%"=="5" goto check_status
if "%choice%"=="6" goto monitor_com
if "%choice%"=="0" goto exit
goto menu

:verify_process
cls
echo Running process architecture verification...
echo.
echo This will check if the Java process is 32-bit or 64-bit
echo and provide appropriate recommendations.
echo.
powershell -ExecutionPolicy Bypass -Command "& {if(!(Test-Path 'verify_process_architecture.ps1')){Write-Host 'Script not found!' -ForegroundColor Red}else{.\verify_process_architecture.ps1}}"
echo.
pause
goto menu

:enhanced_injection
cls
echo Running enhanced DLL injection...
echo.
echo This method provides detailed logging of the injection process
echo and will report specific errors if they occur.
echo.
powershell -ExecutionPolicy Bypass -Command "& {if(!(Test-Path 'enhanced_inject.ps1')){Write-Host 'Script not found!' -ForegroundColor Red}else{.\enhanced_inject.ps1}}"
echo.
pause
goto menu

:procexp_injection
cls
echo Running Process Explorer injection method...
echo.
echo This will use the Process Explorer GUI to inject the DLL,
echo which may bypass some security restrictions.
echo.
powershell -ExecutionPolicy Bypass -Command "& {if(!(Test-Path 'procexp_inject.ps1')){Write-Host 'Script not found!' -ForegroundColor Red}else{.\procexp_inject.ps1}}"
echo.
pause
goto menu

:lightweight_injection
cls
echo Running lightweight C# injector...
echo.
echo This method uses a custom C# implementation that may
echo bypass some security restrictions.
echo.
powershell -ExecutionPolicy Bypass -Command "& {if(!(Test-Path 'light_inject.ps1')){Write-Host 'Script not found!' -ForegroundColor Red}else{.\light_inject.ps1}}"
echo.
pause
goto menu

:check_status
cls
echo Checking injection status...
echo.

if not exist "C:\temp\com_hook_log.txt" (
    echo Status: NOT INJECTED
    echo The log file C:\temp\com_hook_log.txt does not exist.
    echo.
    echo This suggests that either:
    echo - The DLL has not been successfully injected
    echo - The injected DLL has not intercepted any COM port activity yet
    echo - There might be permission issues with creating the log file
    echo.
) else (
    echo Status: POTENTIALLY INJECTED
    echo The log file C:\temp\com_hook_log.txt exists.
    echo.
    echo Contents of log file:
    echo ----------------------------------------------------------
    type "C:\temp\com_hook_log.txt"
    echo ----------------------------------------------------------
    echo.
)

:: Additional checks
if exist "C:\temp\injection_debug.log" (
    echo Enhanced injection debug log exists.
    echo You can view it with: type C:\temp\injection_debug.log
    echo.
)

if exist "C:\temp\injection_log.txt" (
    echo Lightweight injector log exists.
    echo You can view it with: type C:\temp\injection_log.txt
    echo.
)

:: Check for running Java processes
echo Checking for running Java processes:
echo ----------------------------------------------------------
powershell -Command "Get-Process -Name java*" 2>nul
if %errorlevel% neq 0 (
    echo No Java processes found running!
    echo The target application may have been closed.
)
echo ----------------------------------------------------------
echo.

pause
goto menu

:monitor_com
cls
echo Monitoring COM port traffic...
echo.
echo This will continuously display new COM port communications
echo as they are intercepted by the DLL.
echo.
echo Press Ctrl+C to stop monitoring.
echo.

if not exist "C:\temp\com_hook_log.txt" (
    echo WARNING: Log file doesn't exist yet!
    echo Either the DLL is not injected or it hasn't captured any traffic.
    echo.
    echo The monitor will start when the log file is created.
)

echo Starting monitoring...
echo ----------------------------------------------------------
powershell -ExecutionPolicy Bypass -Command "& {if(Test-Path 'C:\temp\com_hook_log.txt'){Get-Content 'C:\temp\com_hook_log.txt' -Wait}else{Write-Host 'Waiting for log file to be created...' -ForegroundColor Yellow; while(-not (Test-Path 'C:\temp\com_hook_log.txt')){Start-Sleep -Seconds 1}; Get-Content 'C:\temp\com_hook_log.txt' -Wait}}"
echo ----------------------------------------------------------
echo.
pause
goto menu

:exit
cls
echo Thank you for using the DLL Injection Toolkit.
echo.
timeout /t 2 >nul
exit 