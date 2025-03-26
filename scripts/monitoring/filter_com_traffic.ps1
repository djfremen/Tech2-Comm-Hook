# COM Port Traffic Filter Tool
Write-Host "===================================================="
Write-Host "COM Port Traffic Filter Tool"
Write-Host "===================================================="
Write-Host ""

$logFile = "C:\temp\com_hook_log.txt"

# Check if log file exists
if (-not (Test-Path $logFile)) {
    Write-Host "Log file not found at: $logFile" -ForegroundColor Red
    Write-Host "Please run a COM port capture first."
    exit
}

# Read the log file
$logContent = Get-Content $logFile -Raw

Write-Host "Log file loaded: $logFile" -ForegroundColor Green
Write-Host "File size: $((Get-Item $logFile).Length) bytes" -ForegroundColor Gray
Write-Host ""

# Define known patterns based on the analysis report
$patterns = @{
    "Command81"           = "81 [0-9A-F]{2}"  # Messages starting with 0x81
    "FileOperationsSPS"   = "\.SPS"           # SPS file references
    "FileOperationsMEM"   = "\.MEM"           # MEM file references
    "FileOperationsNFO"   = "\.NFO"           # NFO file references
    "AREQUEST"            = "AREQUEST"        # AREQUEST command
    "HardwareKey"         = "RDWAREKEY|HARDWAREKEY" # Hardware key operations
    "SCAREQUEST"          = "SCAREQUEST"      # SCAREQUEST command
    "CalibrationFiles"    = "CALIBRAT[0-9]"   # Calibration files
}

# Function to filter content based on pattern
function Filter-LogContent {
    param (
        [string]$content,
        [string]$pattern,
        [string]$description
    )
    
    Write-Host "----- Filtering for $description -----" -ForegroundColor Cyan
    
    $matches = [regex]::Matches($content, $pattern)
    
    if ($matches.Count -eq 0) {
        Write-Host "No matches found." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Found $($matches.Count) matches:" -ForegroundColor Green
    
    # Find and display full lines containing the matches
    $lines = $content -split "`n"
    $matchedLines = @()
    
    foreach ($line in $lines) {
        if ($line -match $pattern) {
            $matchedLines += $line
            # Limit to first 10 matches to avoid overwhelming output
            if ($matchedLines.Count -ge 10) {
                break
            }
        }
    }
    
    # Display matched lines with some context
    foreach ($line in $matchedLines) {
        Write-Host $line -ForegroundColor White
    }
    
    if ($matches.Count -gt 10) {
        Write-Host "(Showing first 10 matches of $($matches.Count) total)" -ForegroundColor Gray
    }
    
    Write-Host ""
}

# Display menu for filtering options
function Show-FilterMenu {
    Write-Host "===================================================="
    Write-Host "Select a filter to apply:"
    Write-Host "===================================================="
    Write-Host "1. Messages starting with 0x81 (command headers)"
    Write-Host "2. SPS file operations (calibration files)"
    Write-Host "3. MEM file operations (memory files)"
    Write-Host "4. NFO file operations (information files)"
    Write-Host "5. AREQUEST commands"
    Write-Host "6. Hardware key operations"
    Write-Host "7. SCAREQUEST commands"
    Write-Host "8. Calibration file references"
    Write-Host "9. Custom filter (regex pattern)"
    Write-Host "10. Display all data"
    Write-Host "0. Exit"
    Write-Host ""
    
    $choice = Read-Host "Enter choice (0-10)"
    
    switch ($choice) {
        "1" { Filter-LogContent $logContent $patterns["Command81"] "Command Headers (0x81)" }
        "2" { Filter-LogContent $logContent $patterns["FileOperationsSPS"] "SPS File Operations" }
        "3" { Filter-LogContent $logContent $patterns["FileOperationsMEM"] "MEM File Operations" }
        "4" { Filter-LogContent $logContent $patterns["FileOperationsNFO"] "NFO File Operations" }
        "5" { Filter-LogContent $logContent $patterns["AREQUEST"] "AREQUEST Commands" }
        "6" { Filter-LogContent $logContent $patterns["HardwareKey"] "Hardware Key Operations" }
        "7" { Filter-LogContent $logContent $patterns["SCAREQUEST"] "SCAREQUEST Commands" }
        "8" { Filter-LogContent $logContent $patterns["CalibrationFiles"] "Calibration File References" }
        "9" {
            $customPattern = Read-Host "Enter custom regex pattern"
            Filter-LogContent $logContent $customPattern "Custom Pattern: $customPattern"
        }
        "10" {
            Write-Host "Displaying all log data:" -ForegroundColor Cyan
            Write-Host $logContent -ForegroundColor White
        }
        "0" { return $false }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
        }
    }
    
    return $true
}

# Main loop
$continue = $true
while ($continue) {
    $continue = Show-FilterMenu
}

Write-Host "Exiting filter tool." -ForegroundColor Yellow 