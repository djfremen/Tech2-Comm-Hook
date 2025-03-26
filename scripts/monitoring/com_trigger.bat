@echo off
title COM Port Trigger and Monitor
color 0E

:: Clear any existing log file
echo Clearing any existing log file...
if exist "C:\temp\com_hook_log.txt" del "C:\temp\com_hook_log.txt"

:: Find Java process
echo Finding Java process...
for /f "tokens=2" %%a in ('tasklist ^| findstr "java"') do (
    set JAVA_PID=%%a
    goto :found_java
)
echo No Java process found!
goto :end

:found_java
echo Found Java process with PID: %JAVA_PID%

:: Inject DLL
echo Injecting DLL...
Injector.x86.exe %JAVA_PID% "Interceptor.x86.dll"
echo Return code: %errorlevel%

:: Start COM activity (open a console to let user interact with COM port)
echo Starting COM port activity tools...
start "COM Port Tools" cmd /c "mode && echo You can now use the Java application to generate COM port traffic && pause"

:: Monitor log file
echo Monitoring log file...
echo Press Ctrl+C to stop monitoring.
echo.

:check_log
if exist "C:\temp\com_hook_log.txt" (
    echo Log file found! Contents:
    echo -----------------------------------------
    type "C:\temp\com_hook_log.txt"
    echo -----------------------------------------
) else (
    echo Waiting for log file to be created...
)
timeout /t 2 > nul
goto :check_log

:end
echo.
echo Press any key to exit...
pause > nul 