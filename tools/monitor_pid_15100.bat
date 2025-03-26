@echo off
setlocal

echo === Inject and Monitor PID 15100 ===
echo.
echo This script will:
echo 1. Inject the Interceptor.x86.dll into process with PID 15100
echo 2. Monitor the log file for COM port communication
echo.
echo Press any key to start the injection process...
pause > nul

:: Check if the required files exist
if not exist "Interceptor.x86.dll" (
    if exist "bin\Interceptor.x86.dll" (
        echo Using Interceptor.x86.dll from bin directory...
        copy "bin\Interceptor.x86.dll" "Interceptor.x86.dll" > nul
    ) else (
        echo ERROR: Interceptor.x86.dll not found.
        goto End
    )
)

if not exist "Injector.x86.exe" (
    if exist "bin\Injector.x86.exe" (
        echo Using Injector.x86.exe from bin directory...
        copy "bin\Injector.x86.exe" "Injector.x86.exe" > nul
    ) else (
        echo ERROR: Injector.x86.exe not found.
        goto End
    )
)

:: Run the injection
echo Running injection on PID 15100...
call inject_pid_15100.bat

:: Check if log file was created
if not exist "C:\temp\com_hook_log.txt" (
    echo ERROR: Log file was not created.
    goto End
)

echo.
echo === Starting COM Port Traffic Monitor ===
echo.
echo This will continuously monitor the log file.
echo Press Ctrl+C to stop monitoring.
echo.

:: Use PowerShell to watch the log file for changes
powershell -Command "Get-Content -Path 'C:\temp\com_hook_log.txt' -Wait | Select-String -Pattern 'TX Data|RX Data'"

:End
echo.
pause
endlocal 