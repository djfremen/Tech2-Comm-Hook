// injector_xp.cpp - Injector for VS2008 / WinXP
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0501 // Target Windows XP
#include <windows.h>
#include <iostream>
#include <string>
#include <stdlib.h>    // For strtoul
#include <tlhelp32.h>
#include <stdio.h>     // For sprintf_s (optional)

// Function to enable SeDebugPrivilege (Should work on XP)
bool EnableDebugPrivilege() {
    HANDLE hToken;
    LUID luid;
    TOKEN_PRIVILEGES tkp;

    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hToken)) {
        std::cerr << "Injector Error: OpenProcessToken failed: " << GetLastError() << std::endl;
        return false;
    }

    // SE_DEBUG_NAME is defined in headers included by windows.h
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

     // Check GetLastError() after AdjustTokenPrivileges
     if (GetLastError() == ERROR_NOT_ALL_ASSIGNED) {
         std::cerr << "Injector Warning: The token does not have the specified privilege (SeDebugPrivilege). Injection might fail." << std::endl;
     }

    CloseHandle(hToken);
    return true;
}


int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <PID> <DLL_Path>" << std::endl;
        return 1; // Return non-zero for incorrect usage
    }

    DWORD targetPID = 0;
    char *endptr;
    // Use strtoul for converting string to unsigned long (DWORD)
    targetPID = strtoul(argv[1], &endptr, 10);
    if (*endptr != '\0' || targetPID == 0) { // Check for conversion errors
        std::cerr << "Error: Invalid PID provided: " << argv[1] << std::endl;
        return 1; // Return non-zero for invalid PID
    }

    const char* dllPath = argv[2];
    char fullDllPath[MAX_PATH];

    if (GetFullPathNameA(dllPath, MAX_PATH, fullDllPath, NULL) == 0) {
        std::cerr << "Error: Could not get full path for DLL: " << dllPath << " (Error: " << GetLastError() << ")" << std::endl;
        return 1; // Return non-zero for path error
    }

    // Check existence using GetFileAttributesA
     DWORD fileAttr = GetFileAttributesA(fullDllPath);
     if (fileAttr == INVALID_FILE_ATTRIBUTES) { // Check if file exists
          std::cerr << "Error: DLL file not found at specified path: " << fullDllPath << " (Error: " << GetLastError() << ")" << std::endl;
          return 1; // Return non-zero if DLL not found
     } else if (fileAttr & FILE_ATTRIBUTE_DIRECTORY) { // Check if it's a directory
          std::cerr << "Error: Specified path is a directory, not a file: " << fullDllPath << std::endl;
          return 1; // Return non-zero if path is directory
     }

    std::cout << "Attempting to inject " << fullDllPath << " into process " << targetPID << std::endl;

    if (!EnableDebugPrivilege()) {
        std::cout << "Warning: Could not enable SeDebugPrivilege. Proceeding anyway..." << std::endl;
    }

    // --- Injection Steps ---
    HANDLE hProcess = NULL;
    LPVOID remoteMem = NULL;
    HANDLE hRemoteThread = NULL;
    DWORD lastError = 0;
    bool injectionStepsOk = false;


    // 1. Open Target Process
    hProcess = OpenProcess(
        PROCESS_QUERY_INFORMATION | PROCESS_CREATE_THREAD | PROCESS_VM_OPERATION |
        PROCESS_VM_WRITE | PROCESS_VM_READ,
        FALSE, targetPID);

    if (hProcess == NULL) {
        lastError = GetLastError();
        std::cerr << "Error: OpenProcess failed for PID " << targetPID << ". Error: " << lastError << std::endl;
        goto cleanup; // Use goto for cleanup on failure
    }
    std::cout << "Process opened successfully." << std::endl;

    // 2. Allocate Memory
    size_t dllPathSize = strlen(fullDllPath) + 1; // +1 for null terminator
    remoteMem = VirtualAllocEx(hProcess, NULL, dllPathSize, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (remoteMem == NULL) {
        lastError = GetLastError();
        std::cerr << "Error: VirtualAllocEx failed. Error: " << lastError << std::endl;
        goto cleanup;
    }
     std::cout << "Memory allocated in target process." << std::endl;

    // 3. Write DLL Path
    SIZE_T bytesWritten = 0;
    if (!WriteProcessMemory(hProcess, remoteMem, fullDllPath, dllPathSize, &bytesWritten) || bytesWritten != dllPathSize) {
        lastError = GetLastError();
        std::cerr << "Error: WriteProcessMemory failed. Error: " << lastError << std::endl;
        goto cleanup;
    }
     std::cout << "DLL path written to target process." << std::endl;

    // 4. Get LoadLibraryA Address
    LPVOID loadLibAddr = (LPVOID)GetProcAddress(GetModuleHandleA("kernel32.dll"), "LoadLibraryA");
    if (loadLibAddr == NULL) {
         lastError = GetLastError();
         std::cerr << "Error: GetProcAddress(LoadLibraryA) failed. Error: " << lastError << std::endl;
         goto cleanup;
    }
    std::cout << "LoadLibraryA address found." << std::endl;

    // 5. Create Remote Thread
    hRemoteThread = CreateRemoteThread(hProcess, NULL, 0, (LPTHREAD_START_ROUTINE)loadLibAddr, remoteMem, 0, NULL);
    if (hRemoteThread == NULL) {
        lastError = GetLastError();
        std::cerr << "Error: CreateRemoteThread failed. Error: " << lastError << std::endl;
        goto cleanup;
    }
     std::cout << "Remote thread created. Waiting..." << std::endl;

    // If we got here, the injection attempt itself was initiated
    injectionStepsOk = true;

    // 6. Wait and Check Result
    WaitForSingleObject(hRemoteThread, INFINITE); // Wait indefinitely

    DWORD remoteThreadExitCode = 0;
    // Check if GetExitCodeThread succeeds before checking the code
    if (!GetExitCodeThread(hRemoteThread, &remoteThreadExitCode)) {
        lastError = GetLastError();
        std::cerr << "Warning: GetExitCodeThread failed. Error: " << lastError << std::endl;
        // Cannot determine LoadLibrary result, but injection was started
    } else {
        // LoadLibrary returns HMODULE (non-zero) on success, NULL (0) on failure
        if (remoteThreadExitCode == 0) {
             std::cerr << "Error: LoadLibraryA failed inside target process (returned NULL)." << std::endl;
             std::cerr << "Possible reasons: DLL dependencies (VC++ Redist?), arch mismatch, DllMain failure, security." << std::endl;
             // Keep injectionStepsOk as true, but the DLL didn't load
        } else {
             std::cout << "Injection likely successful! (LoadLibrary returned non-zero)." << std::endl;
             // Corrected Line 150: Hardcode log path or make message generic
             std::cout << "Check the log file: C:\\temp\\com_hook_log.txt" << std::endl;
        }
    }


cleanup:
    // 7. Cleanup Resources
    if (hRemoteThread != NULL) CloseHandle(hRemoteThread);
    // Only free memory if it was successfully allocated
    if (remoteMem != NULL) VirtualFreeEx(hProcess, remoteMem, 0, MEM_RELEASE);
    if (hProcess != NULL) CloseHandle(hProcess);

    // Return 0 if injection thread was created, non-zero otherwise
    // Or specifically return 1 if LoadLibrary likely failed
    if (!injectionStepsOk) {
        return 1; // Injector failed before creating thread
    } else if (remoteThreadExitCode == 0 && GetLastError() == 0) { // Check if GetExitCodeThread succeeded
        return 1; // LoadLibrary likely failed inside target
    } else {
        return 0; // Injection thread created (LoadLibrary might have succeeded or we couldn't check)
    }
}