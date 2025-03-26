@echo off
setlocal

echo === Run Injection as Administrator ===
echo.
echo This script will:
echo 1. Launch a new Command Prompt window with administrator privileges
echo 2. Navigate to this directory (%CD%)
echo 3. Execute the injection script
echo.
echo Please:
echo - Allow the UAC prompt when it appears
echo - Consider temporarily disabling your antivirus
echo.
echo Press any key to continue...
pause > nul

:: Create a temporary VBS script to elevate privileges
echo Set UAC = CreateObject^("Shell.Application"^) > "%TEMP%\elevation.vbs"
echo UAC.ShellExecute "cmd.exe", "/c cd /d ""%CD%"" && powershell -ExecutionPolicy Bypass -File inject_ps.ps1", "", "runas", 1 >> "%TEMP%\elevation.vbs"

:: Execute the VBS script to launch with admin rights
echo Launching with administrator privileges...
cscript //nologo "%TEMP%\elevation.vbs"
del "%TEMP%\elevation.vbs"

echo.
echo Command launched in a new window.
echo After the injection completes, you can check C:\temp\com_hook_log.txt for results.
echo.
echo If successful, use this command to monitor COM port traffic:
echo   powershell -Command "Get-Content -Path 'C:\temp\com_hook_log.txt' -Wait"
echo.

pause
endlocal 