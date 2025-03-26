#include <windows.h>
#include <stdio.h>

FILE* logFile = NULL;

void Log(const char* format, ...) {
    if (!logFile) {
        logFile = fopen("C:\\temp\\com_hook_log.txt", "a");
        if (!logFile) return;
    }
    
    va_list args;
    va_start(args, format);
    vfprintf(logFile, format, args);
    fprintf(logFile, "\n");
    fflush(logFile);
    va_end(args);
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
    switch (fdwReason) {
        case DLL_PROCESS_ATTACH:
            Log("--- Test Hook DLL Attached (Simplified) ---");
            Log("Process ID: %d", GetCurrentProcessId());
            break;
        case DLL_PROCESS_DETACH:
            if (logFile) {
                Log("--- Test Hook DLL Detached ---");
                fclose(logFile);
                logFile = NULL;
            }
            break;
    }
    return TRUE;
} 