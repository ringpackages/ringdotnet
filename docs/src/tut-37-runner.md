---
title: "A project: a command runner"
lead: Many useful programs are a friendly window around a command-line tool. This one lets you type a command, runs it, and shows everything it prints together with its exit code.
---

## What you will learn

- starting another program from a window application,
- reading its output and error output,
- exit codes,
- handling failure with `try` / `catch`,
- a read-only, console-style text area.

## The idea

Almost every tool has a command-line version: `git`, `ping`, `dotnet`, `ffmpeg`, `robocopy`. A Ring program starts it with a `Process`, collects what it prints, and shows it. The same pattern is how you would build a front-end for any such tool: gather the options in controls, build the command line from them, run, show the result.

## The program

{{file:samples/UsingDotNet/tutorials/ch12_runner.ring}}

![The command runner after running echo](img/shots/tut-g37.png "The command runner")

{{output:samples/UsingDotNet/tutorials/ch12_runner.ring --selftest}}

## How it works

### Describing the program to start

A `ProcessStartInfo` says *what* to run:

| Property | Meaning |
|---|---|
| `FileName = "cmd"` | the program: the Windows command interpreter |
| `Arguments = "/c " + cCommand` | `/c` means "run this command and then exit" |
| `RedirectStandardOutput = True` | capture what it prints |
| `RedirectStandardError = True` | capture its error messages (a different stream) |
| `UseShellExecute = False` | start it directly (needed for redirecting) |
| `CreateNoWindow = True` | do not open a console window |

Using `cmd /c` lets the user type anything that the command prompt understands, including `&&` to chain commands and built-in commands such as `echo` and `dir`.

### Running and reading

`Process.Start([ :startInfo = oInfo ])` starts it. `StandardOutput.ReadToEnd()` waits until the program closes its output, then returns all of it; the same for `StandardError`. `WaitForExit(NULL)` waits for the end, and `ExitCode` is the program's answer: **0 means success**, anything else means an error. The program also measures the time with a `Stopwatch`.

> [!NOTE] Read the output **before** `WaitForExit`, as the program does. If the output is big and nobody reads it, the program blocks when its buffer is full and `WaitForExit` waits forever. (For both streams of a very chatty program you would read one of them asynchronously.)

### Failure

If the program cannot be started at all (a wrong `FileName`), `Process.Start` raises an error: the `try` / `catch` shows it in the output box and sets the status to *Failed*. A program that starts and *returns an error code* is a different case: you see its messages in `StandardError` and the exit code in the status line, as the test shows with a folder that does not exist.

### The output box

A `TextBox` with `Multiline`, `ReadOnly` (the user cannot type in it), a monospaced `Font` (`Consolas`) and black background with green text looks like a console. `ScrollBars` come from `uiMemo`.

### Testing

`selfTest` runs `echo one && echo two` and checks that both lines are in the box, that the exit code is 0; then `dir` of a non-existing folder: the box has an error text and the exit code is not 0.

> [!WARNING] A command runner executes **whatever is typed**. That is fine on your own computer. Never build a command line from text that came from somebody else (a web form, a file) without checking it: the person could add `&& del` to it.

## What you learned

- `ProcessStartInfo` + `Process` run any program,
- output and error output are separate streams,
- the exit code tells success or failure,
- a window around a command-line tool.

## Exercises

1. Add a **Stop** button that kills a long-running command (`oProcess.Kill()`; the process must be a global variable).
2. Keep a history: a `ComboBox` with the last ten commands.
3. Make a **ping** window: a host box, a *Ping* button and the result in plain text.
4. Run a command in a given folder (`WorkingDirectory`).

## Next

[A project: an address book with a database](tut-48-addressbook.html)
