# COM Port Traffic Monitoring Toolkit

This toolkit provides a complete set of tools for monitoring, capturing, and analyzing COM port traffic in Windows applications, with a focus on Java applications.

## Key Tools

### Capture Tools

1. **success_replay.bat** - Our most reliable approach that combines multiple techniques:
   - Registers the DLL with regsvr32
   - Finds a running Java process
   - Injects the DLL using Injector.x86.exe
   - Opens an interactive menu for further actions

2. **continuous_monitor.ps1** - PowerShell script that provides continuous monitoring:
   - Automatically re-injects the DLL at regular intervals
   - Monitors the log file for changes
   - Displays captured traffic in real-time

3. **direct_inject_test.bat** - Simple batch script for direct DLL injection:
   - Automatically finds Java processes
   - Performs one-time DLL injection
   - Reports results

### Monitoring Tools

1. **monitor_log.bat** - Continuously monitors the log file:
   - Refreshes every 2 seconds
   - Shows the current log file contents

2. **filter_com_traffic.ps1** - Advanced tool for analyzing captured data:
   - Filters traffic based on message types
   - Identifies specific commands (AREQUEST, HARDWAREKEY, etc.)
   - Finds file operations (.SPS, .MEM, .NFO files)
   - Supports custom regex-based filtering

### Utility Tools

1. **check_com_ports.ps1** - Lists all available COM ports:
   - Shows detailed port information
   - Provides diagnostic details

2. **test_com_communication.ps1** - Allows direct COM port interaction:
   - Configurable communication parameters
   - Send/receive data manually
   - Useful for troubleshooting

## Quick Start Guide

1. **Check Available COM Ports**
   ```
   powershell -ExecutionPolicy Bypass -File check_com_ports.ps1
   ```

2. **Start Your Java Application**
   Make sure your Java application that uses COM ports is running.

3. **Launch the Success Replay Script**
   ```
   success_replay.bat
   ```
   This will:
   - Register the DLL
   - Find your Java process
   - Inject the DLL
   - Start monitoring the log file
   - Provide an interactive menu

4. **Analyze the Captured Traffic**
   Once you've captured some data:
   ```
   powershell -ExecutionPolicy Bypass -File filter_com_traffic.ps1
   ```

## Advanced Usage

### Continuous Monitoring

If you need persistent monitoring with automatic re-injection:
```
powershell -ExecutionPolicy Bypass -File continuous_monitor.ps1
```

### Direct COM Port Testing

If you want to test COM port communication directly:
```
powershell -ExecutionPolicy Bypass -File test_com_communication.ps1
```

## Troubleshooting

1. **No Log File Created**
   - Make sure the Java process is running
   - Verify you have write permissions to C:\temp
   - Try the continuous_monitor.ps1 which re-injects periodically

2. **DLL Injection Fails**
   - Run as Administrator
   - Temporarily disable antivirus
   - Verify the Java process architecture (must be 32-bit)
   - Try registering the DLL with regsvr32 first

3. **Cannot Connect to COM Port**
   - Verify the port isn't already in use
   - Check COM port permissions
   - Try a different port number

## Files and Components

- **Interceptor.x86.dll** - The 32-bit DLL that hooks COM port functions
- **Injector.x86.exe** - Tool that injects the DLL into processes
- **C:\temp\com_hook_log.txt** - Log file created by the DLL

## Technical Details

The injection works by hooking these Windows APIs:
- CreateFileW - To detect when COM ports are opened
- ReadFile - To capture incoming COM port data
- WriteFile - To capture outgoing COM port data

The captured protocol appears to be a SAAB-specific diagnostic protocol with:
- Messages starting with 0x81 followed by command bytes
- File operations for .SPS, .MEM, and .NFO files
- Various commands like AREQUEST, HARDWAREKEY, etc. 