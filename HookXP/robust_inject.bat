@echo off
setlocal enabledelayedexpansion

echo ============================================
echo Robust COM Port Hook Injection Tool
echo ============================================

if "%1"=="" (
  echo Please provide a PID as argument
  echo Example: robust_inject.bat 6068
  exit /b 1
)

:: Check for admin privileges
net session >nul 2>nul
if %ERRORLEVEL% neq 0 (
  echo WARNING: Not running as administrator
  echo Some injection operations may fail without admin rights.
  echo Consider restarting this script as administrator.
  echo.
  echo Press any key to continue anyway...
  pause >nul
)

set PID=%1
echo Target process PID: %PID%

:: Verify process exists and is accessible
tasklist /FI "PID eq %PID%" | find "%PID%" > nul
if %ERRORLEVEL% neq 0 (
  echo ERROR: No process found with PID %PID%
  pause
  exit /b 1
)

:: Get process name
for /f "tokens=1" %%a in ('tasklist /FI "PID eq %PID%" /FO list ^| find "Image Name"') do (
  for /f "tokens=3" %%b in ('tasklist /FI "PID eq %PID%" /FO list ^| find "Image Name"') do (
    set PROC_NAME=%%b
  )
)
echo Target process name: %PROC_NAME%

:: Prepare log directory
if not exist C:\temp mkdir C:\temp 2>nul

:: Verify injector exists
if not exist tools\Injector.x86.exe (
  echo ERROR: Injector not found at tools\Injector.x86.exe
  pause
  exit /b 1
)

:: Verify DLL exists
if not exist build\Interceptor.x86.dll (
  echo ERROR: Hook DLL not found at build\Interceptor.x86.dll
  pause
  exit /b 1
)

:: Clear previous log
if exist C:\temp\com_hook_log.txt del C:\temp\com_hook_log.txt

echo.
echo ============================================
echo Injection Configuration:
echo ============================================
echo Target Process: %PROC_NAME% (PID: %PID%)
echo Injector: tools\Injector.x86.exe
echo Hook DLL: build\Interceptor.x86.dll
echo Log File: C:\temp\com_hook_log.txt
echo ============================================

echo.
echo Attempting to set permissions on the hook DLL...
icacls build\Interceptor.x86.dll /grant Everyone:F >nul 2>nul
icacls tools\Injector.x86.exe /grant Everyone:F >nul 2>nul
icacls C:\temp /grant Everyone:F >nul 2>nul

echo.
echo Ready to inject. Press any key to continue...
pause >nul

echo.
echo Running injection...
tools\Injector.x86.exe %PID% build\Interceptor.x86.dll
set INJECT_RESULT=%ERRORLEVEL%

echo.
if %INJECT_RESULT% neq 0 (
  echo Injection FAILED with error code %INJECT_RESULT%
  echo.
  echo Possible causes:
  echo 1. Windows security is blocking the injection
  echo 2. The target process has restrictions
  echo 3. The process is protected
  echo.
  echo Try these troubleshooting steps:
  echo - Run as administrator
  echo - Temporarily disable anti-virus
  echo - Create Windows Defender exclusions for:
  echo   * %CD%\tools\Injector.x86.exe
  echo   * %CD%\build\Interceptor.x86.dll
  echo   * C:\temp\com_hook_log.txt
) else (
  echo Injection command completed successfully.
  echo.
  echo Important notes:
  echo 1. The log file will ONLY be created when the target
  echo    process actually opens a COM port.
  echo 2. If no COM activity occurs, no log will be created.
  
  echo.
  echo Waiting 5 seconds to check for log file...
  timeout /t 5 >nul
  
  if exist C:\temp\com_hook_log.txt (
    echo SUCCESS! Log file created.
    echo First few lines of log:
    echo ----------------------------------------
    type C:\temp\com_hook_log.txt | findstr /n "." | findstr "^[1-5]:"
    echo ----------------------------------------
  ) else (
    echo No log file created yet.
    echo This is normal if no COM port activity has occurred.
    echo Try using the application now to generate COM port activity.
  )
)

echo.
echo Press any key to exit...
pause >nul 