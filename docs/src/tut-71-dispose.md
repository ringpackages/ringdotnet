---
title: "Tutorial 71: Releasing resources"
lead: A file you opened stays locked until you give it back. This lesson shows what a leaked resource does, how Dispose gives it back, and how to be sure that the clean-up runs even when an error happens.
---

## What you will learn

- what a **resource** is and why programs must release them,
- seeing a file stay locked,
- `Dispose` (and `Close`),
- clean-up that runs after an error,
- which classes need it.

## Resources

Memory is cleaned automatically, but some things are *lent* by the operating system: open files, network connections, database connections, window handles. While you hold one, others may be unable to use it — a file that is open for writing cannot be deleted or moved, a connection counts against the limit of the server. **You** must give them back. In .NET the method is `Dispose()` (many classes also have `Close()`, which does the same).

## The program

{{file:docs/tutorials/t71_dispose.ring}}

{{output:docs/tutorials/t71_dispose.ring}}

## How it works

### Locked while open

Step 1 opens the file and tries to delete it: *no*, the system refuses, because the file is in use. Step 2 calls `Dispose()` and now the delete works. A program that forgets this leaves files locked until it ends, and a long-running program (a service, a window) can run out of handles.

### An error skips the clean-up

Step 3 is the typical bug. The function opens a reader, then does some work that fails (here a number that cannot be read), and the line `oReader.Dispose()` after the failing call is never reached: the file is still locked after the error. Note the comment in the output: Ring forgets the variable when the function ends, but the **.NET object is still alive and open**. The Ring variable is not the resource.

### The careful way

Step 4 puts the `Dispose` **after** the `try … catch … done` block: it runs whether the work succeeded or failed.

```ring
oReader = new StreamReader(cFile)
try
	work()
catch
	? "an error"
done
oReader.Dispose()                  # always reached
```

C# has a `using` statement and `finally` for this; in Ring the pattern is *open → try / catch → dispose after*. If the function must `return` from inside the `try`, store the result in a variable and return after the dispose.

### What needs Dispose

Streams and readers/writers, `HttpClient`, sockets and listeners, `JsonDocument` ([tutorial 6](tut-06-json-xml.html)), database contexts ([tutorial 17](tut-17-databases.html)), timers and bitmaps. Rule of thumb: if the class has a `Dispose` or `Close` method, use it. Methods that do everything for you in one call (`File.ReadAllText`, `File.WriteAllText`) open and close the file themselves — another reason to prefer them for small files.

> [!TIP] Release in the **same function** that created the resource whenever you can. A resource that travels between functions is a resource that nobody releases.

## What you learned

- resources and locks,
- `Dispose` and `Close`,
- an error can skip a clean-up,
- the clean-up goes after the `try` block,
- the .NET object outlives the Ring variable.

## Exercises

1. Write `readFirstLine(cFile)` that opens a `StreamReader`, reads a line, disposes it and returns the line — even if the file is empty.
2. Open the same file twice for writing and see the error message.
3. Write a function that copies a file with two streams and releases both even if the copy fails.

## Next

[Tutorial 72: XML in depth](tut-72-xml.html)
