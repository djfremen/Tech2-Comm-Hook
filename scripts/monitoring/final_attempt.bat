@echo off
title Final DLL Injection Attempt
color 0E

:: Configuration 
set PID=6068
set DLL_PATH=C:\temp\Interceptor.x86.dll
set ORIGINAL_DLL=Interceptor.x86.dll
set INJECTOR=Injector.x86.exe
set LOG_FILE=C:\temp\com_hook_log.txt

echo ========================================================
echo  FINAL DLL INJECTION ATTEMPT (PID: %PID%)
echo ========================================================
echo.

:: Create C:\temp directory if it doesn't exist
if not exist "C:\temp" (
    echo Creating C:\temp directory...
    mkdir "C:\temp"
)

:: Copy DLL to temp directory for reliable path
if not exist "%DLL_PATH%" (
    echo Copying DLL to C:\temp...
    copy "%ORIGINAL_DLL%" "C:\temp\" /Y
)

:: Verify files exist
if not exist "%INJECTOR%" (
    echo ERROR: Injector not found: %INJECTOR%
    goto error
)

if not exist "%DLL_PATH%" (
    echo ERROR: DLL not found: %DLL_PATH%
    goto error
)

:: Verify process exists
tasklist /fi "pid eq %PID%" | find "%PID%" > nul
if %errorlevel% neq 0 (
    echo ERROR: Process with PID %PID% not found.
    goto error
)

:: Delete old log file if it exists
if exist "%LOG_FILE%" (
    echo Deleting old log file...
    del "%LOG_FILE%"
)

echo Running injection command with maximum verbosity...
echo.
echo Command: %INJECTOR% %PID% "%DLL_PATH%"
echo.

%INJECTOR% %PID% "%DLL_PATH%"
set RESULT=%errorlevel%

echo.
echo Return code: %RESULT%
echo.

if %RESULT% equ 0 (
    echo Injection appears to be successful!
) else (
    echo WARNING: Injection returned non-zero exit code.
    echo This might indicate an error, but we'll continue to check for the log file.
)

echo.
echo Checking for log file creation...
echo.

set COUNT=1
:check_log
if %COUNT% gtr 10 goto no_log

if exist "%LOG_FILE%" (
    echo Log file found! Content:
    echo --------------------------------------------------------
    type "%LOG_FILE%"
    echo --------------------------------------------------------
    goto success
)

echo Waiting for log file (attempt %COUNT% of 10)...
timeout /t 1 > nul
set /a COUNT+=1
goto check_log

:no_log
echo Log file not created after 10 attempts.
echo.
echo ADDITIONAL DEBUGGING:
echo.

echo 1. Checking with handle.exe (if available):
if exist "handle.exe" (
    handle.exe -p %PID% | find "Interceptor" 
    if %errorlevel% equ 0 (
        echo DLL appears to be loaded in process!
    ) else (
        echo DLL not found in process handles.
    )
)

echo.
echo 2. Checking javaw process location:
wmic process where processid=%PID% get executablepath

echo.
echo 3. Checking security settings:
whoami /priv

goto end

:success
echo.
echo SUCCESS! The DLL appears to be loaded and COM hook is working.
echo.
echo To continuously monitor COM port traffic, use:
echo powershell -Command "Get-Content -Path '%LOG_FILE%' -Wait"
goto end

:error
echo.
echo ERROR: One or more prerequisites not met.
echo Please check the error messages above.

:end
echo.
echo Press any key to exit...
pause >nul 