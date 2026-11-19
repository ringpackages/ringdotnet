---
title: "Giving your program to others"
lead: A program that works on your computer is not finished until it works on somebody else's. This lesson turns a RingDotNet program into a folder with a program file that runs without Ring, explains what must be on the other computer, and adds a self check that says what is missing instead of crashing.
---

## What you will learn

- what **Ring2EXE** makes and what it copies for a RingDotNet program,
- the steps: build, look at the folder, test it without Ring,
- what the other computer needs (the .NET runtime, and sometimes more),
- a **self check** at the start of the program,
- where a distributed program writes its data,
- the usual errors and what they mean.

[Getting started](getting-started.html) installed the package for *you*. This lesson is about the people who only *use* your program.

## The program

{{file:docs/tutorials/t119_distribution.ring}}

{{output:docs/tutorials/t119_distribution.ring}}

This program is the self check. It is a good start for your own program: put its checks in a function at the start, and call it when the program starts.

## The steps

**1. Build.** In the folder of the program (here `myprogram.ring`), with the Ring of the package installed:

```powershell
ring ring2exe.ring myprogram.ring -dist -dotnet
```

(`ring2exe.ring` is in `ring/tools/ring2exe`; give its path, or build `ring2exe.exe` once and use `ring2exe myprogram.ring -dist -dotnet`.) The option `-dist` prepares a folder for distribution and `-dotnet` adds the files of RingDotNet. Use `-gui` too for a program with a window, so that no console window opens behind it.

**2. Look at the folder.** `target/windows` now holds the program (`myprogram.exe`), `ring.dll`, the compiled program (`ring.ringo`), the extension (`ring_dotnet.dll`), the **bridge** and its libraries (`RingDotNet.Bridge.dll`, `RingDotNet.Data.dll`, `RingDotNet.Web.dll` and the runtime configuration files), the libraries for databases (Entity Framework and SQLite with `e_sqlite3.dll`), and `System.Data.Odbc.dll` for Access (the tutorial [Microsoft Access databases](tut-115-access.html)). The list of files is in `tools/ring2exe/libs/dotnet.ring`; the folder is about 11 MB.

**3. Test it without Ring.** The only real test is on a computer or a folder where Ring is *not* in the `PATH`: open a command window, go to `target/windows`, and run `myprogram.exe`. The self check of this lesson, built this way and run from its own folder, says *yes* to every line.

**4. Give it.** Copy the whole folder (a zip file is the simplest) and tell the user what to install first.

## What the other computer needs

| Need | When |
|---|---|
| the **.NET runtime**, version 6 or newer (the files are made for .NET 9: install the 9.0 runtime) | always. This is the *runtime*, not the SDK. Without it the program stops with *".NET runtime not found"* |
| the **ASP.NET Core runtime**, same version | programs with a web server, or that use `Microsoft.AspNetCore`, `Microsoft.Extensions.*` (configuration, data protection, rate limiting, routing...). It is installed together with the "ASP.NET Core Runtime" or the "Hosting Bundle" |
| the **Windows Desktop runtime** | programs with Windows Forms or WPF windows (Windows only) |
| the **Microsoft Access Database Engine** (64-bit) | programs that open Access files (the tutorial [Microsoft Access databases](tut-115-access.html)) |
| 64-bit Windows | the files are 64-bit |

The runtimes are free downloads from `dotnet.microsoft.com`; tell users the exact name. If the runtime is installed in an unusual place, the variable `DOTNET_ROOT` points to it.

## The self check

A program that cannot start should say **why**, in words the user understands. The program above checks, one by one, that the runtime has the right version, that the bridge and its configuration files are next to the program, that SQLite works (`RingDotNet.Data.dll` is loaded first, because it knows where the native library of this system is, and then a database in memory is opened, which proves that the library is found), whether the ASP.NET runtime is installed, and that a folder for the data exists. When a line says *0*, the program can print what to install and stop, instead of showing an error message of .NET. Do the check **before** you use the part that needs it, and only for what your program really uses.

## Where the data goes

A program in `C:\Program Files` usually may not write next to itself. Put settings and data in a folder of the user: `Environment.GetFolderPath("ApplicationData")` is the folder for the settings of the user (inside, make a folder with the name of your program), `LocalApplicationData` for data that stays on this computer, and `CommonApplicationData` for data of all users (writing there may need rights). Never write into the folder of the program itself.

## Linux and macOS

The same options work (`ring ring2exe.ring myprogram.ring -dist -dotnet`), and the program is made for the system it is built on. On these systems ring2exe takes the files from `ring/lib`, so `setup.ring` copies the managed files there when you install the package; the list takes the SQLite library of one system and processor (it says in the file which line to change for arm64 or an Intel Mac). The distribution for Linux and macOS is prepared in this way but **not tested yet**: build on the system you distribute for and run the result on a clean computer.

## When something goes wrong

| Message | Cause and answer |
|---|---|
| *.NET runtime not found (install the .NET runtime or set DOTNET_ROOT)* | the runtime is missing or in an unusual place: install it, or set `DOTNET_ROOT` |
| *Bridge assembly not found* | the folder is incomplete: `RingDotNet.Bridge.dll` must be next to `ring_dotnet.dll`; copy the whole `target/windows` folder |
| *Can't find the .NET type ...* | the assembly of that class is not in the folder (a library of your own, a NuGet package): copy its DLL next to the program and load it with `dnLoad` ([Your own assemblies](own-assemblies.html)) |
| *A library or file cannot be loaded* for a web or Access program | the ASP.NET Core runtime or the Access engine is missing, or its bitness does not match |
| *Unable to load e_sqlite3* | the SQLite library of the right system is missing from the list |
| the program works on your computer and not on another | run the self check, then compare: the same runtime version? the same folder? a file next to the program that your computer has and the other does not? |

> [!NOTE] Do not copy the folder of the .NET runtime into your program folder to avoid the install: the runtime is shared, updated by Windows Update, and its license allows it only in a *self-contained* publish, which Ring2EXE does not make.

## What you learned

- `ring2exe -dist -dotnet` makes a folder that runs without Ring,
- what is in the folder and what the other computer must have,
- a self check that names what is missing,
- user data goes to the folder of the user,
- the usual errors and their causes.

## Exercises

1. Build the self check as `selfcheck.exe` and run it from a folder where Ring is not in the `PATH`.
2. Add your own library (`dnLoad`) and see what ring2exe does not copy; add it to your distribution by hand.
3. Make the program print *"Install the .NET runtime 9.0 from dotnet.microsoft.com"* and stop when line 1 says no.
4. Make a zip file of the folder with `ZipFile` (the tutorial [Files and folders](tut-05-files.html)) and check its size.

## Where to go next

This was the last tutorial of the last chapter. Keep [Core concepts](concepts.html), the [class reference](api.html) and [Gotchas & limits](gotchas.html) at hand, and read the [applications](gallery-apps.html) for bigger programs.
