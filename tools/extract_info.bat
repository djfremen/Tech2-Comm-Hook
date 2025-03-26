@echo off
setlocal

echo === COM Port Communication Analysis ===
echo.
echo Extracting key information from C:\temp\com_hook_log.txt
echo.

if not exist "C:\temp\com_hook_log.txt" (
    echo ERROR: Log file not found at C:\temp\com_hook_log.txt
    goto End
)

:: Create directory for extracted information
if not exist "extracted_data" mkdir "extracted_data"

:: Extract all file references
echo Extracting file references...
findstr /C:".SPS" /C:".MEM" /C:".NFO" "C:\temp\com_hook_log.txt" > "extracted_data\file_references.txt"
echo Done. See extracted_data\file_references.txt

:: Extract SAAB references
echo Extracting SAAB-related information...
findstr /C:"SAAB" "C:\temp\com_hook_log.txt" > "extracted_data\saab_references.txt"
echo Done. See extracted_data\saab_references.txt

:: Extract commands
echo Extracting commands...
findstr /C:"REQUEST" /C:"HARDWARE" "C:\temp\com_hook_log.txt" > "extracted_data\commands.txt"
echo Done. See extracted_data\commands.txt

:: Create summary
echo Creating summary...
echo === COM Port Communication Summary === > "extracted_data\summary.txt"
echo Created: %date% %time% >> "extracted_data\summary.txt"
echo. >> "extracted_data\summary.txt"

echo === SAAB Files === >> "extracted_data\summary.txt"
findstr /C:".SPS" /C:".MEM" /C:".NFO" "C:\temp\com_hook_log.txt" | findstr /R /C:"[A-Z0-9]\{3,\}\.[A-Z0-9]\{3\}" >> "extracted_data\summary.txt"
echo. >> "extracted_data\summary.txt"

echo === Commands === >> "extracted_data\summary.txt"
findstr /C:"AREQUEST" /C:"HARDWAREKEY" /C:"RDWAREKEY" "C:\temp\com_hook_log.txt" | findstr /V /C:"handle: " >> "extracted_data\summary.txt" 
echo. >> "extracted_data\summary.txt"

echo === SAAB Information === >> "extracted_data\summary.txt"
findstr /C:"SAAB Automobile AB" "C:\temp\com_hook_log.txt" >> "extracted_data\summary.txt"
echo. >> "extracted_data\summary.txt"

echo === Communication Statistics === >> "extracted_data\summary.txt"
echo Total TX Messages: >> "extracted_data\summary.txt"
findstr /C:"TX Data" "C:\temp\com_hook_log.txt" | find /C "TX Data" >> "extracted_data\summary.txt"
echo Total RX Messages: >> "extracted_data\summary.txt"
findstr /C:"RX Data" "C:\temp\com_hook_log.txt" | find /C "RX Data" >> "extracted_data\summary.txt"
echo. >> "extracted_data\summary.txt"

echo Summary created. See extracted_data\summary.txt

echo.
echo Analysis complete. All extracted information is in the "extracted_data" directory.
echo.

:End
pause 