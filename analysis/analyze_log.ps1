# COM Port Traffic Analyzer - Static Analysis
# This script parses the existing log file and displays the data in a more readable format

$logFile = "C:\temp\com_hook_log.txt"

# Check if log file exists
if (-not (Test-Path $logFile)) {
    Write-Host "Log file not found at $logFile" -ForegroundColor Red
    exit
}

Write-Host "=== COM Port Traffic Analyzer - Static Analysis ===" -ForegroundColor Cyan
Write-Host "Analyzing log file: $logFile" -ForegroundColor Cyan
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

# Process the log file
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

Write-Host "---------------------------------" -ForegroundColor Cyan
Write-Host "Analysis complete!" -ForegroundColor Cyan

# Summary of findings
Write-Host "Summary of Findings:" -ForegroundColor Magenta
Write-Host "1. This appears to be communication with a SAAB automotive system" -ForegroundColor White
Write-Host "2. File operations include reading calibration files (CALIBRAT0.SPS, etc.)" -ForegroundColor White
Write-Host "3. Commands include AREQUEST, RDWAREKEY#, HARDWAREKEY#, etc." -ForegroundColor White
Write-Host "4. Communication includes both binary data and readable text" -ForegroundColor White
Write-Host "5. The protocol appears to be a proprietary SAAB diagnostic protocol" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "To monitor real-time COM port traffic, run: powershell -ExecutionPolicy Bypass -File .\parse_com_log.ps1" -ForegroundColor White 