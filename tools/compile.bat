@echo off
setlocal

:: --- Configuration ---
set "SOURCE_FILE=hook.cpp"
set "OUTPUT_DLL=Interceptor.dll"
set "TARGET_ARCH=x64"
set "MINHOOK_INC_DIR=."
set "MINHOOK_LIB_DIR=."
set "MINHOOK_LIB=MinHook.x64.lib"

:: Check if cl.exe is in PATH
where cl.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo Found cl.exe in PATH
    goto CompileWithCL
)

:: If we're in a Developer Command Prompt, we should have VSINSTALLDIR defined
if defined VSINSTALLDIR (
    echo Already in a Developer Command Prompt environment
    goto CompileWithCL
)

:: Not running in the correct environment
echo ===============================================================
echo ERROR: Visual Studio compiler (cl.exe) not found.
echo ===============================================================
echo.
echo This script requires Visual Studio with C++ development tools.
echo You have two options:
echo.
echo 1. Install Visual Studio with C++ desktop development workload:
echo    - Download from https://visualstudio.microsoft.com/downloads/
echo    - During installation, select "Desktop development with C++"
echo.
echo 2. Install only the Build Tools (smaller download):
echo    - Download from https://visualstudio.microsoft.com/visual-cpp-build-tools/
echo    - During installation, select "C++ build tools"
echo.
echo After installation, you should run this script from the
echo "Developer Command Prompt for VS" shortcut in the Start Menu.
echo.
echo ===============================================================
goto End

:CompileWithCL
:: --- Check for Source and Lib Files ---
if not exist "%SOURCE_FILE%" (
    echo ERROR: Source file "%SOURCE_FILE%" not found.
    goto End
)

if not exist "%MINHOOK_LIB%" (
    echo ERROR: MinHook library "%MINHOOK_LIB%" not found.
    echo Make sure MinHook is built and the library file is in the correct directory.
    goto End
)

:: --- Compile with cl.exe ---
echo Compiling %SOURCE_FILE% for %TARGET_ARCH% using cl.exe...

cl.exe /EHsc /MD /LD /Fe"%OUTPUT_DLL%" "%SOURCE_FILE%" /I"%MINHOOK_INC_DIR%" /link "%MINHOOK_LIB%" user32.lib

if errorlevel 1 (
    echo ERROR: Compilation failed.
    goto End
)

echo Successfully compiled "%OUTPUT_DLL%".

:End
echo.
pause
endlocal