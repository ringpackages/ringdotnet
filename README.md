# RingDotNet

Use .NET classes and methods from Ring programs.

The package hosts the .NET runtime inside the Ring process (through `hostfxr`) and talks to it through a small managed bridge. The .NET base class library, Windows Forms, WPF, ASP.NET Core, Entity Framework Core and any assembly (the framework's or your own `.dll`, or a NuGet package) can be used from Ring with the same simple syntax.

```ring
load "dotnet.ring"

using {
	"System"
	"System.Text"
}

? dnVersion()                                   # .NET 9.0.x
? new Math().Max(3,9)                           # 9: a static method

oSB = new StringBuilder("Hello")
oSB.Append(", Ring!")
? oSB.ToString()                                # Hello, Ring!
? oSB.Length                                    # 12
```

## What you get

* **Object code.** The .NET types are generated Ring classes with the .NET names: `new` makes an object, the dot calls a method or reads a property, and braces `{ }` set several properties at once. Properties are attributes (`oForm.Text = "Hello"`), enums are texts (`"Maximized"`), and `out` / `ref` parameters come back in a list.
* **Overloads in one Ring method.** `Name(NULL)` calls the parameterless overload, `Name(value)` the one with one parameter, and `Name([ :param = value ])` chooses the overload by the .NET parameter names.
* **Callbacks and events.** `dnCallback("code")` is a .NET delegate, and `oButton.setClickEvent("clicked()")` handles an event, as in RingQt.
* **LINQ.** `dnQuery(aList).Where(...).OrderBy(...).ToList()` works on Ring lists and .NET collections.
* **Windows Forms and WPF** with short helpers (`uiForm()`, `uiButton()`, `wpfXaml()`...), keyboard handling for games, and programs that test themselves (`--selftest`).
* **ASP.NET Core.** A web server whose requests are handled by Ring functions (`WebServer`).
* **Entity Framework Core** with SQLite from data written as Ring lists (`RingDatabase`, `RingEntityDb`).
* **Your own assemblies and NuGet packages**, wrapped by one command (`wrapassembly.ring`).

## Requirements

| You need | Why |
|---|---|
| **Ring** 1.28 or newer | The language. |
| **.NET 6 or newer** runtime (tested with .NET 9) | The runtime that the package hosts. |
| Windows Desktop runtime | Only for Windows Forms and WPF programs. |
| ASP.NET Core runtime | Only for web programs. |
| .NET SDK | Only to build C# libraries and to restore NuGet packages. |

Windows is the tested platform. Linux (x64, Ubuntu 24.04, .NET 9) is tested too, except the Windows Forms and WPF programs, which need the Windows Desktop runtime. macOS and arm64 have not been tested yet.

## Install

```
ringpm install ringdotnet from ringpackages
```

The package is one zip file, `extensions/ringdotnet.zip`: `setup.ring` extracts it into the Ring folder (`uninstall.ring` removes it). Then a program starts with `load "dotnet.ring"`. On Linux and macOS the C extension is built once for the system (`extensions/ringdotnet/buildgcc.sh` or `buildclang.sh`); see *Getting started* in the manual.

## Documentation

| | |
|---|---|
| [`docs/index.html`](docs/index.html) | The manual: start with *Getting started*, then *Core concepts*. It has guides for Windows Forms, WPF, ASP.NET Core and Entity Framework, callbacks and events, advanced .NET types, your own assemblies, the generator, testing, and the rules and limits. |
| [`docs/tutorials.html`](docs/tutorials.html) | Step-by-step lessons in chapters, from the basics to projects. Each lesson has a program in `samples/UsingDotNet/tutorials`. |
| [`docs/api.html`](docs/api.html) | The class reference: every wrapped class with its constructors, properties, methods (with the way to call each from Ring) and events. |
| [`docs/reference.html`](docs/reference.html) | The function index of the Ring library. |
| PDF | `python docs/tools/makepdf.py` makes `docs/pdf/RingDotNet-documentation.pdf`, the manual with the class reference (several thousand pages). `--no-api` makes the manual alone. |

Rebuild the HTML manual with `python docs/tools/build.py` (after `python docs/tools/dumpapi.py` when the classes changed).

## Samples and tests

`samples/UsingDotNet` has:

* `introduction`: short programs for each area,
* `Forms` and `Wpf`: one small window program for each feature,
* `applications`: complete programs (a calculator, an editor, games, a web API, a contacts book...). Each is the folder `<Name>` with the program `<Name>.ring`,
* `tutorials`: the programs of the lessons, named by chapter (`chNN_name.ring`),
* `tests`: the automated tests, including tests against real NuGet packages.

```
sh samples/UsingDotNet/tests/run.sh ring.exe          # everything
sh samples/UsingDotNet/tests/run.sh ring.exe --quick  # only the tests and the introduction samples
```

`run.sh` takes the path of `ring` and adds the package `bin` folder to the PATH itself. Options: `--quick`, `--no-packages`, `--packages-only`, `--jobs N`, `--show` (see *Testing* in the manual).

## Your own assemblies and NuGet packages

```
cd tools/dotnettools
ring wrapassembly.ring path/to/MyLibrary.dll ../../myclasses
```

generates Ring classes (with inheritance, properties, events, enums as strings and the extension methods of the types) for every public class of the assembly, a loader and a class file for each namespace. Use them with:

```ring
load "dotnet.ring"

dnLoad("path/to/MyLibrary.dll")                  # dependencies are found next to the dll
dnImportFrom("myclasses/","MyCompany.Tools")
oCalc = new Calculator()
```

A NuGet package comes to Ring in four steps: a project file with a `PackageReference`, `dotnet publish`, `wrapassembly.ring`, then `dnLoad` and `dnImportFrom`. Without generated classes any assembly is usable through `dnType("Namespace.Type")`, `dnNew()` and `callMethod()`. See *Your own assemblies* in the manual; `samples/UsingDotNet/tests/UserLib` is a complete example.

## The wrapped classes

The namespaces that have Ring classes are listed in `tools/dotnettools/dotnetmanifest.ring`: the base class library (`System`, `System.Text`, `System.IO`, `System.Net`, `System.Xml`, `System.Data`...), Windows Forms and `System.Drawing`, WPF, ASP.NET Core with `Microsoft.Extensions.*`, and Entity Framework Core with SQLite. `tools/dotnettools/gendotnet.ring` generates the classes into `libraries/dotnetlib/generated` (run it without namespace names for the library; a run with names is for trying a change), and `dnImport("Namespace")` or a `using { }` block loads them on demand.

## Limits

* Ring code runs on one thread: a callback that .NET invokes from another thread is not run, and web handlers do not run in parallel (see *Rules and limits* in the manual).
* A class written in C# cannot be declared in Ring: write it in C#, build a DLL and wrap it.
* Windows Forms and WPF need Windows; everything else runs on Windows, Linux and macOS (macOS and arm64 are not tested yet).
* .NET objects are released when Ring drops them; `release()` releases one at once.

## How it is made

```
Ring program ── dotnetlib (Ring) ── ring_dotnet.dll (C, hosts the CLR) ── RingDotNet.Bridge.dll (C#, reflection)
```

| Folder | Contents |
|---|---|
| `libraries/dotnetlib` | The Ring library (functions, the helpers, the generated classes). |
| `extensions/ringdotnet` | The C extension, the managed bridge, the web host and the Entity Framework layer, with the build scripts (Windows clang or Visual Studio: `buildclang_win.bat`, `buildvc_x64.bat`; Linux: `buildgcc.sh`; macOS: `buildclang.sh`). The .NET SDK builds the managed parts. |
| `tools/dotnettools` | The generators (`gendotnet.ring`, `wrapassembly.ring`), the manifest and the package script. |
| `samples/UsingDotNet` | Samples, applications, tutorials and tests. |
| `docs` | The manual (`docs/src` is the source) and its tools. |

## Packaging

After changing the library, the samples, the DLLs, the tests or the documentation, rebuild the zip before you commit:

```
python tools/dotnettools/makepackage.py
```

## Version and license

The package version is in `package.ring`, and the changes are in [CHANGELOG.md](CHANGELOG.md). The package is tested with Ring 1.28 and .NET 9. It is released under the MIT License.
