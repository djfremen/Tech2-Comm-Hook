@echo off
setlocal

echo === Checking DLL Injection Status ===
echo.

:: Check if log file exists
if exist "C:\temp\com_hook_log.txt" (
    echo SUCCESS: Log file found at C:\temp\com_hook_log.txt
    echo.
    echo First 10 lines of log file:
    echo ----------------------------
    type "C:\temp\com_hook_log.txt" | findstr /n "." | findstr /b "[1-9]" | findstr /b "[1-9][0-9]" /v
    echo.
    echo To continuously monitor the log file, run:
    echo   powershell -Command "Get-Content -Path 'C:\temp\com_hook_log.txt' -Wait"
) else (
    echo ERROR: Log file not found at C:\temp\com_hook_log.txt
    echo.
    echo Possible issues:
    echo 1. The DLL injection failed
    echo 2. The target process hasn't accessed COM ports yet
    echo 3. Write permissions for C:\temp folder are restricted
    echo.
    echo Next steps:
    echo 1. Try running the injection script as Administrator
    echo 2. Temporarily disable antivirus software
    echo 3. Confirm the Java process is still running: tasklist /fi "pid eq 15100"
)

echo.
pause
endlocal 