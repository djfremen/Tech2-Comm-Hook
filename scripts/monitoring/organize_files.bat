@echo off
setlocal

echo === Organizing Files into Directory Structure ===
echo.

:: Check if directories exist, create if not
if not exist "src" mkdir "src"
if not exist "bin" mkdir "bin"
if not exist "tools" mkdir "tools"
if not exist "analysis" mkdir "analysis"

:: First, copy the current script to avoid moving it
copy "organize_files.bat" "organize_files_temp.bat"

echo Moving source files to src directory...
for %%F in (*.cpp) do if not "%%F"=="organize_files.bat" move /Y "%%F" "src\"
for %%F in (*.h) do if not "%%F"=="organize_files.bat" move /Y "%%F" "src\"

echo Moving compiled binaries to bin directory...
for %%F in (*.dll) do move /Y "%%F" "bin\"
for %%F in (*.exe) do move /Y "%%F" "bin\"
for %%F in (*.lib) do move /Y "%%F" "bin\"

echo Moving batch scripts and tools to tools directory...
for %%F in (*.bat) do (
    if not "%%F"=="organize_files.bat" (
        if not "%%F"=="organize_files_temp.bat" (
            move /Y "%%F" "tools\"
        )
    )
)

echo Moving analysis scripts and logs to analysis directory...
for %%F in (*.ps1) do move /Y "%%F" "analysis\"
for %%F in (*.md) do move /Y "%%F" "analysis\"
if exist "extracted_data" move /Y "extracted_data" "analysis\"

echo Creating symbolic links for important executables in root directory...
if exist "bin\Interceptor.x86.dll" (
    echo Creating link for Interceptor.x86.dll...
    copy "bin\Interceptor.x86.dll" "Interceptor.x86.dll"
)

if exist "bin\Injector.x86.exe" (
    echo Creating link for Injector.x86.exe...
    copy "bin\Injector.x86.exe" "Injector.x86.exe"
)

if exist "tools\inject_pid_15100.bat" (
    echo Creating link for inject_pid_15100.bat...
    copy "tools\inject_pid_15100.bat" "inject_pid_15100.bat"
)

:: Delete the temporary script
del "organize_files_temp.bat"

echo.
echo Organization complete.
echo.
echo The files have been organized as follows:
echo   - src: Source code files (.cpp, .h)
echo   - bin: Compiled binaries (.dll, .exe, .lib)
echo   - tools: Scripts and utilities (.bat)
echo   - analysis: Analysis scripts and results (.ps1, .md, extracted_data)
echo.
echo Copies have been created in the root directory for:
echo   - Interceptor.x86.dll
echo   - Injector.x86.exe
echo   - inject_pid_15100.bat
echo.

pause
endlocal 