@echo off
echo Windows Defender Test - DLL Injection

echo This script will attempt to temporarily disable Windows Defender real-time protection
echo for the injection test. This requires Administrator privileges.
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause > nul

:: Check for admin privileges
net session >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: Administrator privileges required. Please run this script as Administrator.
    goto end
)

:: Save current Defender status
echo Checking current Windows Defender status...
for /f "tokens=2 delims=:" %%a in ('powershell -Command "Get-MpPreference | Select-Object -ExpandProperty DisableRealtimeMonitoring"') do (
    set CURRENT_STATUS=%%a
    echo Current status: %%a
)

:: Try to disable real-time protection
echo Attempting to disable Windows Defender real-time protection...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true"
if %ERRORLEVEL% neq 0 (
    echo Failed to disable Windows Defender. Continuing anyway...
)

:: Delete any existing log file
if exist C:\temp\com_hook_log.txt del C:\temp\com_hook_log.txt

:: Find Java process
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq javaw.exe" /fo list ^| find "PID:"') do (
    set JAVAPID=%%i
    echo Found Java process with PID: %%i
)

if "%JAVAPID%"=="" (
    echo No Java process found!
    goto restore_defender
)

:: Inject the DLL
echo Injecting DLL into process %JAVAPID%...
Injector.x86.exe %JAVAPID% build\Interceptor.x86.dll
set RESULT=%ERRORLEVEL%

echo Injection completed with return code: %RESULT%
if %RESULT% equ 0 (
    echo Injection successful
) else (
    echo Injection failed with code %RESULT%
)

:: Check if log file was created (indicates DLL attached)
timeout /t 2 > nul
if exist C:\temp\com_hook_log.txt (
    echo Log file created! DLL successfully loaded and executed.
    type C:\temp\com_hook_log.txt
) else (
    echo No log file found. DLL did not attach or could not create log.
)

:restore_defender
:: Restore original Defender settings
echo Restoring Windows Defender settings...
if "%CURRENT_STATUS%" == " False" (
    powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false"
    echo Windows Defender real-time protection has been re-enabled.
)

:end
pause 