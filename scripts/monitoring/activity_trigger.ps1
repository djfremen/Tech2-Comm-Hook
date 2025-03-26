# COM Port Activity Trigger Script
Write-Host "=== COM Port Activity Trigger ===" -ForegroundColor Cyan

# List available COM ports
Write-Host "Available COM ports:" -ForegroundColor Yellow
[System.IO.Ports.SerialPort]::GetPortNames() | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Gray
}

# Target COM8 if available, otherwise use the first available port
$comPorts = [System.IO.Ports.SerialPort]::GetPortNames()
$targetPort = "COM8"

if ($comPorts -contains $targetPort) {
    Write-Host "Target port $targetPort found!" -ForegroundColor Green
} elseif ($comPorts.Count -gt 0) {
    $targetPort = $comPorts[0]
    Write-Host "COM8 not found. Using $targetPort instead." -ForegroundColor Yellow
} else {
    Write-Host "No COM ports available!" -ForegroundColor Red
    exit 1
}

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

Write-Host ""
Write-Host "Setting up COM port monitor and trigger..." -ForegroundColor Cyan

# Start a separate process to monitor the log file
$monitorCommand = "& { while (`$true) { if (Test-Path '$logFile') { Clear-Host; Write-Host 'COM Port Activity Log:' -ForegroundColor Cyan; Get-Content -Path '$logFile' -Raw; Write-Host 'Monitoring...' -ForegroundColor Yellow; } Start-Sleep -Seconds 1 } }"
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -Command `"$monitorCommand`"" -WindowStyle Normal

# Try to open COM port and send some data to trigger activity
try {
    # Load the required assembly
    Add-Type -AssemblyName System.IO.Ports

    Write-Host "Attempting to open $targetPort to generate activity..." -ForegroundColor Yellow
    $port = New-Object System.IO.Ports.SerialPort($targetPort, 9600, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)
    
    # Try to open and write to port
    $port.Open()
    if ($port.IsOpen) {
        Write-Host "$targetPort opened successfully!" -ForegroundColor Green
        
        # Send test data every few seconds
        for ($i = 1; $i -le 10; $i++) {
            $testData = "TEST DATA PACKET $i" + [char]13 + [char]10
            Write-Host "Sending: $testData" -ForegroundColor Gray
            $port.Write($testData)
            Start-Sleep -Seconds 2
        }
        
        $port.Close()
        Write-Host "$targetPort closed" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error accessing $targetPort: $_" -ForegroundColor Red
    Write-Host "This is not a problem if the Java application is already using the port." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Activities completed. Checking for log file..." -ForegroundColor Cyan

# Final check for log file
if (Test-Path $logFile) {
    $content = Get-Content -Path $logFile -Raw -ErrorAction SilentlyContinue
    if ($content) {
        Write-Host "Success! Log file contains data:" -ForegroundColor Green
        Write-Host "-----------------------------------------" -ForegroundColor Gray
        Write-Host $content -ForegroundColor White
        Write-Host "-----------------------------------------" -ForegroundColor Gray
    } else {
        Write-Host "Log file exists but is empty." -ForegroundColor Yellow
    }
} else {
    Write-Host "No log file was created." -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 