# COM Port Traffic Analyzer
# This script parses the log file and displays the data in a more readable format

$logFile = "C:\temp\com_hook_log.txt"

# Check if log file exists
if (-not (Test-Path $logFile)) {
    Write-Host "Log file not found at $logFile" -ForegroundColor Red
    exit
}

Write-Host "=== COM Port Traffic Analyzer ===" -ForegroundColor Cyan
Write-Host "Analyzing log file: $logFile" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to exit" -ForegroundColor Cyan
Write-Host "---------------------------------" -ForegroundColor Cyan

function Extract-Text {
    param (
        [string]$hexData
    )
    
    # Convert hex string to bytes
    $bytes = @()
    $hexData -split ' ' | ForEach-Object {
        if ($_ -match '[0-9A-Fa-f]{2}') {
            $bytes += [Convert]::ToByte($_, 16)
        }
    }
    
    # Convert bytes to ASCII text, replacing non-printable characters with dots
    $text = ""
    foreach ($byte in $bytes) {
        if ($byte -ge 32 -and $byte -le 126) {
            $text += [char]$byte
        } else {
            $text += "."
        }
    }
    
    return $text
}

function Process-LogData {
    $content = Get-Content $logFile
    
    $direction = ""
    $hexData = ""
    $handle = ""
    $size = 0
    
    foreach ($line in $content) {
        if ($line -match "TX Data \(Handle: ([0-9A-Fa-f]+), Size: (\d+) bytes\):") {
            if ($hexData -ne "") {
                # Process previous data
                $text = Extract-Text $hexData
                Write-Host "$direction ($handle, $size bytes):" -ForegroundColor Yellow
                Write-Host "  HEX: $hexData" -ForegroundColor Gray
                Write-Host "  TXT: $text" -ForegroundColor Green
                Write-Host ""
            }
            
            $direction = "TX"
            $handle = $matches[1]
            $size = $matches[2]
            $hexData = ""
        }
        elseif ($line -match "RX Data \(Handle: ([0-9A-Fa-f]+), Size: (\d+) bytes\):") {
            if ($hexData -ne "") {
                # Process previous data
                $text = Extract-Text $hexData
                Write-Host "$direction ($handle, $size bytes):" -ForegroundColor Yellow
                Write-Host "  HEX: $hexData" -ForegroundColor Gray
                Write-Host "  TXT: $text" -ForegroundColor Green
                Write-Host ""
            }
            
            $direction = "RX"
            $handle = $matches[1]
            $size = $matches[2]
            $hexData = ""
        }
        elseif ($line -match "\| (.+) \|") {
            # Extract hex data
            $hexData += " " + ($matches[1] -replace '\s+', ' ').Trim()
        }
    }
    
    # Process the last data entry
    if ($hexData -ne "") {
        $text = Extract-Text $hexData
        Write-Host "$direction ($handle, $size bytes):" -ForegroundColor Yellow
        Write-Host "  HEX: $hexData" -ForegroundColor Gray
        Write-Host "  TXT: $text" -ForegroundColor Green
    }
}

# Main execution
Process-LogData

# Now monitor for changes
Write-Host "---------------------------------" -ForegroundColor Cyan
Write-Host "Monitoring for new COM port traffic..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to exit" -ForegroundColor Cyan
Write-Host "---------------------------------" -ForegroundColor Cyan

$lastSize = (Get-Item $logFile).Length
$initialRun = $true

while ($true) {
    Start-Sleep -Seconds 1
    
    $currentSize = (Get-Item $logFile).Length
    
    if ($currentSize -gt $lastSize) {
        if ($initialRun) {
            # Skip initial processing to avoid duplicate output
            $initialRun = $false
        } else {
            $newContent = Get-Content $logFile | Select-Object -Skip (Get-Content $logFile).Count - 10
            
            $direction = ""
            $hexData = ""
            $handle = ""
            $size = 0
            
            foreach ($line in $newContent) {
                if ($line -match "TX Data \(Handle: ([0-9A-Fa-f]+), Size: (\d+) bytes\):") {
                    if ($hexData -ne "") {
                        # Process previous data
                        $text = Extract-Text $hexData
                        Write-Host "$direction ($handle, $size bytes):" -ForegroundColor Yellow
                        Write-Host "  HEX: $hexData" -ForegroundColor Gray
                        Write-Host "  TXT: $text" -ForegroundColor Green
                        Write-Host ""
                    }
                    
                    $direction = "TX"
                    $handle = $matches[1]
                    $size = $matches[2]
                    $hexData = ""
                }
                elseif ($line -match "RX Data \(Handle: ([0-9A-Fa-f]+), Size: (\d+) bytes\):") {
                    if ($hexData -ne "") {
                        # Process previous data
                        $text = Extract-Text $hexData
                        Write-Host "$direction ($handle, $size bytes):" -ForegroundColor Yellow
                        Write-Host "  HEX: $hexData" -ForegroundColor Gray
                        Write-Host "  TXT: $text" -ForegroundColor Green
                        Write-Host ""
                    }
                    
                    $direction = "RX"
                    $handle = $matches[1]
                    $size = $matches[2]
                    $hexData = ""
                }
                elseif ($line -match "\| (.+) \|") {
                    # Extract hex data
                    $hexData += " " + ($matches[1] -replace '\s+', ' ').Trim()
                }
            }
            
            # Process the last data entry
            if ($hexData -ne "") {
                $text = Extract-Text $hexData
                Write-Host "$direction ($handle, $size bytes):" -ForegroundColor Yellow
                Write-Host "  HEX: $hexData" -ForegroundColor Gray
                Write-Host "  TXT: $text" -ForegroundColor Green
            }
        }
        
        $lastSize = $currentSize
    }
} 