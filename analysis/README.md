# COM Port Monitoring Tool

This project provides tools for monitoring and analyzing COM port communications by intercepting Windows API calls using the MinHook library.

## Components

- **MinHook Library**: Used for API hooking
- **Interceptor DLL**: Hooks the Windows API functions related to COM port operations
- **Injector**: Injects the DLL into target processes
- **Analysis Tools**: Scripts for analyzing and visualizing the captured data

## Quick Start

### Prerequisites

- Windows 10 or later
- Visual Studio with C++ support (for building from source)
- PowerShell 5.0 or later (for analysis scripts)

### Using Pre-built Binaries

1. Identify the target process that communicates with the COM port
   ```
   .\find_java_com8.bat
   ```

2. Note the Process ID (PID) of the target process

3. For 64-bit target processes, use:
   ```
   .\inject_hook.bat
   ```

4. For 32-bit target processes (like the Java process), use:
   ```
   .\inject_x86_auto.bat
   ```

5. Monitor the log file:
   ```
   type C:\temp\com_hook_log.txt
   ```

### Building from Source

#### Building 64-bit Components
```
.\build.bat
```

#### Building 32-bit Components
```
.\build_x86.bat
```

## Analysis Tools

### Basic Log Viewing
```
type C:\temp\com_hook_log.txt
```

### Real-time Monitoring
```
.\monitor_com.bat
```

### Detailed Analysis
```
powershell -ExecutionPolicy Bypass -File .\parse_com_log.ps1
```

### Static Analysis
```
powershell -ExecutionPolicy Bypass -File .\analyze_log.ps1
```

### Extract Key Information
```
.\extract_info.bat
```

## Architecture Notes

### 64-bit vs 32-bit

It's crucial to match the architecture of the DLL with the target process:

- For 64-bit processes, use Interceptor.dll and Injector.exe
- For 32-bit processes, use Interceptor.x86.dll and Injector.x86.exe

Attempting to inject a 64-bit DLL into a 32-bit process (or vice versa) will fail.

### Log File Location

All captured data is logged to:
```
C:\temp\com_hook_log.txt
```

Make sure this directory exists and is writable.

## Troubleshooting

### No Log File Created

1. Check that the target process is still running
2. Verify that you're using the correct architecture (32-bit or 64-bit)
3. Make sure C:\temp directory exists and is writable
4. Run the injection script as administrator

### Process Explorer Doesn't Show the DLL

If Process Explorer doesn't show the injected DLL in the target process:

1. Try restarting the target application
2. Ensure you have administrator privileges
3. Check Windows Event Log for any security or application errors

## Analysis Results

See [COM_Port_Analysis_Report.md](COM_Port_Analysis_Report.md) for detailed findings from the COM port communication analysis.

## License

This project uses the MinHook library, which is licensed under the Simplified BSD License. 