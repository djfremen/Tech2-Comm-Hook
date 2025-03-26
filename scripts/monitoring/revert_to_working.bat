@echo off
title Revert to Original Working Version
color 0A

echo ===========================================================
echo  REVERTING TO ORIGINAL WORKING APPROACH
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
echo Step 3: Setting up environment...
echo.

:: Create temp directory if it doesn't exist
if not exist "C:\temp" (
    echo Creating C:\temp directory...
    mkdir "C:\temp"
)

:: Copy DLL to temp directory with original filename (not renamed)
echo Copying original DLL to C:\temp...
copy "Interceptor.x86.dll" "C:\temp\" /Y

echo.
echo Step 4: Enter the PID of the Java process to inject into:
set /p PID=Enter PID: 

echo.
echo Attempting injection using original approach...
echo.

:: Run the original injector command 
Injector.x86.exe %PID% "Interceptor.x86.dll"

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
echo If this approach is not working, remember what was different in the successful attempt:
echo - Was a different Java process targeted?
echo - Was a different version of the DLL used?
echo - Was a different path specified?
echo - Was there any special configuration?
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