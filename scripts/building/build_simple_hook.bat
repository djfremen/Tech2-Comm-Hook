@echo off
echo Building Simple Hook DLL (32-bit)

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
    echo ERROR: Could not find Build Tools at D:\buildtools\VC\Auxiliary\Build\vcvars32.bat
    echo Please ensure the build tools are installed.
    goto end
)

echo Cleaning build directory...
if not exist build mkdir build
del /Q build\SimpleHook.x86.dll 2>nul

echo Compiling Simple Hook DLL (32-bit)...
:: A very simple compilation with minimal dependencies
cl.exe /nologo /MD /LD /EHsc src\simple_hook.cpp /Fe"build\SimpleHook.x86.dll" /link /SUBSYSTEM:WINDOWS /DLL

if %ERRORLEVEL% neq 0 (
    echo ERROR: Compilation failed with error code %ERRORLEVEL%
    goto end
)

echo Compilation successful!
echo DLL created: build\SimpleHook.x86.dll

:: Create an injection script for the simple DLL
echo Creating test injection script...
echo @echo off > test_simple_inject.bat
echo echo Testing Simple DLL Injection >> test_simple_inject.bat
echo. >> test_simple_inject.bat
echo :: Delete any existing log file >> test_simple_inject.bat
echo if exist C:\temp\com_hook_log.txt del C:\temp\com_hook_log.txt >> test_simple_inject.bat
echo. >> test_simple_inject.bat
echo :: Find Java process >> test_simple_inject.bat
echo for /f "tokens=2" %%%%i in ('tasklist /fi "imagename eq javaw.exe" /fo list ^| find "PID:"') do ( >> test_simple_inject.bat
echo     set JAVAPID=%%%%i >> test_simple_inject.bat
echo     echo Found Java process with PID: %%%%i >> test_simple_inject.bat
echo ) >> test_simple_inject.bat
echo. >> test_simple_inject.bat
echo if "%%JAVAPID%%"=="" ( >> test_simple_inject.bat
echo     echo No Java process found! >> test_simple_inject.bat
echo     goto end >> test_simple_inject.bat
echo ) >> test_simple_inject.bat
echo. >> test_simple_inject.bat
echo :: Inject the simple DLL >> test_simple_inject.bat
echo echo Injecting Simple DLL into process %%JAVAPID%%... >> test_simple_inject.bat
echo Injector.x86.exe %%JAVAPID%% build\SimpleHook.x86.dll >> test_simple_inject.bat
echo set RESULT=%%ERRORLEVEL%% >> test_simple_inject.bat
echo. >> test_simple_inject.bat
echo echo Injection completed with return code: %%RESULT%% >> test_simple_inject.bat
echo if %%RESULT%% equ 0 ( >> test_simple_inject.bat
echo     echo Injection successful >> test_simple_inject.bat
echo ) else ( >> test_simple_inject.bat
echo     echo Injection failed with code %%RESULT%% >> test_simple_inject.bat
echo ) >> test_simple_inject.bat
echo. >> test_simple_inject.bat
echo :: Check if log file was created >> test_simple_inject.bat
echo timeout /t 2 ^> nul >> test_simple_inject.bat
echo if exist C:\temp\com_hook_log.txt ( >> test_simple_inject.bat
echo     echo Log file created! DLL successfully loaded and executed. >> test_simple_inject.bat
echo     type C:\temp\com_hook_log.txt >> test_simple_inject.bat
echo ) else ( >> test_simple_inject.bat
echo     echo No log file found. DLL did not attach or could not create log. >> test_simple_inject.bat
echo ) >> test_simple_inject.bat
echo. >> test_simple_inject.bat
echo :end >> test_simple_inject.bat
echo pause >> test_simple_inject.bat

echo Test injection script created: test_simple_inject.bat

:end
pause 