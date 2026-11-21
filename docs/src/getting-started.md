---
title: Getting started
lead: Install the package, run your first .NET call from Ring, and learn the four startup modes.
---

New to Ring? The appendix has a [Quick introduction to Ring](ring-intro.html) (about 15 minutes); read it first if you have never written a Ring program.

## Requirements

| You need | Why |
|---|---|
| **Ring** 1.28 or newer | The language. The package is a normal Ring package. |
| **.NET 6 or newer** (tested with .NET 9) | The runtime that RingDotNet hosts inside the Ring process. |
| **Windows Desktop runtime** | Only for Windows Forms and WPF programs (it is part of the .NET Desktop runtime installer). |
| **ASP.NET Core runtime** | Only for web programs (`"RingDotNet.Web"`). |

> [!NOTE] The package is built and tested on Windows with Ring 1.28 and .NET 9. The C extension and the managed bridge are portable; the Windows Forms and WPF parts are Windows-only by nature.

## Install

Install the package with **RingPM**, the Ring package manager, in one step:

```bash
ringpm install ringdotnet from ringpackages
```

That is all. The package is one zip file (`extensions/ringdotnet.zip`): RingPM copies it and its `setup.ring` extracts it into your Ring folder, which is much faster than installing thousands of files one by one. It brings the library, the extension (`ring_dotnet.dll`), the managed assemblies, the samples and the applications, so every program can start with:

```ring
load "dotnet.ring"
```

You do not need to set a path or copy files. To test the installation, run a sample from the Ring folder:

```bash
ring samples/UsingDotNet/introduction/test00_first.ring
```

## Linux and macOS

The package works on Linux (tested on Ubuntu 24.04, x64, with .NET 9) and should work on macOS. The extension is a C library, so it is **built once** for your system; the managed files are the same on every system and are installed in `ring/bin` by the package.

```bash
cd ring/extensions/ringdotnet
sh buildgcc.sh          # Linux (macOS: sh buildclang.sh); writes libring_dotnet.so to ring/lib
```

The build needs the Ring headers and library (`ring/language/include` and `ring/lib`). Install the .NET **runtime** (not only the SDK) with the packages of your system or with the `dotnet-install` script, and for the web programs also the ASP.NET Core runtime. The .NET **SDK** is needed only to build a project: the packages of the package lessons (`dotnet publish`) and your own C# libraries. If `dotnet` is not in the usual place, set `DOTNET_ROOT`. The extension finds the managed files in `ring/bin` when they are not next to the library. Windows Forms and WPF programs need Windows; everything else (text, files, collections, JSON, XML, HTTP, sockets, tasks, databases with Entity Framework and SQLite, the web server) runs the same way.

## Your first program

{{file:samples/UsingDotNet/introduction/test00_first.ring}}

{{output:samples/UsingDotNet/introduction/test00_first.ring}}

The `using { }` block opens the .NET namespaces, like `using System;` in C#. After it, every class of those namespaces is a Ring class with the same name: `new StringBuilder("Hello")`, `oSB.Append(...)`, `oSB.Length`, `new Math().Max(3,9)`. This is what you will use almost always.

Everything you write in the first tutorials is object code like this: `new` makes an object, the dot calls its methods and reads its properties, and braces `{ }` set several properties at once. For the few cases where there is no generated class, [Core concepts](concepts.html#plain-objects) shows the generic calls, and the sample `samples/UsingDotNet/introduction/test01_hello.ring` uses them.

## The startup modes

The first .NET call starts the runtime, and the runtime can be started in one **mode** only. You do not have to choose it: the `using { }` block looks at the names and starts the mode that the program needs.

| The block names... | Mode that is started | Use it for |
|---|---|---|
| only `System...` namespaces | the base runtime | Console programs, files, networking, JSON, XML, reflection, LINQ |
| `System.Windows*` or `System.Drawing*` | Windows Desktop runtime, Ring thread becomes STA | Windows Forms, WPF |
| `Microsoft.AspNetCore*` or `"RingDotNet.Web"` | ASP.NET Core runtime, loads the web server | `WebServer` ([ASP.NET Core](aspnet.html)) |
| both of the two above | Desktop and ASP.NET Core together | A GUI program that also serves HTTP |
| `Microsoft.EntityFrameworkCore*` or `"RingDotNet.Data"` | loads the Entity Framework assemblies | `RingDatabase`, `RingEntityDb` ([Entity Framework](ef.html)) |

```ring
load "dotnet.ring"
using {
	"System.Drawing"                # starts the desktop mode: Windows Forms or WPF
	"System.Windows.Forms"
}
```

`"RingDotNet.Web"` and `"RingDotNet.Data"` are not .NET namespaces: they name the helper classes of this package (`WebServer`; `RingDatabase`, `RingEntityDb`) so that you can ask for them in the same place.

Put the `using` block **before any other .NET call**. If the mode is already started and the block asks for another one, the program stops with a message that says so. (Programs that do not use `using` choose the mode with functions such as `dnUseDesktop()`: [Core functions](core-api.html).)

## Importing namespaces

The wrapper classes are loaded **on demand**, one namespace at a time, so a program only pays for what it uses. Name the namespaces in a `using` block, like C#. Each item must be a text; anything else is an error:

```ring
using {
	"System.IO"                         # File, Directory, Path, StreamReader ...
	"System.Text.RegularExpressions"
	"System.Windows.Forms"              # also loads the GUI helpers (uiForm, uiButton ...)
}
```

`using` is the same as calling `dnImport("Namespace")` for each text; the function form is handy when the name is computed.

If a method returns an object whose class belongs to a namespace you did not import, that namespace is imported automatically, so chains like `oProcess.StandardOutput.ReadToEnd()` just work.

## Your first window

{{file:samples/UsingDotNet/Forms/02_button_click.ring}}

![The click counter](img/shots/forms-02_button_click.png "samples/UsingDotNet/Forms/02_button_click.ring — a form, a label and a button")

Run it with `ring samples/UsingDotNet/Forms/02_button_click.ring` (Windows). The tutorial [Your first window](tut-11-first-window.html) explains each line.

## Run the tests

Every feature has a test, and every sample and application can test itself:

```bash
sh samples/UsingDotNet/tests/run.sh ring.exe          # runs tests, samples and applications (add --quick for a short run)
ring samples/UsingDotNet/applications/Calculator/main.ring --selftest   # drives the form and prints SELFTEST OK
```

Read [Testing](testing.html) for how the self tests work.

## Where to go next

- [Tutorials](tutorials.html): lessons grouped by topic; start with the chapter **The basics**. The program of each lesson is in `samples/UsingDotNet/tutorials`.
- [Core concepts](concepts.html): how .NET names, overloads, properties, enums and events look in Ring.
- [Windows Forms](winforms.html) and the [applications](gallery-apps.html).
- [ASP.NET Core](aspnet.html) and [Entity Framework Core](ef.html) for servers and databases.
- [Rules and limits](gotchas.html) before you write a long program.
