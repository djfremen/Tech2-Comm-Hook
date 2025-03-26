# Simple COM Port Monitor Script
Write-Host "=== Simple COM Port Monitor ===" -ForegroundColor Cyan

# Clear any existing log file to start fresh
$logFile = "C:\temp\com_hook_log.txt"
if (Test-Path $logFile) {
    Remove-Item -Path $logFile -Force
    Write-Host "Removed old log file" -ForegroundColor Yellow
}

# Get the current Java process
$javaProcess = Get-Process -Name "java*" | Select-Object -First 1
if ($null -eq $javaProcess) {
    Write-Host "No Java process found! Please start your Java application." -ForegroundColor Red
    exit 1
}

$javaPid = $javaProcess.Id
Write-Host "Found Java process: $($javaProcess.ProcessName) (PID: $javaPid)" -ForegroundColor Green

# One-time injection
Write-Host "Performing DLL injection..." -ForegroundColor Yellow
& ".\Injector.x86.exe" $javaPid "Interceptor.x86.dll" | Out-Null

Write-Host "Monitoring COM port traffic in C:\temp\com_hook_log.txt" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
Write-Host ""

# Simple infinite loop to monitor the log file
while ($true) {
    if (Test-Path $logFile) {
        $content = Get-Content -Path $logFile -Raw -ErrorAction SilentlyContinue
        if ($content) {
            Clear-Host
            Write-Host "=== COM Port Traffic ===" -ForegroundColor Cyan
            Write-Host ""
            Write-Host $content
            Write-Host ""
            Write-Host "Monitoring... Press Ctrl+C to stop" -ForegroundColor Yellow
        }
    }
    Start-Sleep -Seconds 1
} 