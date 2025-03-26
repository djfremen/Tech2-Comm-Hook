@echo off
set OUTPUT_DIR=build
set OUTPUT_NAME=TestInterceptor.x86.dll

if not exist %OUTPUT_DIR% mkdir %OUTPUT_DIR%

echo Checking for available compilers...

:: Try with cl.exe (MSVC)
where cl.exe >nul 2>nul
if %ERRORLEVEL% equ 0 goto use_cl

:: Try with gcc (MinGW)
where gcc.exe >nul 2>nul
if %ERRORLEVEL% equ 0 goto use_gcc

echo ERROR: No compiler found. Please install Visual Studio or MinGW.
exit /b 1

:use_cl
echo Using MSVC compiler...
cl.exe /nologo /MD /LD /EHsc src/test_hook.cpp /Fe%OUTPUT_DIR%\%OUTPUT_NAME% /link /SUBSYSTEM:WINDOWS /DLL
goto check_result

:use_gcc
echo Using GCC compiler...
gcc -shared -o %OUTPUT_DIR%\%OUTPUT_NAME% src/test_hook.cpp -luser32
goto check_result

:check_result
if %ERRORLEVEL% neq 0 (
    echo ERROR: Compilation failed with error code %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo Compilation successful: %OUTPUT_DIR%\%OUTPUT_NAME% 