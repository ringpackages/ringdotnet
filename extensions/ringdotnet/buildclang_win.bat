rem Windows build using clang (no Visual Studio command prompt needed)
clang --target=x86_64-pc-windows-msvc -shared -O2 -D_CRT_SECURE_NO_WARNINGS -I..\..\language\include ring_dotnet.c ..\..\lib\ring.lib -o ..\..\bin\ring_dotnet.dll
cd bridge
dotnet build -c Release -o ..\..\..\bin
cd ..
