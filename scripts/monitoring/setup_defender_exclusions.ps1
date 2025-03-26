# Windows Defender Exclusion Setup for COM Port Hook
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Windows Defender Exclusion Setup for COM Port Hook" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script requires administrative privileges." -ForegroundColor Red
    Write-Host "Please right-click on the PowerShell icon and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "Running with administrative privileges." -ForegroundColor Green
Write-Host ""

# Get current directory
$currentDir = Get-Location

# Define paths to exclude
$injectorPath = Join-Path -Path $currentDir -ChildPath "tools\Injector.x86.exe"
$dllPath = Join-Path -Path $currentDir -ChildPath "build\Interceptor.x86.dll"
$toolsDir = Join-Path -Path $currentDir -ChildPath "tools"
$buildDir = Join-Path -Path $currentDir -ChildPath "build"
$tempDir = "C:\temp"

# Check if files exist
$allFilesExist = $true

Write-Host "Checking for required files..." -ForegroundColor Cyan
if (Test-Path $injectorPath) {
    Write-Host "  [OK] Found Injector at: $injectorPath" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Injector not found at: $injectorPath" -ForegroundColor Yellow
    $allFilesExist = $false
}

if (Test-Path $dllPath) {
    Write-Host "  [OK] Found Hook DLL at: $dllPath" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Hook DLL not found at: $dllPath" -ForegroundColor Yellow
    $allFilesExist = $false
}

if (-not $allFilesExist) {
    Write-Host ""
    Write-Host "Some files were not found. Make sure you're running this script from the correct directory." -ForegroundColor Yellow
    Write-Host "Current directory: $currentDir" -ForegroundColor Yellow
    
    $continue = Read-Host "Continue anyway? (Y/N)"
    if ($continue -ne "Y" -and $continue -ne "y") {
        Write-Host "Exiting..." -ForegroundColor Yellow
        exit 1
    }
}

# Check current Windows Defender status
Write-Host ""
Write-Host "Checking current Windows Defender status..." -ForegroundColor Cyan
try {
    $defenderStatus = Get-MpPreference
    $realTimeProtection = Get-MpComputerStatus | Select-Object -ExpandProperty RealTimeProtectionEnabled
    
    Write-Host "  Real-time protection enabled: " -NoNewline
    if ($realTimeProtection) {
        Write-Host "Yes" -ForegroundColor Yellow
    } else {
        Write-Host "No" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Current exclusions:" -ForegroundColor Cyan
    Write-Host "  Process exclusions: $($defenderStatus.ExclusionProcess.Count)" -ForegroundColor White
    Write-Host "  Path exclusions: $($defenderStatus.ExclusionPath.Count)" -ForegroundColor White
    
    # Check if our paths are already excluded
    $injectorExcluded = $defenderStatus.ExclusionProcess -contains $injectorPath
    $dllPathExcluded = $defenderStatus.ExclusionPath -contains $buildDir -or $defenderStatus.ExclusionPath -contains $dllPath
    $toolsDirExcluded = $defenderStatus.ExclusionPath -contains $toolsDir
    $tempDirExcluded = $defenderStatus.ExclusionPath -contains $tempDir
    
    Write-Host ""
    Write-Host "Current status of required exclusions:" -ForegroundColor Cyan
    Write-Host "  Injector excluded: " -NoNewline
    if ($injectorExcluded) { Write-Host "Yes" -ForegroundColor Green } else { Write-Host "No" -ForegroundColor Red }
    
    Write-Host "  Hook DLL excluded: " -NoNewline
    if ($dllPathExcluded) { Write-Host "Yes" -ForegroundColor Green } else { Write-Host "No" -ForegroundColor Red }
    
    Write-Host "  Tools directory excluded: " -NoNewline
    if ($toolsDirExcluded) { Write-Host "Yes" -ForegroundColor Green } else { Write-Host "No" -ForegroundColor Red }
    
    Write-Host "  Temp directory excluded: " -NoNewline
    if ($tempDirExcluded) { Write-Host "Yes" -ForegroundColor Green } else { Write-Host "No" -ForegroundColor Red }
} 
catch {
    Write-Host "  [ERROR] Failed to get Windows Defender status: $_" -ForegroundColor Red
}

# Confirm before adding exclusions
Write-Host ""
Write-Host "The following exclusions will be added to Windows Defender:" -ForegroundColor Yellow
Write-Host "  1. Process: $injectorPath" -ForegroundColor White
Write-Host "  2. Path: $dllPath" -ForegroundColor White
Write-Host "  3. Path: $toolsDir" -ForegroundColor White
Write-Host "  4. Path: $buildDir" -ForegroundColor White
Write-Host "  5. Path: $tempDir" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Add these exclusions to Windows Defender? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Operation cancelled by user." -ForegroundColor Yellow
    exit 0
}

# Add exclusions
Write-Host ""
Write-Host "Adding exclusions to Windows Defender..." -ForegroundColor Cyan

try {
    # Add process exclusion
    if (-not $injectorExcluded) {
        Write-Host "  Adding process exclusion for Injector.x86.exe..." -ForegroundColor White
        Add-MpPreference -ExclusionProcess $injectorPath -ErrorAction Stop
        Write-Host "  [OK] Added process exclusion" -ForegroundColor Green
    } else {
        Write-Host "  [OK] Injector.x86.exe already excluded" -ForegroundColor Green
    }
    
    # Add path exclusions
    if (-not $dllPathExcluded) {
        Write-Host "  Adding path exclusion for Hook DLL..." -ForegroundColor White
        Add-MpPreference -ExclusionPath $dllPath -ErrorAction Stop
        Write-Host "  [OK] Added DLL path exclusion" -ForegroundColor Green
    } else {
        Write-Host "  [OK] Hook DLL path already excluded" -ForegroundColor Green
    }
    
    if (-not $toolsDirExcluded) {
        Write-Host "  Adding path exclusion for tools directory..." -ForegroundColor White
        Add-MpPreference -ExclusionPath $toolsDir -ErrorAction Stop
        Write-Host "  [OK] Added tools directory exclusion" -ForegroundColor Green
    } else {
        Write-Host "  [OK] Tools directory already excluded" -ForegroundColor Green
    }
    
    if (-not $buildDirExcluded) {
        Write-Host "  Adding path exclusion for build directory..." -ForegroundColor White
        Add-MpPreference -ExclusionPath $buildDir -ErrorAction Stop
        Write-Host "  [OK] Added build directory exclusion" -ForegroundColor Green
    } else {
        Write-Host "  [OK] Build directory already excluded" -ForegroundColor Green
    }
    
    if (-not $tempDirExcluded) {
        Write-Host "  Adding path exclusion for temp directory..." -ForegroundColor White
        if (-not (Test-Path $tempDir)) {
            Write-Host "  [INFO] Creating temp directory..." -ForegroundColor White
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        }
        Add-MpPreference -ExclusionPath $tempDir -ErrorAction Stop
        Write-Host "  [OK] Added temp directory exclusion" -ForegroundColor Green
    } else {
        Write-Host "  [OK] Temp directory already excluded" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "All exclusions added successfully!" -ForegroundColor Green
}
catch {
    Write-Host "  [ERROR] Failed to add exclusions: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "You may need to add these exclusions manually in Windows Security settings:" -ForegroundColor Yellow
    Write-Host "  1. Open Windows Security" -ForegroundColor White
    Write-Host "  2. Go to Virus & threat protection" -ForegroundColor White
    Write-Host "  3. Click on Manage settings under Virus & threat protection settings" -ForegroundColor White
    Write-Host "  4. Scroll down to Exclusions and click Add or remove exclusions" -ForegroundColor White
    Write-Host "  5. Add the paths and processes listed above" -ForegroundColor White
}

# Provide additional information
Write-Host ""
Write-Host "Additional information:" -ForegroundColor Cyan
Write-Host "  1. If you continue to have issues, you can temporarily disable Real-time protection" -ForegroundColor White
Write-Host "     just before running the injection script." -ForegroundColor White
Write-Host "  2. If Windows Defender is managed by your organization, you may need to" -ForegroundColor White
Write-Host "     contact your administrator to add these exclusions." -ForegroundColor White
Write-Host "  3. After successful injection, you can consider removing these exclusions if desired." -ForegroundColor White
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run the improved_inject_hook.bat script to inject the hook" -ForegroundColor White
Write-Host "  2. If issues persist, run injection_diagnostic.bat for detailed troubleshooting" -ForegroundColor White
Write-Host ""

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 