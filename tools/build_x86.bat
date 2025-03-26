@echo off
setlocal enabledelayedexpansion

echo === Building 32-bit MinHook Library and Interceptor.dll ===

:: Try to find the same Visual Studio installation that we used before
set "VCVARSALL="

if exist "D:\buildtools\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=D:\buildtools\VC\Auxiliary\Build\vcvarsall.bat"
)

if not defined VCVARSALL (
    echo ERROR: Could not find Visual Studio vcvarsall.bat. Please make sure Visual Studio is installed.
    goto End
)

echo Found Visual Studio environment at: %VCVARSALL%

:: Set up environment for x86 architecture (32-bit)
echo Setting up Visual Studio environment for x86 (32-bit)...
call "%VCVARSALL%" x86
if errorlevel 1 (
    echo ERROR: Failed to initialize Visual Studio environment.
    goto End
)

:: Build 32-bit MinHook library
echo === Building 32-bit MinHook Library ===

:: Set paths
set "MINHOOK_SRC=minhook-master\minhook-master"
set "MINHOOK_INC=minhook-master\minhook-master\include"
set "MINHOOK_SRC_DIR=minhook-master\minhook-master\src"
set "OUTPUT_DIR=."
set "OUTPUT_LIB=MinHook.x86.lib"

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

:: Compile MinHook library for x86
echo Compiling MinHook library for x86...
cl.exe /c /EHsc /MD /O2 /I"%MINHOOK_INC%" %SRC_FILES%

:: Check if compilation was successful
if errorlevel 1 (
    echo ERROR: Failed to compile MinHook source files.
    goto End
)

:: Create library
echo Creating 32-bit library...
lib.exe /OUT:"%OUTPUT_DIR%\%OUTPUT_LIB%" *.obj

:: Check if library creation was successful
if errorlevel 1 (
    echo ERROR: Failed to create MinHook library.
    goto End
)

:: Clean up object files
echo Cleaning up...
del *.obj

echo Successfully built 32-bit MinHook library: %OUTPUT_DIR%\%OUTPUT_LIB%

:: Now compile the Interceptor.dll for 32-bit
echo === Building 32-bit Interceptor.dll ===

:: Copy MinHook.h to the current directory if not already there
if not exist "MinHook.h" (
    copy "%MINHOOK_INC%\MinHook.h" .
)

:: Set paths for the hook DLL
set "SOURCE_FILE=hook.cpp"
set "OUTPUT_DLL=Interceptor.x86.dll"
set "MINHOOK_INC_DIR=."
set "MINHOOK_LIB=MinHook.x86.lib"

:: Check for Source and Lib Files
if not exist "%SOURCE_FILE%" (
    echo ERROR: Source file "%SOURCE_FILE%" not found.
    goto End
)

if not exist "%MINHOOK_LIB%" (
    echo ERROR: MinHook library "%MINHOOK_LIB%" not found.
    goto End
)

:: Compile with cl.exe
echo Compiling %SOURCE_FILE% for x86 using cl.exe...

cl.exe /EHsc /MD /LD /Fe"%OUTPUT_DLL%" "%SOURCE_FILE%" /I"%MINHOOK_INC_DIR%" /link "%MINHOOK_LIB%" user32.lib

if errorlevel 1 (
    echo ERROR: Compilation failed.
    goto End
)

echo Successfully compiled "%OUTPUT_DLL%".

:: Now compile the 32-bit injector directly
echo === Now build 32-bit Injector ===
echo Building 32-bit Injector.exe...

:: Check if injector.cpp exists
if not exist "injector.cpp" (
    echo ERROR: injector.cpp not found in the current directory.
    goto End
)

:: Direct compilation using cl.exe
echo Compiling injector.cpp for x86 using cl.exe...
cl.exe /EHsc /MD /O2 /Fe"Injector.x86.exe" "injector.cpp"

if errorlevel 1 (
    echo ERROR: Failed to compile the 32-bit injector.
    goto End
)

echo Successfully compiled 32-bit Injector.exe

echo === Build Process Complete ===
echo.
echo 32-bit Files Created:
echo - MinHook.x86.lib (32-bit MinHook library)
echo - Interceptor.x86.dll (32-bit hook DLL)
echo - Injector.x86.exe (32-bit injector)
echo.
echo You can now inject the 32-bit DLL into the 32-bit Java process with:
echo Injector.x86.exe 14528 .\Interceptor.x86.dll

:End
pause
endlocal 