# Check COM Ports PowerShell Script
Write-Host "===================================================="
Write-Host "COM Port Checker"
Write-Host "===================================================="
Write-Host ""

Write-Host "Checking for available COM ports..."
$comPorts = [System.IO.Ports.SerialPort]::GetPortNames()

if ($comPorts.Count -eq 0) {
    Write-Host "No COM ports found on this system."
} else {
    Write-Host "Found $($comPorts.Count) COM port(s):"
    foreach ($port in $comPorts) {
        Write-Host "- $port"
    }
    
    Write-Host ""
    Write-Host "Getting detailed information for each port..."
    
    # Use WMI to get detailed information
    $portInfo = Get-WmiObject Win32_SerialPort
    
    if ($portInfo) {
        foreach ($port in $portInfo) {
            Write-Host ""
            Write-Host "Port: $($port.DeviceID)"
            Write-Host "  Description: $($port.Description)"
            Write-Host "  Status: $($port.Status)"
            Write-Host "  PNP Device ID: $($port.PNPDeviceID)"
            Write-Host "  Provider Type: $($port.ProviderType)"
            Write-Host "  Max Baud Rate: $($port.MaxBaudRate)"
        }
    } else {
        Write-Host "Unable to retrieve detailed port information."
    }
}

Write-Host ""
Write-Host "===================================================="
Write-Host "Check complete."
Write-Host "====================================================" 