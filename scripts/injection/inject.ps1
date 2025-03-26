$targetProcessId = 15100 
$dllPath = (Resolve-Path ".\Interceptor.x86.dll").Path 
Write-Host "Injecting DLL into process: $targetProcessId" 
Write-Host "DLL Path: $dllPath" 
 
$ErrorActionPreference = "Stop" 
try { 
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()) 
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) 
    Write-Host "Running as administrator: $isAdmin" 
    if (-not $isAdmin) { 
        Write-Host "WARNING: Not running as administrator. This may fail." 
    } 
    # Create log file 
    if (Test-Path "C:\temp\com_hook_log.txt") { Remove-Item "C:\temp\com_hook_log.txt" } 
