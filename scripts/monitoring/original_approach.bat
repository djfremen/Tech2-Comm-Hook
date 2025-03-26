@echo off
title Original Simple Approach
color 0A

echo ===========================================================
echo  ABSOLUTE SIMPLEST INJECTION APPROACH
echo ===========================================================
echo.

echo Step 1: Finding all java processes...
echo.
tasklist /fi "imagename eq java*.exe" /v

echo.
echo Step 2: Locating DLL and Injector files...
echo.
dir /b *.dll
dir /b *.exe

echo.
echo Step 3: Enter the PID of the Java process to inject into:
set /p PID=Enter PID: 

echo.
echo Attempting injection using ABSOLUTE SIMPLEST approach...
echo Using current directory paths with NO copying to C:\temp
echo.

:: Run the original injector command with full path to current directory
set CURRENT_DIR=%CD%
echo Current directory: %CURRENT_DIR%
echo.

echo Command: Injector.x86.exe %PID% "%CURRENT_DIR%\Interceptor.x86.dll"
echo.

Injector.x86.exe %PID% "%CURRENT_DIR%\Interceptor.x86.dll"

echo.
echo Return code: %errorlevel%
echo.

echo Checking for log file...
echo.

set ATTEMPTS=1
:check_log
if %ATTEMPTS% gtr 15 goto no_log

if exist "C:\temp\com_hook_log.txt" (
    echo Log file found! Content:
    echo ----------------------------------------------------------
    type "C:\temp\com_hook_log.txt"
    echo ----------------------------------------------------------
    goto success
)

echo Waiting for log file (attempt %ATTEMPTS% of 15)...
timeout /t 1 > nul
set /a ATTEMPTS+=1
goto check_log

:no_log
echo Log file not created after 15 attempts.
echo.
echo Trying another approach: relative path to DLL...
echo.

echo Command: Injector.x86.exe %PID% "Interceptor.x86.dll"
echo.

Injector.x86.exe %PID% "Interceptor.x86.dll"

echo.
echo Return code: %errorlevel%
echo.

echo Checking for log file again...
echo.

set ATTEMPTS=1
:check_log2
if %ATTEMPTS% gtr 15 goto no_log2

if exist "C:\temp\com_hook_log.txt" (
    echo Log file found! Content:
    echo ----------------------------------------------------------
    type "C:\temp\com_hook_log.txt"
    echo ----------------------------------------------------------
    goto success
)

echo Waiting for log file (attempt %ATTEMPTS% of 15)...
timeout /t 1 > nul
set /a ATTEMPTS+=1
goto check_log2

:no_log2
echo No log file created after both attempts.
echo.
echo If these approaches are not working, try to recall what was different in the successful attempt.
goto end

:success
echo.
echo SUCCESS! The DLL is injected and logging COM port traffic.
echo.
echo To continuously monitor COM port traffic, use:
echo powershell -Command "Get-Content -Path 'C:\temp\com_hook_log.txt' -Wait"

:end
echo.
echo Press any key to exit...
pause >nul 