---
title: "More than one system"
lead: A Ring program that uses .NET runs on Windows and on Linux, and should run on macOS. Most of it is the same everywhere, and a few things are not. This lesson shows the output of one program on Windows and on Linux, explains the differences, and gives a short list for writing programs that work on both.
---

## What you will learn

- what is the same on every system and what is not,
- how a program asks which system it is on (`isWindows()`, `isLinux()`, `isMacOSX()`),
- paths, upper and lower case in file names, and the end of a line,
- how to keep a feature of one system (a window) away from the others,
- a checklist for a portable program.

## What works where

| | Windows | Linux | macOS |
|---|---|---|---|
| Text, numbers, dates, collections, LINQ | yes | yes | should work |
| Files, folders, streams, compression, JSON, XML | yes | yes | should work |
| HTTP, sockets, web servers, databases (SQLite, EF Core) | yes | yes | should work |
| Windows Forms and WPF (windows, controls, drawing) | yes | **no** | **no** |
| The registry, Access (`OLEDB`), named shared memory | yes | no | no |

The package was tested on Windows and on Linux (Ubuntu 24.04, x64, .NET 9). **macOS and arm64 were not tested**, so the last column says "should work", not "works". The extension is a C library that is built once for each system; the steps are in [Getting started](getting-started.html).

Windows Forms and WPF are made of the Windows system, so nothing in the package can bring them to another system. The classes are in the package, but they need the Windows desktop part of .NET, and a Linux computer does not have it. A Windows-only program (a window, a clipboard, a tray icon) has to say that it is.

## The program

It asks the system six questions and prints the answers. The program is the same on every system:

{{file:samples/UsingDotNet/tutorials/ch13_systems.ring}}

Windows prints:

{{output:samples/UsingDotNet/tutorials/ch13_systems.ring}}

and Linux prints:

```text
1. windows: 0, linux: 1, macos: 0, platform: Unix
2. separator: /   Combine: data/report.txt
3. notes.txt exists: 1, NOTES.TXT exists: 0
4. the end of a line has 1 character(s)
5. the home folder exists: 1
6. no windows here: the program works in the console
```

## How it works

### 1. Ask which system

`isWindows()`, `isLinux()` and `isMacOSX()` are functions of Ring. .NET answers too: `Environment.OSVersion.Platform` is `Win32NT` on Windows and `Unix` on Linux and macOS. Use the Ring functions for a choice in the program, and the .NET ones when the platform is only to be shown.

### 2. Paths

Windows writes `data\report.txt` and Linux writes `data/report.txt`. Do not write the separator yourself: `Path.Combine` joins the parts with the right one. A `/` is accepted by every system, also on Windows, so a path in the program text can be written with `/`. A path that starts with a letter and a colon (`C:\`) or one that starts with `/home/` exists on one system only; take the folders from the system instead (see 5 below, the tutorial [Paths and the environment](tut-59-paths.html) and [File information](tut-123-file-info.html)).

### 3. Upper and lower case

On Windows `notes.txt` and `NOTES.TXT` are the same file. On Linux they are two names, and the second one does not exist. A program that works on Windows by luck (it opens `Config.JSON` and the file is `config.json`) stops with a *file not found* error on Linux. Write the name of a file the same way everywhere, and prefer lower case names.

### 4. The end of a line

Windows ends a line with two characters (13 and 10), Linux and macOS with one (10). `Environment.NewLine` is the right one for the system. `File.ReadAllLines` reads both kinds (the tutorial [Text files and encodings](tut-132-text-encodings.html)), so a program that only reads lines does not notice. Notice it when you count characters, compare files byte by byte or write a file for another system.

### 5. Ask the system for a folder

`Environment.GetFolderPath("UserProfile")` is `C:\Users\Ann` on Windows and `/home/ann` on Linux. `Path.GetTempPath()` is the folder for temporary files. The names `ApplicationData`, `LocalApplicationData` and `MyDocuments` work the same way.

### 6. Keep a feature of one system behind a question

The most important line of the program is at the top:

```ring
if isWindows()
	using { "System.Windows.Forms" }
ok
```

On Linux, `using { "System.Windows.Forms" }` does not give an error that the program can catch: the runtime of .NET cannot start the desktop part, prints the message `You must install or update .NET to run this application... Microsoft.WindowsDesktop.App... No frameworks were found` and the program **ends**. A program that has a window mode and a console mode puts every `using` and every `new Form` behind `isWindows()`.

## A checklist for a program for every system

1. **Paths** with `Path.Combine` and folders from `GetFolderPath`; no `C:\` and no `\`.
2. **File names** the same way every time, and lower case.
3. **Windows-only features** (windows, registry, clipboard, tray icon, Access, named shared memory) behind `isWindows()`, with a message or a console version for the others.
4. **Commands of the system** chosen with `isWindows()`: `cmd /c dir` or `sh -c ls` (the tutorial [Time, tasks and other programs](tut-10-tasks-processes.html)).
5. **Time zone names**: Windows has `Eastern Standard Time` and Linux has `America/New_York`; see [Time zones](tut-68-timezones.html).
6. **Tests on both systems**, or at least a look at the output of one program on the other system. A difference such as the one in step 3 shows only when the program runs.

> [!NOTE] `System.Drawing` (pictures, `Bitmap`, `Graphics`) is a Windows feature in current versions of .NET. A program that must make pictures on Linux needs a package that does not use it, such as SkiaSharp (the lesson [Pictures on every system](tut-168-pictures.html)).

## What you learned

- text, files, network and data work everywhere; windows and the registry are Windows-only,
- `isWindows()`, `isLinux()` and `isMacOSX()` ask the system,
- `Path.Combine`, `GetFolderPath` and `NewLine` give the right answer for each system,
- a window feature must be behind `isWindows()`, because on Linux the program cannot recover from asking for it,
- a checklist for programs that run everywhere.

## Exercises

1. Run the program on a computer with another system (or a Linux system under WSL) and compare the output with the two blocks above.
2. Add a seventh question: what does `Path.GetTempPath()` start with?
3. Make a function `configPath()` that returns the path of `settings.json` inside the folder `ApplicationData` of the user, for every system.
4. Write a program that prints `Windows` in a window when it can and in the console when it cannot.

## Next

[Testing your programs](tut-28-testing.html)
