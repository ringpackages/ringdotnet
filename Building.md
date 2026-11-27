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

The manual is written in Markdown in `docs/src/*.md`. The tools in `docs/tools` are plain Ring programs (no Python). Run them from the `docs/tools` folder (they load their helper files from it):

```
cd docs/tools
```

As in step 5, unset `RING_HOME`. The example programs that the pages show (`{{output:...}}`) have their output kept in `docs/tools/output-cache`, so a normal build does not run them.

### 7. Make the API data (only when the wrapped classes changed)

```
ring dumpapi.ring
```

It lists the wrapped classes of the generated library, asks .NET (by reflection) for the API of each one and writes `docs/tools/api-data/types.txt` and `api.jsonl`. This is the only documentation tool that uses RingDotNet, so `ringdotnet/bin` must be on `PATH`. Run it after step 4 and before step 8.

### 8. Build the HTML pages

```
ring build.ring
```

It turns `docs/src/*.md` into `docs/*.html`, makes the gallery pages from the samples, builds the class reference (one page per namespace, `docs/api/*.html`, from `apipages.ring`) and writes the search index `docs/assets/search-index.js`. It takes about 25 seconds.

Options:

- `--no-api`: leave out the class reference (about 5 seconds, for writing the pages).
- `--refresh`: run every example program again and replace the cache in `docs/tools/output-cache` (do it when the library changed; `ringdotnet/bin` must be on `PATH`).

### 9. Make the PDF (optional)

```
ring makepdf.ring
```

It joins all the pages, in the order of the navigation (`docpages.ring`), into `docs/pdf/RingDotNet-documentation.html` and prints it with headless Chrome or Edge to `docs/pdf/RingDotNet-documentation.pdf`. The links between pages become links inside the PDF, and the PDF has bookmarks. Chrome or Edge must be installed (the paths it tries are listed at the top of `makepdf.ring`).

Options:

- `--no-api`: the manual without the class reference (the reference is thousands of pages in print).
- `--html-only`: write the joined HTML file only, no PDF.

### The files of the tools

| File | What it has |
|------|-------------|
| `doclib.ring` | Helpers: text files, escaping, strings, JSON text, base64, templates |
| `mdlib.ring` | The Markdown converter and the highlighting of code blocks |
| `docpages.ring` | The list of the pages of the manual, in the order of the navigation |
| `page.template`, `pdfdoc.template`, `pdf.css` | The HTML of a page, and of the one document for the PDF |
| `apipages.ring` | The class reference |
| `shootlib.ring`, `shoot*.ring`, `tutorialshots.ring` | The screenshots (ring-cffi) |
| `bracify.ring`, `booleans.ring` | Tools for editing Ring samples: turn runs of `oVar.Member = value` into brace blocks, and write `True`/`False` for logical values (`ring bracify.ring [--dry] file ...`) |

### Screenshots (only when a window sample or tutorial changed)

The pictures in `docs/img/shots` are made by running the GUI programs and capturing their windows (Windows only). The tools call the Windows API with [ring-cffi](https://github.com/ysdragon/ring-cffi), so install it once: `ringpm install ring-cffi from ysdragon`.

```
cd docs/tools
ring shoot_all.ring [forms] [wpf] [apps]        # samples and applications
ring shoot_tutorials.ring [shot name ...]       # tutorial programs
ring shoot.ring <folder> <program.ring> <out.png> [delay ms] [arguments]   # one program
```

`shootlib.ring` does the work (start the program, find its window, copy it with `PrintWindow`, crop it to the frame, write the PNG with GDI+); `tutorialshots.ring` lists the tutorial shots. The tool puts `ringdotnet/bin` first in `PATH` for the program it starts.
