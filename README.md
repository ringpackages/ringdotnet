# RingDotNet

RingDotNet is a package for the Ring programming language that enables developers to use .NET classes and methods directly from Ring. 
The package hosts the .NET runtime inside the Ring process and talks to it through a small managed bridge. 

The .NET base class library, Windows Forms, WPF, ASP.NET Core, Entity Framework Core and any assembly (the framework's or your own `.dll`, or a NuGet package) can be used from Ring with the same simple syntax.

```ring
load "dotnet.ring"

using {
	"System"
	"System.Text"
}

? new Math().Max(3,9)                           # 9: a static method

oSB = new StringBuilder("Hello")
oSB.Append(", Ring!")
? oSB.ToString()                                # Hello, Ring!
? oSB.Length                                    # 12
```

## Install

```
ringpm install ringdotnet from ringpackages
```

It includes over one million lines of generated Ring code, more than 6,000 pages of documentation, and a large collection of samples and applications.

![RingDotNet: the cover of the PDF manual, and the size of the package](docs/img/ringdotnet.png)

## Features

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

Windows is the tested platform. Linux (x64, Ubuntu 24.04, .NET 9) is tested too, except the Windows Forms and WPF programs, which need the Windows Desktop runtime. 

## Architecture

![Architecture of RingDotNet: your Ring program, dotnetlib, the C extension ring_dotnet.dll, and the C# bridge that reaches the .NET class library, WinForms, WPF, ASP.NET, EF and your own DLLs](docs/img/architecture.svg)

| Folder | Contents |
|---|---|
| `libraries/dotnetlib` | The Ring library (functions, the helpers, the generated classes). |
| `extensions/ringdotnet` | The C extension, the managed bridge, the web host and the Entity Framework layer, with the build scripts (Windows clang or Visual Studio: `buildclang_win.bat`, `buildvc_x64.bat`; Linux: `buildgcc.sh`; macOS: `buildclang.sh`). The .NET SDK builds the managed parts. |
| `tools/dotnettools` | The generators (`gendotnet.ring`, `wrapassembly.ring`), the manifest and the package script. |
| `samples/UsingDotNet` | Samples, applications, tutorials and tests. |
| `docs` | The manual (`docs/src` is the source) and its tools. |

## Samples and tests

`samples/UsingDotNet` has:

* `introduction`: short programs for each area,
* `Forms` and `Wpf`: one small window program for each feature,
* `applications`: complete programs (a calculator, an editor, games, a web API, a contacts book...). Each is the folder `<Name>` with the program `<Name>.ring`,
* `tutorials`: the programs of the lessons, named by chapter (`chNN_name.ring`),
* `tests`: the automated tests, including tests against real NuGet packages.

## License

The package is tested with Ring 1.28 and .NET 9. 

It is released under the MIT License.
