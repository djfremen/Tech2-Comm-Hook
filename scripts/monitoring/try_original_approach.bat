@echo off
setlocal enabledelayedexpansion
title Recreate Original Working Approach
color 0E

echo ===========================================================
echo  RECREATING ORIGINAL WORKING APPROACH
echo ===========================================================
echo.

echo Step 1: Finding all java processes...
echo.
tasklist /fi "imagename eq java*.exe" /v 

echo.
echo Step 2: Enter the PID of the Java process to inject into:
set /p PID=Enter PID: 

echo.
echo Step 3: Setting up environment...

:: Check if the process exists
tasklist /fi "pid eq %PID%" | find "%PID%" > nul
if errorlevel 1 (
    echo ERROR: No process with PID %PID% found.
    goto Error
)

echo Confirmed process is running with PID %PID%

:: Create C:\temp directory if it doesn't exist
if not exist "C:\temp" (
    echo Creating C:\temp directory for logging...
    mkdir "C:\temp"

    if errorlevel 1 (
        echo ERROR: Failed to create C:\temp directory. Please run as administrator.
        goto Error
    )
)

:: Check if temp directory is writable
echo Testing write access to C:\temp...
echo test > "C:\temp\test_write.txt"
if errorlevel 1 (
    echo ERROR: Cannot write to C:\temp directory. Please check permissions.
    goto Error
) else (
    del "C:\temp\test_write.txt"
    echo C:\temp directory is writable.
)

:: If log file exists, delete it first
if exist "C:\temp\com_hook_log.txt" (
    echo Removing previous log file...
    del "C:\temp\com_hook_log.txt"
)

:: Get the absolute path to the DLL
set "CURRENT_DIR=%~dp0"
set "DLL_PATH=%CURRENT_DIR%Interceptor.x86.dll"

echo.
echo === Injection Information ===
echo Target Process ID: %PID%
echo DLL to inject: %DLL_PATH%
echo Injector: %CURRENT_DIR%Injector.x86.exe
echo Log file: C:\temp\com_hook_log.txt
echo.

:: Inject the DLL
echo Injecting 32-bit DLL into process with PID %PID%...
echo Command: "%CURRENT_DIR%Injector.x86.exe" %PID% "%DLL_PATH%"

"%CURRENT_DIR%Injector.x86.exe" %PID% "%DLL_PATH%"
set RESULT=!errorlevel!

echo.
echo Return code: %RESULT%
echo.

:: Check injection result
if %RESULT% neq 0 (
    echo.
    echo WARNING: DLL injection returned non-zero exit code.
    echo This may indicate a problem, but we'll continue to check for the log file.
    echo.
) else (
    echo.
    echo DLL injection command completed successfully.
    echo.
)

:: Wait and check for log file
echo Waiting for log file to be created...
echo.

set ATTEMPTS=1
:check_log
if %ATTEMPTS% gtr 15 goto no_log

if exist "C:\temp\com_hook_log.txt" (
    echo Log file found! Content:
    echo ----------------------------------------------------------
    type "C:\temp\com_hook_log.txt"
    echo ----------------------------------------------------------
    goto Success
)

echo Waiting for log file (attempt %ATTEMPTS% of 15)...
timeout /t 1 > nul
set /a ATTEMPTS+=1
goto check_log

:no_log
echo Log file not created after 15 attempts.
echo.
echo TRYING ALTERNATIVE APPROACH: Using only relative paths...
echo.

echo Command: Injector.x86.exe %PID% "Interceptor.x86.dll"
echo.

Injector.x86.exe %PID% "Interceptor.x86.dll"
set RESULT=!errorlevel!

echo.
echo Return code: %RESULT%
echo.

echo Checking for log file again...
echo.

set ATTEMPTS=1
:check_log2
if %ATTEMPTS% gtr 15 goto Fail

if exist "C:\temp\com_hook_log.txt" (
    echo Log file found! Content:
    echo ----------------------------------------------------------
    type "C:\temp\com_hook_log.txt"
    echo ----------------------------------------------------------
    goto Success
)

echo Waiting for log file (attempt %ATTEMPTS% of 15)...
timeout /t 1 > nul
set /a ATTEMPTS+=1
goto check_log2

:Fail
echo All attempts failed to create log file.
echo.
echo Some troubleshooting tips:
echo 1. Make sure Java is actively communicating with the COM port
echo 2. Try restarting the Java application
echo 3. Try different Java processes
echo 4. Check if the DLL has any dependencies it can't find
goto End

:Error
echo.
echo ERROR: One or more prerequisites not met.
echo Please check the error messages above.
goto End

:Success
echo.
echo SUCCESS! The DLL appears to be loaded and COM hook is working.
echo.
echo To continuously monitor COM port traffic, use:
echo powershell -Command "Get-Content -Path 'C:\temp\com_hook_log.txt' -Wait"

:End
echo.
echo Press any key to exit...
pause >nul 