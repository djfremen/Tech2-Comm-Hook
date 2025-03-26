// injector.cpp - Simple Command-Line DLL Injector
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <iostream>
#include <string>
#include <tlhelp32.h> // For GetProcAddress / LoadLibraryA addresses

// Log file path definition (same as in hook.cpp for consistency)
const char* LOG_FILE_PATH = "C:\\temp\\com_hook_log.txt";

// Function to enable SeDebugPrivilege (often needed for injection)
bool EnableDebugPrivilege() {
    HANDLE hToken;
    LUID luid;
    TOKEN_PRIVILEGES tkp;

    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hToken)) {
        std::cerr << "Injector Error: OpenProcessToken failed: " << GetLastError() << std::endl;
        return false;
    }

    if (!LookupPrivilegeValue(NULL, SE_DEBUG_NAME, &luid)) {
        std::cerr << "Injector Error: LookupPrivilegeValue failed: " << GetLastError() << std::endl;
        CloseHandle(hToken);
        return false;
    }

    tkp.PrivilegeCount = 1;
    tkp.Privileges[0].Luid = luid;
    tkp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;

    if (!AdjustTokenPrivileges(hToken, FALSE, &tkp, sizeof(tkp), NULL, NULL)) {
        std::cerr << "Injector Error: AdjustTokenPrivileges failed: " << GetLastError() << std::endl;
        CloseHandle(hToken);
        return false;
    }

    if (GetLastError() == ERROR_NOT_ALL_ASSIGNED) {
         std::cerr << "Injector Warning: The token does not have the specified privilege (SeDebugPrivilege). Injection might fail." << std::endl;
         // Continue anyway, might work if target process has lower integrity
    }

    CloseHandle(hToken);
    return true;
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <PID> <DLL_Path>" << std::endl;
        return 1;
    }

    DWORD targetPID = 0;
    try {
        targetPID = std::stoul(argv[1]);
    } catch (const std::exception& e) {
        std::cerr << "Error: Invalid PID provided: " << argv[1] << " (" << e.what() << ")" << std::endl;
        return 1;
    }

    const char* dllPath = argv[2];
    char fullDllPath[MAX_PATH];

    // Get full path to DLL - important for LoadLibrary in target process
    if (GetFullPathNameA(dllPath, MAX_PATH, fullDllPath, nullptr) == 0) {
        std::cerr << "Error: Could not get full path for DLL: " << dllPath << " (Error: " << GetLastError() << ")" << std::endl;
        return 1;
    }

     // Check if DLL file actually exists before trying to inject
     if (GetFileAttributesA(fullDllPath) == INVALID_FILE_ATTRIBUTES) {
          std::cerr << "Error: DLL file not found at specified path: " << fullDllPath << std::endl;
          return 1;
     }

    std::cout << "Attempting to inject " << fullDllPath << " into process " << targetPID << std::endl;

    // Try to enable Debug Privilege
    if (!EnableDebugPrivilege()) {
        std::cout << "Warning: Could not enable SeDebugPrivilege. Proceeding anyway..." << std::endl;
    }

    // 1. Open Target Process
    HANDLE hProcess = OpenProcess(
        PROCESS_QUERY_INFORMATION | // Needed by some injection techniques/checks
        PROCESS_CREATE_THREAD     | // Needed for CreateRemoteThread
        PROCESS_VM_OPERATION      | // Needed for VirtualAllocEx/WriteProcessMemory
        PROCESS_VM_WRITE          | // Needed for WriteProcessMemory
        PROCESS_VM_READ,            // Optional, but useful for some techniques
        FALSE, targetPID);

    if (hProcess == NULL) {
        std::cerr << "Error: OpenProcess failed for PID " << targetPID << ". Error: " << GetLastError() << std::endl;
        std::cerr << "Possible reasons: PID doesn't exist, insufficient permissions (try Run as Admin), process protection." << std::endl;
        return 1;
    }
    std::cout << "Process opened successfully." << std::endl;

    // 2. Allocate Memory in Target Process for DLL Path
    size_t dllPathSize = strlen(fullDllPath) + 1; // +1 for null terminator
    LPVOID remoteMem = VirtualAllocEx(hProcess, NULL, dllPathSize, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (remoteMem == NULL) {
        std::cerr << "Error: VirtualAllocEx failed. Error: " << GetLastError() << std::endl;
        CloseHandle(hProcess);
        return 1;
    }
    std::cout << "Memory allocated in target process at 0x" << std::hex << remoteMem << std::dec << std::endl;

    // 3. Write DLL Path to Allocated Memory
    SIZE_T bytesWritten = 0;
    if (!WriteProcessMemory(hProcess, remoteMem, fullDllPath, dllPathSize, &bytesWritten) || bytesWritten != dllPathSize) {
        std::cerr << "Error: WriteProcessMemory failed. Error: " << GetLastError() << std::endl;
        VirtualFreeEx(hProcess, remoteMem, 0, MEM_RELEASE);
        CloseHandle(hProcess);
        return 1;
    }
    std::cout << "DLL path written to target process." << std::endl;

    // 4. Get LoadLibraryA Address
    // Note: Assumes kernel32.dll is loaded at the same base address in both injector and target
    // (Generally true due to ASLR for system DLLs, but not guaranteed across reboots/versions)
    LPVOID loadLibAddr = (LPVOID)GetProcAddress(GetModuleHandleA("kernel32.dll"), "LoadLibraryA");
    if (loadLibAddr == NULL) {
         std::cerr << "Error: GetProcAddress(LoadLibraryA) failed. Error: " << GetLastError() << std::endl;
         VirtualFreeEx(hProcess, remoteMem, 0, MEM_RELEASE);
         CloseHandle(hProcess);
         return 1;
    }
     std::cout << "LoadLibraryA address found at 0x" << std::hex << loadLibAddr << std::dec << std::endl;

    // 5. Create Remote Thread to Call LoadLibraryA
    HANDLE hRemoteThread = CreateRemoteThread(hProcess, NULL, 0, (LPTHREAD_START_ROUTINE)loadLibAddr, remoteMem, 0, NULL);
    if (hRemoteThread == NULL) {
        std::cerr << "Error: CreateRemoteThread failed. Error: " << GetLastError() << std::endl;
        VirtualFreeEx(hProcess, remoteMem, 0, MEM_RELEASE);
        CloseHandle(hProcess);
        return 1;
    }
    std::cout << "Remote thread created successfully. Waiting for it to finish..." << std::endl;

    // 6. Wait for the remote thread and check LoadLibrary's result (optional but good)
    WaitForSingleObject(hRemoteThread, INFINITE);

    DWORD remoteThreadExitCode = 0;
    GetExitCodeThread(hRemoteThread, &remoteThreadExitCode);

    // LoadLibrary returns the HMODULE (base address) of the loaded DLL on success, NULL (0) on failure
    if (remoteThreadExitCode == 0) {
         std::cerr << "Error: LoadLibraryA failed inside the target process (returned NULL)." << std::endl;
         std::cerr << "Possible reasons: DLL dependencies missing (VC++ Redist?), wrong DLL architecture, DLL DllMain returned FALSE, security software blocking." << std::endl;
         // No need to return 1 here necessarily, the primary injector function succeeded
    } else {
         std::cout << "Remote thread finished. LoadLibraryA returned 0x" << std::hex << remoteThreadExitCode << std::dec << " (non-zero indicates success)." << std::endl;
         std::cout << "Injection likely successful! Check the log file: " << LOG_FILE_PATH << std::endl;
    }

    // 7. Cleanup
    CloseHandle(hRemoteThread);
    VirtualFreeEx(hProcess, remoteMem, 0, MEM_RELEASE); // Free the allocated memory
    CloseHandle(hProcess);

    // Return 0 if CreateRemoteThread succeeded, even if LoadLibrary failed inside target
    // Return non-zero only if injector itself failed major steps
    return 0; // Indicate injector command ran ok
} 