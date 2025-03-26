@echo off
setlocal enabledelayedexpansion
echo COM Port Hook - Build Script for Hook DLL and Injector

:: Check if we're in the correct directory
if not exist src (
    echo ERROR: This script must be run from the project root directory.
    goto end
)

:: Set MSVC environment variables for D: drive build tools
set VCVARS_PATH="D:\buildtools\VC\Auxiliary\Build\vcvars32.bat"
if exist %VCVARS_PATH% (
    echo Setting up build environment from D:\buildtools...
    call %VCVARS_PATH%
) else (
    echo WARNING: Could not find Build Tools at D:\buildtools, trying system default...
    where cl.exe >nul 2>nul
    if %ERRORLEVEL% neq 0 (
        echo ERROR: Could not find cl.exe in path.
        echo Please ensure Visual Studio or Build Tools are installed and run from a Developer Command Prompt.
        goto end
    )
)

:: Set build configuration
set TARGET_ARCH=x86
set LOG_PATH=C:\temp\com_hook_log.txt

:: Create directories
echo Setting up directories...
if not exist build mkdir build
if not exist tools mkdir tools
if not exist C:\temp mkdir C:\temp 2>nul

::-------------------------
:: Build MinHook First
::-------------------------
echo.
echo --------------------------------------
echo Building MinHook Library (Required Dependency)...
echo --------------------------------------

:: Check if MinHook.x86.lib already exists
if exist vendor\minhook\lib\MinHook.x86.lib (
    echo MinHook library already exists - skipping build
) else (
    echo Building MinHook library...
    call scripts\building\build_minhook.bat
    
    :: Check if MinHook build was successful
    if not exist vendor\minhook\lib\MinHook.x86.lib (
        echo ERROR: MinHook library build failed. Cannot continue.
        goto end
    )
)

::-------------------------
:: Build the Hook DLL
::-------------------------
echo.
echo --------------------------------------
echo Compiling Interceptor DLL (32-bit)...
echo --------------------------------------

:: Clean previous output
del /Q build\Interceptor.%TARGET_ARCH%.dll 2>nul

:: Check for the MinHook library
if not exist vendor\minhook\lib\MinHook.%TARGET_ARCH%.lib (
    echo ERROR: MinHook library not found at vendor\minhook\lib\MinHook.%TARGET_ARCH%.lib
    echo Please ensure MinHook library is available.
    goto EndDllCompile
)

:: Compile DLL
cl.exe /nologo /MD /LD /EHsc /I"vendor\minhook\include" src\hook.cpp vendor\minhook\lib\MinHook.%TARGET_ARCH%.lib /Fe"build\Interceptor.%TARGET_ARCH%.dll" /link /SUBSYSTEM:WINDOWS /DLL

if %ERRORLEVEL% neq 0 (
    echo ERROR: Hook DLL compilation failed with error code %ERRORLEVEL%
    goto EndDllCompile
)

echo Successfully compiled build\Interceptor.%TARGET_ARCH%.dll

:EndDllCompile

::-------------------------
:: Build the Injector
::-------------------------
echo.
echo --------------------------------------
echo Compiling Injector (injector.cpp)...
echo --------------------------------------

:: Clean previous output
del /Q tools\Injector.%TARGET_ARCH%.exe 2>nul

:: Compile Injector
cl.exe /nologo /EHsc /MD src\injector.cpp /Fe"tools\Injector.%TARGET_ARCH%.exe" /link kernel32.lib user32.lib advapi32.lib

if %ERRORLEVEL% neq 0 (
    echo ERROR: Injector compilation failed with error code %ERRORLEVEL%
    goto end
)

echo Successfully compiled tools\Injector.%TARGET_ARCH%.exe

::-------------------------
:: Create injection test script
::-------------------------
echo.
echo --------------------------------------
echo Creating test injection script...
echo --------------------------------------

set INJECT_SCRIPT=scripts\injection\inject_hook.bat

echo @echo off > %INJECT_SCRIPT%
echo :: COM Port Hook DLL Injection Script >> %INJECT_SCRIPT%
echo echo COM Port Interceptor Injection >> %INJECT_SCRIPT%
echo. >> %INJECT_SCRIPT%
echo :: Check for admin privileges >> %INJECT_SCRIPT%
echo net session >nul 2>nul >> %INJECT_SCRIPT%
echo if %%ERRORLEVEL%% neq 0 ( >> %INJECT_SCRIPT%
echo     echo WARNING: This script is not running with administrator privileges. >> %INJECT_SCRIPT%
echo     echo Injection may fail if target process has higher privileges. >> %INJECT_SCRIPT%
echo     echo Consider running as administrator. >> %INJECT_SCRIPT%
echo     echo. >> %INJECT_SCRIPT%
echo ) >> %INJECT_SCRIPT%
echo. >> %INJECT_SCRIPT%
echo :: Check if log directory exists >> %INJECT_SCRIPT%
echo if not exist C:\temp mkdir C:\temp 2>nul >> %INJECT_SCRIPT%
echo. >> %INJECT_SCRIPT%
echo :: Clear previous log file >> %INJECT_SCRIPT%
echo if exist %LOG_PATH% del %LOG_PATH% >> %INJECT_SCRIPT%
echo echo Log file will be created at: %LOG_PATH% >> %INJECT_SCRIPT%
echo. >> %INJECT_SCRIPT%
echo if "%%1"=="" ( >> %INJECT_SCRIPT%
echo     :: No PID specified, offer process selection >> %INJECT_SCRIPT%
echo     echo No process ID specified. >> %INJECT_SCRIPT%
echo     echo. >> %INJECT_SCRIPT%
echo     echo Please enter the PID of the process to inject into, >> %INJECT_SCRIPT%
echo     echo or leave blank to see a list of processes: >> %INJECT_SCRIPT%
echo     set /p PID="Process ID: " >> %INJECT_SCRIPT%
echo. >> %INJECT_SCRIPT%
echo     if "%%PID%%"=="" ( >> %INJECT_SCRIPT%
echo         :: Show process list using tasklist >> %INJECT_SCRIPT%
echo         echo. >> %INJECT_SCRIPT%
echo         echo Available processes: >> %INJECT_SCRIPT%
echo         tasklist /fi "sessionname eq console" >> %INJECT_SCRIPT%
echo         echo. >> %INJECT_SCRIPT%
echo         echo Please restart the script and provide a PID. >> %INJECT_SCRIPT%
echo         goto end >> %INJECT_SCRIPT%
echo     ) >> %INJECT_SCRIPT%
echo ) else ( >> %INJECT_SCRIPT%
echo     :: Use the specified PID >> %INJECT_SCRIPT%
echo     set PID=%%1 >> %INJECT_SCRIPT%
echo ) >> %INJECT_SCRIPT%
echo. >> %INJECT_SCRIPT%
echo :: Confirm the PID is a number >> %INJECT_SCRIPT%
echo set "INVALIDCHARS=false" >> %INJECT_SCRIPT%
echo for /f "delims=0123456789" %%%%i in ("%%PID%%") do set "INVALIDCHARS=true" >> %INJECT_SCRIPT%
echo if "%%INVALIDCHARS%%"=="true" ( >> %INJECT_SCRIPT%
echo     echo ERROR: Invalid PID specified. PID must be a number. >> %INJECT_SCRIPT%
echo     goto end >> %INJECT_SCRIPT%
echo ) >> %INJECT_SCRIPT%
echo. >> %INJECT_SCRIPT%
echo :: Find process name for the given PID >> %INJECT_SCRIPT%
echo for /f "tokens=1,2 usebackq" %%%%a in (`tasklist /FI "PID eq %%PID%%" /FO list ^| findstr /B "Image Name:"`) do ( >> %INJECT_SCRIPT%
echo     set PROCESS_NAME=%%%%b >> %INJECT_SCRIPT%
echo ) >> %INJECT_SCRIPT%
echo. >> %INJECT_SCRIPT%
echo if "%%PROCESS_NAME%%"=="" ( >> %INJECT_SCRIPT%
echo     echo ERROR: No process found with PID %%PID%% >> %INJECT_SCRIPT%
echo     goto end >> %INJECT_SCRIPT%
echo ) >> %INJECT_SCRIPT%
echo. >> %INJECT_SCRIPT%
echo echo Target process: %%PROCESS_NAME%% (PID: %%PID%%) >> %INJECT_SCRIPT%
echo echo. >> %INJECT_SCRIPT%
echo echo About to inject COM port hook DLL into this process. >> %INJECT_SCRIPT%
echo echo This will log all COM port communications to %LOG_PATH% >> %INJECT_SCRIPT%
echo echo. >> %INJECT_SCRIPT%
echo set /p CONFIRM="Continue? (Y/N): " >> %INJECT_SCRIPT%
echo if /i not "%%CONFIRM%%"=="Y" goto end >> %INJECT_SCRIPT%
echo. >> %INJECT_SCRIPT%
echo :: Execute the injector >> %INJECT_SCRIPT%
echo echo Executing DLL Injection... >> %INJECT_SCRIPT%
echo tools\Injector.%TARGET_ARCH%.exe %%PID%% build\Interceptor.%TARGET_ARCH%.dll >> %INJECT_SCRIPT%
echo. >> %INJECT_SCRIPT%
echo if %%ERRORLEVEL%% neq 0 ( >> %INJECT_SCRIPT%
echo     echo ERROR: Injection failed with code %%ERRORLEVEL%% >> %INJECT_SCRIPT%
echo ) else ( >> %INJECT_SCRIPT%
echo     echo Injection command completed successfully. >> %INJECT_SCRIPT%
echo     echo. >> %INJECT_SCRIPT%
echo     echo To verify if the hook is working: >> %INJECT_SCRIPT%
echo     echo 1. Use the target application to perform COM port operations >> %INJECT_SCRIPT%
echo     echo 2. Check the log file at %LOG_PATH% >> %INJECT_SCRIPT%
echo     echo. >> %INJECT_SCRIPT%
echo     :: Check if log file exists after a short delay >> %INJECT_SCRIPT%
echo     timeout /t 3 >nul >> %INJECT_SCRIPT%
echo     if exist %LOG_PATH% ( >> %INJECT_SCRIPT%
echo         echo Log file detected! Showing the first few lines: >> %INJECT_SCRIPT%
echo         echo ---------------------------------------- >> %INJECT_SCRIPT%
echo         type %LOG_PATH% | find /v "" /c > temp.txt >> %INJECT_SCRIPT%
echo         set /p LINECOUNT=<temp.txt >> %INJECT_SCRIPT%
echo         del temp.txt >> %INJECT_SCRIPT%
echo         echo Total lines in log: %%LINECOUNT%% >> %INJECT_SCRIPT%
echo         echo. >> %INJECT_SCRIPT%
echo         type %LOG_PATH% | find "" /n | findstr "^\[1-10\]" >> %INJECT_SCRIPT%
echo         echo ---------------------------------------- >> %INJECT_SCRIPT%
echo     ) else ( >> %INJECT_SCRIPT%
echo         echo Log file not yet created. >> %INJECT_SCRIPT%
echo         echo This could be normal if no COM port activity has occurred yet. >> %INJECT_SCRIPT%
echo     ) >> %INJECT_SCRIPT%
echo ) >> %INJECT_SCRIPT%
echo. >> %INJECT_SCRIPT%
echo :end >> %INJECT_SCRIPT%
echo pause >> %INJECT_SCRIPT%

echo.
echo Injection script created at: %INJECT_SCRIPT%
echo.
echo Build process completed.
echo DLL compiled to: build\Interceptor.%TARGET_ARCH%.dll
echo Injector compiled to: tools\Injector.%TARGET_ARCH%.exe
echo.
echo To inject the DLL, run scripts\injection\inject_hook.bat [optional_PID]

:end
endlocal
pause 