@echo off
echo Attempting injection into Java process (PID 6068)...
Injector.x86.exe 6068 "Interceptor.x86.dll"
echo Return code: %errorlevel%
echo.
echo Checking for log file...
timeout /t 10 /nobreak
if exist "C:\temp\com_hook_log.txt" (
    echo Log file created! Content:
    echo -----------------------------------------
    type "C:\temp\com_hook_log.txt"
    echo -----------------------------------------
) else (
    echo No log file found.
)
pause 