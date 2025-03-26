@echo off
setlocal enabledelayedexpansion

echo === 32-bit DLL Injection for Java Process ===

:: Check if the DLL exists
if not exist "Interceptor.x86.dll" (
    echo ERROR: Interceptor.x86.dll not found in the current directory.
    echo Please run build_x86.bat first to create the 32-bit DLL.
    goto End
)

:: Check if Injector exists
if not exist "Injector.x86.exe" (
    echo ERROR: Injector.x86.exe not found in the current directory.
    echo Please run build_x86.bat first to create the 32-bit injector.
    goto End
)

:: Create C:\temp directory if it doesn't exist
if not exist "C:\temp" (
    echo Creating C:\temp directory for logging...
    mkdir "C:\temp"
    
    if errorlevel 1 (
        echo ERROR: Failed to create C:\temp directory. Please run as administrator.
        goto End
    )
)

:: Check if temp directory is writable
echo Testing write access to C:\temp...
echo test > "C:\temp\test_write.txt"
if errorlevel 1 (
    echo ERROR: Cannot write to C:\temp directory. Please check permissions.
    goto End
) else (
    del "C:\temp\test_write.txt"
    echo C:\temp directory is writable.
)

:: Get PID for Java process
echo.
echo Attempting to locate Java processes...
tasklist /fi "imagename eq javaw.exe" /fo list

set /p PID=Enter the PID of the Java process (from above list): 

:: Validate PID input
set "NUMERIC=1234567890"
set "VALID=true"
for /L %%i in (0,1,%PID:~0,-1%) do (
    set "CHAR=!PID:~%%i,1!"
    set "FOUND=false"
    for /L %%j in (0,1,9) do (
        if "!CHAR!"=="!NUMERIC:~%%j,1!" (
            set "FOUND=true"
            goto :nextChar
        )
    )
    :nextChar
    if "!FOUND!"=="false" set "VALID=false"
)

if "!VALID!"=="false" (
    echo ERROR: Invalid PID format. Please enter a valid number.
    goto End
)

:: Check if PID exists
tasklist /fi "pid eq %PID%" | find "%PID%" > nul
if errorlevel 1 (
    echo ERROR: No process with PID %PID% found.
    goto End
)

:: If log file exists, delete it first
if exist "C:\temp\com_hook_log.txt" (
    echo Removing previous log file...
    del "C:\temp\com_hook_log.txt"
)

:: Get the absolute path to the DLL
set "CURRENT_DIR=%~dp0"
set "DLL_PATH=%CURRENT_DIR%Interceptor.x86.dll"

echo.
echo === Injection Information ===
echo Target Process ID: %PID%
echo DLL to inject: %DLL_PATH%
echo Log file: C:\temp\com_hook_log.txt
echo.

:: Inject the DLL
echo Injecting 32-bit DLL into process with PID %PID%...
echo Command: "%CURRENT_DIR%Injector.x86.exe" %PID% "%DLL_PATH%"

"%CURRENT_DIR%Injector.x86.exe" %PID% "%DLL_PATH%"

:: Check injection result
if errorlevel 1 (
    echo.
    echo ERROR: DLL injection failed with exit code !errorlevel!
    goto End
) else (
    echo.
    echo DLL injection completed. Return code: !errorlevel!
)

:: Wait and check for log file
echo.
echo Waiting for log file to be created (5 seconds)...
timeout /t 5 /nobreak > nul

if exist "C:\temp\com_hook_log.txt" (
    echo Log file created successfully!
    echo.
    echo === First 10 lines of log file: ===
    type "C:\temp\com_hook_log.txt" | findstr /n "." | findstr /b "[1-9]" | findstr /b "[1-9][0-9]" /v
    echo.
    echo To monitor the log file continuously, run:
    echo     type "C:\temp\com_hook_log.txt"
) else (
    echo WARNING: Log file was not created within the timeout period.
    echo This might indicate that:
    echo  - The DLL was not successfully loaded
    echo  - The hooked functions have not been called yet
    echo  - There might be permission issues with the C:\temp directory
    echo.
    echo Try using Process Explorer to confirm if the DLL is loaded in the target process.
)

:End
echo.
pause
endlocal 