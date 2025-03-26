# COM Port Redirection and Monitoring Script
Write-Host "======================================================"
Write-Host "COM Port Redirection and Monitoring"
Write-Host "======================================================"
Write-Host ""

# Configuration
$monitorLogFile = "C:\temp\com_port_monitor.txt"
$baudRate = 9600  # Default baud rate, can be changed

# Make sure the System.IO.Ports namespace is available
Add-Type -AssemblyName System.IO.Ports

# Check if com0com is properly installed
Write-Host "Checking for com0com virtual port pairs..." -ForegroundColor Cyan
$comPorts = [System.IO.Ports.SerialPort]::GetPortNames()
$virtualPorts = $comPorts | Where-Object { $_ -match 'CNCA\d+|CNCB\d+' -or $_ -like 'COM*' -and (Get-WmiObject Win32_SerialPort | Where-Object { $_.DeviceID -eq $_ -and $_.Description -match 'com0com' }) }

if ($virtualPorts.Count -eq 0) {
    Write-Host "No com0com virtual ports found. Please make sure com0com is installed correctly." -ForegroundColor Red
    Write-Host "You can download it from: https://sourceforge.net/projects/com0com/" -ForegroundColor Yellow
    exit
}

# Display available virtual port pairs
Write-Host "Available com0com virtual ports:" -ForegroundColor Green
foreach ($port in $virtualPorts) {
    $portInfo = Get-WmiObject Win32_SerialPort | Where-Object { $_.DeviceID -eq $port }
    if ($portInfo) {
        Write-Host "- $port : $($portInfo.Description)" -ForegroundColor White
    } else {
        Write-Host "- $port" -ForegroundColor White
    }
}

# Setup menu
Write-Host ""
Write-Host "Select monitoring mode:" -ForegroundColor Cyan
Write-Host "1. Monitor an existing port pair"
Write-Host "2. Create a port mapping to redirect Java application to a monitored port"
Write-Host ""

$monitorMode = Read-Host "Enter choice (1-2)"

# Function to monitor a COM port
function Monitor-ComPort {
    param (
        [string]$portName,
        [int]$baudRate = 9600
    )
    
    Write-Host "Starting monitoring on port $portName at $baudRate baud..." -ForegroundColor Cyan
    
    # Clear any existing log file
    if (Test-Path $monitorLogFile) {
        Remove-Item $monitorLogFile -Force
        Write-Host "Cleared existing log file" -ForegroundColor Yellow
    }
    
    try {
        # Create and configure the serial port
        $port = New-Object System.IO.Ports.SerialPort
        $port.PortName = $portName
        $port.BaudRate = $baudRate
        $port.Parity = [System.IO.Ports.Parity]::None
        $port.DataBits = 8
        $port.StopBits = [System.IO.Ports.StopBits]::One
        $port.ReadTimeout = 500
        $port.WriteTimeout = 500
        
        # Open the port
        $port.Open()
        
        if ($port.IsOpen) {
            Write-Host "Port $portName opened successfully!" -ForegroundColor Green
            Write-Host "Press Ctrl+C to stop monitoring." -ForegroundColor Yellow
            
            # Buffer for accumulating received data
            $buffer = New-Object byte[] 4096
            $dataReceived = $false
            
            while ($true) {
                try {
                    # Check if there's data available to read
                    if ($port.BytesToRead -gt 0) {
                        $bytesRead = $port.Read($buffer, 0, [Math]::Min($port.BytesToRead, $buffer.Length))
                        
                        if ($bytesRead -gt 0) {
                            $dataReceived = $true
                            
                            # Convert to hex and ASCII
                            $hexOutput = ""
                            $asciiOutput = ""
                            
                            for ($i = 0; $i -lt $bytesRead; $i++) {
                                $hexOutput += " " + $buffer[$i].ToString("X2")
                                $asciiOutput += if (($buffer[$i] -ge 32) -and ($buffer[$i] -le 126)) { [char]$buffer[$i] } else { "." }
                            }
                            
                            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                            $logEntry = "[$timestamp] RX ($bytesRead bytes): $hexOutput | $asciiOutput"
                            
                            # Display and log
                            Write-Host $logEntry -ForegroundColor Magenta
                            Add-Content -Path $monitorLogFile -Value $logEntry
                        }
                    }
                    
                    # Brief pause to avoid high CPU usage
                    Start-Sleep -Milliseconds 50
                    
                    # Status update if no data
                    if (-not $dataReceived) {
                        $currentTime = Get-Date
                        if ($currentTime.Second % 15 -eq 0 -and $currentTime.Millisecond -lt 100) {
                            Write-Host "Waiting for data on port $portName..." -ForegroundColor Gray
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
            Write-Host "Failed to open port $portName." -ForegroundColor Red
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
}

# Process user selection
if ($monitorMode -eq "1") {
    # Mode 1: Monitor an existing port pair
    Write-Host ""
    for ($i = 0; $i -lt $virtualPorts.Count; $i++) {
        Write-Host "[$i] $($virtualPorts[$i])"
    }
    
    $portIndex = Read-Host "Enter the number of the port to monitor"
    $selectedPort = $virtualPorts[$portIndex]
    
    $baudRate = Read-Host "Enter baud rate (default: 9600)"
    if ([string]::IsNullOrEmpty($baudRate)) { $baudRate = 9600 }
    
    # Start monitoring
    Monitor-ComPort -portName $selectedPort -baudRate $baudRate
}
elseif ($monitorMode -eq "2") {
    # Mode 2: Create a port mapping
    Write-Host ""
    Write-Host "This mode will help you redirect the Java application to use a monitored port." -ForegroundColor Cyan
    Write-Host "You need to know which port the Java application is trying to use." -ForegroundColor Yellow
    
    $targetPort = Read-Host "Enter the port name the Java app is trying to use (e.g., COM8)"
    
    # Find a suitable virtual port pair
    $pairFound = $false
    $pairA = ""
    $pairB = ""
    
    foreach ($port in $virtualPorts) {
        if ($port -match 'CNCA(\d+)') {
            $pairNumber = $matches[1]
            $pairA = "CNCA$pairNumber"
            $pairB = "CNCB$pairNumber"
            
            if ($virtualPorts -contains $pairB) {
                $pairFound = $true
                break
            }
        }
    }
    
    if (-not $pairFound) {
        Write-Host "Could not find a complete virtual port pair. Please check com0com setup." -ForegroundColor Red
        exit
    }
    
    # Configure com0com to redirect
    Write-Host ""
    Write-Host "Found virtual port pair: $pairA <-> $pairB" -ForegroundColor Green
    Write-Host "We'll map $targetPort to $pairA and monitor $pairB" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "IMPORTANT INSTRUCTIONS:" -ForegroundColor Yellow
    Write-Host "1. Open com0com setup utility as Administrator" -ForegroundColor Yellow
    Write-Host "2. Use the following commands:" -ForegroundColor Yellow
    Write-Host "   - change CNCA$pairNumber PortName=$targetPort" -ForegroundColor White
    Write-Host "   - change CNCB$pairNumber PortName=COM_MONITOR" -ForegroundColor White
    Write-Host "3. Click 'Apply' to save changes" -ForegroundColor Yellow
    Write-Host "4. When ready, press Enter to start monitoring" -ForegroundColor Yellow
    
    Read-Host "Press Enter when ready"
    
    $baudRate = Read-Host "Enter baud rate (default: 9600)"
    if ([string]::IsNullOrEmpty($baudRate)) { $baudRate = 9600 }
    
    # Start monitoring on the B side of the pair
    Monitor-ComPort -portName "COM_MONITOR" -baudRate $baudRate
}
else {
    Write-Host "Invalid selection." -ForegroundColor Red
} 