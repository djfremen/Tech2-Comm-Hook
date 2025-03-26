@echo off
setlocal

echo Checking if handle.exe exists...
if not exist "%~dp0handle.exe" (
    echo ERROR: handle.exe not found in the current directory.
    goto End
)

echo.
echo === Finding all COM port usage ===
echo.
echo Running: "%~dp0handle.exe" -a | findstr /i "COM"
"%~dp0handle.exe" -a 2>nul | findstr /i "COM"

echo.
echo === Finding Java processes with COM ports ===
echo.
echo Running: "%~dp0handle.exe" -p java.exe 2>nul | findstr /i "COM"
"%~dp0handle.exe" -p java.exe 2>nul | findstr /i "COM"

:End
echo.
pause
endlocal 