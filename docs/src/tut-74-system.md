---
title: "Asking the computer"
lead: What system is this? How many processors? How much memory does my program use? Which programs are running? This lesson asks the computer with Environment, RuntimeInformation, Process, GC and the file system.
---

## What you will learn

- the operating system and the .NET runtime,
- processors, memory, drives and the user,
- the current process and the list of all processes,
- the .NET memory manager (`GC`),
- writing a program that behaves differently on Windows and on other systems.

## The program

{{file:docs/tutorials/t74_system.ring}}

{{output:docs/tutorials/t74_system.ring}}

The output shows what is true on the computer where the page was made; the program prints *yes* and *no* for private details instead of the names themselves.

## How it works

### The system and the runtime

`Environment.OSVersion.Platform` is `Win32NT` on Windows and `Unix` on Linux and macOS. `RuntimeInformation.FrameworkDescription` is the .NET version and `ProcessArchitecture` the type of the processor (`X64`, `Arm64`...). A program that needs a different path or command on each system asks first and then chooses (the tutorial [Paths and the environment](tut-59-paths.html) shows paths that work everywhere).

### The machine and the user

`ProcessorCount` is the number of logical processors; it tells you how many tasks can really run at the same time (the tutorial [Time, tasks and other programs](tut-10-tasks-processes.html)). `TickCount64` is the number of milliseconds since the system started. `UserName` and `MachineName` can be useful for the user's own folders or settings, but **do not write them into logs or send them anywhere** without a reason.

### Drives

`Directory.GetLogicalDrives()` lists the drives (`C:\`, `D:\`, ...; on Linux just `/`). For the space on a drive look at the `DriveInfo` class in a C# library if your program needs it.

### This process and the others

`Process.GetCurrentProcess()` describes the running program: `Id`, `ProcessName` (the program is the Ring interpreter, `ring`) and `WorkingSet64`, the memory it uses in bytes. `Process.GetProcesses(NULL)` is the list of all programs; the program finds itself in it by the `Id`. Starting and stopping other programs is in the tutorial [Time, tasks and other programs](tut-10-tasks-processes.html) and the tutorial [A project: a command runner](tut-37-runner.html).

### The memory manager

.NET cleans up its own objects with the **garbage collector** (`GC`). `GC.GetTotalMemory(False)` is the memory used by .NET objects right now. Step 6 creates a `StringBuilder` with room for five million characters and the number grows by more than a megabyte. You almost never call the collector yourself; resources such as files need `Dispose` (the tutorial [Releasing resources](tut-71-dispose.html)).

### Time

`Stopwatch.IsHighResolution` says that the processor has a precise counter, the right tool for measuring (the tutorial [Speed — measure first](tut-53-speed.html)).

> [!NOTE] Some functions return values that are different on every computer, so a test cannot compare them with a number. Test **properties** instead: *the number is positive*, *the folder exists*, *this program is in the list*.

## What you learned

- `Environment`, `RuntimeInformation`,
- `Process.GetCurrentProcess` and `GetProcesses`,
- `GC.GetTotalMemory`,
- testing values that differ between computers.

## Exercises

1. Print the memory used by your program (in MB) before and after you fill a list with a million numbers.
2. Show the 10 programs that use the most memory (name and MB) — a text task manager.
3. Read the environment variable `PATH` and print each folder on its own line (the tutorial [Paths and the environment](tut-59-paths.html)).

## Next

[A command-line tool](tut-50-cli.html)
