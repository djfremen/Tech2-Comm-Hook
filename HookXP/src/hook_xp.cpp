// hook_xp.cpp - Hook DLL for VS2008 / WinXP
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0501 // Target Windows XP
#include <windows.h>
#include <string>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <set>
#include <time.h>      // For time
#include <stdio.h>     // For sprintf_s
#include <wchar.h>     // For _wcsicmp

// Include MinHook header
#include "MinHook.h"

// --- Globals ---
const char* LOG_FILE_PATH = "C:\\temp\\com_hook_log.txt";
std::ofstream logFile;
CRITICAL_SECTION logCs;          // Use Critical Section instead of std::mutex
std::set<HANDLE> monitoredComHandles;
CRITICAL_SECTION handleCs;       // Use Critical Section instead of std::mutex

// --- Original Function Pointers ---
typedef HANDLE(WINAPI* CREATEFILEW)(LPCWSTR, DWORD, DWORD, LPSECURITY_ATTRIBUTES, DWORD, DWORD, HANDLE);
typedef BOOL(WINAPI* WRITEFILE)(HANDLE, LPCVOID, DWORD, LPDWORD, LPOVERLAPPED);
typedef BOOL(WINAPI* READFILE)(HANDLE, LPVOID, DWORD, LPDWORD, LPOVERLAPPED);
typedef BOOL(WINAPI* CLOSEHANDLE)(HANDLE);

CREATEFILEW fpCreateFileW = NULL;
WRITEFILE fpWriteFile = NULL;
READFILE fpReadFile = NULL;
CLOSEHANDLE fpCloseHandle = NULL;

// --- Helper Functions ---

// Get current timestamp as string (WinAPI/CRT version)
std::string getCurrentTimestamp() {
    SYSTEMTIME st;
    FILETIME ft;
    char buffer[100];

    GetSystemTimeAsFileTime(&ft); // Gets UTC time
    // Optional: Convert to local time if needed using FileTimeToLocalFileTime, FileTimeToSystemTime
    FileTimeToSystemTime(&ft, &st); // Convert to SYSTEMTIME (still UTC unless converted)

    // Get milliseconds
    // WORD ms = st.wMilliseconds; // This is from SystemTime, less precise if not careful

    // Alternative: High-resolution timer for ms (more complex)
    // For simplicity, just use seconds here, add ms if needed later

    sprintf_s(buffer, sizeof(buffer), "%04d-%02d-%02d %02d:%02d:%02d.%03d",
              st.wYear, st.wMonth, st.wDay,
              st.wHour, st.wMinute, st.wSecond, st.wMilliseconds); // Use ms from SYSTEMTIME
    return std::string(buffer);
}


// Thread-safe logging function with timestamp (WinAPI Critical Section)
void Log(const std::string& message) {
    EnterCriticalSection(&logCs);
    if (logFile.is_open()) {
        logFile << "[" << getCurrentTimestamp() << "] " << message << std::endl;
        logFile.flush(); // Ensure it gets written
    }
     // OutputDebugStringA(message.c_str()); // Use OutputDebugString for debugging
    LeaveCriticalSection(&logCs);
}

// Helper to log buffer data as hex/ASCII (Mostly compatible)
void LogBuffer(const char* direction, HANDLE hFile, const BYTE* buffer, DWORD bytesToLog) {
    if (!buffer || bytesToLog == 0) return;

    std::stringstream ss_hdr;
    // Need alternative for reinterpret_cast<uintptr_t>(hFile) if uintptr_t not avail
    // Using unsigned long which should work for 32-bit handles
    ss_hdr << direction << " Data (Handle: 0x" << std::hex << (unsigned long)hFile
           << ", Size: " << std::dec << bytesToLog << " bytes)";
    Log(ss_hdr.str());

    std::stringstream ss_hex;
    std::stringstream ss_ascii;
    const int bytes_per_line = 16;

    for (DWORD i = 0; i < bytesToLog; ++i) {
        // Use sprintf_s for safer hex formatting if needed, but stream usually works
        ss_hex << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(buffer[i]) << " ";

        char c = (buffer[i] >= 32 && buffer[i] <= 126) ? static_cast<char>(buffer[i]) : '.';
        ss_ascii << c;

        if ((i + 1) % bytes_per_line == 0 || (i + 1) == bytesToLog) {
            if ((i + 1) % bytes_per_line != 0) {
                for (int k = 0; k < (bytes_per_line - ((i + 1) % bytes_per_line)); ++k) {
                    ss_hex << "   ";
                }
            }
            Log("  " + ss_hex.str() + "| " + ss_ascii.str());
            ss_hex.str("");
            ss_hex.clear();
            ss_ascii.str("");
            ss_ascii.clear();
        }
    }
}

// --- Hooked Functions (Mostly the same logic, ensure API calls are XP compatible) ---

HANDLE WINAPI DetourCreateFileW(
    LPCWSTR lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode,
    LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition,
    DWORD dwFlagsAndAttributes, HANDLE hTemplateFile)
{
    bool isComPort = false;
    if (lpFileName != NULL) {
        // Basic case-insensitive check for "\\.\COM" prefix
        if (wcsncmp(lpFileName, L"\\\\.\\COM", 7) == 0 && wcslen(lpFileName) > 7)
        {
             // Could add check for digits after COM if needed
             isComPort = true;
        }
    }

    HANDLE hRet = fpCreateFileW(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);

    if (isComPort) {
        std::stringstream ss;
        // Basic WCHAR* to std::string conversion (potential issues with non-ASCII)
        std::wstring ws(lpFileName ? lpFileName : L"NULL");
        std::string sFileName(ws.begin(), ws.end());

        if (hRet != INVALID_HANDLE_VALUE) {
            ss << "CreateFileW SUCCESS (Handle: 0x" << std::hex << (unsigned long)hRet
               << "): \"" << sFileName << "\"";
            Log(ss.str());
            EnterCriticalSection(&handleCs);
            monitoredComHandles.insert(hRet);
            LeaveCriticalSection(&handleCs);
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
    EnterCriticalSection(&handleCs);
    isMonitored = monitoredComHandles.count(hFile) > 0;
    LeaveCriticalSection(&handleCs);

    if (isMonitored) {
        LogBuffer("TX", hFile, static_cast<const BYTE*>(lpBuffer), nNumberOfBytesToWrite);
    }

    BOOL bRet = fpWriteFile(hFile, lpBuffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, lpOverlapped);

    if (isMonitored && !bRet) {
         std::stringstream ss;
         ss << "WriteFile FAILED (Handle: 0x" << std::hex << (unsigned long)hFile
            << ", Error: " << std::dec << GetLastError() << ")";
         Log(ss.str());
    }
    return bRet;
}


BOOL WINAPI DetourReadFile(
    HANDLE hFile, LPVOID lpBuffer, DWORD nNumberOfBytesToRead,
    LPDWORD lpNumberOfBytesRead, LPOVERLAPPED lpOverlapped)
{
    bool isMonitored = false;
    EnterCriticalSection(&handleCs);
    isMonitored = monitoredComHandles.count(hFile) > 0;
    LeaveCriticalSection(&handleCs);

    BOOL bRet = fpReadFile(hFile, lpBuffer, nNumberOfBytesToRead, lpNumberOfBytesRead, lpOverlapped);

    if (isMonitored && bRet) {
        if (lpNumberOfBytesRead && *lpNumberOfBytesRead > 0) {
            LogBuffer("RX", hFile, static_cast<const BYTE*>(lpBuffer), *lpNumberOfBytesRead);
        }
    } else if (isMonitored && !bRet) {
         std::stringstream ss;
         DWORD lastError = GetLastError();
         if (lastError != ERROR_IO_PENDING) { // Still relevant
              ss << "ReadFile FAILED (Handle: 0x" << std::hex << (unsigned long)hFile
                 << ", Error: " << std::dec << lastError << ")";
              Log(ss.str());
         }
    }
    return bRet;
}

BOOL WINAPI DetourCloseHandle(HANDLE hObject) {
     bool wasMonitored = false;
     EnterCriticalSection(&handleCs);
     // Use iterator to find and erase for std::set in older C++
     std::set<HANDLE>::iterator it = monitoredComHandles.find(hObject);
     if (it != monitoredComHandles.end()) {
          wasMonitored = true;
          monitoredComHandles.erase(it);
     }
     LeaveCriticalSection(&handleCs);

     if (wasMonitored) {
        std::stringstream ss;
        ss << "CloseHandle called for monitored COM port (Handle: 0x" << std::hex << (unsigned long)hObject << ")";
        Log(ss.str());
     }
     return fpCloseHandle(hObject);
}

// --- DllMain ---
BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved) {
    switch (ul_reason_for_call) {
        case DLL_PROCESS_ATTACH:
            {
                DisableThreadLibraryCalls(hModule);
                InitializeCriticalSection(&logCs);
                InitializeCriticalSection(&handleCs);

                // Open log file (same path)
                logFile.open(LOG_FILE_PATH, std::ios::app);
                if (!logFile.is_open()) {
                    OutputDebugStringA("HookXP DLL ERROR: Failed to open log file.\n");
                    // return FALSE; // Decide if fatal
                }

                Log("--- HookXP DLL Attached ---");

                MH_STATUS status = MH_Initialize();
                if (status != MH_OK) {
                    Log("ERROR: MH_Initialize failed"); // MH_StatusToString might not exist/work in old MinHook
                    DeleteCriticalSection(&logCs);
                    DeleteCriticalSection(&handleCs);
                    return FALSE;
                }
                Log("MinHook Initialized.");

                // Create Hooks - Basic logging
                if (MH_CreateHookApi(L"kernel32.dll", "CreateFileW", &DetourCreateFileW, (LPVOID*)&fpCreateFileW) != MH_OK) Log("ERROR: MH_CreateHook(CreateFileW) failed");
                if (MH_CreateHookApi(L"kernel32.dll", "WriteFile", &DetourWriteFile, (LPVOID*)&fpWriteFile) != MH_OK) Log("ERROR: MH_CreateHook(WriteFile) failed");
                if (MH_CreateHookApi(L"kernel32.dll", "ReadFile", &DetourReadFile, (LPVOID*)&fpReadFile) != MH_OK) Log("ERROR: MH_CreateHook(ReadFile) failed");
                if (MH_CreateHookApi(L"kernel32.dll", "CloseHandle", &DetourCloseHandle, (LPVOID*)&fpCloseHandle) != MH_OK) Log("ERROR: MH_CreateHook(CloseHandle) failed");
                Log("Hooks Created (check logs).");

                // Enable Hooks
                status = MH_EnableHook(MH_ALL_HOOKS);
                if (status != MH_OK) {
                    Log("ERROR: MH_EnableHook failed");
                    MH_Uninitialize();
                    DeleteCriticalSection(&logCs);
                    DeleteCriticalSection(&handleCs);
                    return FALSE;
                }
                Log("Hooks Enabled.");
            }
            break;

        case DLL_PROCESS_DETACH:
            {
                // Ensure resources are only cleaned up if initialized
                Log("--- HookXP DLL Detaching ---");

                MH_DisableHook(MH_ALL_HOOKS); Log("Hooks Disabled.");
                MH_Uninitialize(); Log("MinHook Uninitialized.");

                if (logFile.is_open()) {
                    logFile.close();
                }
                DeleteCriticalSection(&logCs);
                DeleteCriticalSection(&handleCs);
            }
            break;

        case DLL_THREAD_ATTACH:
        case DLL_THREAD_DETACH:
            break;
    }
    return TRUE;
}