@echo off
title Checking Injection History
color 0B

echo ================================================================
echo  CHECKING SYSTEM FOR EVIDENCE OF PAST SUCCESSFUL INJECTIONS
echo ================================================================
echo.

echo Step 1: Checking if log file was ever created...
echo.

if exist "C:\temp\com_hook_log.txt" (
    echo SUCCESS! Log file exists at C:\temp\com_hook_log.txt
    echo.
    echo File creation time:
    dir "C:\temp\com_hook_log.txt"
    echo.
    echo Content:
    echo ------------------------------------------------------------------
    type "C:\temp\com_hook_log.txt"
    echo ------------------------------------------------------------------
) else (
    echo No log file found at C:\temp\com_hook_log.txt
)

echo.
echo Step 2: Checking for log file in other locations...
echo.

dir /s /b %USERPROFILE%\com_hook_log.txt 2>nul
dir /s /b C:\com_hook_log.txt 2>nul
dir /s /b C:\Windows\Temp\com_hook_log.txt 2>nul
dir /s /b %TEMP%\com_hook_log.txt 2>nul

echo.
echo Step 3: Checking for backups of previous injection scripts...
echo.

echo Looking for .bak files in current directory:
dir /b *.bak 2>nul
echo.
echo Looking for old injection scripts:
dir /b *inject*.bat 2>nul

echo.
echo Step 4: Checking Windows Event Logs for relevant events...
echo.

powershell -Command "Get-EventLog -LogName 'Application' -Newest 50 | Where-Object {$_.Message -like '*java*' -or $_.Message -like '*dll*' -or $_.Message -like '*inject*'} | Format-Table TimeGenerated, Source, EventID, Message -AutoSize" 2>nul

echo.
echo Step 5: Checking recent command history...
echo.

doskey /history | findstr /i "injector dll java" 2>nul

echo.
echo ================================================================
echo  ANALYSIS AND RECOMMENDATIONS
echo ================================================================
echo.
echo Based on the information above, if you see evidence of successful
echo injections in the past, try to identify what was different:
echo.
echo 1. Different Java process/version
echo 2. Different file locations/paths
echo 3. Different injection technique
echo 4. Different permissions/privileges
echo 5. Different antivirus settings
echo.
echo Remember: If injection worked before, the key differences will
echo help identify what to change to make it work again.
echo.

echo Press any key to exit...
pause >nul 