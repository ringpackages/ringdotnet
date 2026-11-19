---
title: "Working with other programs"
lead: A program can start other programs, send them text on their standard input, read what they print, set their environment, check their exit codes, and stop them when they take too long. This lesson does all of it with the Process class.
---

## What you will learn

- the three streams of a program: **standard input**, **standard output** and **standard error**,
- sending lines to a program and closing its input,
- chaining programs: the output of one is the input of another,
- environment variables and the working folder of the new program,
- exit codes: `0` means success,
- `WaitForExit(ms)` as a time limit and `Kill`.

The tutorial [Time, tasks and other programs](tut-10-tasks-processes.html) started programs and the tutorial [A project: a command runner](tut-37-runner.html) showed their output in a window. This lesson adds the input side and the control of the new program.

> [!NOTE] The examples use the Windows commands `sort`, `find` and `cmd`. On Linux and macOS use `sort`, `grep` and `sh -c`; the Ring code stays the same.

## The program

{{file:docs/tutorials/t85_feed_programs.ring}}

{{output:docs/tutorials/t85_feed_programs.ring}}

## How it works

### Starting a program with redirected streams

`startProgram` makes a `ProcessStartInfo` (the file, the arguments) and sets three things: `UseShellExecute = False` (needed to redirect), `CreateNoWindow` (no console window) and, when asked, `RedirectStandardInput`, `RedirectStandardOutput` and `RedirectStandardError`. `Process.Start(info)` starts it and gives a `Process`. After that `oProcess.StandardInput`, `StandardOutput` and `StandardError` are stream writers and readers: your program is now the keyboard and the screen of the other program.

### Input

`sort` reads lines until its input ends, then prints them sorted. So the program writes the lines (`StandardInput.WriteLine`) and then **closes the input** (`StandardInput.Close()`): without `Close` the other program keeps waiting for more and your program waits for the answer — a *deadlock*. Then `ReadToEnd()` reads the whole answer and `WaitForExit(NULL)` waits for the program to end.

### Chaining

Step 2 is the shell's `sort | find "e"` written by hand: the output of the first program is written into the input of the second. The pattern is always: write, close, read, wait.

> [!WARNING] If a program writes a lot to both its output and its error and you read only one of them, the other fills its buffer and the program stops. Read both (one with `ReadToEnd()` and the other after the program ended, or one in a loop), or redirect only what you need.

### Environment and folder

A new program gets a copy of the environment of its parent. `oInfo.EnvironmentVariables.Add("GREETING", "…")` adds a variable that only the child sees; `cmd /c echo %GREETING%` prints it. `WorkingDirectory` sets the folder in which the program starts. The folder is put into a variable first because a `new` on the right side of a property assignment loses the assignment ([Gotchas](gotchas.html)).

### Exit codes and errors

A program tells its result with an **exit code**: `0` is success, anything else a problem (the program decides which number means what). A program writes its error messages to the **standard error** stream, separate from its normal output: step 4 reads `File Not Found` from `StandardError` and sees exit code `1`. `oProcess.ExitCode` is available after the program ended.

### A time limit

`WaitForExit(300)` waits at most 300 ms and answers *true* if the program ended, *false* if it is still running. `Kill(NULL)` stops it at once (use it only when you must: the program gets no chance to clean up); then `HasExited` is true.

## What you learned

- redirecting the three streams,
- the write, close, read, wait pattern,
- environment variables and `WorkingDirectory`,
- exit codes and standard error,
- `WaitForExit(ms)` and `Kill`.

## Exercises

1. Write a function `runAndCapture(cFile, cArguments)` that returns `[exit code, output, error]`.
2. Run `ping` with a time limit of two seconds and stop it if it is slower.
3. Write a little program that reads lines from its input and prints them in upper case (the child of the tutorial [Two programs talking](tut-79-processes-talk.html)) and feed it from the parent.
4. Chain three programs: sort, remove duplicates (`uniq` or `sort /unique`), count lines.

## Next

[Two programs talking](tut-79-processes-talk.html)
