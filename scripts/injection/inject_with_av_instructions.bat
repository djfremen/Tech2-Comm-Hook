@echo off
setlocal enabledelayedexpansion

echo === DLL Injection with Antivirus Considerations ===
echo.
echo The DLL injection is being blocked by your antivirus software.
echo.
echo Instructions:
echo -------------
echo 1. Temporarily disable your antivirus real-time protection
echo    - Windows Defender: Settings -^> Virus ^& threat protection -^> Manage settings -^> Turn off Real-time protection
echo    - Other antivirus: Check their specific instructions for temporarily disabling
echo.
echo 2. After disabling protection, press any key to continue with injection
echo    (Note: This will only inject our COM port monitoring DLL)
echo.
echo 3. Remember to re-enable your antivirus protection after testing
echo.
echo WARNING: Only disable protection temporarily and in a controlled environment.
echo          Only run DLL injection on systems you control and trust.
echo.
pause

echo Running injection for PID 15100...
call inject_pid_15100.bat

echo.
echo === IMPORTANT ===
echo Don't forget to re-enable your antivirus protection!
echo.

pause
endlocal 