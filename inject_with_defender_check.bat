@echo off
echo COM Port Hook Injection with Windows Defender Check

if "%1"=="" (
  echo Please provide a PID as argument
  echo Example: inject_with_defender_check.bat 6068
  exit /b 1
)

set PID=%1
echo Target process PID: %PID%

:: Check for admin privileges
net session >nul 2>nul
if %ERRORLEVEL% neq 0 (
  echo This script requires administrative privileges.
  echo Please run as administrator.
  pause
  exit /b 1
)

:: Save original Windows Defender state
echo Checking current Windows Defender status...
powershell -Command "Get-MpPreference | Select-Object DisableRealtimeMonitoring" > defender_state.txt

:: Try to disable Windows Defender temporarily
echo Attempting to temporarily disable Windows Defender real-time protection...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true" >nul 2>nul
if %ERRORLEVEL% neq 0 (
  echo Failed to disable Windows Defender. Continuing anyway.
)

:: Clear any existing log file
if exist C:\temp\com_hook_log.txt del C:\temp\com_hook_log.txt
echo Log will be at C:\temp\com_hook_log.txt

:: Run the injection
echo.
echo Running injection with PID %PID%...
tools\Injector.x86.exe %PID% build\Interceptor.x86.dll
set INJECT_RESULT=%ERRORLEVEL%

:: Try to restore Windows Defender
echo.
echo Restoring Windows Defender settings...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false" >nul 2>nul

:: Check for DLL log file
echo.
if %INJECT_RESULT% neq 0 (
  echo Injection FAILED with error code %INJECT_RESULT%
) else (
  echo Injection command completed successfully.
  timeout /t 2 >nul
  
  if exist C:\temp\com_hook_log.txt (
    echo Log file created! DLL successfully loaded.
    echo First few lines of log:
    echo ----------------------------------------
    type C:\temp\com_hook_log.txt | find "" /n | findstr "^\[1-5\]"
    echo ----------------------------------------
  ) else (
    echo No log file created yet. This is normal if:
    echo 1. The DLL loaded but no COM port activity has occurred
    echo 2. The target process hasn't tried to access COM ports yet
    echo 3. The DLL failed to load in the target process
  )
)

echo.
echo If injection is still failing, verify that:
echo 1. The target process is 32-bit (x86) - our injector is 32-bit
echo 2. The target process has appropriate permissions
echo 3. Try rebooting or using Process Explorer to verify architecture

pause 