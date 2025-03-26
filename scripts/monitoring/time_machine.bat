@echo off
title COM Port Monitoring Time Machine
color 0B

echo ===================================================
echo COM Port Monitoring Time Machine
echo Recreating the exact steps that previously worked
echo ===================================================
echo.

:: Step 1: Clear any existing log file
echo Step 1: Clearing any existing log file...
if exist C:\temp\com_hook_log.txt del C:\temp\com_hook_log.txt
echo.

:: Step 2: Register the DLL with regsvr32
echo Step 2: Registering the DLL with regsvr32...
echo This step previously helped with getting the DLL to load properly
regsvr32 /s Interceptor.x86.dll
echo.

:: Step 3: Find the Java process
echo Step 3: Finding Java process...
set FOUND_JAVA=0
for /f "tokens=1" %%p in ('wmic process where "name like 'java%%'" get ProcessId ^| findstr /r "[0-9]"') do (
    set JAVA_PID=%%p
    set FOUND_JAVA=1
    echo Found Java process with PID: %%p
    goto :found_java
)

if %FOUND_JAVA%==0 (
    echo No Java process found. Please start a Java application and try again.
    goto :eof
)

:found_java

:: Step 4: Inject multiple times with pauses in between
echo.
echo Step 4: Performing DLL injection sequence...
echo This step will inject the DLL multiple times with 2-second pauses
echo.

echo First injection attempt...
Injector.x86.exe %JAVA_PID% "Interceptor.x86.dll"
echo Return code: %ERRORLEVEL%
echo Pausing to let DLL initialize...
timeout /t 2 /nobreak > nul

echo Second injection attempt...
Injector.x86.exe %JAVA_PID% "Interceptor.x86.dll"
echo Return code: %ERRORLEVEL%
echo Pausing to let DLL initialize...
timeout /t 2 /nobreak > nul

echo Third injection attempt...
Injector.x86.exe %JAVA_PID% "Interceptor.x86.dll"
echo Return code: %ERRORLEVEL%
echo.

:: Step 5: Check if log file was created
echo Step 5: Checking for log file...
if exist C:\temp\com_hook_log.txt (
    echo SUCCESS! Log file found at C:\temp\com_hook_log.txt
    echo Contents:
    echo ------------------------------------------
    type C:\temp\com_hook_log.txt
    echo ------------------------------------------
) else (
    echo No log file found. DLL may not be correctly hooking COM port functions.
)
echo.

:: Step 6: Start monitoring in a separate window
echo Step 6: Starting log file monitor...
start "Log Monitor" cmd /c "monitor_log.bat"
echo Started log monitor in separate window.
echo.

:: Step 7: Wait for COM port activity
echo Step 7: Waiting for COM port activity...
echo The Java application should now be generating COM port traffic
echo If no traffic appears in the monitor window, you may need to:
echo - Trigger activity in the Java application
echo - Use one of the communication test tools
echo - Check if the COM port is correctly configured
echo.

:: Step 8: Provide options for next steps
echo ===================================================
echo What would you like to do next?
echo ===================================================
echo 1. Try direct COM port communication
echo 2. Start continuous monitoring (re-injects periodically)
echo 3. View current log file
echo 4. Exit
echo.

:menu
set /p choice="Enter choice (1-4): "

if "%choice%"=="1" (
    echo.
    echo Starting COM port communication test...
    start "COM Port Test" powershell -ExecutionPolicy Bypass -File test_com_communication.ps1
    goto :menu
) else if "%choice%"=="2" (
    echo.
    echo Starting continuous monitoring...
    start "Continuous Monitor" powershell -ExecutionPolicy Bypass -File continuous_monitor.ps1
    goto :menu
) else if "%choice%"=="3" (
    echo.
    echo Current log file contents:
    echo ------------------------------------------
    if exist C:\temp\com_hook_log.txt (
        type C:\temp\com_hook_log.txt
    ) else (
        echo No log file found.
    )
    echo ------------------------------------------
    echo.
    goto :menu
) else if "%choice%"=="4" (
    echo.
    echo Exiting Time Machine...
    exit /b
) else (
    echo Invalid choice. Please try again.
    goto :menu
) 