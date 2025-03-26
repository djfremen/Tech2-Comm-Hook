@echo off
title COM Port Redirection Setup
color 0A

echo ========================================================
echo COM Port Redirection Setup
echo ========================================================
echo.
echo This script will help you set up port redirection using com0com
echo to monitor COM port traffic without DLL injection.
echo.

:: Check if com0com is installed
echo Checking for com0com installation...
reg query "HKLM\SOFTWARE\com0com" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo com0com does not appear to be installed.
    echo Please download and install it from:
    echo https://sourceforge.net/projects/com0com/
    echo.
    echo After installation, run this script again.
    goto :eof
)

echo com0com is installed. Proceeding with setup.
echo.

:: Check for available com0com ports
echo Checking available COM ports...
echo.
echo COM ports on your system:
mode
echo.

echo Based on the list above, identify:
echo 1. Which COM port your Java application is using (e.g., COM8)
echo 2. Which virtual com0com ports are available (e.g., CNCA0, CNCB0)
echo.

set /p APP_PORT=Enter the COM port used by your Java application (e.g., COM8): 

echo.
echo To set up port redirection, you need to:
echo.
echo 1. Open com0com Setup utility as Administrator
echo    (Look in Start Menu under "com0com" folder)
echo.
echo 2. In the com0com Setup window, configure a port pair:
echo    a. Select a port pair (e.g., CNCA0-CNCB0)
echo    b. For the first port (e.g., CNCA0):
echo       - Change its PortName to %APP_PORT%
echo    c. For the second port (e.g., CNCB0):
echo       - Change its PortName to COM_MONITOR
echo    d. Click "Apply" to save changes
echo.
echo 3. After configuring com0com, your Java application will 
echo    connect to the virtual port that redirects to COM_MONITOR,
echo    which we can monitor without injection.
echo.

pause

echo.
echo Now you can:
echo 1. Run your Java application normally (it will use the redirected port)
echo 2. Monitor the traffic using our COM monitoring tool
echo.

set /p MONITOR=Would you like to start monitoring now? (Y/N): 

if /i "%MONITOR%"=="Y" (
    echo.
    echo Starting the COM port monitor...
    echo.
    start "COM Monitor" powershell -ExecutionPolicy Bypass -File "com_port_redirect.ps1"
) else (
    echo.
    echo To monitor COM port traffic later, run:
    echo powershell -ExecutionPolicy Bypass -File "com_port_redirect.ps1"
    echo.
)

echo.
echo Setup complete!
echo.
pause 