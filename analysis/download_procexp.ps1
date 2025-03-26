# PowerShell script to download Process Explorer from Sysinternals
$url = "https://download.sysinternals.com/files/ProcessExplorer.zip"
$tempDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
$null = New-Item -ItemType Directory -Path $tempDir -Force
$zipPath = "$tempDir\ProcessExplorer.zip"

Write-Host "Downloading Process Explorer from Sysinternals..."
try {
    # Download the zip file
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
    
    # Extract the zip file
    Write-Host "Extracting the zip file..."
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
    
    # Find procexp.exe and procexp64.exe in the extracted files
    $procExpFiles = Get-ChildItem -Path $tempDir -Recurse -Include "procexp*.exe" 
    
    if ($procExpFiles) {
        # Create a ProcessExplorer directory if it doesn't exist
        $targetDir = ".\ProcessExplorer"
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        # Copy Process Explorer executables to the target directory
        foreach ($file in $procExpFiles) {
            Copy-Item -Path $file.FullName -Destination $targetDir -Force
            Write-Host "Copied $($file.Name) to $targetDir"
        }
        
        Write-Host "Process Explorer has been downloaded and extracted to $targetDir"
        Write-Host "Run .\ProcessExplorer\procexp64.exe to start Process Explorer."
    } else {
        throw "Could not find Process Explorer executables in the extracted files."
    }
} catch {
    Write-Host "Error downloading or extracting Process Explorer: $_"
    exit 1
}

# Clean up
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
} 