@echo off
setlocal enabledelayedexpansion

:: --- Configuration ---
set "TARGET_PROCESS_NAME=java.exe"
set "TARGET_COM_PORT=COM8"          REM <--- CHANGE THIS to your virtual COM port (e.g., COM5, COM10)
set "HOOK_DLL_PATH=%~dp0Interceptor.dll" REM Path to the DLL we just compiled
set "INJECTOR_EXE=C:\Users\manfr\Downloads\hook\Injector.exe"     REM <--- CHANGE THIS to the name/path of your injector tool
set "HANDLE_EXE=%~dp0handle.exe"     REM <--- CHANGE THIS if handle.exe is not in PATH or named differently
:: --- End Configuration ---

echo === Debug Info ===
echo Current Directory: %CD%
echo HOOK_DLL_PATH: %HOOK_DLL_PATH%
echo INJECTOR_EXE: %INJECTOR_EXE%
echo HANDLE_EXE: %HANDLE_EXE%

echo Checking if handle.exe exists...
if not exist "%HANDLE_EXE%" (
    echo ERROR: handle.exe not found at "%HANDLE_EXE%".
    goto End
)

echo Checking if Injector.exe exists...
if not exist "%INJECTOR_EXE%" (
    echo ERROR: Injector.exe not found at "%INJECTOR_EXE%".
    goto End
)

echo Checking if Interceptor.dll exists...
if not exist "%HOOK_DLL_PATH%" (
    echo ERROR: Interceptor.dll not found at "%HOOK_DLL_PATH%".
    goto End
)

echo Searching for %TARGET_PROCESS_NAME% using %TARGET_COM_PORT%...

:: Construct the NT Device Path (handle.exe often prefers this)
set "NT_DEVICE_PATH=\Device\Serial%TARGET_COM_PORT:~3%" REM Extracts the number after "COM"
echo NT_DEVICE_PATH: %NT_DEVICE_PATH%

echo Running handle.exe with NT device path...
echo Command: %HANDLE_EXE% -a "%NT_DEVICE_PATH%" 2^>nul
"%HANDLE_EXE%" -a "%NT_DEVICE_PATH%" 2>nul | findstr /i "%TARGET_PROCESS_NAME%"
echo Handle.exe with NT device path returned: %errorlevel%

:: Use handle.exe to find the process holding the handle
set "TARGET_PID="
for /f "tokens=1,2,3,*" %%a in ('%HANDLE_EXE% -a "%NT_DEVICE_PATH%" 2^>nul ^| findstr /i /c:"%TARGET_PROCESS_NAME%"') do (
    echo Found potential match: %%a %%b %%c %%d
    set "PID_LINE=%%c"
    REM Basic check if the 3rd token looks like a PID (numeric)
    echo !PID_LINE! | findstr /r /c:"^[0-9][0-9]*$" > nul
    if !errorlevel! == 0 (
        set "TARGET_PID=%%c"
        echo Found %TARGET_PROCESS_NAME% PID: !TARGET_PID! using handle for %NT_DEVICE_PATH%
        goto FoundPID
    ) else (
        echo Skipping line, token '%%c' is not a PID.
    )
)

:: Fallback: Try searching with the DOS device name if NT path failed
echo Did not find PID using %NT_DEVICE_PATH%. Trying %TARGET_COM_PORT%...
echo Running handle.exe with COM port name...
echo Command: %HANDLE_EXE% -a "%TARGET_COM_PORT%" 2^>nul
"%HANDLE_EXE%" -a "%TARGET_COM_PORT%" 2>nul | findstr /i "%TARGET_PROCESS_NAME%"
echo Handle.exe with COM port name returned: %errorlevel%

for /f "tokens=1,2,3,*" %%a in ('%HANDLE_EXE% -a "%TARGET_COM_PORT%" 2^>nul ^| findstr /i /c:"%TARGET_PROCESS_NAME%"') do (
    echo Found potential match: %%a %%b %%c %%d
    set "PID_LINE=%%c"
    echo !PID_LINE! | findstr /r /c:"^[0-9][0-9]*$" > nul
    if !errorlevel! == 0 (
        set "TARGET_PID=%%c"
        echo Found %TARGET_PROCESS_NAME% PID: !TARGET_PID! using handle for %TARGET_COM_PORT%
        goto FoundPID
    ) else (
        echo Skipping line, token '%%c' is not a PID.
    )
)

:: Last resort: try searching for any COM port
echo Did not find PID using specific COM port. Trying to find any java.exe process with COM ports...
echo Command: %HANDLE_EXE% -a java.exe 2^>nul
"%HANDLE_EXE%" -a "java.exe" 2>nul | findstr /i "COM"
echo Handle.exe with java.exe process returned: %errorlevel%


:NotFound
echo ERROR: Could not find PID for %TARGET_PROCESS_NAME% using %TARGET_COM_PORT%.
echo Make sure the application is running and using the COM port.
echo Make sure %HANDLE_EXE% is accessible.
goto End

:FoundPID
if not defined TARGET_PID (
    goto NotFound
)

echo Injecting %HOOK_DLL_PATH% into PID %TARGET_PID%...

:: Check if DLL exists
if not exist "%HOOK_DLL_PATH%" (
    echo ERROR: Hook DLL not found at "%HOOK_DLL_PATH%"
    goto End
)

:: Check if Injector exists
if not exist "%INJECTOR_EXE%" (
    echo ERROR: Injector tool not found at "%INJECTOR_EXE%"
    echo Please provide a command-line DLL injector.
    goto End
)

:: Execute the injector
echo Running injector command: "%INJECTOR_EXE%" %TARGET_PID% "%HOOK_DLL_PATH%"
"%INJECTOR_EXE%" %TARGET_PID% "%HOOK_DLL_PATH%"

if !errorlevel! == 0 (
    echo Injection command executed successfully. Check logs at C:\temp\com_hook_log.txt
) else (
    echo Injection command failed with error code !errorlevel!
)

:End
echo.
pause
endlocal 
