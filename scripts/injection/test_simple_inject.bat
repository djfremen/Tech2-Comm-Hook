@echo off 
echo Testing Simple DLL Injection 
 
:: Delete any existing log file 
if exist C:\temp\com_hook_log.txt del C:\temp\com_hook_log.txt 
 
:: Find Java process 
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq javaw.exe" /fo list | find "PID:"') do ( 
    set JAVAPID=%%i 
    echo Found Java process with PID: %%i 
) 
 
if "%JAVAPID%"=="" ( 
    echo No Java process found! 
    goto end 
) 
 
:: Inject the simple DLL 
echo Injecting Simple DLL into process %JAVAPID%... 
Injector.x86.exe %JAVAPID% build\SimpleHook.x86.dll 
set RESULT=%ERRORLEVEL% 
 
echo Injection completed with return code: %RESULT% 
if %RESULT% equ 0 ( 
    echo Injection successful 
) else ( 
    echo Injection failed with code %RESULT% 
) 
 
:: Check if log file was created 
timeout /t 2 > nul 
if exist C:\temp\com_hook_log.txt ( 
    echo Log file created! DLL successfully loaded and executed. 
    type C:\temp\com_hook_log.txt 
) else ( 
    echo No log file found. DLL did not attach or could not create log. 
) 
 
:end 
pause 
