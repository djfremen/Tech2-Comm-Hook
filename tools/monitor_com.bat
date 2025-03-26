@echo off
setlocal

echo === COM Port Traffic Monitor ===
echo.
echo This script provides a filtered view of the COM port traffic log.
echo Press Ctrl+C to stop monitoring.
echo.
echo Starting monitoring - look for text patterns in the binary data...
echo ----------------------------------------------------------------

:loop
powershell -Command "Get-Content -Path 'C:\temp\com_hook_log.txt' | Select-Object -Last 100 | ForEach-Object { if ($_ -match 'TX Data|RX Data') { $data = $_ -replace '^.*\|', '' -replace '\s+\|.*$', ''; Write-Host $data } }"
timeout /t 2 /nobreak > nul
goto loop

endlocal 