# Keep Alive Script - Continuously re-injects the DLL
Write-Host "=== DLL Injection Keep-Alive Script ===" -ForegroundColor Cyan
Write-Host ""

$targetProcessId = 6068
$dllPath = "Interceptor.x86.dll"
$injectorPath = "Injector.x86.exe"
$logFile = "C:\temp\com_hook_log.txt"

# Check if the process exists
try {
    $process = Get-Process -Id $targetProcessId -ErrorAction Stop
    Write-Host "Target process found: $($process.ProcessName) (PID: $targetProcessId)" -ForegroundColor Green
} catch {
    Write-Host "Process with ID $targetProcessId not found!" -ForegroundColor Red
    exit 1
}

# Create C:\temp if it doesn't exist
if (-not (Test-Path "C:\temp")) {
    Write-Host "Creating C:\temp directory..." -ForegroundColor Yellow
    New-Item -Path "C:\temp" -ItemType Directory -Force | Out-Null
}

# Define a function to inject the DLL
function Inject-DLL {
    Write-Host "Injecting DLL: $dllPath into process $targetProcessId..." -ForegroundColor Yellow
    
    & ".\$injectorPath" $targetProcessId $dllPath | Out-Null
    
    # Check if log file was updated with new content
    if (Test-Path $logFile) {
        $contentBefore = (Get-Content -Path $logFile -Raw -ErrorAction SilentlyContinue)
        $contentLength = if ($contentBefore) { $contentBefore.Length } else { 0 }
        
        Write-Host "Current log file size: $contentLength bytes" -ForegroundColor Gray
        return $contentLength
    } else {
        return 0
    }
}

# Start continuous monitoring and re-injection
Write-Host ""
Write-Host "Starting continuous injection and monitoring..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

$iterations = 0
$lastLogSize = 0
$currentLogSize = 0

try {
    # Start monitoring log file in a separate window
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -Command `"Get-Content -Path '$logFile' -Wait`"" -WindowStyle Normal
    
    while ($true) {
        $iterations++
        Write-Host "[Iteration $iterations] Re-injecting DLL..." -ForegroundColor Cyan
        
        # Inject DLL and get log file size
        $currentLogSize = Inject-DLL
        
        # Check if log file size has changed
        if ($currentLogSize -gt $lastLogSize) {
            Write-Host "Log file size increased! New content detected." -ForegroundColor Green
            
            # Get the new content only
            $newContent = (Get-Content -Path $logFile -Raw).Substring($lastLogSize)
            Write-Host "New content:" -ForegroundColor Green
            Write-Host "---------------------------------------------------" -ForegroundColor Gray
            Write-Host $newContent -ForegroundColor White
            Write-Host "---------------------------------------------------" -ForegroundColor Gray
            
            $lastLogSize = $currentLogSize
        }
        
        # Wait before next injection
        Write-Host "Waiting 10 seconds before next injection..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    Write-Host ""
    Write-Host "Keep-alive script stopped." -ForegroundColor Cyan
} 