# Monitor COM port traffic log file
Write-Host "=== COM Port Traffic Monitor ===" -ForegroundColor Cyan
Write-Host ""

$logFile = "C:\temp\com_hook_log.txt"

if (Test-Path $logFile) {
    Write-Host "Log file exists - current content:" -ForegroundColor Green
    Write-Host "---------------------------------------------------" -ForegroundColor Gray
    Get-Content -Path $logFile
    Write-Host "---------------------------------------------------" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "Log file not found at $logFile" -ForegroundColor Yellow
    Write-Host "Creating an empty log file..." -ForegroundColor Yellow
    "" | Out-File -FilePath $logFile -Encoding utf8
}

Write-Host "Starting continuous monitoring of COM port traffic..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop monitoring." -ForegroundColor Yellow
Write-Host ""

try {
    Get-Content -Path $logFile -Wait -Tail 10
} catch {
    Write-Host "Error monitoring log file: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Monitoring stopped." -ForegroundColor Cyan 