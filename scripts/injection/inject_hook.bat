@echo off 
:: COM Port Hook DLL Injection Script 
echo COM Port Interceptor Injection 
 
:: Check for admin privileges 
net session 
if %ERRORLEVEL% neq 0 ( 
    echo WARNING: This script is not running with administrator privileges. 
    echo Injection may fail if target process has higher privileges. 
    echo Consider running as administrator. 
    echo. 
) 
 
:: Check if log directory exists 
if not exist C:\temp mkdir C:\temp 
 
:: Clear previous log file 
if exist C:\temp\com_hook_log.txt del C:\temp\com_hook_log.txt 
echo Log file will be created at: C:\temp\com_hook_log.txt 
 
if "%1"=="" ( 
    :: No PID specified, offer process selection 
    echo No process ID specified. 
    echo. 
    echo Please enter the PID of the process to inject into, 
    echo or leave blank to see a list of processes: 
    set /p PID="Process ID: " 
 
    if "%PID%"=="" ( 
        :: Show process list using tasklist 
        echo. 
        echo Available processes: 
        tasklist /fi "sessionname eq console" 
        echo. 
        echo Please restart the script and provide a PID. 
        goto end 
    ) 
) else ( 
    :: Use the specified PID 
    set PID=%1 
) 
 
:: Confirm the PID is a number 
set "INVALIDCHARS=false" 
for /f "delims=0123456789" %%i in ("%PID%") do set "INVALIDCHARS=true" 
if "%INVALIDCHARS%"=="true" ( 
    echo ERROR: Invalid PID specified. PID must be a number. 
    goto end 
) 
 
:: Find process name for the given PID 
for /f "tokens=1,2 usebackq" %%a in (`tasklist /FI "PID eq %PID%" /FO list | findstr /B "Image Name:"`) do ( 
    set PROCESS_NAME=%%b 
) 
 
if "%PROCESS_NAME%"=="" ( 
    echo ERROR: No process found with PID %PID% 
    goto end 
) 
 
echo Target process: %PROCESS_NAME% (PID: %PID%) 
echo. 
echo About to inject COM port hook DLL into this process. 
echo This will log all COM port communications to C:\temp\com_hook_log.txt 
echo. 
set /p CONFIRM="Continue? (Y/N): " 
if /i not "%CONFIRM%"=="Y" goto end 
 
:: Execute the injector 
echo Executing DLL Injection... 
tools\Injector.x86.exe %PID% build\Interceptor.x86.dll 
 
if %ERRORLEVEL% neq 0 ( 
    echo ERROR: Injection failed with code %ERRORLEVEL% 
) else ( 
    echo Injection command completed successfully. 
    echo. 
    echo To verify if the hook is working: 
    echo 1. Use the target application to perform COM port operations 
    echo 2. Check the log file at C:\temp\com_hook_log.txt 
    echo. 
    :: Check if log file exists after a short delay 
    timeout /t 3 
    if exist C:\temp\com_hook_log.txt ( 
        echo Log file detected 
        echo ---------------------------------------- 
1
        del temp.txt 
        echo Total lines in log: %LINECOUNT% 
        echo. 
        echo ---------------------------------------- 
    ) else ( 
        echo Log file not yet created. 
        echo This could be normal if no COM port activity has occurred yet. 
    ) 
) 
 
:end 
pause 
