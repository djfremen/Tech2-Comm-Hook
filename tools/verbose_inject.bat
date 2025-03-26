@echo off
setlocal

set "PID=14528"
set "DLL_PATH=%~dp0Interceptor.dll"

echo === Verbose DLL Injection ===
echo.
echo Target Process ID: %PID%
echo DLL Path: %DLL_PATH%
echo.

echo Checking if the DLL exists...
if not exist "%DLL_PATH%" (
    echo ERROR: DLL file not found at "%DLL_PATH%"
    goto End
)

echo Checking if C:\temp exists and is writable...
if not exist "C:\temp" (
    echo Creating C:\temp directory...
    mkdir "C:\temp"
)

echo Writing a test file to C:\temp...
echo This is a test > "C:\temp\test_write.txt"
if not exist "C:\temp\test_write.txt" (
    echo ERROR: Cannot write to C:\temp directory! Check permissions.
    goto End
)
echo Successfully wrote to C:\temp

echo.
echo Running injection with verbose output...
echo Command: ".\Injector.exe" %PID% "%DLL_PATH%"
".\Injector.exe" %PID% "%DLL_PATH%"

echo.
echo Injection command completed with exit code: %errorlevel%
echo.

echo Checking if process is still running...
tasklist /FI "PID eq %PID%" /FO TABLE
echo.

echo Waiting for log file...
timeout /t 5 /nobreak

if exist "C:\temp\com_hook_log.txt" (
    echo Log file found!
    echo Contents:
    type "C:\temp\com_hook_log.txt"
) else (
    echo Log file not found at C:\temp\com_hook_log.txt
)

:End
echo.
echo === Injection Process Complete ===
pause
endlocal 