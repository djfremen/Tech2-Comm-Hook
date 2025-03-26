@echo off
title Direct 32-bit DLL Injection
color 0E

echo ========================================================
echo  Direct 32-bit Injection (Antivirus should be disabled)
echo ========================================================
echo.
echo Target Process: javaw.exe (PID: 6068)
echo Injector: Injector.x86.exe (32-bit)
echo DLL: Interceptor.x86.dll (32-bit)
echo.

echo Creating C:\temp directory if it doesn't exist...
if not exist "C:\temp" mkdir "C:\temp"

echo Copying DLL to C:\temp for reliable path...
copy "Interceptor.x86.dll" "C:\temp\" /Y
echo.

echo Running injection command...
echo.
Injector.x86.exe 6068 "C:\temp\Interceptor.x86.dll"
echo.
echo Return code: %errorlevel%
echo.

echo Checking for log file creation...
timeout /t 5 /nobreak > nul
if exist "C:\temp\com_hook_log.txt" (
    echo Log file created successfully!
    echo Content:
    echo --------------------------------------------------------
    type "C:\temp\com_hook_log.txt"
    echo --------------------------------------------------------
) else (
    echo Log file not created within timeout period.
    echo This may indicate the injection failed or no COM activity has occurred.
)

echo.
echo To monitor COM port traffic, use:
echo powershell -Command "Get-Content -Path 'C:\temp\com_hook_log.txt' -Wait"
echo.
pause 