# Changes

## 1.0.0

The first release. It needs Ring 1.28 and an installed .NET runtime (6.0 or newer; tested with .NET 9).

**Core**
- The .NET runtime is hosted in the Ring process (`hostfxr`); a managed bridge calls any public member by reflection.
- Generated Ring classes for the framework namespaces (and `tools/wrapassembly.ring` for your own assemblies), loaded on demand.
- `using { "System" "System.Text" }` imports namespaces and starts the runtime mode that the names need (desktop, web, data).
- `new Class` works without parentheses for classes that need no value; `new Class(args)` with parentheses when values are passed.
- Overloaded methods are one Ring method: `Name(NULL)`, `Name(value)` or `Name([ :parameter = value ])`.
- `out` and `ref` parameters come back as a list; enums are texts; `byte[]` is a Ring text of bytes (binary safe).
- `dnBuffer(size)` is a byte buffer that .NET can fill (`Stream.Read`, `Socket.Receive`...) and that is accepted by `byte[]` and `object` parameters (registry `Binary` values); `dnBufferBytes` reads it back.
- .NET objects are released when Ring drops them (managed pointers, handles released in groups); `release()` releases at once.
- Callbacks from .NET to Ring (`dnCallback`) and events (`setXXXEvent`) while a call from Ring is running on the Ring thread.
- LINQ helpers (`dnQuery`), closed generic collections, generic types with `dnNewGeneric`.

**Desktop**
- Windows Forms and WPF classes, helper functions (`uiForm`, `wpfXaml`...), self-testing programs (`--selftest`), keys typed into your own form for tests.

**Web and data**
- A web server on ASP.NET Core with Ring handlers (`WebServer`), and the ASP.NET Core classes.
- Entity Framework Core with SQLite from data written as Ring lists (`RingEntityDb`, `RingDatabase`), and ODBC (for example Microsoft Access).

**Platforms**
- Windows (tested), Linux (tested on x64 with the GUI parts excluded), macOS and arm64 (not tested yet).

**Learning material**
- A manual (`docs/index.html`, also as a PDF), tutorials in chapters with their programs in `samples/UsingDotNet/tutorials` (`chNN_name.ring`), samples for each area, complete applications, and an automated test suite (`samples/UsingDotNet/tests/run.sh`).
