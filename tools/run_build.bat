@echo off
setlocal enabledelayedexpansion

echo === Visual Studio Build Helper Script ===

:: Check if we're being called to just set up the environment
if "%1"=="setup_env_only" goto SetupEnvironment

:: Use vswhere to find VS installation path
echo Searching for Visual Studio using vswhere.exe...
set "VSWHERE=C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"

if not exist "%VSWHERE%" (
    echo ERROR: vswhere.exe not found at "%VSWHERE%".
    goto ManualSearch
)

:: Try to find any VS installation with C++ tools
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
    set "VS_INSTALL_PATH=%%i"
)

if defined VS_INSTALL_PATH (
    echo Found Visual Studio at: !VS_INSTALL_PATH!
    
    set "VCVARSALL=!VS_INSTALL_PATH!\VC\Auxiliary\Build\vcvarsall.bat"
    
    if exist "!VCVARSALL!" (
        goto FoundVS
    ) else (
        echo vcvarsall.bat not found at expected location: "!VCVARSALL!"
    )
)

:ManualSearch
echo Falling back to manual search in common locations...

:: Try to find Visual Studio in common locations
echo Searching for Visual Studio...

:: Check for VS 2022 on D: drive
if exist "D:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=D:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

if exist "D:\Program Files (x86)\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=D:\Program Files (x86)\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

:: Check for VS 2022 Community
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

:: Check for VS 2022 Professional
if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

:: Check for VS 2022 Enterprise
if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

:: Check for VS 2019 Community
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

if exist "D:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=D:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

:: Check for VS 2019 Professional
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

:: Check for VS 2019 Enterprise
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

:: Check for VS 2017 Community
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

if exist "D:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=D:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

:: Check for Visual Studio Build Tools
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

if exist "D:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=D:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

if exist "D:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=D:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

if exist "D:\buildtools\VC\Auxiliary\Build\vcvarsall.bat" (
    set "VCVARSALL=D:\buildtools\VC\Auxiliary\Build\vcvarsall.bat"
    goto FoundVS
)

:: If we get here, we couldn't find Visual Studio
echo ERROR: Could not find Visual Studio with C++ development tools.
echo Please install Visual Studio with C++ development tools or run from a Developer Command Prompt.
goto Error

:FoundVS
echo Found Visual Studio environment at: %VCVARSALL%

:SetupEnvironment
:: Set up environment for x64 architecture
echo Setting up Visual Studio environment for x64...
call "%VCVARSALL%" x64
if errorlevel 1 (
    echo ERROR: Failed to initialize Visual Studio environment.
    goto Error
)

:: If we're just setting up the environment, return now
if "%1"=="setup_env_only" (
    exit /b 0
)

:: Run the compile.bat script
echo Running compile.bat...
call compile.bat
if errorlevel 1 (
    echo ERROR: compile.bat failed with error code %errorlevel%.
    goto Error
)

echo Build completed successfully!
goto End

:Error
echo.
echo Build failed! Please check the errors above.
pause
exit /b 1

:End
pause
endlocal 