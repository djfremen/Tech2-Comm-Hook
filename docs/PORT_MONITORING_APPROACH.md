# COM Port Monitoring: Recommended Approach

## Summary of Findings

The DLL injection approach consistently results in the hook DLL being loaded but immediately detaching. This makes it unsuitable for sustained monitoring of COM port traffic. We've created a more reliable approach using port redirection instead of DLL injection.

## Port Redirection Approach

Instead of trying to inject code into the Java process, we'll redirect the COM port traffic through a virtual port pair that we can monitor directly. This approach:

1. Is more reliable than DLL injection
2. Doesn't require modifications to the target process
3. Works regardless of security restrictions
4. Allows monitoring of all traffic with full fidelity

## Tools Provided

### 1. Port Redirection Setup

- **setup_port_redirect.bat**: Guides you through setting up the COM port redirection
  - Detects com0com installation
  - Helps configure port mapping
  - Launches the monitoring tool

### 2. Port Monitoring

- **com_port_redirect.ps1**: Advanced port redirection and monitoring tool
  - Detects virtual port pairs
  - Provides guided setup for redirection
  - Monitors and logs all port traffic

- **simple_port_monitor.ps1**: Simplified direct COM port monitor
  - Easy to use interface
  - Works with any COM port including virtual ones
  - Logs all traffic to a file

## Step-by-Step Instructions

### Step 1: Install com0com

If not already installed:
1. Download com0com (null-modem emulator) from:
   https://sourceforge.net/projects/com0com/
2. Install it with administrator privileges
3. Reboot if necessary to complete the installation

### Step 2: Configure Port Redirection

1. Run `setup_port_redirect.bat`
2. Follow the prompts to configure com0com
3. The script will guide you through mapping your Java app's port to a monitored port

### Step 3: Start Monitoring

1. Run the Java application as normal
2. Run `simple_port_monitor.ps1` and select the COM_MONITOR port
3. All traffic will be displayed in real-time and logged to `C:\temp\com_port_monitor.txt`

### Step 4: Analyze the Traffic

1. The monitor will display traffic in both hex and ASCII formats
2. All data is timestamped for easy analysis
3. You can use the existing `filter_com_traffic.ps1` script to analyze log files

## Advantages of This Approach

1. **Reliability**: Works consistently without detachment issues
2. **Security**: Doesn't trigger antivirus or security alerts
3. **Simplicity**: No need for complex DLL injection
4. **Completeness**: Captures all COM port traffic accurately
5. **Persistence**: Continues to work even if the Java process restarts

## For Advanced Users

If you need more detailed control, the `com_port_redirect.ps1` script offers additional configuration options for:
- Monitoring multiple ports
- Setting up complex redirections
- Configuring baud rates and other COM parameters

## Conclusion

The port redirection approach is the recommended method for monitoring COM port traffic from your Java application. It avoids the issues encountered with DLL injection while providing reliable and comprehensive monitoring capabilities. 