@echo off
echo ====================================================
echo Direct DLL injection test script
echo ====================================================
echo.

:: Clear any existing log file
echo Clearing any existing log file...
if exist C:\temp\com_hook_log.txt del C:\temp\com_hook_log.txt

:: Check for Java process
echo Checking for Java process...
set FOUND_JAVA=0
for /f "tokens=1" %%p in ('wmic process where "name like 'java%%'" get ProcessId ^| findstr /r "[0-9]"') do (
    set JAVA_PID=%%p
    set FOUND_JAVA=1
    echo Found Java process with PID: %%p
)

if %FOUND_JAVA%==0 (
    echo No Java process found. Please start a Java application and try again.
    goto :EOF
)

:: Attempt DLL injection
echo.
echo Attempting DLL injection...
echo.
echo Using command: Injector.x86.exe %JAVA_PID% "Interceptor.x86.dll"
Injector.x86.exe %JAVA_PID% "Interceptor.x86.dll"
echo Return code: %ERRORLEVEL%
echo.

:: Check for log file
echo Checking for log file...
if exist C:\temp\com_hook_log.txt (
    echo Log file exists. Contents:
    type C:\temp\com_hook_log.txt
) else (
    echo Log file does not exist. DLL injection may have failed.
)

echo.
echo ====================================================
echo Test complete. Press any key to exit.
echo ====================================================
pause > nul 