# COM Port Monitoring Tool

This project provides tools for monitoring and analyzing COM port communications by intercepting Windows API calls using the MinHook library.

## Project Structure

The project is organized into the following directories:

- **src**: Source code files (.cpp, .h)
- **bin**: Compiled binaries (.dll, .exe, .lib)
- **tools**: Scripts and utilities (.bat)
- **analysis**: Analysis scripts and results (.ps1, .md, extracted_data)

## Quick Start

### Prerequisites

- Windows 10 or later
- Visual Studio with C++ support (for building from source)
- PowerShell 5.0 or later (for analysis scripts)

### Steps to Capture COM Port Traffic

1. **Identify the target process that communicates with the COM port**
   - Find the PID of the Java application using Process Explorer or Task Manager
   - Verify it's a 32-bit process if it's Java (most likely in Program Files (x86) directory)

2. **Inject the DLL using one of these methods:**

   a. **With Administrator privileges (recommended):**
   ```
   .\run_as_admin.bat
   ```
   
   b. Using a preset PID script (edit for your PID first):
   ```
   .\inject_pid_15100.bat
   ```
   
   c. Using the custom PID script (specify PID as argument):
   ```
   .\inject_custom_pid.bat 12345
   ```
   Where 12345 is the PID of your target process.

3. **Monitor the log file**
   ```
   powershell -Command "Get-Content -Path 'C:\temp\com_hook_log.txt' -Wait"
   ```
   
   Or for a more formatted view:
   ```
   .\monitor_com_traffic.bat
   ```

4. **Analyze the captured data**
   - Use the analysis scripts in the `analysis` directory
   - Refer to COM_Port_Analysis_Report.md for interpretation guidance

## Building from Source

### Building 32-bit Components (for 32-bit target processes)
```
.\tools\build_x86.bat
```

### Building 64-bit Components (for 64-bit target processes)
```
.\tools\build.bat
```

## Troubleshooting

If you're experiencing issues with the DLL injection, please refer to the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) file for detailed information on common issues and solutions.

Common injection issues include:
- Antivirus/security software blocking the injection
- Privilege/permission issues
- Architecture mismatches
- DLL dependencies missing
- Process protection mechanisms

### Quick Troubleshooting Steps

1. Run the injection as administrator using `run_as_admin.bat`
2. Temporarily disable your antivirus software
3. Verify that the target process is still running
4. Confirm that C:\temp directory exists and is writable

## Protocol Analysis

The protocol captured appears to be a SAAB-specific diagnostic protocol with:

- Command structures like AREQUEST, RDWAREKEY#, HARDWAREKEY#
- File operations on .SPS, .MEM, and .NFO files
- Binary data mixed with ASCII text

For detailed analysis, see [analysis/COM_Port_Analysis_Report.md](analysis/COM_Port_Analysis_Report.md)

## License

This project uses the MinHook library, which is licensed under the Simplified BSD License.

# COM Port Monitoring with DLL Injection

This repository contains tools for monitoring and capturing COM port traffic by injecting a DLL into processes that use COM ports.

## Project Structure

- `Interceptor.dll` - 64-bit DLL for intercepting COM port communications
- `Interceptor.x86.dll` - 32-bit DLL for intercepting COM port communications
- `Injector.exe` - 64-bit DLL injector
- `Injector.x86.exe` - 32-bit DLL injector
- `handle.exe` - Sysinternals Handle utility for checking open handles
- `inject_hook.bat` - Original batch script for injection
- Various PowerShell and batch scripts for enhanced injection capabilities

## Prerequisites

- Windows 7/10/11
- Administrative privileges
- Target application using COM port (e.g., Java application)
- C:\temp directory (created automatically by scripts)

## Injection Toolkit

A comprehensive toolkit is now available to help with the DLL injection process. The toolkit provides multiple methods to inject the DLL into the target process.

### How to Use the Toolkit

1. Run `dll_injection_toolkit.bat` as Administrator
2. Select the appropriate option from the menu:
   - **Process Verification**: Check if the target Java process is 32-bit or 64-bit
   - **Enhanced DLL Injection**: Detailed logging and error reporting
   - **Process Explorer Injection**: GUI-based approach using Process Explorer
   - **Lightweight C# Injector**: Alternative approach that might bypass security restrictions
   - **Check Injection Status**: Verify if the injection was successful
   - **Monitor COM Port Traffic**: View captured COM port communications

### Available Tools

Each tool in the toolkit can also be run individually:

- `verify_process_architecture.ps1` - Determines if the target process is 32-bit or 64-bit
- `enhanced_inject.ps1` - Provides detailed logging and error reporting during injection
- `procexp_inject.ps1` - Uses Process Explorer for DLL injection (may bypass security restrictions)
- `light_inject.ps1` - Alternative C# implementation for DLL injection

## Steps to Capture COM Port Traffic

1. Identify the target Java process that communicates with the COM port
2. Run the DLL Injection Toolkit as Administrator: `dll_injection_toolkit.bat`
3. Verify the process architecture using option 1
4. Try injecting the DLL using options 2, 3, or 4
5. Check the injection status using option 5
6. Monitor the COM port traffic using option 6

If you prefer to run scripts manually instead of using the toolkit:

```batch
# Verify process architecture
powershell -ExecutionPolicy Bypass -File verify_process_architecture.ps1

# Enhanced injection with detailed logging
powershell -ExecutionPolicy Bypass -File enhanced_inject.ps1

# Process Explorer injection (GUI method)
powershell -ExecutionPolicy Bypass -File procexp_inject.ps1

# Lightweight C# injector
powershell -ExecutionPolicy Bypass -File light_inject.ps1

# Monitor traffic
powershell -Command "Get-Content -Path 'C:\temp\com_hook_log.txt' -Wait"
```

## Troubleshooting

### Common Issues

1. **Antivirus/Security Software Blocking**
   - Symptoms: Injection fails with no specific error
   - Solution: Temporarily disable real-time protection or add exceptions

2. **Privilege/Permission Issues**
   - Symptoms: Access denied errors
   - Solution: Run scripts as Administrator

3. **Architecture Mismatch**
   - Symptoms: "Bad image format" errors
   - Solution: Use `verify_process_architecture.ps1` to ensure you're using the correct DLL

4. **DLL Dependencies Missing**
   - Symptoms: "Module not found" errors
   - Solution: Check for missing dependencies using Dependency Walker

5. **Process Protection Mechanisms**
   - Symptoms: Injection fails with no specific reason
   - Solution: Try alternative injection methods in the toolkit

### Quick Troubleshooting Steps

1. Always run the injection as Administrator using `dll_injection_toolkit.bat`
2. Temporarily disable antivirus software if necessary
3. Verify that the target process is still running
4. Ensure C:\temp directory exists and is writable

## Building from Source

The source code for the DLL and injector is included in the `src` directory. To build:

1. Open the solution in Visual Studio
2. Build the solution for both x86 and x64 configurations
3. Copy the resulting DLLs and executables to the root directory

## Protocol Analysis

The captured protocol is a SAAB-specific diagnostic protocol with various command structures and file operations. See the analysis report for more details.

# COM Port Hook - Diagnostic and Testing

## Successfully Rebuilt DLLs

We've successfully rebuilt the DLLs from source code using the Visual Studio Build Tools:

1. **SimpleHook.x86.dll** - A minimal DLL that only logs to a file without any COM port hooking
2. ~~Interceptor.x86.dll~~ - The full COM port hook DLL (could not be rebuilt because MinHook library is missing)

## Testing Instructions

### Test the Simple DLL Injection

1. **Run as regular user**:
   ```
   .\inject_simple.bat
   ```
   This will attempt to inject the simple DLL without disabling Windows Defender.

2. **Run as Administrator with Defender temporarily disabled**:
   - Right-click Command Prompt or PowerShell
   - Select "Run as administrator"
   - Navigate to the hook directory:
     ```
     cd /d C:\Users\manfr\Downloads\hook
     ```
   - Run the script:
     ```
     .\defender_simple_inject.bat
     ```

### Troubleshooting

If injection fails with "LoadLibraryA returned 0", this indicates one of these issues:

1. **Missing dependencies**: Install Visual C++ Redistributable 2015-2022 (x86)
   - Download from: https://aka.ms/vs/17/release/vc_redist.x86.exe

2. **Windows Defender blocking**: Make sure to run the defender_simple_inject.bat script as Administrator

3. **Architecture mismatch**: Ensure the Java process is 32-bit

4. **Permission issues**: Try copying SimpleHook.x86.dll to the same folder as the Java executable

### What We've Achieved

1. Successfully set up the build environment for 32-bit DLLs
2. Created a simplified test DLL to isolate dependency issues
3. Created scripts to test with and without Windows Defender
4. Documented the injection process and troubleshooting steps

## Next Steps

- Acquire the MinHook library to rebuild the full Interceptor.x86.dll
- Consider the COM port redirection approach if DLL injection continues to fail 