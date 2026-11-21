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
- `dnHandleCount()` gives the number of .NET objects that Ring holds, for tests of the release of handles.

**Packages from nuget.org and other assemblies**
- A package is brought to Ring in four steps: a project file with a `PackageReference`, `dotnet publish` (the package with the DLLs it needs and its native libraries), `wrapassembly.ring`, then `dnLoad` and `dnImportFrom`. The lessons from [A NuGet package](docs/tut-162-nuget.html) on show it with Newtonsoft.Json, QRCoder, ClosedXML, SkiaSharp, PDFsharp and System.Speech.
- Native libraries of a package are found in `runtimes/<system>-<architecture>/native` next to its DLL.
- `wrapassembly.ring` can wrap one namespace or all of them; the class index of the folder lets an object of a namespace that was not imported be wrapped when it comes back, and several assemblies can share a folder.
- A class of the assembly that has the name of a class of the library gets the prefix of its namespace (`YamlDotNet.Core.Version` is `CoreVersion`), and the generator lists the renames.
- An object that comes back as a class that is not public is wrapped as the interface named after it (`XLWorksheet` as `IXLWorksheet`), and an interface has the members that it inherits from other interfaces.
- Extension methods are methods of the Ring class of the type that they extend (`oTable.AddColumn("Name")`), for the types of the same generated set; the methods of the object come first and a method that the class already has keeps its signature.
- Methods that a class implements explicitly are found through its public interfaces (the rows of Dapper), and a parameter of the type `System.Enum` takes the full name of a member (`"System.DayOfWeek.Friday"`).

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
