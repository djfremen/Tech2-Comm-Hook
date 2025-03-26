@echo off
echo Process Architecture Checker

if "%1"=="" (
  echo Please provide a PID as argument
  echo Example: check_process_arch.bat 6068
  exit /b 1
)

set PID=%1
echo Checking architecture for process with PID: %PID%

:: First check if the process exists
tasklist /FI "PID eq %PID%" | find "%PID%" > nul
if %ERRORLEVEL% neq 0 (
  echo ERROR: No process found with PID %PID%
  pause
  exit /b 1
)

:: Get process name
for /f "tokens=1,2 delims=," %%a in ('tasklist /FI "PID eq %PID%" /FO csv ^| findstr /v "PID"') do (
  set PROCESS_NAME=%%~a
)
echo Process name: %PROCESS_NAME%

:: Create temporary PowerShell script
echo $process = Get-Process -Id %PID% > check_arch.ps1
echo if ($process.StartInfo.EnvironmentVariables["PROCESSOR_ARCHITECTURE"] -eq "x86" -or >> check_arch.ps1
echo     $process.MainModule.FileName -like "*\SysWOW64\*" -or >> check_arch.ps1
echo     $process.MainModule.ModuleName -like "*32*") { >> check_arch.ps1
echo     Write-Host "Process appears to be 32-bit (x86)" >> check_arch.ps1
echo } elseif ($process.StartInfo.EnvironmentVariables["PROCESSOR_ARCHITECTURE"] -eq "AMD64" -or >> check_arch.ps1
echo           $process.MainModule.FileName -like "*\System32\*") { >> check_arch.ps1
echo     Write-Host "Process appears to be 64-bit (x64)" >> check_arch.ps1
echo } else { >> check_arch.ps1
echo     # Alternative check using Windows API >> check_arch.ps1
echo     Add-Type -TypeDefinition @" >> check_arch.ps1
echo     using System; >> check_arch.ps1
echo     using System.Runtime.InteropServices; >> check_arch.ps1
echo     public class ProcessInfo { >> check_arch.ps1
echo         [DllImport("kernel32.dll")] >> check_arch.ps1
echo         public static extern bool IsWow64Process(IntPtr hProcess, out bool wow64Process); >> check_arch.ps1
echo     } >> check_arch.ps1
echo "@ >> check_arch.ps1
echo     try { >> check_arch.ps1
echo         $is32on64 = $false >> check_arch.ps1
echo         $result = [ProcessInfo]::IsWow64Process($process.Handle, [ref]$is32on64) >> check_arch.ps1
echo         if ($result) { >> check_arch.ps1
echo             if ($is32on64) { >> check_arch.ps1
echo                 Write-Host "Process is 32-bit running on 64-bit Windows (WOW64)" >> check_arch.ps1
echo             } else { >> check_arch.ps1
echo                 # Not running under WOW64 - if on 64-bit Windows, must be 64-bit process >> check_arch.ps1
echo                 if ([Environment]::Is64BitOperatingSystem) { >> check_arch.ps1
echo                     Write-Host "Process is 64-bit" >> check_arch.ps1
echo                 } else { >> check_arch.ps1
echo                     Write-Host "Process is 32-bit on 32-bit Windows" >> check_arch.ps1
echo                 } >> check_arch.ps1
echo             } >> check_arch.ps1
echo         } else { >> check_arch.ps1
echo             Write-Host "Unable to determine process architecture via API" >> check_arch.ps1
echo         } >> check_arch.ps1
echo     } catch { >> check_arch.ps1
echo         Write-Host "Error checking process architecture via API: $_" >> check_arch.ps1
echo     } >> check_arch.ps1
echo } >> check_arch.ps1

:: Run the PowerShell script
echo.
echo Running architecture check...
powershell -ExecutionPolicy Bypass -File check_arch.ps1

:: Clean up temp file
del check_arch.ps1

echo.
echo IMPORTANT: Our DLL injector is 32-bit (x86).
echo If the target process is 64-bit, injection will fail.
echo In that case, you need to use a 64-bit injector.

pause 