@echo off
echo COM Port Hook - Build Script

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
del /Q build\Interceptor.x86.dll 2>nul

echo Compiling Interceptor DLL (32-bit)...
cl.exe /nologo /MD /LD /EHsc /I"vendor\minhook\include" src\hook.cpp vendor\minhook\lib\MinHook.x86.lib /Fe"build\Interceptor.x86.dll" /link /SUBSYSTEM:WINDOWS /DLL

if %ERRORLEVEL% neq 0 (
    echo ERROR: Compilation failed with error code %ERRORLEVEL%
    goto end
)

echo Compilation successful!
echo DLL created: build\Interceptor.x86.dll

:end
pause 