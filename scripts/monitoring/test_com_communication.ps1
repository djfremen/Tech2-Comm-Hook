# Test COM Communication PowerShell Script
Write-Host "===================================================="
Write-Host "COM Port Communication Test"
Write-Host "===================================================="
Write-Host ""

# List available COM ports
Write-Host "Available COM ports:"
$comPorts = [System.IO.Ports.SerialPort]::GetPortNames()
for ($i = 0; $i -lt $comPorts.Count; $i++) {
    Write-Host "[$i] $($comPorts[$i])"
}

# If no COM ports available, exit
if ($comPorts.Count -eq 0) {
    Write-Host "No COM ports found. Exiting."
    exit
}

# Ask user to select COM port
Write-Host ""
$selection = Read-Host "Enter the number of the COM port to test"
$portName = $comPorts[$selection]

# Configure COM port parameters
Write-Host ""
Write-Host "Setting up COM port $portName"
$baudRate = Read-Host "Enter baud rate (default: 9600)"
if ([string]::IsNullOrEmpty($baudRate)) { $baudRate = 9600 }

$dataBits = Read-Host "Enter data bits (default: 8)"
if ([string]::IsNullOrEmpty($dataBits)) { $dataBits = 8 }

$parityOptions = @("None", "Odd", "Even", "Mark", "Space")
Write-Host "Parity options:"
for ($i = 0; $i -lt $parityOptions.Count; $i++) {
    Write-Host "[$i] $($parityOptions[$i])"
}
$paritySelection = Read-Host "Enter parity selection (default: 0)"
if ([string]::IsNullOrEmpty($paritySelection)) { $paritySelection = 0 }
$parity = [System.IO.Ports.Parity]($paritySelection)

$stopBitsOptions = @("One", "Two", "OnePointFive")
Write-Host "Stop bits options:"
for ($i = 0; $i -lt $stopBitsOptions.Count; $i++) {
    Write-Host "[$i] $($stopBitsOptions[$i])"
}
$stopBitsSelection = Read-Host "Enter stop bits selection (default: 0)"
if ([string]::IsNullOrEmpty($stopBitsSelection)) { $stopBitsSelection = 0 }
$stopBits = [System.IO.Ports.StopBits]($stopBitsSelection)

# Create and configure the serial port
try {
    $port = New-Object System.IO.Ports.SerialPort $portName, $baudRate, $parity, $dataBits, $stopBits
    $port.ReadTimeout = 1000
    $port.WriteTimeout = 1000
    
    # Open the port
    Write-Host ""
    Write-Host "Attempting to open $portName..."
    $port.Open()
    
    if ($port.IsOpen) {
        Write-Host "Port opened successfully!"
        Write-Host ""
        Write-Host "Enter data to send (empty line to exit):"
        
        # Communication loop
        while ($true) {
            $dataToSend = Read-Host ">"
            if ([string]::IsNullOrEmpty($dataToSend)) {
                break
            }
            
            # Send data
            $bytes = [System.Text.Encoding]::ASCII.GetBytes($dataToSend)
            $port.Write($bytes, 0, $bytes.Length)
            Write-Host "Data sent. Bytes: $($bytes.Length)"
            
            # Try to read response
            try {
                $buffer = New-Object byte[] 4096
                $bytesRead = $port.Read($buffer, 0, $buffer.Length)
                if ($bytesRead -gt 0) {
                    $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)
                    Write-Host "Response received:"
                    Write-Host $response
                    Write-Host "Hex: $([BitConverter]::ToString($buffer, 0, $bytesRead))"
                } else {
                    Write-Host "No response received."
                }
            }
            catch [TimeoutException] {
                Write-Host "Read timeout - no response received."
            }
            catch {
                Write-Host "Error reading response: $($_.Exception.Message)"
            }
            
            Write-Host ""
        }
        
        # Close the port
        $port.Close()
        Write-Host "Port closed."
    }
    else {
        Write-Host "Failed to open the port."
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)"
}
finally {
    # Ensure port is closed
    if ($port -and $port.IsOpen) {
        $port.Close()
        Write-Host "Port closed."
    }
}

Write-Host ""
Write-Host "===================================================="
Write-Host "Test complete."
Write-Host "====================================================" 