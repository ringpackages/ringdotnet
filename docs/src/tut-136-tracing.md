---
title: "Tracing"
lead: Tracing writes messages about what a program does, for the person who looks for a problem. The program sends its messages to Trace, and listeners decide where they go: memory, a file, a window. This lesson adds listeners, indents messages, writes messages on a condition and removes a listener.
---

## What you will learn

- `Trace.WriteLine` and the **listeners** of `Trace`,
- a listener that collects messages in memory (`StringWriter`) and one that writes a file,
- `Indent` and `Unindent`,
- `WriteLineIf` and a **category**,
- adding and removing listeners without changing the code that writes messages,
- how tracing differs from logging.

The tutorial [Logging](tut-51-logging.html) wrote a log that the program owns. Tracing is for diagnosis: the program sends messages to a standard place, and what happens to them is decided outside the code that writes them.

## The program

{{file:samples/UsingDotNet/tutorials/ch06_tracing.ring}}

{{output:samples/UsingDotNet/tutorials/ch06_tracing.ring}}

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnStatic`, `dnNewGeneric`, `callMethod`, `getProp`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### Trace and listeners

`Trace` is a static class, called here with `dnStatic("System.Diagnostics.Trace", ...)`. `Trace.WriteLine(text)` sends a message to every **listener** in `Trace.Listeners`. A `TextWriterTraceListener` writes into any text writer: a `StringWriter` (memory), a file or the console. The listener is added with `Listeners.Add(listener)`. `AutoFlush = True` makes each message go to the listeners at once; without it messages wait in a buffer until `Flush` or the end of the program.

### Memory and files

The memory listener is the best choice for a test, because the test can read the messages back: `oWriter.ToString()` is everything that was traced. A listener made from a file name writes the file; the program flushes and disposes it before reading the file.

### Indent

`Indent()` pushes the following messages four spaces to the right and `Unindent()` takes them back. A function that traces what it does indents on entry and unindents on exit, and the trace shows the structure of the calls like an outline.

### Conditions and categories

`WriteLineIf(condition, text)` writes the message only when the condition is true, so a program does not need an `if` around each message. A second value is a **category**: `WriteLine("slow query", "database")` writes `database: slow query`, and a listener or a reader can filter on the category.

### Many listeners

One message went to the memory listener and to the file. Removing a listener (`Listeners.Remove`) stops the messages going to it, and the program that writes the messages did not change. This is the reason to use `Trace` for diagnosis: a developer adds a file listener when there is a problem, and the code stays as it is.

### Time

A trace is most useful when the messages say how long something took. The program takes a `Stopwatch` and uses `ElapsedMilliseconds` in the messages (the exact number differs on each run, so the program prints a yes or no about it).

> [!NOTE] A new program has only the default listener, which writes to an attached debugger, so the messages do not appear on the screen until a listener is added (a `ConsoleTraceListener`, for example). The class `Debug` has the same members as `Trace`, but C# compilers remove its calls from release builds; `Trace` calls stay in every build.

## What you learned

- the listeners of `Trace` and where messages go,
- memory and file listeners,
- indented messages, conditions and categories,
- adding and removing listeners without changing the code.

## Exercises

1. Write a function `traced(name, code)` that writes `enter name`, runs the code, and writes `leave name` with the time, with `Indent` and `Unindent` around it.
2. Add a `ConsoleTraceListener` and look at the messages on the screen.
3. Write each message with the date and time in front of it.
4. Make the file listener append to a file, run the program twice, and read the file.

## Next

[Working with other programs](tut-85-feed-programs.html)
