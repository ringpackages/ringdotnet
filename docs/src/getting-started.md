---
title: Getting started
lead: Install the package, run your first .NET call from Ring, and learn the four startup modes.
---

## Requirements

| You need | Why |
|---|---|
| **Ring** 1.27 or newer | The language. The package is a normal Ring package. |
| **.NET 6 or newer** (tested with .NET 9) | The runtime that RingDotNet hosts inside the Ring process. |
| **Windows Desktop runtime** | Only for Windows Forms and WPF programs (it is part of the .NET Desktop runtime installer). |
| **ASP.NET Core runtime** | Only for web programs (`dnUseWeb()`). |

> [!NOTE] The package is built and tested on Windows with Ring 1.28 and .NET 9. The C extension and the managed bridge are portable; the Windows Forms and WPF parts are Windows-only by nature.

## Install

Install the package with **RingPM**, the Ring package manager, in one step:

```bash
ringpm install ringdotnet from ringpackages
```

That is all. The command copies the library, the extension (`ring_dotnet.dll`), the managed assemblies, the samples and the applications into your Ring folder, so every program can start with:

```ring
load "dotnet.ring"
```

You do not need to set a path or copy files. To test the installation, run a sample:

```bash
ring samples/UsingDotNet/introduction/test00_first.ring
```

## Your first program

{{file:samples/UsingDotNet/introduction/test00_first.ring}}

{{output:samples/UsingDotNet/introduction/test00_first.ring}}

The `using { }` block opens the .NET namespaces, like `using System;` in C#. After it, every class of those namespaces is a Ring class with the same name: `new StringBuilder("Hello")`, `oSB.Append(...)`, `oSB.Length`, `new Math().Max(3,9)`. This is what you will use almost always.

For a type that has no generated class you can also make **generic calls**: `dnType("System.Console").callMethod("WriteLine",["text"])`, `dnNew(...)`, `dnStatic(...)`. See [Core functions](core-api.html) and the sample `samples/UsingDotNet/introduction/test01_hello.ring`.

## The startup modes

The first .NET call starts the runtime. If your program needs more than the base library, call one of these **before any other .NET call**:

| Call | Starts | Use it for |
|---|---|---|
| *(none)* | .NET base runtime | Console programs, files, networking, JSON, XML, reflection, LINQ |
| `dnUseDesktop()` | Windows Desktop runtime, Ring thread becomes STA | Windows Forms, WPF |
| `dnUseWeb()` | ASP.NET Core runtime, loads the web server | `WebServer` ([ASP.NET Core](aspnet.html)) |
| `dnUseAll()` | Desktop and ASP.NET Core together | A GUI program that also serves HTTP |
| `dnUseData()` | Loads the Entity Framework assemblies | `RingDatabase`, `RingEntityDb` ([Entity Framework](ef.html)) |

```ring
dnUseDesktop()                      # Windows Forms or WPF
using {
	"System.Drawing"
	"System.Windows.Forms"
}
```

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

## Run the tests

Every feature has a test, and every sample and application can test itself:

```bash
sh tests/run.sh B:/ring/bin/ring.exe          # runs tests, samples and applications
ring samples/UsingDotNet/applications/Calculator/main.ring --selftest   # drives the form and prints SELFTEST OK
```

Read [Testing](testing.html) for how the self tests work.

## Where to go next

- [Core concepts](concepts.html): how .NET names, overloads, properties, enums and events look in Ring.
- [Windows Forms](winforms.html) and the [applications](gallery-apps.html).
- [ASP.NET Core](aspnet.html) and [Entity Framework Core](ef.html) for servers and databases.
- [Gotchas & limits](gotchas.html) before you write a long program.
