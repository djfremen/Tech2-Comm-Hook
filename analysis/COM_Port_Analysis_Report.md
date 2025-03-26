# COM Port Analysis Report

## Introduction

This report provides a detailed analysis of the COM port communication captured using the MinHook library to intercept Windows API calls related to COM port operations. The analysis revealed communication between a Java application and a SAAB automotive system.

## Technical Implementation

### Architecture Mismatch and Solution

The initial attempt to hook the COM port communication failed because of an architecture mismatch:
- The Java process was running as a 32-bit application (`C:\Program Files (x86)\Java\jre6\bin\javaw.exe`)
- Our initial DLL was compiled for 64-bit systems

We successfully resolved this by:
1. Compiling a 32-bit version of the MinHook library
2. Creating a 32-bit version of the Interceptor DLL
3. Building a 32-bit version of the Injector
4. Injecting the 32-bit DLL into the 32-bit Java process

### Hook Implementation

The hook was implemented to intercept the following Windows API functions:
- ReadFile
- WriteFile
- DeviceIoControl
- CreateFileA/W

This allowed us to capture all COM port communication.

## Communication Analysis

### Communication Overview

The log file reveals bidirectional communication between the Java application and the SAAB system:
- TX (transmit): Data sent from the application to the SAAB system
- RX (receive): Data received from the SAAB system to the application

### Protocol Structure

The communication follows a structured protocol:
1. Most messages start with 0x81 followed by a command byte (0x7b, 0x5a, etc.)
2. Many messages contain readable text strings
3. File references and commands are clearly visible in the ASCII representation

### File Operations

The application reads various SAAB-specific files with extensions:
- `.SPS` - Calibration files (CALIBRAT0.SPS, CALIBRAT1.SPS, etc.)
- `.MEM` - Memory files (T3COMMON.MEM)
- `.NFO` - Information files (SAABDTC.NFO)

### Commands

Several commands were identified in the communication:
- AREQUEST
- RDWAREKEY# (likely "Read Hardware Key")
- HARDWAREKEY#
- SCAREQUEST

### Device Information

The communication revealed that the system is a SAAB Automobile AB product, likely a diagnostic or programming tool.

## Interesting Findings

1. The application appears to be accessing calibration files (CALIBRAT0.SPS through CALIBRAT3.SPS)
2. There are multiple hardware key requests, suggesting some form of authentication or validation
3. The protocol includes both binary data and ASCII text
4. The handle used for all communication was consistently 0x000008D4

## Conclusion

The hook successfully intercepted COM port communication between a Java application and a SAAB automotive system. The communication appears to be a proprietary diagnostic protocol used for reading vehicle data, accessing calibration files, and possibly programming vehicle modules.

The successful implementation of the 32-bit hook demonstrates that proper architecture matching is crucial when injecting DLLs into target processes.

## Future Work

For more detailed analysis:
1. Create a protocol decoder specific to this SAAB diagnostic protocol
2. Implement real-time monitoring with pattern recognition
3. Add functionality to save captured sessions for later analysis
4. Create filters to focus on specific message types or commands 