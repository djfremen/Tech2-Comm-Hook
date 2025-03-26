# Simple COM Port Monitor
Write-Host "======================================================"
Write-Host "Simple COM Port Monitor"
Write-Host "======================================================"
Write-Host ""

# Configuration
$monitorLogFile = "C:\temp\com_port_monitor.txt"

# Clear log file if it exists
if (Test-Path $monitorLogFile) {
    Remove-Item $monitorLogFile -Force
    Write-Host "Cleared existing log file at $monitorLogFile" -ForegroundColor Yellow
}

# Make sure the System.IO.Ports namespace is available
Add-Type -AssemblyName System.IO.Ports

# List available COM ports
$comPorts = [System.IO.Ports.SerialPort]::GetPortNames()
Write-Host "Available COM ports:" -ForegroundColor Cyan
for ($i = 0; $i -lt $comPorts.Count; $i++) {
    Write-Host "[$i] $($comPorts[$i])"
}

if ($comPorts.Count -eq 0) {
    Write-Host "No COM ports found! Please check your device connections." -ForegroundColor Red
    exit
}

# Get port selection
$portIndex = Read-Host "Enter the number of the port to monitor"
if (-not ($portIndex -match "^\d+$") -or [int]$portIndex -ge $comPorts.Count) {
    Write-Host "Invalid selection!" -ForegroundColor Red
    exit
}
$selectedPort = $comPorts[[int]$portIndex]

# Get baud rate
$baudRate = Read-Host "Enter baud rate (default: 9600)"
if ([string]::IsNullOrEmpty($baudRate) -or -not ($baudRate -match "^\d+$")) {
    $baudRate = 9600
}

# Configure serial port settings
$dataBits = 8
$parity = [System.IO.Ports.Parity]::None
$stopBits = [System.IO.Ports.StopBits]::One

Write-Host ""
Write-Host "Starting monitor with these settings:" -ForegroundColor Green
Write-Host "Port: $selectedPort" -ForegroundColor White
Write-Host "Baud Rate: $baudRate" -ForegroundColor White
Write-Host "Data Bits: $dataBits" -ForegroundColor White
Write-Host "Parity: $parity" -ForegroundColor White
Write-Host "Stop Bits: $stopBits" -ForegroundColor White
Write-Host "Log File: $monitorLogFile" -ForegroundColor White
Write-Host ""

# Create and open the serial port
try {
    $port = New-Object System.IO.Ports.SerialPort
    $port.PortName = $selectedPort
    $port.BaudRate = [int]$baudRate
    $port.DataBits = $dataBits
    $port.Parity = $parity
    $port.StopBits = $stopBits
    $port.ReadTimeout = 500
    $port.WriteTimeout = 500
    
    Write-Host "Opening port $selectedPort..." -ForegroundColor Yellow
    $port.Open()
    
    if ($port.IsOpen) {
        Write-Host "Port opened successfully!" -ForegroundColor Green
        Write-Host "Press Ctrl+C to stop monitoring." -ForegroundColor Yellow
        Write-Host ""
        
        # Buffer for accumulating received data
        $buffer = New-Object byte[] 4096
        $dataReceived = $false
        
        # Main monitoring loop
        while ($true) {
            try {
                # Check if there's data available to read
                if ($port.BytesToRead -gt 0) {
                    $bytesRead = $port.Read($buffer, 0, [Math]::Min($port.BytesToRead, $buffer.Length))
                    
                    if ($bytesRead -gt 0) {
                        $dataReceived = $true
                        
                        # Format output in hex and ASCII
                        $hexOutput = ""
                        $asciiOutput = ""
                        
                        for ($i = 0; $i -lt $bytesRead; $i++) {
                            $hexOutput += " " + $buffer[$i].ToString("X2")
                            $asciiOutput += if (($buffer[$i] -ge 32) -and ($buffer[$i] -le 126)) { [char]$buffer[$i] } else { "." }
                        }
                        
                        # Timestamp and format the log entry
                        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                        $logEntry = "[$timestamp] RX ($bytesRead bytes): $hexOutput | $asciiOutput"
                        
                        # Display and log
                        Write-Host $logEntry -ForegroundColor Magenta
                        Add-Content -Path $monitorLogFile -Value $logEntry
                    }
                }
                
                # Brief pause to avoid high CPU usage
                Start-Sleep -Milliseconds 50
                
                # Status update if no data seen in a while
                if (-not $dataReceived) {
                    $currentTime = Get-Date
                    if ($currentTime.Second % 10 -eq 0 -and $currentTime.Millisecond -lt 100) {
                        Write-Host "Waiting for data on port $selectedPort..." -ForegroundColor Gray
                    }
                }
            }
            catch {
                if (-not ($_.Exception -is [System.IO.Ports.TimeoutException])) {
                    Write-Host "Error reading from port: $_" -ForegroundColor Red
                }
            }
        }
    }
    else {
        Write-Host "Failed to open port $selectedPort." -ForegroundColor Red
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
finally {
    # Cleanup
    if ($port -and $port.IsOpen) {
        $port.Close()
        Write-Host "Port closed." -ForegroundColor Yellow
    }
} 