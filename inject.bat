@echo off
echo COM Port Hook Injection Tool

if "%1"=="" (
  echo Please provide a PID as argument
  echo Example: inject.bat 6068
  exit /b 1
)

set PID=%1
echo Injecting into process with PID: %PID%

if exist C:\temp\com_hook_log.txt del C:\temp\com_hook_log.txt
echo Log will be at C:\temp\com_hook_log.txt

echo Running injection...
tools\Injector.x86.exe %PID% build\Interceptor.x86.dll

if %ERRORLEVEL% neq 0 (
  echo Injection FAILED with error code %ERRORLEVEL%
) else (
  echo Injection command successful
  echo Check C:\temp\com_hook_log.txt for activity after using COM ports
)

pause 