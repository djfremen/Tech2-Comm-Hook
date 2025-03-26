@echo off
setlocal

echo === Compiling 32-bit Interceptor.dll and Injector.exe ===

call "D:\buildtools\VC\Auxiliary\Build\vcvarsall.bat" x86

echo === Building Interceptor.x86.dll ===
cl.exe /EHsc /MD /LD /Fe"Interceptor.x86.dll" hook.cpp /I"." /link "MinHook.x86.lib" user32.lib

echo === Building Injector.x86.exe ===
cl.exe /EHsc /MD /O2 /Fe"Injector.x86.exe" injector.cpp

echo === Build Process Complete ===
dir *.x86.*

endlocal 