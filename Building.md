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

## Building the documentation (HTML and PDF)

The manual is written in Markdown in `docs/src/*.md`. The scripts in `docs/tools` are Python 3 (standard library only). They need to find the Ring executable: set `RING_EXE` (for example `B:/ring/bin/ring.exe`), because the default is `B:/ring/bin/ring.exe`. As in step 5, unset `RING_HOME` and have `ringdotnet/bin` on `PATH`.

### 7. Make the API data (only when the wrapped classes changed)

```
python docs/tools/dumpapi.py
```

It asks .NET (by reflection) for the API of every wrapped class and writes `docs/tools/api-data/api.jsonl`. Run it after step 4 and before step 8.

### 8. Build the HTML pages

```
python docs/tools/build.py
```

It turns `docs/src/*.md` into `docs/*.html`, makes the gallery pages from the samples, builds the class reference (one page per namespace, `docs/api/*.html`, through `apipages.py`) and writes the search index `docs/assets/search-index.js`.

The output of the example programs shown in the pages is cached in `docs/tools/output-cache`. Add `--refresh` to run every example again and replace the cache (do it when the library changed).

### 9. Make the PDF (optional)

```
python docs/tools/makepdf.py
```

It joins all the pages, in the order of the navigation, into `docs/pdf/RingDotNet-documentation.html` and prints it with headless Chrome or Edge to `docs/pdf/RingDotNet-documentation.pdf`. The links between pages become links inside the PDF, and the PDF has bookmarks. Chrome or Edge must be installed (the paths it tries are listed at the top of `makepdf.py`).

Options:

- `--no-api`: the manual without the class reference (the reference is thousands of pages in print).
- `--html-only`: write the joined HTML file only, no PDF.

### Screenshots (only when a window sample or tutorial changed)

The pictures in `docs/img/shots` are made by running the GUI programs and capturing their windows (Windows only):

```
sh docs/tools/shoot_all.sh               # samples and applications
python docs/tools/shoot_tutorials.py     # tutorial programs
```
