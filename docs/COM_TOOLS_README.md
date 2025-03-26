# COM Port Monitoring Tools

This set of tools helps you monitor and test COM port traffic using DLL injection.

## Available Tools

### 1. DLL Injection Tools

- **direct_inject_test.bat**: Tests DLL injection into a running Java process.
  - Automatically finds a running Java process
  - Injects the DLL and reports the result
  - Checks for and displays log file contents

### 2. Monitoring Tools

- **monitor_log.bat**: Continuously monitors the log file for changes.
  - Displays the current contents of the log file
  - Refreshes every 2 seconds

### 3. COM Port Tools

- **check_com_ports.ps1**: Lists all available COM ports and their properties.
  - Shows detailed information about each COM port
  - Uses WMI to gather port information

- **test_com_communication.ps1**: Interactive tool to test direct COM port communication.
  - Allows you to select a COM port
  - Configure communication parameters (baud rate, parity, etc.)
  - Send and receive data manually

## Usage Instructions

### Step 1: Check COM Ports

Run the COM port checker first to identify available ports:

```
powershell -ExecutionPolicy Bypass -File check_com_ports.ps1
```

### Step 2: Start the Java Application

Make sure your Java application is running before attempting DLL injection.

### Step 3: Inject the DLL

Run the direct injection test:

```
direct_inject_test.bat
```

### Step 4: Monitor the Log File

In a separate command prompt, run the log monitor:

```
monitor_log.bat
```

### Step 5: Test Direct COM Port Communication (Optional)

If you need to test direct communication with a COM port:

```
powershell -ExecutionPolicy Bypass -File test_com_communication.ps1
```

## Troubleshooting

If the DLL injection fails:

1. Make sure you're running as Administrator
2. Verify that the Java process is running and is 32-bit (x86)
3. Check that antivirus software isn't blocking the injection
4. Ensure the DLL and injector files are accessible
5. Look for error messages in the command output

If no log file is created:

1. The DLL may be failing to initialize
2. The COM port may not be active
3. Try using direct COM port communication to send test data

## Files Overview

- `Interceptor.x86.dll`: The DLL that hooks COM port functions
- `Injector.x86.exe`: Tool to inject the DLL into a process
- `C:\temp\com_hook_log.txt`: Log file created by the DLL
- Various .bat and .ps1 files for testing and monitoring 