# Continuous COM Port Monitor with Auto-Reinjection
Write-Host "===================================================="
Write-Host "Continuous COM Port Monitor"
Write-Host "===================================================="

$logFile = "C:\temp\com_hook_log.txt"
$injectorPath = ".\Injector.x86.exe"
$dllPath = ".\Interceptor.x86.dll"
$lastLogSize = 0
$reinjectionInterval = 15 # seconds

# Clear log file if it exists
if (Test-Path $logFile) {
    Remove-Item $logFile -Force
    Write-Host "Cleared existing log file" -ForegroundColor Yellow
}

# First, register the DLL with regsvr32 (this has helped in previous attempts)
Write-Host "Registering DLL with regsvr32..." -ForegroundColor Cyan
Start-Process regsvr32 -ArgumentList "/s `"$dllPath`"" -Wait

# Function to find Java process
function Find-JavaProcess {
    $javaProcess = Get-Process | Where-Object { $_.ProcessName -like "java*" } | Select-Object -First 1
    return $javaProcess
}

# Function to inject DLL
function Inject-DLL($processId) {
    Write-Host "Injecting DLL into process $processId..." -ForegroundColor Yellow
    $result = Start-Process $injectorPath -ArgumentList "$processId `"$dllPath`"" -Wait -PassThru
    Write-Host "Injection result: $($result.ExitCode)" -ForegroundColor $(if ($result.ExitCode -eq 0) { "Green" } else { "Red" })
    return $result.ExitCode
}

# Monitoring loop
while ($true) {
    # Check for Java process
    $javaProcess = Find-JavaProcess
    
    if ($javaProcess) {
        $processId = $javaProcess.Id
        Write-Host "Found Java process: $($javaProcess.ProcessName) (PID: $processId)" -ForegroundColor Green
        
        # Inject DLL (first time or periodically)
        Inject-DLL $processId
        
        $startTime = Get-Date
        $lastInjectionTime = $startTime
        
        # Inner loop for monitoring with the current process
        while ($true) {
            $currentTime = Get-Date
            
            # Check if we need to re-inject
            if (($currentTime - $lastInjectionTime).TotalSeconds -ge $reinjectionInterval) {
                Write-Host "Re-injection interval reached..." -ForegroundColor Yellow
                
                # Verify process is still running
                try {
                    $process = Get-Process -Id $processId -ErrorAction Stop
                    Inject-DLL $processId
                    $lastInjectionTime = Get-Date
                }
                catch {
                    Write-Host "Process $processId no longer exists. Looking for new Java process..." -ForegroundColor Red
                    break # Break inner loop to find new process
                }
            }
            
            # Check log file
            if (Test-Path $logFile) {
                try {
                    $currentLogSize = (Get-Item $logFile).Length
                    
                    if ($currentLogSize -gt $lastLogSize) {
                        # Log has grown, show new content
                        $content = Get-Content $logFile -Raw -ErrorAction SilentlyContinue
                        
                        Write-Host ("-" * 50) -ForegroundColor Gray
                        Write-Host "Log update detected at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
                        Write-Host $content -ForegroundColor White
                        Write-Host ("-" * 50) -ForegroundColor Gray
                        
                        $lastLogSize = $currentLogSize
                    }
                }
                catch {
                    Write-Host "Error reading log file: $_" -ForegroundColor Red
                }
            }
            
            # Brief pause
            Start-Sleep -Seconds 2
            
            # Status update every minute
            if (($currentTime - $startTime).TotalSeconds % 60 -lt 2) {
                Write-Host "Monitoring active... Last injection: $lastInjectionTime" -ForegroundColor Gray
            }
        }
    }
    else {
        Write-Host "No Java process found. Waiting..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
} 