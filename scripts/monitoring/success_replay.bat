@echo off
echo ====================================================
echo COM Port Traffic Capture - Success Replay
echo ====================================================
echo.

:: Clear any existing log file
echo Clearing any existing log file...
if exist C:\temp\com_hook_log.txt del C:\temp\com_hook_log.txt

:: Register the DLL first (this worked in our previous attempts)
echo Registering the DLL with regsvr32...
regsvr32 /s Interceptor.x86.dll

:: Find Java process
echo Finding Java process...
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
:: Perform DLL injection
echo.
echo Performing DLL injection...
echo Using command: Injector.x86.exe %JAVA_PID% "Interceptor.x86.dll"
Injector.x86.exe %JAVA_PID% "Interceptor.x86.dll"
echo Return code: %ERRORLEVEL%
echo.

:: Start monitoring in a separate window
echo Starting log monitor in a separate window...
start "Log Monitor" cmd /c "monitor_log.bat"

:: Interactive console
echo.
echo ====================================================
echo What would you like to do next?
echo ====================================================
echo 1. Try to communicate directly with COM port
echo 2. View current log file
echo 3. Re-inject DLL
echo 4. Exit
echo.

:menu
set /p choice="Enter choice (1-4): "

if "%choice%"=="1" (
    echo.
    echo Launching COM port communication test...
    start "COM Port Test" powershell -ExecutionPolicy Bypass -File test_com_communication.ps1
    goto :menu
) else if "%choice%"=="2" (
    echo.
    echo Current log file contents:
    echo ---------------------------------------------
    if exist C:\temp\com_hook_log.txt (
        type C:\temp\com_hook_log.txt
    ) else (
        echo No log file found.
    )
    echo ---------------------------------------------
    echo.
    goto :menu
) else if "%choice%"=="3" (
    echo.
    echo Re-injecting DLL...
    Injector.x86.exe %JAVA_PID% "Interceptor.x86.dll"
    echo Return code: %ERRORLEVEL%
    echo.
    goto :menu
) else if "%choice%"=="4" (
    echo.
    echo Exiting...
    goto :eof
) else (
    echo Invalid choice. Please try again.
    goto :menu
) 