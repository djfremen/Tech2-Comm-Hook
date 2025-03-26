@echo off
setlocal enabledelayedexpansion
echo Building MinHook Library (32-bit)

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

:: Set paths
set "MINHOOK_SRC=lib\minhook-master\minhook-master"
set "MINHOOK_INC=%MINHOOK_SRC%\include"
set "MINHOOK_SRC_DIR=%MINHOOK_SRC%\src"
set "OUTPUT_DIR=vendor\minhook\lib"
set "OUTPUT_LIB=MinHook.x86.lib"

:: Create vendor directory if needed
if not exist vendor\minhook\include mkdir vendor\minhook\include
if not exist vendor\minhook\lib mkdir vendor\minhook\lib

:: Check if MinHook source exists
if not exist "%MINHOOK_SRC%" (
    echo ERROR: MinHook source not found at %MINHOOK_SRC%
    goto End
)

:: Check if MinHook.h exists
if not exist "%MINHOOK_INC%\MinHook.h" (
    echo ERROR: MinHook.h not found at %MINHOOK_INC%
    goto End
)

:: Copy MinHook.h to vendor include directory
echo Copying MinHook.h to vendor include directory...
copy /Y "%MINHOOK_INC%\MinHook.h" vendor\minhook\include\

:: Find all C files in MinHook source
echo Finding MinHook source files...
set "SRC_FILES="
for /r "%MINHOOK_SRC_DIR%" %%F in (*.c) do (
    set "SRC_FILES=!SRC_FILES! "%%F""
)

:: Check if we found any source files
if "%SRC_FILES%"=="" (
    echo ERROR: No source files found in %MINHOOK_SRC_DIR%
    goto End
)

echo Found MinHook source files.

:: Compile MinHook library
echo Compiling MinHook library for x86...
cl.exe /nologo /c /EHsc /MD /O2 /I"%MINHOOK_INC%" %SRC_FILES%

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to compile MinHook source files.
    goto End
)

:: Create library
echo Creating MinHook.x86.lib...
lib.exe /nologo /OUT:"%OUTPUT_DIR%\%OUTPUT_LIB%" *.obj

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to create MinHook library.
    goto End
)

:: Clean up object files
echo Cleaning up temporary files...
del *.obj

echo Successfully built MinHook library: %OUTPUT_DIR%\%OUTPUT_LIB%

:End
endlocal
pause 