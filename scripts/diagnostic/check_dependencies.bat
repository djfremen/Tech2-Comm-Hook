@echo off
echo Checking DLL dependencies...

:: First check if dumpbin is available
where dumpbin >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo Using dumpbin to check dependencies...
    dumpbin /DEPENDENTS build\Interceptor.x86.dll
    goto end
)

:: If dumpbin is not available, try using PowerShell
echo Dumpbin not found, trying PowerShell...
powershell -Command "try { Add-Type -AssemblyName System.Reflection; $domain = [System.AppDomain]::CurrentDomain; $domain.add_AssemblyResolve({ param($sender, $args); $name = $args.Name; if ($name -like '*vcruntime*' -or $name -like '*msvcp*') { Write-Host \"[$name] requested, which could indicate missing VC++ Redistributable.\"; }; return $null; }); [System.Reflection.Assembly]::LoadFile(\"%~dp0build\Interceptor.x86.dll\"); Write-Host \"DLL loaded for inspection.\"; } catch { Write-Host \"Error: $_\"; }"

echo.
echo Checking for Visual C++ Redistributable installations...
powershell -Command "Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like '*Visual C++*' } | Format-Table Name, Version -AutoSize"
echo.

echo Next steps:
echo 1. Install Visual C++ Redistributable for Visual Studio 2015-2022 (x86):
echo    https://aka.ms/vs/17/release/vc_redist.x86.exe
echo.
echo 2. Ensure these paths are excluded in Windows Defender:
echo    - C:\Users\manfr\Downloads\hook\Injector.x86.exe
echo    - C:\Users\manfr\Downloads\hook\build\Interceptor.x86.dll
echo    - C:\temp

:end
pause 