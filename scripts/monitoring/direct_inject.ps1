# Simple direct injection script for PowerShell

# Check for Java processes
Write-Host "Checking for Java processes..." -ForegroundColor Cyan
$javaProcesses = Get-Process | Where-Object { $_.Name -like "java*" }

if ($javaProcesses -and $javaProcesses.Count -gt 0) {
    Write-Host "Found Java processes:" -ForegroundColor Green
    $javaProcesses | Format-Table Id, Name, Path -AutoSize
    
    # Target the first Java process found
    $targetPid = $javaProcesses[0].Id
    Write-Host "Targeting Java process with PID: $targetPid" -ForegroundColor Yellow
    
    # Create C:\temp if it doesn't exist
    if (-not (Test-Path "C:\temp")) {
        Write-Host "Creating C:\temp directory..." -ForegroundColor Cyan
        New-Item -Path "C:\temp" -ItemType Directory -Force | Out-Null
    }
    
    # Remove old log file if it exists
    if (Test-Path "C:\temp\com_hook_log.txt") {
        Write-Host "Removing old log file..." -ForegroundColor Cyan
        Remove-Item -Path "C:\temp\com_hook_log.txt" -Force
    }
    
    # Run the injector
    Write-Host "Running injection command..." -ForegroundColor Cyan
    Write-Host "Command: .\Injector.x86.exe $targetPid Interceptor.x86.dll" -ForegroundColor Gray
    
    $process = Start-Process -FilePath ".\Injector.x86.exe" -ArgumentList "$targetPid", "Interceptor.x86.dll" -NoNewWindow -Wait -PassThru
    $exitCode = $process.ExitCode
    
    Write-Host "Injection process completed with exit code: $exitCode" -ForegroundColor $(if ($exitCode -eq 0) { "Green" } else { "Red" })
    
    # Check for log file
    Write-Host "Checking for log file..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    
    if (Test-Path "C:\temp\com_hook_log.txt") {
        Write-Host "Log file created successfully!" -ForegroundColor Green
        Write-Host "Log file content:" -ForegroundColor Cyan
        Write-Host "---------------------------------------------------" -ForegroundColor Gray
        Get-Content -Path "C:\temp\com_hook_log.txt"
        Write-Host "---------------------------------------------------" -ForegroundColor Gray
    } else {
        Write-Host "Log file not created. Waiting longer..." -ForegroundColor Yellow
        
        # Wait up to 20 seconds for log file
        $attempts = 1
        $maxAttempts = 10
        $success = $false
        
        while ($attempts -le $maxAttempts -and -not $success) {
            Write-Host "Waiting for log file (attempt $attempts of $maxAttempts)..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            
            if (Test-Path "C:\temp\com_hook_log.txt") {
                Write-Host "Log file created!" -ForegroundColor Green
                Write-Host "Log file content:" -ForegroundColor Cyan
                Write-Host "---------------------------------------------------" -ForegroundColor Gray
                Get-Content -Path "C:\temp\com_hook_log.txt"
                Write-Host "---------------------------------------------------" -ForegroundColor Gray
                $success = $true
            }
            
            $attempts++
        }
        
        if (-not $success) {
            Write-Host "Log file was not created after multiple attempts." -ForegroundColor Red
            Write-Host "The injection may have failed or the Java application may not be using the COM port yet." -ForegroundColor Red
        }
    }
} else {
    Write-Host "No Java processes found!" -ForegroundColor Red
    Write-Host "Please start your Java application before running this script." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 