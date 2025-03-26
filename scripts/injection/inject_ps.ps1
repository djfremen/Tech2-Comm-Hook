Write-Host "=== PowerShell DLL Injection ===" -ForegroundColor Cyan
Write-Host

# Target process ID
$targetProcessId = 15100

# Get path to DLL
$dllPath = (Resolve-Path ".\Interceptor.x86.dll").Path

Write-Host "Target Process ID: $targetProcessId"
Write-Host "DLL Path: $dllPath"
Write-Host

# Check if process exists
$process = Get-Process -Id $targetProcessId -ErrorAction SilentlyContinue
if ($null -eq $process) {
    Write-Host "ERROR: Process with ID $targetProcessId not found." -ForegroundColor Red
    exit
}

Write-Host "Process found: $($process.ProcessName)" -ForegroundColor Green
Write-Host "Process path: $($process.MainModule.FileName)" -ForegroundColor Green
Write-Host

# Check if C:\temp exists, create if not
if (-not (Test-Path "C:\temp")) {
    Write-Host "Creating C:\temp directory..."
    New-Item -Path "C:\temp" -ItemType Directory | Out-Null
}

# Create or clear log file
if (Test-Path "C:\temp\com_hook_log.txt") {
    Remove-Item "C:\temp\com_hook_log.txt"
}
"--- PowerShell Injection Test Log ---" | Out-File "C:\temp\com_hook_log.txt"
"Injection attempted at: $(Get-Date)" | Out-File "C:\temp\com_hook_log.txt" -Append
"Target Process: $($process.ProcessName) (PID: $targetProcessId)" | Out-File "C:\temp\com_hook_log.txt" -Append
"Process Path: $($process.MainModule.FileName)" | Out-File "C:\temp\com_hook_log.txt" -Append
"" | Out-File "C:\temp\com_hook_log.txt" -Append

Write-Host "Running as Administrator: " -NoNewline
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host $isAdmin -ForegroundColor Green
} else {
    Write-Host $isAdmin -ForegroundColor Yellow
    Write-Host "WARNING: Not running as administrator. This may fail." -ForegroundColor Yellow
}

Write-Host
Write-Host "Attempting DLL injection using Injector.x86.exe..." -ForegroundColor Cyan
Write-Host "Command: .\Injector.x86.exe $targetProcessId `"$dllPath`""

# Run the injector
try {
    $output = & .\Injector.x86.exe $targetProcessId "$dllPath" 2>&1
    $exitCode = $LASTEXITCODE
    
    Write-Host $output
    Write-Host "Exit code: $exitCode"
    
    $output | Out-File "C:\temp\com_hook_log.txt" -Append
    "Exit code: $exitCode" | Out-File "C:\temp\com_hook_log.txt" -Append
    
    if ($exitCode -eq 0) {
        Write-Host "Injection appears successful!" -ForegroundColor Green
    } else {
        Write-Host "Injection failed with exit code $exitCode" -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    $_ | Out-File "C:\temp\com_hook_log.txt" -Append
}

Write-Host
Write-Host "Log file created at C:\temp\com_hook_log.txt" -ForegroundColor Cyan
Write-Host "Note: If injection was successful, the DLL will replace this log with its own output." -ForegroundColor Cyan
Write-Host
Write-Host "To monitor COM port traffic, run:" -ForegroundColor Cyan
Write-Host "  Get-Content -Path 'C:\temp\com_hook_log.txt' -Wait" -ForegroundColor White

Write-Host
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 