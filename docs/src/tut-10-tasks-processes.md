---
title: "Time, tasks and other programs"
lead: Measure how long something takes, wait for background work, read the environment, and run another program and read what it prints.
---

## What you will learn

- `Stopwatch` to measure time,
- tasks and `Wait`,
- `Environment`: the computer and its variables,
- `Process`: start another program,
- the one important rule about threads.

## The program

{{file:samples/UsingDotNet/tutorials/ch01_tasks_processes.ring}}

{{output:samples/UsingDotNet/tutorials/ch01_tasks_processes.ring}}

## How it works

### Stopwatch

`Start()`, `Stop()`, then `ElapsedMilliseconds` (or `Elapsed` for a `TimeSpan`). `Thread.Sleep(120)` pauses the program for 120 ms. Measure the parts of a program that feel slow before you try to speed anything up.

### Tasks

A `Task` represents work that happens "in the background" or in the future. `Task.Delay(100)` is a task that completes after 100 ms. `IsCompleted` says whether it is done; `Wait(NULL)` blocks until it is. `Task.FromResult("done")` is a task that is already finished, with the result `done`, read with its property `Result`.

### The rule: Ring runs on one thread

> [!NOTE] .NET can do many things at once on many *threads*. **Ring code runs on one thread only.** A callback that .NET wants to start from another thread has to be handed to the Ring thread: the web server does it with `serveOne()` (see [HTTP](tut-09-http.html)), and the timers of Windows Forms (`uiTimer`) already tick on the Ring thread. So use tasks for waiting and for pure .NET work (HTTP, files, hashing), and keep your Ring code on the Ring thread.

### The environment

`Environment` knows the computer: `MachineName`, `ProcessorCount`, `CurrentDirectory`, `GetEnvironmentVariable("PATH")`, `UserName`, `OSVersion`. The program prints only `true` for each, so that the output is the same on every computer.

### Running another program

`ProcessStartInfo` describes *what* to run: `FileName`, `Arguments`, and:

| Property | Meaning |
|---|---|
| `RedirectStandardOutput = True` | you read what the program prints |
| `UseShellExecute = False` | run it directly (needed to redirect) |
| `CreateNoWindow = True` | no console window |

`Process.Start([ :startInfo = oInfo ])` starts it; `StandardOutput.ReadToEnd()` reads all its output; `WaitForExit(NULL)` waits for the end; `ExitCode` is `0` when the program succeeded.

The program starts the shell of the system with a command: `cmd /c "echo ..."` on Windows and `sh -c "echo ..."` on Linux and macOS (`isWindows()` chooses). This is how a Ring program uses any command-line tool: `git`, `ping`, `ffmpeg`, `dotnet`.

## What you learned

- time measuring and waiting,
- tasks and their results,
- the Ring-thread rule,
- the environment and starting other programs.

## Exercises

1. Measure how long it takes to compute 100000 square roots in a Ring loop.
2. Run `cmd /c dir` (`sh -c ls` on Linux and macOS) and count the lines in its output.
3. Print the three biggest environment variables by length (`GetEnvironmentVariables()`).
4. Start `notepad.exe` (on Windows) with a `Process`, wait 3 seconds and close it with `Kill()`.

## Where to go next

This was the last tutorial of the chapter **The basics**. The next chapter is **Text and data formats**: it starts with [Regular expressions in depth](tut-29-regex.html). The [Tutorials](tutorials.html) page lists all the chapters, and you can start any of them.
