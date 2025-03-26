@echo off
setlocal enabledelayedexpansion
title Improved COM Port Hook Injector
color 0B

echo ====================================================================
echo Improved COM Port Hook Injector
echo ====================================================================
echo.

:: Ensure running as admin
echo Checking administrative privileges...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script requires administrative privileges.
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)
echo Running with administrative privileges.
echo.

:: Verify paths and tools exist
echo Checking required files and tools...
set TOOLS_DIR=tools
set BUILD_DIR=build
set INJECTOR=%TOOLS_DIR%\Injector.x86.exe
set HANDLE_EXE=%TOOLS_DIR%\handle.exe
set DLL=%BUILD_DIR%\Interceptor.x86.dll
set LOG_FILE=C:\temp\com_hook_log.txt

if not exist "%INJECTOR%" (
    echo ERROR: Injector not found at "%INJECTOR%"
    echo Current directory: %CD%
    echo.
    pause
    exit /b 1
)

if not exist "%HANDLE_EXE%" (
    echo ERROR: Handle.exe not found at "%HANDLE_EXE%"
    echo Current directory: %CD%
    echo.
    pause
    exit /b 1
)

if not exist "%DLL%" (
    echo ERROR: Hook DLL not found at "%DLL%"
    echo Current directory: %CD%
    echo.
    pause
    exit /b 1
)

echo All required files found:
echo - Injector: %INJECTOR%
echo - Handle.exe: %HANDLE_EXE%
echo - Hook DLL: %DLL%
echo.

:: Ensure temp directory exists
if not exist "C:\temp" (
    echo Creating C:\temp directory...
    mkdir "C:\temp" > nul 2>&1
    if errorlevel 1 (
        echo ERROR: Failed to create C:\temp directory.
        echo.
        pause
        exit /b 1
    )
)

:: Clear any existing log file
if exist "%LOG_FILE%" (
    echo Clearing previous log file...
    del "%LOG_FILE%" > nul 2>&1
)
echo.

:: Get COM port to monitor
set /p COM_PORT=Enter COM port to hook (e.g., COM8): 
echo.

:: Find Java processes with handles to the COM port
echo Looking for Java processes with handles to %COM_PORT%...
echo Using command: "%HANDLE_EXE%" %COM_PORT%
echo.

:: Run handle.exe with the COM port and capture output
"%HANDLE_EXE%" %COM_PORT% > handle_output.txt 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Handle.exe failed to run properly. Error code: %errorlevel%
    echo Output:
    type handle_output.txt
    echo.
    goto :manual_pid
)

:: Look for javaw.exe process with the COM port handle
echo Searching for javaw.exe with handle to %COM_PORT%...
findstr /i "javaw.exe.*%COM_PORT%" handle_output.txt > javaw_handles.txt
if %errorlevel% neq 0 (
    echo WARNING: No javaw.exe process found with handle to %COM_PORT%
    echo Available processes with handles to %COM_PORT%:
    type handle_output.txt
    echo.
    goto :manual_pid
)

:: Extract the PID from the handle output
for /f "tokens=3" %%a in (javaw_handles.txt) do (
    set TARGET_PID=%%a
    echo Found javaw.exe with PID !TARGET_PID! holding %COM_PORT%
    goto :found_pid
)

:: If no PID found automatically, ask for manual entry
:manual_pid
echo No Java process automatically found with handle to %COM_PORT%
set /p TARGET_PID=Enter PID of javaw.exe process to inject into: 

:: Validate the manually entered PID
powershell -Command "try { $proc = Get-Process -Id %TARGET_PID% -ErrorAction Stop; if ($proc.ProcessName -like 'java*') { exit 0 } else { Write-Host 'WARNING: Process with PID %TARGET_PID% is not a Java process.' -ForegroundColor Yellow; exit 1 } } catch { Write-Host 'ERROR: Process with PID %TARGET_PID% not found.' -ForegroundColor Red; exit 2 }"
if %errorlevel% neq 0 (
    echo.
    set /p CONTINUE=Continue anyway? (Y/N): 
    if /i not "!CONTINUE!"=="Y" (
        echo Aborted by user.
        goto :cleanup
    )
)

:found_pid
echo.
:: Display target process information
powershell -Command "$proc = Get-Process -Id %TARGET_PID% -ErrorAction SilentlyContinue; if ($proc) { Write-Host ('Target Process: ' + $proc.ProcessName + ' (PID: ' + $proc.Id + ')'); Write-Host ('Path: ' + $proc.Path) }"
echo.

:: Prepare injection command
set INJECT_CMD="%INJECTOR%" %TARGET_PID% "%DLL%"
echo Ready to inject using command:
echo %INJECT_CMD%
echo.

:: Confirm before injecting
set /p CONFIRM=Proceed with injection? (Y/N): 
if /i not "%CONFIRM%"=="Y" (
    echo Injection cancelled by user.
    goto :cleanup
)

:: Execute injection
echo.
echo Executing injection...
%INJECT_CMD%
set INJECT_RESULT=%errorlevel%

echo Return code: %INJECT_RESULT%
if %INJECT_RESULT% neq 0 (
    echo ERROR: Injection failed with error code %INJECT_RESULT%
) else (
    echo Injection command completed successfully.
)
echo.

:: Check for log file creation
echo Checking for log file creation...
timeout /t 2 /nobreak > nul
if exist "%LOG_FILE%" (
    echo SUCCESS: Log file created at %LOG_FILE%
    echo.
    echo Log file contents:
    echo --------------------------------------------------
    type "%LOG_FILE%"
    echo --------------------------------------------------
) else (
    echo WARNING: No log file was created at %LOG_FILE%
    echo This may indicate that the DLL failed to initialize properly.
)
echo.

:: Start monitoring the log file
echo Would you like to monitor the log file for changes?
set /p MONITOR=Start log file monitor? (Y/N): 
if /i "%MONITOR%"=="Y" (
    echo.
    echo Starting log monitor...
    start "Log Monitor" cmd /c "powershell -Command \"while($true) { if(Test-Path '%LOG_FILE%') { Clear-Host; Get-Content '%LOG_FILE%'; Write-Host \"`nMonitoring %LOG_FILE% - Press Ctrl+C to stop\" -ForegroundColor Yellow } else { Write-Host \"Waiting for log file...\" -ForegroundColor Gray }; Start-Sleep -Seconds 1 }\""
)

:cleanup
:: Clean up temporary files
del handle_output.txt 2>nul
del javaw_handles.txt 2>nul

echo.
echo Injection process complete.
echo.
echo If injection failed, try running the diagnostic tool: injection_diagnostic.bat
echo If the DLL loads but detaches immediately, try the COM port redirection approach.
echo.
pause 