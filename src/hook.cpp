// hook.cpp - Simplified Hook DLL
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <string>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <set>
#include <mutex>
#include <chrono>   // For timestamps
#include <ctime>    // For formatting timestamps

// Include MinHook header (ensure path is correct during compilation)
#include "MinHook.h"

// --- Globals ---
const char* LOG_FILE_PATH = "C:\\temp\\com_hook_log.txt"; // Define log path clearly
std::ofstream logFile;
std::mutex logMutex;
std::set<HANDLE> monitoredComHandles;
std::mutex handleSetMutex;

// --- Original Function Pointers (Trampolines) ---
typedef HANDLE(WINAPI* CREATEFILEW)(LPCWSTR, DWORD, DWORD, LPSECURITY_ATTRIBUTES, DWORD, DWORD, HANDLE);
typedef BOOL(WINAPI* WRITEFILE)(HANDLE, LPCVOID, DWORD, LPDWORD, LPOVERLAPPED);
typedef BOOL(WINAPI* READFILE)(HANDLE, LPVOID, DWORD, LPDWORD, LPOVERLAPPED);
typedef BOOL(WINAPI* CLOSEHANDLE)(HANDLE); // Add CloseHandle

CREATEFILEW fpCreateFileW = nullptr;
WRITEFILE fpWriteFile = nullptr;
READFILE fpReadFile = nullptr;
CLOSEHANDLE fpCloseHandle = nullptr; // Original CloseHandle

// --- Helper Functions ---

// Get current timestamp as string
std::string getCurrentTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto now_c = std::chrono::system_clock::to_time_t(now);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;

    std::tm now_tm;
    localtime_s(&now_tm, &now_c); // Use thread-safe localtime_s

    std::stringstream ss;
    ss << std::put_time(&now_tm, "%Y-%m-%d %H:%M:%S");
    ss << '.' << std::setw(3) << std::setfill('0') << ms.count();
    return ss.str();
}

// Simple thread-safe logging function with timestamp
void Log(const std::string& message) {
    std::lock_guard<std::mutex> lock(logMutex);
    if (logFile.is_open()) {
        logFile << "[" << getCurrentTimestamp() << "] " << message << std::endl;
    }
    // OutputDebugStringA( DllName + message + '\n'); // Optional debug output
}

// Helper to log buffer data as hex/ASCII (Improved formatting slightly)
void LogBuffer(const char* direction, HANDLE hFile, const BYTE* buffer, DWORD bytesToLog) {
    if (!buffer || bytesToLog == 0) return;

    std::stringstream ss_hdr;
    ss_hdr << direction << " Data (Handle: 0x" << std::hex << reinterpret_cast<uintptr_t>(hFile)
           << ", Size: " << std::dec << bytesToLog << " bytes)";
    Log(ss_hdr.str());

    std::stringstream ss_hex;
    std::stringstream ss_ascii;
    const int bytes_per_line = 16;

    for (DWORD i = 0; i < bytesToLog; ++i) {
        // Hex part
        ss_hex << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(buffer[i]) << " ";

        // ASCII part
        char c = (buffer[i] >= 32 && buffer[i] <= 126) ? static_cast<char>(buffer[i]) : '.';
        ss_ascii << c;

        // End of line or buffer
        if ((i + 1) % bytes_per_line == 0 || (i + 1) == bytesToLog) {
            // Pad remaining hex spaces if line is not full
            if ((i + 1) % bytes_per_line != 0) {
                for (int k = 0; k < (bytes_per_line - ((i + 1) % bytes_per_line)); ++k) {
                    ss_hex << "   ";
                }
            }
            Log("  " + ss_hex.str() + "| " + ss_ascii.str());
            ss_hex.str(""); // Clear hex stream
            ss_hex.clear();
            ss_ascii.str(""); // Clear ascii stream
            ss_ascii.clear();
        }
    }
}

// --- Hooked Function Implementations ---

HANDLE WINAPI DetourCreateFileW(
    LPCWSTR lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode,
    LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition,
    DWORD dwFlagsAndAttributes, HANDLE hTemplateFile)
{
    bool isComPort = false;
    std::wstring wsFileName;
    if (lpFileName) {
        wsFileName = lpFileName;
        std::wstring wsLower = wsFileName;
        for (wchar_t& c : wsLower) { c = towlower(c); } // Basic lowercasing

        // Simple check for COM port names (adjust if needed)
        if (wsLower.find(L"\\\\.\\com") == 0 && wsLower.length() > 7) {
            isComPort = true;
        }
    }

    // Call original first
    HANDLE hRet = fpCreateFileW(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);

    // Log after call
    if (isComPort) {
        std::stringstream ss;
        std::string sFileName(wsFileName.begin(), wsFileName.end()); // Basic conversion
        if (hRet != INVALID_HANDLE_VALUE) {
            ss << "CreateFileW SUCCESS (Handle: 0x" << std::hex << reinterpret_cast<uintptr_t>(hRet)
               << "): \"" << sFileName << "\"";
        Log(ss.str());
        std::lock_guard<std::mutex> lock(handleSetMutex);
            monitoredComHandles.insert(hRet); // Add handle if successful COM open
        } else {
            ss << "CreateFileW FAILED (Error: " << std::dec << GetLastError()
               << "): \"" << sFileName << "\"";
        Log(ss.str());
        }
    }

    return hRet;
}

BOOL WINAPI DetourWriteFile(
    HANDLE hFile, LPCVOID lpBuffer, DWORD nNumberOfBytesToWrite,
    LPDWORD lpNumberOfBytesWritten, LPOVERLAPPED lpOverlapped)
{
    bool isMonitored = false;
    {
        std::lock_guard<std::mutex> lock(handleSetMutex);
        isMonitored = monitoredComHandles.count(hFile) > 0;
    }

    if (isMonitored) {
        LogBuffer("TX", hFile, static_cast<const BYTE*>(lpBuffer), nNumberOfBytesToWrite);
    }

    // Call original
    BOOL bRet = fpWriteFile(hFile, lpBuffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, lpOverlapped);

    if (isMonitored && !bRet) {
         std::stringstream ss;
        ss << "WriteFile FAILED (Handle: 0x" << std::hex << reinterpret_cast<uintptr_t>(hFile)
           << ", Error: " << std::dec << GetLastError() << ")";
         Log(ss.str());
    }
    // Optional: Log success and bytes written (*lpNumberOfBytesWritten) if needed

    return bRet;
}

BOOL WINAPI DetourReadFile(
    HANDLE hFile, LPVOID lpBuffer, DWORD nNumberOfBytesToRead,
    LPDWORD lpNumberOfBytesRead, LPOVERLAPPED lpOverlapped)
{
    bool isMonitored = false;
    {
        std::lock_guard<std::mutex> lock(handleSetMutex);
        isMonitored = monitoredComHandles.count(hFile) > 0;
    }

    // Call original (this may block)
    BOOL bRet = fpReadFile(hFile, lpBuffer, nNumberOfBytesToRead, lpNumberOfBytesRead, lpOverlapped);

    // Log received data *after* successful call
    if (isMonitored && bRet) {
        if (lpNumberOfBytesRead && *lpNumberOfBytesRead > 0) {
         LogBuffer("RX", hFile, static_cast<const BYTE*>(lpBuffer), *lpNumberOfBytesRead);
        } else {
            // Optional: Log zero-byte reads if relevant
            // Log("ReadFile SUCCESS (Handle: 0x" + ...) returned 0 bytes");
        }
    }
    else if (isMonitored && !bRet) {
         std::stringstream ss;
         DWORD lastError = GetLastError();
         // Don't log error if it's just pending async I/O
         if (lastError != ERROR_IO_PENDING) {
             ss << "ReadFile FAILED (Handle: 0x" << std::hex << reinterpret_cast<uintptr_t>(hFile)
                << ", Error: " << std::dec << lastError << ")";
             Log(ss.str());
         }
    }

    return bRet;
}

BOOL WINAPI DetourCloseHandle(HANDLE hObject) {
     bool wasMonitored = false;
    {
        std::lock_guard<std::mutex> lock(handleSetMutex);
        if (monitoredComHandles.count(hObject)) {
            wasMonitored = true;
            monitoredComHandles.erase(hObject); // Remove from set
        }
    }

     if (wasMonitored) {
        std::stringstream ss;
        ss << "CloseHandle called for monitored COM port (Handle: 0x" << std::hex << reinterpret_cast<uintptr_t>(hObject) << ")";
        Log(ss.str());
     }

     // Call original
     return fpCloseHandle(hObject);
}


// --- DllMain ---
BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved) {
    switch (ul_reason_for_call) {
        case DLL_PROCESS_ATTACH:
            {
                DisableThreadLibraryCalls(hModule);

                // Use RAII for log file stream if possible, or manage carefully
                logFile.open(LOG_FILE_PATH, std::ios::app);
                if (!logFile.is_open()) {
                    OutputDebugStringA("Hook DLL ERROR: Failed to open log file.\n");
                    // Decide if this is fatal. If logging is critical, return FALSE.
                    // return FALSE;
                }

                Log("--- Hook DLL Attached ---");

                MH_STATUS status = MH_Initialize();
                if (status != MH_OK) {
                    Log("ERROR: MH_Initialize failed: " + std::string(MH_StatusToString(status)));
                    return FALSE; // Fail attach if MinHook can't init
                }
                Log("MinHook Initialized.");

                // Create Hooks - Add error checking for each
                status = MH_CreateHookApi(L"kernel32.dll", "CreateFileW", &DetourCreateFileW, reinterpret_cast<LPVOID*>(&fpCreateFileW));
                if (status != MH_OK) Log("ERROR: MH_CreateHookApi(CreateFileW) failed: " + std::string(MH_StatusToString(status)));

                status = MH_CreateHookApi(L"kernel32.dll", "WriteFile", &DetourWriteFile, reinterpret_cast<LPVOID*>(&fpWriteFile));
                 if (status != MH_OK) Log("ERROR: MH_CreateHookApi(WriteFile) failed: " + std::string(MH_StatusToString(status)));

                status = MH_CreateHookApi(L"kernel32.dll", "ReadFile", &DetourReadFile, reinterpret_cast<LPVOID*>(&fpReadFile));
                 if (status != MH_OK) Log("ERROR: MH_CreateHookApi(ReadFile) failed: " + std::string(MH_StatusToString(status)));

                status = MH_CreateHookApi(L"kernel32.dll", "CloseHandle", &DetourCloseHandle, reinterpret_cast<LPVOID*>(&fpCloseHandle));
                 if (status != MH_OK) Log("ERROR: MH_CreateHookApi(CloseHandle) failed: " + std::string(MH_StatusToString(status)));


                Log("Hooks Created (check logs for individual errors).");

                // Enable Hooks
                status = MH_EnableHook(MH_ALL_HOOKS); // Or MH_EnableHook(MH_ALL_HOOKS); if you check errors above
                if (status != MH_OK) {
                    Log("ERROR: MH_EnableHook failed: " + std::string(MH_StatusToString(status)));
                    MH_Uninitialize(); // Attempt cleanup
                    return FALSE; // Fail attach if hooks can't be enabled
                }
                Log("Hooks Enabled.");
            }
            break;

        case DLL_PROCESS_DETACH:
            {
                // Only try to log/uninitialize if initialization was successful
                // (Needs a global flag set in DLL_PROCESS_ATTACH, omitted for simplicity here,
                // but important for robustness if attach fails early)
                Log("--- Hook DLL Detaching ---");

                MH_STATUS status = MH_DisableHook(MH_ALL_HOOKS); // Disable all hooks
                 if (status != MH_OK) Log("ERROR: MH_DisableHook failed: " + std::string(MH_StatusToString(status)));
                 else Log("Hooks Disabled.");

                status = MH_Uninitialize(); // Uninitialize MinHook
                if (status != MH_OK) Log("ERROR: MH_Uninitialize failed: " + std::string(MH_StatusToString(status)));
                else Log("MinHook Uninitialized.");

                if (logFile.is_open()) {
                    logFile.close();
                }
            }
            break;

        case DLL_THREAD_ATTACH:
        case DLL_THREAD_DETACH:
            break;
    }
    return TRUE; // Return TRUE unless attach critically fails
}