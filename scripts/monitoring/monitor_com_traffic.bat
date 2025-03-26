@echo off
setlocal enabledelayedexpansion

echo === COM Port Traffic Monitor ===
echo.
echo This script will continuously monitor for COM port traffic.
echo Press Ctrl+C to stop monitoring.
echo.

:: Check if the log file exists
if not exist "C:\temp\com_hook_log.txt" (
    echo ERROR: Log file not found at C:\temp\com_hook_log.txt
    echo.
    echo Please run the injection script first and ensure it completes successfully.
    goto End
)

:: Start monitoring with PowerShell
echo Starting monitor...
echo.

:: Use PowerShell to format and display the data nicely
powershell -Command "& {
    Write-Host 'Monitoring COM port traffic in real-time...' -ForegroundColor Cyan
    Write-Host '----------------------------------------' -ForegroundColor Cyan
    
    # Function to extract readable text from hex data
    function Get-ReadableText {
        param([string]$hexData)
        
        $bytes = @()
        $hexData -split ' ' | ForEach-Object {
            if ($_ -match '^[0-9A-Fa-f]{2}$') {
                $bytes += [Convert]::ToByte($_, 16)
            }
        }
        
        $text = ''
        foreach ($byte in $bytes) {
            if ($byte -ge 32 -and $byte -le 126) {
                $text += [char]$byte
            } else {
                $text += '.'
            }
        }
        
        return $text
    }
    
    # Get initial content once
    $content = Get-Content -Path 'C:\temp\com_hook_log.txt'
    $lastLine = $content.Count
    
    # Then monitor continuously
    Get-Content -Path 'C:\temp\com_hook_log.txt' -Wait | ForEach-Object {
        # Skip lines we've already processed
        $lastLine++
        
        # Process TX/RX data lines
        if ($_ -match 'TX Data .Handle: ([0-9A-Fa-f]+), Size: (\d+) bytes.') {
            $handle = $matches[1]
            $size = $matches[2]
            $hexData = ''
            $direction = 'TX'
            $color = 'Green'
        }
        elseif ($_ -match 'RX Data .Handle: ([0-9A-Fa-f]+), Size: (\d+) bytes.') {
            $handle = $matches[1]
            $size = $matches[2]
            $hexData = ''
            $direction = 'RX'
            $color = 'Yellow'
        }
        elseif ($_ -match '\|\s+(.+?)\s+\|') {
            $hexPart = $matches[1] -replace '\s+', ' '
            $hexData += $hexPart
            $text = Get-ReadableText -hexData $hexPart
            
            Write-Host ('{0} [{1}] ({2} bytes): ' -f $direction, $handle, $size) -NoNewline -ForegroundColor $color
            Write-Host $hexPart -NoNewline -ForegroundColor Gray
            Write-Host ' | ' -NoNewline
            Write-Host $text -ForegroundColor Cyan
        }
    }
}"

:End
echo.
pause
endlocal 