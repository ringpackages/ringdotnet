---
title: "Two programs talking"
lead: Programs on one computer can send each other messages through a named pipe, and they can share a lock so that only one copy of a program runs. This lesson starts a second copy of the program, talks to it, and shows what the lock does.
---

## What you will learn

- starting another program with `ProcessStartInfo` and `Process`, and reading what it prints,
- **named pipes**: `NamedPipeServerStream` and `NamedPipeClientStream`,
- a line-based protocol on top of a stream (`StreamReader` / `StreamWriter`),
- a named **mutex** (`Mutex`) that the whole computer shares: *only one copy* of a program,
- the same program as parent and child (`--child`).

## Pipes and mutexes

A **named pipe** is a channel between two processes on one computer. One side is the *server*: it creates the pipe with a name and waits. The other side is the *client*: it connects to the name. Both sides get a stream and use it like a file or a socket (the tutorial [Streams and compression](tut-56-streams.html), the tutorial [Sockets](tut-25-sockets.html)). Pipes are fast and need no network and no port number.

A **named mutex** is a lock with a name. The first program that gets it holds it; another program that asks for the same name does not get it. Typical use: *a program that must not run twice* (a tray application, a database service, an installer).

## The program

{{file:docs/tutorials/t79_processes_talk.ring}}

{{output:docs/tutorials/t79_processes_talk.ring}}

## How it works

### One file, two roles

The program starts itself a second time with the argument `--child` (`exefilename()` is the Ring executable, `filename()` this file). `main` looks at `sysargv`: with `--child` it is the child, otherwise the parent. This keeps the tutorial in one file; in real life the two programs would be different files.

### The parent

1. **The lock.** `dnNew("Mutex",[ :initiallyOwned = False, :name = ... ])` opens (or creates) the mutex; `WaitOne(0)` means *try to take it, do not wait*. The parent gets it.
2. **The pipe.** `NamedPipeServerStream` creates the pipe. The constructor has many forms, so it is made with named arguments; `direction = "InOut"` lets both sides read and write (enums are texts).
3. **The child.** `ProcessStartInfo` describes the program to start: `UseShellExecute = False` and `RedirectStandardOutput = True` let the parent read what the child prints; `CreateNoWindow` hides the window. `Process.Start(info)` starts it.
4. **Talking.** `WaitForConnection()` blocks until the child connects. After that the parent writes one line (`add 20 22`) and reads one line of the answer. `AutoFlush = True` sends each line at once; without it the line may wait in the buffer.
5. **The result.** The child's output (`StandardOutput.ReadToEnd()`), its exit code, and the lock is released.

### The child

The child tries the same mutex with `WaitOne(0)`: it does **not** get it, because the parent holds it, and says so. That is exactly the check a single-instance program makes at the start: *if I cannot get the lock, another copy is running — show that window and exit*. Then the child connects to the pipe (`Connect(5000)` waits up to five seconds for the server), reads requests in a loop and answers them. `quit` ends the conversation.

### The protocol

A *protocol* is an agreement about what the messages look like. Here: one request per line, one answer per line, `quit` to finish, and `error: ...` for requests the child does not understand. Everything that goes over a pipe or a socket needs such an agreement; keep it as simple as this one.

> [!WARNING] `ReadLine` waits until a line arrives; a window program must not wait like this (the tutorial [A chat over TCP](tut-63-chat.html) shows how to poll). Also set time limits (`Connect(5000)`) so that a missing partner cannot block your program for ever.

## What you learned

- `Process.Start` with redirected output,
- named pipes between processes,
- a named mutex for a single-instance program,
- a line protocol over a stream.

## Exercises

1. Make the child answer `time` with the current time.
2. Let the parent start *two* children one after the other, each using the pipe in turn.
3. Make a program that exits with a message when it cannot get the mutex, and start it twice from two terminals.
4. Send a list as a line of JSON (the tutorial [JSON as a tree](tut-80-json-nodes.html)) and parse it on the other side.

## Next

[Shared memory](tut-82-shared-memory.html)
