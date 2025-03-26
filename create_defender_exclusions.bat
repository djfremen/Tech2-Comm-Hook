@echo off
echo ============================================
echo Create Windows Defender Exclusions
echo ============================================
echo This script will add exclusions to Windows Defender
echo for the hook DLL and injector files.
echo.

:: Check for admin rights
net session >nul 2>nul
if %ERRORLEVEL% neq 0 (
  echo ERROR: This script requires administrative privileges.
  echo Please right-click and select "Run as administrator".
  pause
  exit /b 1
)

echo Getting current directory...
set CURRENT_DIR=%CD%

echo Preparing paths for exclusions...
set INJECTOR_PATH=%CURRENT_DIR%\tools\Injector.x86.exe
set DLL_PATH=%CURRENT_DIR%\build\Interceptor.x86.dll
set LOG_PATH=C:\temp

echo.
echo Will create the following exclusions:
echo - %INJECTOR_PATH%
echo - %DLL_PATH%
echo - %LOG_PATH% (folder)
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo Adding exclusions to Windows Defender...

:: Process exclusions
powershell -Command "Add-MpPreference -ExclusionProcess '%INJECTOR_PATH%'" >nul 2>nul
if %ERRORLEVEL% neq 0 (
  echo WARNING: Failed to add process exclusion for %INJECTOR_PATH%
) else (
  echo Added process exclusion for %INJECTOR_PATH%
)

:: Path exclusions
powershell -Command "Add-MpPreference -ExclusionPath '%DLL_PATH%'" >nul 2>nul
if %ERRORLEVEL% neq 0 (
  echo WARNING: Failed to add path exclusion for %DLL_PATH%
) else (
  echo Added path exclusion for %DLL_PATH%
)

powershell -Command "Add-MpPreference -ExclusionPath '%LOG_PATH%'" >nul 2>nul
if %ERRORLEVEL% neq 0 (
  echo WARNING: Failed to add path exclusion for %LOG_PATH%
) else (
  echo Added path exclusion for %LOG_PATH%
)

:: Alternatively, can add more granular exclusions
echo.
echo Checking current exclusions (this may take a moment)...
powershell -Command "Get-MpPreference | Select-Object -ExpandProperty ExclusionPath" > exclusion_paths.txt
powershell -Command "Get-MpPreference | Select-Object -ExpandProperty ExclusionProcess" > exclusion_processes.txt

echo.
echo Exclusion setup complete!
echo After adding exclusions, try running robust_inject.bat again.
echo.
echo Note: You may need to restart the target process or even
echo       reboot your computer for exclusions to take full effect.

pause 