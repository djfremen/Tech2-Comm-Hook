# COM Port Traffic Monitoring Tools

This toolkit provides multiple approaches for monitoring, capturing, and analyzing COM port traffic from Java applications.

## Summary of Approaches

We've developed two main approaches to monitoring COM port traffic:

### Approach 1: DLL Injection (Limited Success)

This approach uses DLL injection to hook Windows API functions related to COM port operations. While technically functional, we've observed that the DLL consistently attaches but then immediately detaches, making sustained monitoring challenging.

**Key Files:**
- `Interceptor.x86.dll` - The hook DLL
- `Injector.x86.exe` - Utility to inject the DLL
- `continuous_monitor.ps1` - Script that re-injects the DLL periodically
- `time_machine.bat` - Recreates the steps that previously worked

### Approach 2: COM Port Redirection (Recommended)

This approach uses com0com (virtual null modem) to create port pairs and redirect the COM port traffic through a monitored port. This is more reliable than DLL injection and doesn't require modifying the target process.

**Key Files:**
- `setup_port_redirect.bat` - Guides through port redirection setup
- `com_port_redirect.ps1` - Advanced port redirection and monitoring
- `simple_port_monitor.ps1` - Direct COM port monitor

## Detailed Instructions

### For the Port Redirection Approach (Recommended)

1. **Install com0com** (if not already installed)
   - Download from: https://sourceforge.net/projects/com0com/
   - Install with administrator privileges

2. **Set Up Port Redirection**
   - Run `setup_port_redirect.bat`
   - Follow the prompts to configure the virtual port pair
   - Map your Java application's COM port to a monitored port

3. **Start Monitoring**
   - Run `simple_port_monitor.ps1`
   - Select the COM_MONITOR port (or other configured port)
   - All traffic will be displayed and logged to `C:\temp\com_port_monitor.txt`

### For the DLL Injection Approach (Alternative)

1. **Quick Test**
   - Run `direct_inject_test.bat` to attempt a simple injection
   - Check if a log file is created at `C:\temp\com_hook_log.txt`

2. **Continuous Monitoring**
   - Run `continuous_monitor.ps1` to repeatedly inject the DLL
   - This may capture brief windows of COM traffic before detachment

3. **Time Machine Approach**
   - Run `time_machine.bat` to recreate the exact steps that worked previously
   - This performs multiple injections with pauses in between

## Analysis Tools

Both approaches include tools for analyzing the captured traffic:

- `filter_com_traffic.ps1` - Filters and analyzes log files for specific patterns
- `test_com_communication.ps1` - Tests direct COM port communication

## Troubleshooting

### Port Redirection Issues

- Make sure com0com is installed correctly
- Verify the Java application is using the redirected port
- Try different baud rates and COM port settings

### DLL Injection Issues

- Run as Administrator
- Temporarily disable antivirus software
- Verify the Java process is 32-bit (the DLL is x86)
- Check the log file for "Hook DLL Attached" messages

## Technical Details

### What's Happening with the DLL Injection

The DLL successfully loads into the Java process but immediately detaches. This is evidenced by log entries:

```
--- Hook DLL Attached ---
MinHook Initialized.
Hooks Created.
Hooks Enabled.
--- Hook DLL Detaching ---
Hooks Disabled.
MinHook Uninitialized.
```

This could be due to:
1. Security restrictions in Windows
2. Anti-tampering in the Java process
3. Issues with the DLL's initialization

### How the Port Redirection Works

1. com0com creates virtual port pairs (e.g., CNCA0 <-> CNCB0)
2. We configure one port of the pair to have the same name as the port your Java app uses
3. When the Java app opens that COM port, it's actually opening a virtual port
4. We monitor the other end of the virtual port pair to see all traffic

## Conclusion

The port redirection approach is the most reliable method for monitoring COM port traffic from your Java application. It avoids the issues encountered with DLL injection while providing comprehensive monitoring capabilities.

If you need to modify the monitoring tools or adapt them for other purposes, the source code is well-commented and follows a modular design. 