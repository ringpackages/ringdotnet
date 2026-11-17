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

Install the package with the Ring package manager, or use the folder directly. The folder contains everything: the extension DLL (`bin/ring_dotnet.dll`), the managed assemblies and the Ring library.

```bash
# use the folder directly: the extension DLL must be found by Ring (put bin on PATH)
set PATH=B:\newpro\ringdotnet\bin;%PATH%
ring samples\UsingDotNet\test01_hello.ring
```

When the package is installed into the Ring folder, `load "dotnetlib.ring"` is enough. From a program inside the package folder load the library by its path:

```ring
load "../../libraries/dotnetlib/dotnetlib.ring"
```

## Your first program

```ring
load "dotnetlib.ring"

? dnVersion()                                   # the .NET runtime that is running

dnImport("System")
dnImport("System.Text")

oSB = new StringBuilder("Hello")
oSB.Append(", ").Append("Ring!")
? oSB.ToString()
? oSB.Length

? new Math().Max(3,9)
```

{{output:samples/UsingDotNet/test01_hello.ring}}

The output above is the real output of `samples/UsingDotNet/test01_hello.ring`, which uses both styles you will see in this documentation:

1. **Natural classes** (generated wrappers): `new StringBuilder("Hello")`, `oSB.Append(...)`, `oSB.Length`. This is what you will use almost always.
2. **Generic calls** (no wrappers needed): `dnType("System.Console").callMethod("WriteLine",["text"])`, `dnNew(...)`, `dnStatic(...)`. Useful for a type that has no generated class — see [Core functions](core-api.html).

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
dnImport("System.Drawing")
dnImport("System.Windows.Forms")
```

## Importing namespaces

The wrapper classes are loaded **on demand**, one namespace at a time, so a program only pays for what it uses:

```ring
dnImport("System.IO")               # File, Directory, Path, StreamReader ...
dnImport("System.Text.RegularExpressions")
dnImport("System.Windows.Forms")    # also loads the GUI helpers (uiForm, uiButton ...)
```

If a method returns an object whose class belongs to a namespace you did not import, that namespace is imported automatically, so chains like `oProcess.StandardOutput.ReadToEnd()` just work.

## Your first window

{{file:samples/Forms/02_button_click.ring}}

![The click counter](img/shots/forms-02_button_click.png "samples/Forms/02_button_click.ring — a form, a label and a button")

## Run the tests

Every feature has a test, and every sample and application can test itself:

```bash
sh tests/run.sh B:/ring/bin/ring.exe          # runs tests, samples and applications
ring applications/Calculator/main.ring --selftest   # drives the form and prints SELFTEST OK
```

Read [Testing](testing.html) for how the self tests work.

## Where to go next

- [Core concepts](concepts.html): how .NET names, overloads, properties, enums and events look in Ring.
- [Windows Forms](winforms.html) and the [applications](gallery-apps.html).
- [ASP.NET Core](aspnet.html) and [Entity Framework Core](ef.html) for servers and databases.
- [Gotchas & limits](gotchas.html) before you write a long program.
