# Simple Debug DLL Injection Script

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.IO;

public class SimpleInjector
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

    [DllImport("kernel32.dll")]
    public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);

    [DllImport("kernel32.dll")]
    public static extern uint GetLastError();

    // Constants
    public const int PROCESS_CREATE_THREAD = 0x0002;
    public const int PROCESS_QUERY_INFORMATION = 0x0400;
    public const int PROCESS_VM_OPERATION = 0x0008;
    public const int PROCESS_VM_WRITE = 0x0020;
    public const int PROCESS_VM_READ = 0x0010;
    public const uint MEM_RESERVE = 0x2000;
    public const uint MEM_COMMIT = 0x1000;
    public const uint PAGE_READWRITE = 0x04;

    public static int InjectDLL(int processId, string dllPath)
    {
        // Get handle to target process
        IntPtr processHandle = OpenProcess(PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ, false, processId);
        if (processHandle == IntPtr.Zero)
        {
            uint errorCode = GetLastError();
            Console.WriteLine("Failed to open process. Error code: " + errorCode);
            return -1;
        }

        try
        {
            // Get address of LoadLibraryA
            IntPtr loadLibraryAddr = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
            if (loadLibraryAddr == IntPtr.Zero)
            {
                uint errorCode = GetLastError();
                Console.WriteLine("Failed to get LoadLibraryA address. Error code: " + errorCode);
                return -2;
            }

            // Allocate memory for DLL path
            byte[] pathBytes = Encoding.ASCII.GetBytes(dllPath);
            IntPtr allocMemAddress = VirtualAllocEx(processHandle, IntPtr.Zero, (uint)pathBytes.Length + 1, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
            if (allocMemAddress == IntPtr.Zero)
            {
                uint errorCode = GetLastError();
                Console.WriteLine("Failed to allocate memory in target process. Error code: " + errorCode);
                return -3;
            }

            // Write DLL path to process memory
            UIntPtr bytesWritten;
            bool writeResult = WriteProcessMemory(processHandle, allocMemAddress, pathBytes, (uint)pathBytes.Length, out bytesWritten);
            if (!writeResult)
            {
                uint errorCode = GetLastError();
                Console.WriteLine("Failed to write to process memory. Error code: " + errorCode);
                return -4;
            }

            // Create remote thread to load DLL
            IntPtr threadHandle = CreateRemoteThread(processHandle, IntPtr.Zero, 0, loadLibraryAddr, allocMemAddress, 0, IntPtr.Zero);
            if (threadHandle == IntPtr.Zero)
            {
                uint errorCode = GetLastError();
                Console.WriteLine("Failed to create remote thread. Error code: " + errorCode);
                return -5;
            }

            // Cleanup
            CloseHandle(threadHandle);
            return 0;
        }
        finally
        {
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
if ($process.Path) {
    Write-Host "Process path: $($process.Path)" -ForegroundColor Cyan
} else {
    Write-Host "Process path not available" -ForegroundColor Yellow
}

Write-Host "Attempting simple DLL injection..." -ForegroundColor Yellow

# Run the simple injector
$result = [SimpleInjector]::InjectDLL($targetProcessId, $dllPath)

# Display result
if ($result -eq 0) {
    Write-Host "Injection reported successful!" -ForegroundColor Green
} else {
    Write-Host "Injection failed with code: $result" -ForegroundColor Red
    
    # Interpret error codes
    switch ($result) {
        -1 { Write-Host "Failed to open process" -ForegroundColor Red }
        -2 { Write-Host "Failed to get LoadLibraryA address" -ForegroundColor Red }
        -3 { Write-Host "Failed to allocate memory in target process" -ForegroundColor Red }
        -4 { Write-Host "Failed to write to process memory" -ForegroundColor Red }
        -5 { Write-Host "Failed to create remote thread" -ForegroundColor Red }
    }
}

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
Write-Host "Important: Even if injection reported success, the DLL must be properly initialized by the target process." -ForegroundColor Cyan
Write-Host "Use Get-Content -Path 'C:\temp\com_hook_log.txt' -Wait to monitor COM port traffic if injection succeeded." -ForegroundColor Cyan 