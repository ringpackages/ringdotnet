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

## Online Documentation

URL: https://ringpackages.github.io/ringdotnet/

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
