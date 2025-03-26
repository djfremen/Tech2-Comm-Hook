@echo off
setlocal enabledelayedexpansion

echo === Building MinHook Library ===

:: Set paths
set "MINHOOK_SRC=minhook-master\minhook-master"
set "MINHOOK_INC=minhook-master\minhook-master\include"
set "MINHOOK_SRC_DIR=minhook-master\minhook-master\src"
set "OUTPUT_DIR=."
set "OUTPUT_LIB=MinHook.x64.lib"

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

:: Create output folder if needed
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

:: Find all C/CPP files in MinHook source
set "SRC_FILES="
for /r "%MINHOOK_SRC_DIR%" %%F in (*.c) do (
    set "SRC_FILES=!SRC_FILES! "%%F""
)

:: Check if we found any source files
if "%SRC_FILES%"=="" (
    echo ERROR: No source files found in %MINHOOK_SRC_DIR%
    goto End
)

echo Found source files.

:: Find Visual Studio - First check D:\buildtools as we found it there earlier
set "VCVARSALL="

if exist "D:\buildtools\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=D:\buildtools\VC\Auxiliary\Build\vcvarsall.bat"
)

if not defined VCVARSALL (
    echo ERROR: Could not find Visual Studio vcvarsall.bat. Please make sure Visual Studio is installed.
    goto End
)

echo Found Visual Studio environment at: %VCVARSALL%

:: Set up environment for x64 architecture
echo Setting up Visual Studio environment for x64...
call "%VCVARSALL%" x64
if errorlevel 1 (
    echo ERROR: Failed to initialize Visual Studio environment.
    goto End
)

:: Compile MinHook library
echo Compiling MinHook library...
cl.exe /c /EHsc /MD /O2 /I"%MINHOOK_INC%" %SRC_FILES%

:: Check if compilation was successful
if errorlevel 1 (
    echo ERROR: Failed to compile MinHook source files.
    goto End
)

:: Create library
echo Creating library...
lib.exe /OUT:"%OUTPUT_DIR%\%OUTPUT_LIB%" *.obj

:: Check if library creation was successful
if errorlevel 1 (
    echo ERROR: Failed to create MinHook library.
    goto End
)

:: Clean up object files
echo Cleaning up...
del *.obj

echo Successfully built MinHook library: %OUTPUT_DIR%\%OUTPUT_LIB%

:End
echo.
pause
endlocal 