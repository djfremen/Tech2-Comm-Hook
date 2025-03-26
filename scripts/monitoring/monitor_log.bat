@echo off
echo ====================================================
echo COM Port Log Monitor
echo ====================================================
echo.
echo Monitoring C:\temp\com_hook_log.txt for changes
echo Press Ctrl+C to stop monitoring
echo.

:check_loop
if exist C:\temp\com_hook_log.txt (
    echo [%TIME%] Log file exists. Current contents:
    type C:\temp\com_hook_log.txt
    echo.
    echo Waiting for updates (checking every 2 seconds)...
    echo.
) else (
    echo [%TIME%] Waiting for log file to be created...
)

timeout /t 2 /nobreak > nul
goto check_loop 