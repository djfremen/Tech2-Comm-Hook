@echo off
setlocal

echo === Process Explorer for COM8 Java Process ===

echo Checking if Process Explorer exists...
if not exist ".\ProcessExplorer\procexp64.exe" (
    echo ERROR: Process Explorer not found. Please run download_procexp.ps1 first.
    goto End
)

echo Launching Process Explorer...
echo.
echo IMPORTANT INSTRUCTIONS:
echo 1. In Process Explorer, press Ctrl+F to open the Find dialog
echo 2. Enter "COM8" (without quotes) in the search field
echo 3. Click Search
echo 4. Look for java.exe processes that have handles to COM8
echo 5. Note the PID (Process ID) number of the relevant java.exe process
echo.
echo Once you found the PID, return to this window and enter it below.
echo.
start "" ".\ProcessExplorer\procexp64.exe"

echo.
echo === Finding Java Processes ===
wmic process where "name='java.exe'" get processid,commandline

echo.
set /p PID=Enter the PID of the Java process using COM8: 
if "%PID%"=="" goto End

echo.
echo === Ready to Inject ===
echo Will inject Interceptor.dll into Java process with PID: %PID%
echo.
set /p CONFIRM=Inject now? (Y/N): 
if /i not "%CONFIRM%"=="Y" goto End

echo.
echo Running injector...
echo Command: "Injector.exe" %PID% "%~dp0Interceptor.dll"
"Injector.exe" %PID% "%~dp0Interceptor.dll"

if errorlevel 1 (
    echo.
    echo ERROR: Injection failed!
) else (
    echo.
    echo Injection successful!
    echo Check C:\temp\com_hook_log.txt for captured data.
)

:End
echo.
pause
endlocal 