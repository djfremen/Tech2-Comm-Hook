# Debug DLL Injection Error Script
# This script attempts to capture the specific error code from LoadLibraryA failure

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.IO;
using System.Diagnostics;

public class AdvancedInjector
{
    [DllImport("kernel32.dll")]
    public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("kernel32.dll", CharSet = CharSet.Ansi, ExactSpelling = true, SetLastError = true)]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

    [DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)]
    public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out UIntPtr lpNumberOfBytesWritten);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);

    [DllImport("kernel32.dll")]
    public static extern uint GetLastError();

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool GetExitCodeThread(IntPtr hThread, out IntPtr lpExitCode);

    // Constants
    public const int PROCESS_CREATE_THREAD = 0x0002;
    public const int PROCESS_QUERY_INFORMATION = 0x0400;
    public const int PROCESS_VM_OPERATION = 0x0008;
    public const int PROCESS_VM_WRITE = 0x0020;
    public const int PROCESS_VM_READ = 0x0010;
    public const uint MEM_RESERVE = 0x2000;
    public const uint MEM_COMMIT = 0x1000;
    public const uint PAGE_READWRITE = 0x04;
    public const uint INFINITE = 0xFFFFFFFF;
    public const uint WAIT_ABANDONED = 0x00000080;
    public const uint WAIT_OBJECT_0 = 0x00000000;
    public const uint WAIT_TIMEOUT = 0x00000102;
    public const uint WAIT_FAILED = 0xFFFFFFFF;

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

    public static string GetWindowsErrorMessage(uint errorCode)
    {
        IntPtr lpMsgBuf = IntPtr.Zero;
        uint dwFlags = 0x00001000 | 0x00000200; // FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM

        uint size = FormatMessage(dwFlags, IntPtr.Zero, errorCode, 0, ref lpMsgBuf, 0, IntPtr.Zero);
        if (size == 0)
            return $"Error code: {errorCode} (Could not retrieve error message)";

        string message = Marshal.PtrToStringAnsi(lpMsgBuf);
        Marshal.FreeHGlobal(lpMsgBuf);
        return $"Error {errorCode}: {message.Trim()}";
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint FormatMessage(uint dwFlags, IntPtr lpSource, uint dwMessageId, uint dwLanguageId, ref IntPtr lpBuffer, uint nSize, IntPtr Arguments);

    public static string InjectDLL(int processId, string dllPath)
    {
        StringBuilder log = new StringBuilder();
        log.AppendLine($"{DateTime.Now} - Attempting to inject DLL: {dllPath} into process: {processId}");
        
        // Get handle to target process
        IntPtr processHandle = OpenProcess(PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ, false, processId);
        if (processHandle == IntPtr.Zero)
        {
            uint errorCode = GetLastError();
            string errorMessage = GetWindowsErrorMessage(errorCode);
            log.AppendLine($"Failed to open process. {errorMessage}");
            return log.ToString();
        }
        log.AppendLine($"Successfully opened process with handle: {processHandle}");

        IntPtr threadHandle = IntPtr.Zero;
        try
        {
            // Get address of LoadLibraryA
            IntPtr kernel32Handle = GetModuleHandle("kernel32.dll");
            if (kernel32Handle == IntPtr.Zero)
            {
                uint errorCode = GetLastError();
                string errorMessage = GetWindowsErrorMessage(errorCode);
                log.AppendLine($"Failed to get kernel32.dll handle. {errorMessage}");
                return log.ToString();
            }
            log.AppendLine($"kernel32.dll handle: {kernel32Handle}");
            
            IntPtr loadLibraryAddr = GetProcAddress(kernel32Handle, "LoadLibraryA");
            if (loadLibraryAddr == IntPtr.Zero)
            {
                uint errorCode = GetLastError();
                string errorMessage = GetWindowsErrorMessage(errorCode);
                log.AppendLine($"Failed to get LoadLibraryA address. {errorMessage}");
                return log.ToString();
            }
            log.AppendLine($"LoadLibraryA address: {loadLibraryAddr}");

            // Check if DLL exists and is accessible
            if (!File.Exists(dllPath))
            {
                log.AppendLine($"The DLL file does not exist at path: {dllPath}");
                return log.ToString();
            }
            
            try 
            {
                FileAttributes attrs = File.GetAttributes(dllPath);
                log.AppendLine($"DLL file exists with attributes: {attrs}");
            }
            catch (Exception ex)
            {
                log.AppendLine($"Error accessing DLL file attributes: {ex.Message}");
            }

            // Allocate memory for DLL path
            byte[] pathBytes = System.Text.Encoding.ASCII.GetBytes(dllPath);
            IntPtr allocMemAddress = VirtualAllocEx(processHandle, IntPtr.Zero, (uint)pathBytes.Length + 1, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
            if (allocMemAddress == IntPtr.Zero)
            {
                uint errorCode = GetLastError();
                string errorMessage = GetWindowsErrorMessage(errorCode);
                log.AppendLine($"Failed to allocate memory in target process. {errorMessage}");
                return log.ToString();
            }
            log.AppendLine($"Allocated memory at address: {allocMemAddress}");

            // Write DLL path to process memory
            UIntPtr bytesWritten;
            bool writeResult = WriteProcessMemory(processHandle, allocMemAddress, pathBytes, (uint)pathBytes.Length, out bytesWritten);
            if (!writeResult)
            {
                uint errorCode = GetLastError();
                string errorMessage = GetWindowsErrorMessage(errorCode);
                log.AppendLine($"Failed to write to process memory. {errorMessage}");
                return log.ToString();
            }
            log.AppendLine($"Successfully wrote {bytesWritten} bytes to process memory");

            // Create remote thread to load DLL
            threadHandle = CreateRemoteThread(processHandle, IntPtr.Zero, 0, loadLibraryAddr, allocMemAddress, 0, IntPtr.Zero);
            if (threadHandle == IntPtr.Zero)
            {
                uint errorCode = GetLastError();
                string errorMessage = GetWindowsErrorMessage(errorCode);
                log.AppendLine($"Failed to create remote thread. {errorMessage}");
                return log.ToString();
            }
            log.AppendLine($"Successfully created remote thread with handle: {threadHandle}");
            
            // Wait for thread to complete
            uint waitResult = WaitForSingleObject(threadHandle, 5000); // Wait up to 5 seconds
            if (waitResult == WAIT_OBJECT_0)
            {
                log.AppendLine("Remote thread completed execution");
                
                // Get thread exit code
                IntPtr exitCode;
                if (GetExitCodeThread(threadHandle, out exitCode))
                {
                    if (exitCode == IntPtr.Zero)
                    {
                        log.AppendLine("ERROR: LoadLibraryA returned 0 (NULL)");
                        log.AppendLine("This typically means the DLL could not be loaded.");
                        log.AppendLine("Common reasons include:");
                        log.AppendLine("1. DLL not found at the specified path");
                        log.AppendLine("2. DLL dependencies are missing");
                        log.AppendLine("3. Architecture mismatch (32-bit vs 64-bit)");
                        log.AppendLine("4. DLL initialization failed (DllMain returned FALSE)");
                        log.AppendLine("5. Security restrictions prevented loading");
                        
                        // Try to determine the specific LoadLibrary error
                        log.AppendLine("Attempting to determine specific LoadLibrary error...");
                        
                        // Create a process with the same architecture to test loading
                        try
                        {
                            System.Reflection.Assembly assembly = System.Reflection.Assembly.LoadFile(dllPath);
                            log.AppendLine($"Current process can load the DLL. Assembly: {assembly.FullName}");
                        }
                        catch (Exception ex)
                        {
                            log.AppendLine($"Current process CANNOT load the DLL: {ex.Message}");
                            if (ex.InnerException != null)
                                log.AppendLine($"Inner exception: {ex.InnerException.Message}");
                        }
                    }
                    else
                    {
                        log.AppendLine($"LoadLibraryA returned: 0x{exitCode.ToInt64():X} (DLL Base Address)");
                        log.AppendLine("DLL was successfully loaded into the process!");
                    }
                }
                else
                {
                    uint errorCode = GetLastError();
                    string errorMessage = GetWindowsErrorMessage(errorCode);
                    log.AppendLine($"Could not get thread exit code. {errorMessage}");
                }
            }
            else if (waitResult == WAIT_TIMEOUT)
            {
                log.AppendLine("Remote thread timed out");
            }
            else
            {
                uint errorCode = GetLastError();
                string errorMessage = GetWindowsErrorMessage(errorCode);
                log.AppendLine($"WaitForSingleObject failed. {errorMessage}");
            }
            
            log.AppendLine("Injection attempt completed");
            return log.ToString();
        }
        finally
        {
            // Cleanup
            if (threadHandle != IntPtr.Zero)
                CloseHandle(threadHandle);
            CloseHandle(processHandle);
        }
    }
}
"@

# Configuration
$targetProcessId = 6068
$dllPath = "C:\temp\Interceptor.x86.dll"

# Ensure C:\temp exists
if (-not (Test-Path "C:\temp")) {
    New-Item -Path "C:\temp" -ItemType Directory -Force | Out-Null
    Write-Host "Created C:\temp directory" -ForegroundColor Green
}

# Ensure DLL exists
if (-not (Test-Path $dllPath)) {
    if (Test-Path ".\Interceptor.x86.dll") {
        Copy-Item -Path ".\Interceptor.x86.dll" -Destination $dllPath -Force
        Write-Host "Copied DLL to $dllPath" -ForegroundColor Green
    } else {
        Write-Host "DLL not found at expected locations" -ForegroundColor Red
        exit 1
    }
}

# Check if target process exists
$process = Get-Process -Id $targetProcessId -ErrorAction SilentlyContinue
if ($null -eq $process) {
    Write-Host "Process with ID $targetProcessId not found" -ForegroundColor Red
    exit 1
}

Write-Host "Target process: $($process.ProcessName) (PID: $targetProcessId)" -ForegroundColor Green
Write-Host "Process path: $($process.Path)" -ForegroundColor Cyan
Write-Host "Attempting detailed diagnostic DLL injection..." -ForegroundColor Yellow

# Run the enhanced injector
$logOutput = [AdvancedInjector]::InjectDLL($targetProcessId, $dllPath)

# Save log to file
$logOutput | Out-File -FilePath "C:\temp\detailed_injection_log.txt" -Encoding utf8

# Display log
Write-Host "===== Detailed Injection Log =====" -ForegroundColor Cyan
Write-Host $logOutput -ForegroundColor White
Write-Host "==================================" -ForegroundColor Cyan

# Check for log file creation
Write-Host "Checking for COM hook log file..." -ForegroundColor Yellow
$attempts = 0
$maxAttempts = 10
$success = $false

while ($attempts -lt $maxAttempts -and -not $success) {
    if (Test-Path "C:\temp\com_hook_log.txt") {
        $fileContent = Get-Content -Path "C:\temp\com_hook_log.txt" -Raw -ErrorAction SilentlyContinue
        if ($fileContent) {
            Write-Host "SUCCESS! Log file created and contains data." -ForegroundColor Green
            Write-Host "Log Content:" -ForegroundColor Cyan
            Write-Host $fileContent -ForegroundColor White
            $success = $true
        } else {
            Write-Host "Log file created but is empty" -ForegroundColor Yellow
            $success = $true
        }
    } else {
        $attempts++
        Write-Host "Waiting for log file (attempt $attempts of $maxAttempts)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
}

if (-not $success) {
    Write-Host "Log file was not created after $maxAttempts attempts" -ForegroundColor Red
}

Write-Host ""
Write-Host "Debug injection attempt completed. See C:\temp\detailed_injection_log.txt for full details." -ForegroundColor Cyan
Write-Host "Use Get-Content -Path 'C:\temp\com_hook_log.txt' -Wait to monitor COM port traffic if injection succeeded." -ForegroundColor Cyan 