# Changes

## 1.0.0

The first release. It needs Ring 1.28 and an installed .NET runtime (6.0 or newer; tested with .NET 9).

**Core**
- The .NET runtime is hosted in the Ring process (`hostfxr`); a managed bridge calls any public member by reflection.
- Generated Ring classes for the framework namespaces (and `tools/dotnettools/wrapassembly.ring` for your own assemblies), loaded on demand.
- `using { "System" "System.Text" }` imports namespaces and starts the runtime mode that the names need (desktop, web, data).
- `new Class` works without parentheses for classes that need no value; `new Class(args)` with parentheses when values are passed.
- Overloaded methods are one Ring method: `Name(NULL)`, `Name(value)` or `Name([ :parameter = value ])`.
- `out` and `ref` parameters come back as a list; enums are texts; `byte[]` is a Ring text of bytes (binary safe).
- `dnBuffer(size)` is a byte buffer that .NET can fill (`Stream.Read`, `Socket.Receive`...) and that is accepted by `byte[]` and `object` parameters (registry `Binary` values); `dnBufferBytes` reads it back.
- .NET objects are released when Ring drops them (managed pointers, handles released in groups); `release()` releases at once.
- Callbacks from .NET to Ring (`dnCallback`) and events (`setXXXEvent`) while a call from Ring is running on the Ring thread.
- LINQ helpers (`dnQuery`), ready classes for the common closed generic types (`StringList`, `NumberDictionary`, `StringSet`, `ResponseTask`...), other generic types with `dnNewGeneric`.
- Object code first: `new`, the dot and braces cover almost every call. The generic functions (`dnNew` with names, `dnStatic`, `dnType`, `callMethod`, `getProp`) are for the few cases that have no class.

**Speed** (Windows, Ring 1.28, .NET 9; `samples/UsingDotNet/tests/bench_calls.ring` measures it on your computer)
- A call that returns a text, a number, a yes/no or nothing, and a property read or write, is packed and read in C (`dotnet_call`, `dotnet_callv`): about 2 to 3 microseconds for a call, which is 350,000 to 450,000 calls per second. A call with an object as an argument, or one that returns an object, takes the Ring path.
- The bridge remembers the overload that it chose for a kind of arguments, so a method with many overloads (`Math.Max`) costs about the same as one with a single overload.
- `new Class(args)` takes about 25 microseconds (the bridge answers a handle number, and the unneeded default object of a class is released in a group).
- `dnHandleCount()` gives the number of .NET objects that Ring holds, for tests of the release of handles.

**Desktop**
- Windows Forms and WPF classes, helper functions (`uiForm`, `wpfXaml`...), keys typed into your own form for tests.
- Self-testing programs: the checks of a window program are in `selftest/<program>.ring` next to it, and `uiRun` / `wpfRun` run them when the program starts with `--selftest`. The programs themselves stay free of test code.

**Web and data**
- A web server on ASP.NET Core with Ring handlers (`WebServer`), and the ASP.NET Core classes.
- Entity Framework Core with SQLite from data written as Ring lists (`RingEntityDb`, `RingDatabase`), and ODBC (for example Microsoft Access).

**Platforms**
- Windows (tested), Linux (tested on x64 with gcc, Ubuntu 24.04 and .NET 9; the Windows Forms and WPF programs are excluded), macOS and arm64 (not tested yet). The extension builds without compiler warnings of its own.

**Learning material**
- A manual (`docs/index.html`, also as a PDF), tutorials in chapters with their programs in `samples/UsingDotNet/tutorials` (`chNN_name.ring`; the early chapters use object code, and a lesson explains the generic functions), samples for each area, complete applications, and an automated test suite (`samples/UsingDotNet/tests/run.sh`).
