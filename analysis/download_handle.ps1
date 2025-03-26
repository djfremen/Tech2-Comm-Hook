# PowerShell script to download Handle.exe from Sysinternals
$url = "https://download.sysinternals.com/files/Handle.zip"
$tempDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
$null = New-Item -ItemType Directory -Path $tempDir -Force
$zipPath = "$tempDir\Handle.zip"

Write-Host "Downloading Handle.exe from Sysinternals..."
try {
    # First approach - use Invoke-WebRequest
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    
    # Extract the zip file
    Write-Host "Extracting the zip file..."
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
    
    # Find Handle.exe in the extracted files
    $handleExe = Get-ChildItem -Path $tempDir -Recurse -Filter "handle.exe" | Select-Object -First 1
    
    if ($handleExe) {
        # Copy Handle.exe to the current directory
        Copy-Item -Path $handleExe.FullName -Destination ".\handle.exe" -Force
        Write-Host "Handle.exe has been downloaded and copied to the current directory."
    } else {
        throw "Could not find handle.exe in the extracted files."
    }
} catch {
    Write-Host "Error downloading or extracting Handle.exe: $_"
    Write-Host "Trying alternative method..."
    
    # Alternative approach - use .NET WebClient
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile("https://live.sysinternals.com/handle.exe", ".\handle.exe")
        Write-Host "Handle.exe has been downloaded directly from live.sysinternals.com."
    } catch {
        Write-Host "Error downloading Handle.exe using alternative method: $_"
        exit 1
    }
}

# Update the inject_hook.bat script to use Handle.exe from the current directory
Write-Host "Updating inject_hook.bat to use the downloaded Handle.exe..."
$content = Get-Content -Path "inject_hook.bat"
$updatedContent = $content -replace 'set "HANDLE_EXE=handle.exe".*REM', 'set "HANDLE_EXE=%~dp0handle.exe"     REM'
Set-Content -Path "inject_hook.bat" -Value $updatedContent

Write-Host "Done! Handle.exe has been downloaded and inject_hook.bat has been updated."

# Clean up
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
} 