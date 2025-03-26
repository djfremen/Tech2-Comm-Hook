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
            Log("--- Simple Hook DLL Attached ---");
            Log("Process ID: %d", GetCurrentProcessId());
            Log("Time: %s", __TIME__);
            Log("Date: %s", __DATE__);
            break;
        case DLL_PROCESS_DETACH:
            if (logFile) {
                Log("--- Simple Hook DLL Detached ---");
                fclose(logFile);
                logFile = NULL;
            }
            break;
    }
    return TRUE;
} 