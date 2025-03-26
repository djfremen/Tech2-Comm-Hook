@echo off
setlocal enabledelayedexpansion
title DLL Injection Diagnostic Tool
color 0A

echo ===================================================================
echo DLL Injection Diagnostic Tool
echo ===================================================================
echo.
echo This tool will diagnose issues with DLL injection for COM port monitoring
echo.

:: Save diagnostic log
set DIAG_LOG=injection_diagnostic_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log
set DIAG_LOG=%DIAG_LOG: =0%
echo Saving diagnostic information to: %DIAG_LOG%
echo.

:: Start logging
echo ===== DIAGNOSTIC LOG - %date% %time% ===== > %DIAG_LOG%
echo. >> %DIAG_LOG%

:: Check if running as admin
echo Checking administrative privileges...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Not running with administrative privileges! >> %DIAG_LOG%
    echo [ERROR] Not running with administrative privileges!
    echo You must run this script as Administrator.
    echo.
    echo Right-click on this batch file and select "Run as administrator"
    echo.
    pause
    goto :eof
) else (
    echo [OK] Running with administrative privileges >> %DIAG_LOG%
    echo [OK] Running with administrative privileges
)
echo.

:: Check Windows Defender settings
echo Checking Windows Defender status...
echo ===== WINDOWS DEFENDER STATUS ===== >> %DIAG_LOG%
powershell -Command "Get-MpPreference | Select-Object DisableRealtimeMonitoring, ExclusionPath, ExclusionProcess | Format-List" >> %DIAG_LOG%

powershell -Command "$status = Get-MpPreference; if ($status.DisableRealtimeMonitoring) { Write-Host '[WARNING] Real-time protection is disabled' } else { Write-Host '[INFO] Real-time protection is enabled' }"
echo.

:: Define file paths - using fixed relative paths
echo Checking for required files...
echo ===== REQUIRED FILES ===== >> %DIAG_LOG%

set INJECTOR=tools\Injector.x86.exe
set DLL=build\Interceptor.x86.dll
set HANDLE_EXE=tools\handle.exe

echo Using fixed file paths:
echo - Injector: %INJECTOR%
echo - DLL: %DLL%
echo - Handle: %HANDLE_EXE%
echo.

:: Check if the script is running from the expected location
echo Checking current directory: "%CD%" >> %DIAG_LOG%
echo Current directory: "%CD%"
if not exist "%INJECTOR%" (
    echo [WARNING] This script may not be running from the SaabComHook root directory >> %DIAG_LOG%
    echo [WARNING] This script may not be running from the SaabComHook root directory
    echo           Make sure to run this script from the root of your project folder >> %DIAG_LOG%
    echo           Make sure to run this script from the root of your project folder
    echo.
)

:: Check if files exist
echo Checking file existence and paths:
if exist "%INJECTOR%" (
    echo [OK] Found Injector at: %INJECTOR% >> %DIAG_LOG%
    echo [OK] Found Injector at: %INJECTOR%
) else (
    echo [ERROR] Missing Injector at: %INJECTOR% >> %DIAG_LOG%
    echo [ERROR] Missing Injector at: %INJECTOR%
    echo.
    echo Please check that you are running this script from the SaabComHook root directory.
    echo If the file exists but is in a different location, edit this script to set the correct path.
)

if exist "%DLL%" (
    echo [OK] Found Hook DLL at: %DLL% >> %DIAG_LOG%
    echo [OK] Found Hook DLL at: %DLL%
) else (
    echo [ERROR] Missing Hook DLL at: %DLL% >> %DIAG_LOG%
    echo [ERROR] Missing Hook DLL at: %DLL%
    echo.
    echo Please check that you are running this script from the SaabComHook root directory.
    echo If the file exists but is in a different location, edit this script to set the correct path.
)

if exist "%HANDLE_EXE%" (
    echo [OK] Found handle.exe at: %HANDLE_EXE% >> %DIAG_LOG%
    echo [OK] Found handle.exe at: %HANDLE_EXE%
) else (
    echo [ERROR] Missing handle.exe at: %HANDLE_EXE% >> %DIAG_LOG%
    echo [ERROR] Missing handle.exe at: %HANDLE_EXE%
    echo.
    echo handle.exe is needed to find Java processes with COM port handles.
    echo Download it from: https://docs.microsoft.com/en-us/sysinternals/downloads/handle
    echo Extract it to the tools directory of your project.
)

:: Check for temp directory
if exist "C:\temp" (
    echo [OK] Found C:\temp directory >> %DIAG_LOG%
    echo [OK] Found C:\temp directory
) else (
    echo [WARNING] C:\temp directory does not exist - will attempt to create it >> %DIAG_LOG%
    echo [WARNING] C:\temp directory does not exist - will attempt to create it
    mkdir "C:\temp" >nul 2>&1
    if exist "C:\temp" (
        echo [OK] Successfully created C:\temp directory >> %DIAG_LOG%
        echo [OK] Successfully created C:\temp directory
    ) else (
        echo [ERROR] Failed to create C:\temp directory! >> %DIAG_LOG%
        echo [ERROR] Failed to create C:\temp directory!
    )
)
echo.

:: Check permissions on directories
echo Checking directory permissions...
echo ===== DIRECTORY PERMISSIONS ===== >> %DIAG_LOG%
icacls "C:\temp" >> %DIAG_LOG%

:: Check tools directory permissions if it exists
if exist "tools" (
    echo Checking permissions for directory: tools >> %DIAG_LOG%
    icacls "tools" >> %DIAG_LOG% 2>&1
) else (
    echo [ERROR] tools directory not found >> %DIAG_LOG%
)

:: Check build directory permissions if it exists
if exist "build" (
    echo Checking permissions for directory: build >> %DIAG_LOG%
    icacls "build" >> %DIAG_LOG% 2>&1
) else (
    echo [ERROR] build directory not found >> %DIAG_LOG%
)

echo [INFO] Directory permission checks completed >> %DIAG_LOG%
echo [INFO] Directory permission checks completed
echo.

:: Check for Java processes
echo Checking for Java processes...
echo ===== JAVA PROCESSES ===== >> %DIAG_LOG%
powershell -Command "Get-Process | Where-Object {$_.ProcessName -like 'java*'} | Select-Object ProcessName, Id, Path | Format-Table -AutoSize" >> %DIAG_LOG%
powershell -Command "$procs = Get-Process | Where-Object {$_.ProcessName -like 'java*'}; if ($procs.Count -eq 0) { Write-Host '[WARNING] No Java processes found' } else { Write-Host ('[INFO] Found ' + $procs.Count + ' Java processes:'); $procs | ForEach-Object { Write-Host ('- ' + $_.ProcessName + ' (PID: ' + $_.Id + ')') } }"
echo.

:: Check for COM ports
echo Checking COM ports...
echo ===== COM PORTS ===== >> %DIAG_LOG%

:: Try using System.IO.Ports
powershell -Command "try { Add-Type -AssemblyName System.IO.Ports; [System.IO.Ports.SerialPort]::GetPortNames() } catch { Write-Host 'Error loading System.IO.Ports: ' + $_.Exception.Message }" >> %DIAG_LOG%

:: Use fallback method if System.IO.Ports fails
powershell -Command "try { Add-Type -AssemblyName System.IO.Ports; $ports = [System.IO.Ports.SerialPort]::GetPortNames(); if ($ports.Count -eq 0) { Write-Host '[WARNING] No COM ports found' } else { Write-Host '[INFO] Found COM ports:'; $ports | ForEach-Object { Write-Host ('- ' + $_) } } } catch { Write-Host '[WARNING] Unable to load System.IO.Ports assembly: ' + $_.Exception.Message; Write-Host 'Trying MODE COM command to list ports...'; $modeOutput = & cmd /c 'mode' | Select-String -Pattern 'COM\d+'; if ($modeOutput) { Write-Host '[INFO] Found COM ports:'; $modeOutput | ForEach-Object { Write-Host ('- ' + $_.ToString().Trim()) } } else { Write-Host '[WARNING] No COM ports found using MODE command' } }"
echo.

:: Specify COM port to look for
set /p COM_PORT=Enter COM port to find in handles (e.g., COM8): 

:: Find process with COM port handle
echo.
echo Looking for processes with handles to %COM_PORT%...
echo ===== COM PORT HANDLE SEARCH (%COM_PORT%) ===== >> %DIAG_LOG%

:: Check if handle.exe exists before trying to run it
if not exist "%HANDLE_EXE%" (
    echo [ERROR] handle.exe not found at specified path: %HANDLE_EXE% >> %DIAG_LOG%
    echo [ERROR] handle.exe not found at specified path: %HANDLE_EXE%
    echo.
    echo You need to download handle.exe from the Sysinternals website:
    echo https://docs.microsoft.com/en-us/sysinternals/downloads/handle
    goto :manual_pid
)

echo Running: "%HANDLE_EXE%" %COM_PORT% >> %DIAG_LOG%
"%HANDLE_EXE%" %COM_PORT% >> %DIAG_LOG% 2>&1
"%HANDLE_EXE%" %COM_PORT% > handle_output.tmp 2>&1

:: Check if handle.exe ran successfully
if %errorlevel% neq 0 (
    echo [ERROR] handle.exe failed to run! Error code: %errorlevel% >> %DIAG_LOG%
    echo [ERROR] handle.exe failed to run! Error code: %errorlevel%
    type handle_output.tmp >> %DIAG_LOG%
    echo.
    echo Check if handle.exe is properly extracted and accessible.
    goto :manual_pid
)

:: Find javaw.exe with COM port handle
findstr /i "javaw.exe.*%COM_PORT%" handle_output.tmp > javaw_handles.tmp
if %errorlevel% neq 0 (
    echo [WARNING] No javaw.exe process found with handle to %COM_PORT% >> %DIAG_LOG%
    echo [WARNING] No javaw.exe process found with handle to %COM_PORT%
    echo.
    echo Available processes with handles to %COM_PORT%:
    type handle_output.tmp
    echo.
    goto :manual_pid
) else (
    for /f "tokens=3" %%a in (javaw_handles.tmp) do (
        set TARGET_PID=%%a
        echo [INFO] Found javaw.exe with PID !TARGET_PID! holding %COM_PORT% >> %DIAG_LOG%
        echo [INFO] Found javaw.exe with PID !TARGET_PID! holding %COM_PORT%
    )
)
echo.

:: If no PID found automatically, ask for manual entry
:manual_pid
if not defined TARGET_PID (
    echo No Java process automatically found with handle to %COM_PORT%
    powershell -Command "$procs = Get-Process | Where-Object {$_.ProcessName -like 'java*'}; if ($procs.Count -gt 0) { Write-Host 'Available Java processes:'; $procs | ForEach-Object { Write-Host ('- ' + $_.ProcessName + ' (PID: ' + $_.Id + ')') } }"
    set /p TARGET_PID=Enter PID of javaw.exe process to inject into: 
)

:: Verify PID is valid
powershell -Command "try { $proc = Get-Process -Id %TARGET_PID% -ErrorAction Stop; Write-Host ('[INFO] Targeting process: ' + $proc.ProcessName + ' (PID: ' + $proc.Id + ')') } catch { Write-Host '[ERROR] Invalid PID or process not found' }"
powershell -Command "try { $proc = Get-Process -Id %TARGET_PID% -ErrorAction Stop; if ($proc.ProcessName -notlike 'java*') { Write-Host '[WARNING] Target process is not a Java process' } } catch {}"
echo.

:: Check architecture
echo Checking target process architecture...
echo ===== TARGET PROCESS ARCHITECTURE ===== >> %DIAG_LOG%
powershell -Command "try { $proc = Get-Process -Id %TARGET_PID% -ErrorAction Stop; if ($proc.MainModule.ModuleName -eq 'javaw.exe' -and $proc.MainModule.FileName -match 'Program Files \(x86\)') { Write-Host '[INFO] Target process is 32-bit (x86)' } elseif ($proc.MainModule.ModuleName -eq 'javaw.exe' -and $proc.MainModule.FileName -match 'Program Files(?! \(x86\))') { Write-Host '[WARNING] Target process appears to be 64-bit but DLL is 32-bit' } else { Write-Host '[INFO] Could not determine architecture automatically' } } catch { Write-Host '[WARNING] Could not access process module information: ' + $_.Exception.Message }" >> %DIAG_LOG%
powershell -Command "try { $proc = Get-Process -Id %TARGET_PID% -ErrorAction Stop; if ($proc.MainModule.ModuleName -eq 'javaw.exe' -and $proc.MainModule.FileName -match 'Program Files \(x86\)') { Write-Host '[INFO] Target process is 32-bit (x86)' } elseif ($proc.MainModule.ModuleName -eq 'javaw.exe' -and $proc.MainModule.FileName -match 'Program Files(?! \(x86\))') { Write-Host '[WARNING] Target process appears to be 64-bit but DLL is 32-bit' } else { Write-Host '[INFO] Could not determine architecture automatically' } } catch { Write-Host '[WARNING] Could not access process module information: ' + $_.Exception.Message }"
echo.

:: Prepare injection command
set INJECT_CMD="%INJECTOR%" %TARGET_PID% "%DLL%"

echo Injection command: %INJECT_CMD% >> %DIAG_LOG%
echo Injection command: %INJECT_CMD%
echo.

:: Clear log file
echo Clearing any existing log file...
if exist "C:\temp\com_hook_log.txt" del "C:\temp\com_hook_log.txt"
echo.

:: Ready to inject
echo Ready to inject the DLL. Press any key to proceed or Ctrl+C to cancel...
pause > nul

:: Execute injection
echo.
echo ===== INJECTION EXECUTION ===== >> %DIAG_LOG%
echo Executing injection... >> %DIAG_LOG%
echo Executing injection...
echo.

%INJECT_CMD% >> %DIAG_LOG% 2>&1
set INJECT_RESULT=%errorlevel%

echo Return code: %INJECT_RESULT% >> %DIAG_LOG%
echo Return code: %INJECT_RESULT%
echo.

:: Check if log file was created
echo Checking for log file...
if exist "C:\temp\com_hook_log.txt" (
    echo [SUCCESS] Log file was created! >> %DIAG_LOG%
    echo [SUCCESS] Log file was created!
    echo.
    echo Log file contents: >> %DIAG_LOG%
    type "C:\temp\com_hook_log.txt" >> %DIAG_LOG%
    echo.
    echo Log file contents:
    type "C:\temp\com_hook_log.txt"
) else (
    echo [ERROR] No log file was created! >> %DIAG_LOG%
    echo [ERROR] No log file was created!
)
echo.

:: Recommend next steps
echo ===== RECOMMENDATIONS ===== >> %DIAG_LOG%
echo Based on the diagnostic results: >> %DIAG_LOG%

if %INJECT_RESULT% neq 0 (
    echo [RECOMMENDATION] The injection failed with return code %INJECT_RESULT%. >> %DIAG_LOG%
    echo [RECOMMENDATION] The injection failed with return code %INJECT_RESULT%.
    
    echo Try the following: >> %DIAG_LOG%
    echo Try the following:
    echo 1. Ensure Windows Defender exclusions are set for: >> %DIAG_LOG%
    echo 1. Ensure Windows Defender exclusions are set for:
    echo    - %CD%\%INJECTOR% >> %DIAG_LOG%
    echo    - %CD%\%INJECTOR%
    echo    - %CD%\%DLL% >> %DIAG_LOG%
    echo    - %CD%\%DLL%
    echo    - C:\temp >> %DIAG_LOG%
    echo    - C:\temp
    echo 2. Temporarily disable Windows Defender Real-time Protection >> %DIAG_LOG%
    echo 2. Temporarily disable Windows Defender Real-time Protection
    echo 3. Verify that the target Java process is 32-bit >> %DIAG_LOG%
    echo 3. Verify that the target Java process is 32-bit
    echo 4. Check that your javaw.exe process is still running >> %DIAG_LOG%
    echo 4. Check that your javaw.exe process is still running
) else if exist "C:\temp\com_hook_log.txt" (
    findstr /c:"Hook DLL Detaching" "C:\temp\com_hook_log.txt" > nul
    if not errorlevel 1 (
        echo [RECOMMENDATION] The DLL loaded but immediately detached. >> %DIAG_LOG%
        echo [RECOMMENDATION] The DLL loaded but immediately detached.
        echo Try the following: >> %DIAG_LOG%
        echo Try the following:
        echo 1. Use a continuous injection approach that re-injects periodically >> %DIAG_LOG%
        echo 1. Use a continuous injection approach that re-injects periodically
        echo 2. Try the Port Redirection approach instead of DLL injection >> %DIAG_LOG%
        echo 2. Try the Port Redirection approach instead of DLL injection
    )
)

:: Alternative approach reminder
echo.
echo [ALTERNATIVE] If DLL injection continues to fail, consider setting up port redirection: >> %DIAG_LOG%
echo [ALTERNATIVE] If DLL injection continues to fail, consider setting up port redirection:
echo 1. Use com0com to create a virtual COM port pair >> %DIAG_LOG%
echo 1. Use com0com to create a virtual COM port pair
echo 2. Configure your Java app to use one port of the pair >> %DIAG_LOG%
echo 2. Configure your Java app to use one port of the pair
echo 3. Monitor the other port directly without injection >> %DIAG_LOG%
echo 3. Monitor the other port directly without injection
echo.

:cleanup
:: Clean up temporary files
del handle_output.tmp 2>nul
del javaw_handles.tmp 2>nul

echo Diagnostic complete. Results saved to %DIAG_LOG%
echo.
pause 