cls
setlocal enableextensions enabledelayedexpansion
call ../../language/build/locatevc.bat auto x64
cl /c %ringcflags% ring_dotnet.c -I"..\..\language\include"
link %ringldflags% ring_dotnet.obj ..\..\lib\ring.lib /DLL /OUT:..\..\bin\ring_dotnet.dll
del *.obj
cd bridge
dotnet build -c Release -o ..\..\..\bin
cd ..
endlocal
