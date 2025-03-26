@echo off
setlocal enabledelayedexpansion

echo === Compiling DLL Injector ===

:: Try to find the same Visual Studio installation that we used for the MinHook library build
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

:: Compile the injector using MSBuild
echo Building injector with MSBuild...
msbuild injector.vcxproj /p:Configuration=Release /p:Platform=x64

if errorlevel 1 (
    echo ERROR: Failed to build the injector.
    goto End
)

echo Successfully built Injector.exe

:: Copy the exe to the current directory
copy /Y x64\Release\Injector.exe .\Injector.exe

:: Update the inject_hook.bat script to use our injector
echo Updating inject_hook.bat to use our injector...
powershell -Command "(Get-Content -Path inject_hook.bat) -replace 'set \"INJECTOR_EXE=Injector.exe\".*REM', 'set \"INJECTOR_EXE=%~dp0Injector.exe\"     REM' | Set-Content -Path inject_hook.bat"

echo Done!

:End
endlocal 