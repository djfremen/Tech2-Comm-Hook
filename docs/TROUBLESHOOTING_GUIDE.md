# COM Port Hook Troubleshooting Guide

This guide provides a systematic approach to troubleshoot and resolve issues with DLL injection for COM port monitoring.

## New Tools Provided

We've created several new tools to help diagnose and fix injection issues:

1. **injection_diagnostic.bat** - Comprehensive diagnostic tool that:
   - Checks administrative privileges
   - Verifies Windows Defender settings
   - Validates file paths and permissions
   - Identifies running Java processes
   - Finds COM port handles
   - Tests the injection process
   - Provides detailed logs and recommendations

2. **improved_inject_hook.bat** - Enhanced injection script with:
   - Better error handling
   - Detailed output at each step
   - Automatic Java process detection
   - Log file monitoring

3. **setup_defender_exclusions.ps1** - PowerShell script to properly configure Windows Defender:
   - Adds all necessary exclusions
   - Validates current exclusion status
   - Provides guidance for manual configuration if needed

4. **COM port redirection tools** (alternative approach):
   - **setup_port_redirect.bat** - Configures com0com for port redirection
   - **simple_port_monitor.ps1** - Direct COM port monitoring tool
   - **com_port_redirect.ps1** - Advanced port redirection and monitoring

## Step-by-Step Troubleshooting Process

### 1. Set Up Windows Defender Exclusions

The most common cause of injection failure is security software blocking the process. Start by properly configuring Windows Defender:

```
powershell -ExecutionPolicy Bypass -File setup_defender_exclusions.ps1
```

This script will:
- Add exclusions for Injector.x86.exe
- Add exclusions for Interceptor.x86.dll
- Add exclusions for tools and build directories
- Add exclusion for C:\temp

### 2. Run the Diagnostic Tool

The diagnostic tool will identify any issues with your setup:

```
injection_diagnostic.bat
```

This will:
- Check for administrative privileges
- Verify all required files exist
- Check directory permissions
- List Java processes
- Find processes with handles to your COM port
- Test the injection process
- Analyze results and provide recommendations

### 3. Try the Improved Injection Script

If the diagnostic tool shows no critical issues, try the improved injection script:

```
improved_inject_hook.bat
```

This script provides:
- Clear feedback at each step
- Automatic PID detection for the Java process
- Immediate log file monitoring
- Error codes and troubleshooting guidance

### 4. Check for Common Issues

If injection still fails, check these common issues:

#### Windows Defender/Security Software

Even with exclusions, security software may be blocking the injection:
- Temporarily disable real-time protection just before injection
- Check the Protection History in Windows Security for blocked actions
- Verify exclusions were properly applied

#### Process Architecture Mismatch

Ensure architecture compatibility:
- Verify the Java process is 32-bit (the DLL is compiled for x86)
- If using a 64-bit Java process, you'll need a 64-bit version of the DLL

#### DLL Loading but Detaching

If the log file shows the DLL attaches but immediately detaches:
- This is often due to an initialization issue in the DLL
- Try the continuous_monitor.ps1 script which re-injects periodically

### 5. Alternative Approach: COM Port Redirection

If DLL injection continues to be problematic, try the COM port redirection approach:

1. Run `setup_port_redirect.bat` to configure com0com 
2. Follow the prompts to create a virtual port pair
3. Map one port to the port your Java application uses
4. Use `simple_port_monitor.ps1` to monitor the other port

This approach:
- Avoids security issues with DLL injection
- Works with any Java application
- Captures all COM port traffic reliably

## When to Use Each Tool

- **injection_diagnostic.bat**: Use first to diagnose issues
- **setup_defender_exclusions.ps1**: Use to set up security exclusions
- **improved_inject_hook.bat**: Use for improved injection process
- **setup_port_redirect.bat**: Use if DLL injection continues to fail

## Interpreting Log Files

The hook DLL writes to C:\temp\com_hook_log.txt. Look for these patterns:

- **Success**: Log contains "Hook DLL Attached" and shows traffic data
- **Instant Detachment**: Log contains "Hook DLL Attached" immediately followed by "Hook DLL Detaching"
- **No Log**: Injection failed completely or security software blocked the DLL

## Reporting Problems

If you continue to experience issues, collect the following information:

1. The diagnostic log file created by injection_diagnostic.bat
2. Windows Event Viewer logs (Application and System)
3. Windows Defender Protection History
4. The exact error message and return code from the injection process

## Additional Resources

- [Windows Defender Exclusions Guide](https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/configure-exclusions-microsoft-defender-antivirus)
- [Handle.exe Documentation](https://docs.microsoft.com/en-us/sysinternals/downloads/handle)
- [COM0COM Documentation](https://sourceforge.net/projects/com0com/) 