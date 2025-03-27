# Tech2-Comm-Hook: COM Port Monitoring Tool

A tool for monitoring COM port traffic in Windows applications via DLL injection. This allows you to see all data being sent and received through COM ports in any application without modifying the application's source code.

## Features

- Intercepts CreateFileW, ReadFile, WriteFile, and CloseHandle API calls
- Logs all COM port traffic with timestamps
- Provides hex and ASCII representations of data
- Non-invasive - works with any application
- Logs to C:\temp\com_hook_log.txt

## Requirements

- Windows operating system
- Target process must be 32-bit (x86)
- Administrative privileges recommended

## Quick Start

1. Run `create_defender_exclusions.bat` as administrator to add necessary Windows Defender exclusions
2. Find the Process ID (PID) of your target application
3. Run `robust_inject.bat <PID>`, for example: `robust_inject.bat 9568`
4. Use the target application to perform COM port operations
5. Check C:\temp\com_hook_log.txt for COM port traffic logs

## Troubleshooting

If injection fails:
- Make sure you're running as Administrator
- Verify the target process is 32-bit using `check_process_arch.bat <PID>`
- Temporarily disable anti-virus/Windows Defender
- Restart the target application and try again

## Building from Source

Pre-compiled binaries are included, but if you want to build from source:

1. Make sure you have Visual Studio with C++ development tools installed
2. Run `scripts\building\build_hook_and_injector.bat` from the project root
3. The compiled files will be placed in `build\` and `tools\` directories

## Files

- `src/hook.cpp` - Source code for the DLL that hooks COM port functions
- `src/injector.cpp` - Source code for the DLL injector
- `build/Interceptor.x86.dll` - Compiled hook DLL (32-bit)
- `tools/Injector.x86.exe` - Compiled injector executable (32-bit)
- `robust_inject.bat` - Main script for injecting the DLL
- `create_defender_exclusions.bat` - Helper to add Windows Defender exclusions
- `check_process_arch.bat` - Utility to check process architecture

## Notes

- This tool is for educational and debugging purposes only
- The tool only logs data when the application actually uses COM ports
- Non-standard COM port access methods may not be captured 