# COM Port Hook - Project Directory

This repository contains tools for monitoring and capturing COM port traffic by injecting a DLL into processes that use COM ports.

## Directory Structure

- **src/**: Source code files for the project
  - C++ source files for the hook DLL and injector
  - MinHook implementation files

- **binary/**: Compiled executables and libraries
  - Interceptor.x86.dll - 32-bit DLL for hooking
  - Injector.x86.exe - 32-bit DLL injector
  - handle.exe - Sysinternals tool for finding process handles

- **scripts/**: All scripts organized by functionality
  - **building/**: Scripts for building the project
    - build_hook.bat - Builds the COM port interceptor DLL
    - build_simple_hook.bat - Builds the simplified test DLL
    - compile_test_hook.bat - Compiles a minimal test DLL
  - **injection/**: Scripts for injecting the DLL into target processes
    - inject_simple.bat - Simple injection script
    - defender_simple_inject.bat - Injection with Windows Defender handling
    - Various other injection methods and approaches
  - **monitoring/**: Scripts for monitoring COM port activity
    - monitor_com.ps1 - Monitoring COM port communication
    - simple_com_monitor.ps1 - Simple COM port monitoring
    - Various other monitoring and data capture scripts
  - **diagnostic/**: Scripts for diagnosing issues
    - injection_diagnostic.bat - Diagnoses DLL injection issues
    - check_dependencies.bat - Checks for required dependencies

- **docs/**: Documentation files
  - Various README and markdown files documenting the project

- **lib/**: External libraries
  - minhook-master/ - The MinHook library used for API hooking

- **build/**: Build output directory
  - SimpleHook.x86.dll - Simplified test DLL

- **backup/**: Backup and historical files
  - Object files and logs
  - Visual Studio project files

## Getting Started

For detailed usage instructions, see the documentation in the `docs/` directory.

Main approaches for COM port monitoring:

1. **DLL Injection**: Inject a hook DLL to intercept COM port calls
   - See scripts in `scripts/injection/` directory
   
2. **COM Port Redirection**: Create virtual COM port pairs
   - See scripts in `scripts/monitoring/` directory 