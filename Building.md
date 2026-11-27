# Building RingDotNet from source

## What you need

- A Ring source tree with its headers and library: `ring/language/include`, and `ring.lib` (Windows) or `libring` (Linux/macOS) in `ring/lib`.
- A C compiler: MSVC or clang on Windows, gcc or clang on Linux/macOS.
- The .NET SDK (to build the C# parts).

## Steps

All commands start from `extensions/ringdotnet` unless a path says otherwise.

### 1. Build the C extension

It hosts .NET through hostfxr and gives Ring its `dotnet_*` functions.

- Windows with MSVC: `buildvc_x64.bat` (it also runs step 2).
- Windows with clang: `buildclang_win.bat`, or by hand:

  ```
  clang --target=x86_64-pc-windows-msvc -shared -O2 -D_CRT_SECURE_NO_WARNINGS -I<ring>/language/include ring_dotnet.c <ring>/lib/ring.lib -lole32 -o ../../bin/ring_dotnet.dll
  ```

- Linux: `sh buildgcc.sh` (writes `libring_dotnet.so` to `ring/lib`).
- macOS: `sh buildclang.sh`.

### 2. Build the C# bridge

The reflection layer between the extension and .NET:

```
cd bridge
dotnet build -c Release -o ../../../bin
```

On Linux use `../../../lib` as the output folder.

### 3. Build the `web` and `data` projects

The ASP.NET and database helpers. The same command in each folder:

```
dotnet build -c Release -o ../../../bin
```

The Windows bat file and `buildgcc.sh` build only the bridge.

### 4. Regenerate the Ring classes (only after a change)

Needed when you change the manifest (`dotnetmanifest.ring`), the generator (`gendotnetcore.ring`) or the bridge:

```
cd tools/dotnettools
ring gendotnet.ring
```

It takes about 30 seconds and writes `libraries/dotnetlib/generated`.

### 5. Verify

Before running either command, unset `RING_HOME` and put `ringdotnet/bin` on `PATH`.

- Generator checks (about 1.5 minutes): `ring tools/dotnettools/checkgenerator.ring`
- Test suite: `sh samples/UsingDotNet/tests/run.sh <path-to-ring>`. Add `--quick` for about 50 seconds; the full run takes about 10 minutes. It prints `N failed`.

On Linux, WinForms and WPF programs do not work, so the suite reports them as failed.

### 6. Pack for release

```
ring tools/dotnettools/makepackage.ring
```

It writes `extensions/ringdotnet.zip` from the files that git tracks. `setup.ring` extracts that zip into the Ring folder. Run it again whenever the library, samples, DLLs or tests change.
