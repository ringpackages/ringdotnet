# ring_dotnet (the C extension and the bridge)

This folder has the C extension that hosts the .NET runtime inside the Ring process (`ring_dotnet.c`), the managed bridge (`bridge/`), the web host (`web/`), the Entity Framework layer (`data/`) and the build scripts.

| Platform | Build the extension |
|---|---|
| Windows (clang) | `buildclang_win.bat` |
| Windows (Visual Studio) | `buildvc_x64.bat` |
| Linux | `buildgcc.sh` |
| macOS | `buildclang.sh` |

The .NET SDK builds the managed parts: `dotnet build -c Release -o ../../../bin` in `bridge`, `web` and `data`. Copy `ring_dotnet.dll` (or `.so` / `.dylib`) and the `RingDotNet.Bridge.*` files to the same folder.

The description of the whole package, the API, the samples and the tutorials is in the main `README.md` one folder up, and the manual is in `docs/index.html`.
