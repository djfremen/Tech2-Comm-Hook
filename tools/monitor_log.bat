@echo off
setlocal

echo === COM Port Interceptor Log Monitor ===
echo.
echo This script will check for the log file at C:\temp\com_hook_log.txt
echo and display it when it's created or updated.
echo.
echo Press Ctrl+C to stop monitoring.
echo.

:CheckLoop
if exist "C:\temp\com_hook_log.txt" (
    echo Log file found! Contents:
    echo ----------------------------------------
    type "C:\temp\com_hook_log.txt"
    echo ----------------------------------------
    echo.
    echo Monitoring for changes...
    goto MonitorLoop
) else (
    echo Waiting for log file to be created...
    timeout /t 2 /nobreak > nul
    goto CheckLoop
)

:MonitorLoop
timeout /t 2 /nobreak > nul
if exist "C:\temp\com_hook_log.txt" (
    echo ----------------------------------------
    type "C:\temp\com_hook_log.txt"
    echo ----------------------------------------
)
goto MonitorLoop 