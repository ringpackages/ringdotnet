---
title: "Shared memory"
lead: Two programs on one computer can use the same block of memory. This lesson creates a named memory-mapped file, writes numbers and text into it, lets a second copy of the program read and answer, and edits a file in place through a mapping.
---

## What you will learn

- what a **memory-mapped file** is,
- `MemoryMappedFile.CreateNew` and `OpenExisting` (a named block that two programs share),
- a **view accessor** for numbers (`Write`, `ReadInt32`, `ReadDouble`) and a **view stream** for text,
- why a text read from the memory ends at the first zero byte,
- mapping a real file (`CreateFromFile`) and changing it in place.

## The idea

A normal file is read and written through calls. A **memory-mapped file** is a file (or just a block of memory with a name) that the system shows to your program as ordinary memory: what one program writes into it, another program that mapped the same name sees at once. It is the fastest way for programs on one computer to share data, and it is also a comfortable way to work with a very big file without loading it.

Compare the tools of the last tutorials: a **named pipe** (the tutorial [Two programs talking](tut-79-processes-talk.html)) sends messages one after another; **shared memory** is a place both programs can read and write at any time.

## The program

{{file:samples/UsingDotNet/tutorials/ch06_shared_memory.ring}}

{{output:samples/UsingDotNet/tutorials/ch06_shared_memory.ring}}

> [!NOTE] A memory-mapped file with a **name** (the first part of the program) is a Windows feature. On Linux and macOS .NET maps files only, so the program prints a message and runs the last part, the file edited in place.

## How it works

### One name, two programs

The parent calls `MemoryMappedFile.CreateNew([ :mapName = "...", :capacity = 4096 ])`: a block of 4,096 bytes with a name. The child (a second copy of the same program, started with `--child` as in [Two programs talking](tut-79-processes-talk.html)) calls `OpenExisting(name)` and gets *the same block*. Nothing is copied.

### Numbers

`CreateViewAccessor(NULL)` gives a view with methods that work at a **position** (a byte number): `Write(position, value)`, `ReadInt32(position)`, `ReadDouble(position)`, `ReadBoolean(position)`. The two programs must agree on the layout — here: position 0 holds an integer, position 4 the answer, position 8 a number with decimals. A whole Ring number is written as 4 bytes (an `int`), a number with decimals as 8 bytes (a `double`); read it back with the matching `Read…` method.

> [!NOTE] `Write` takes the type from the value you give it. Because every whole Ring number is written as an `int`, the accessor in this lesson stores integers and doubles only; for single bytes or other types use a `BinaryWriter` on a view stream.

### Text

`CreateViewStream([ :offset = 100, :size = 200 ])` is a `Stream` over a part of the memory, so `StreamWriter` and `StreamReader` work on it exactly like on a file (the tutorial [Streams and compression](tut-56-streams.html)). The memory starts **filled with zero bytes**: a reader that reads the whole view sees the text and then zeros, so `textOf` cuts the text at the first zero byte. If you design a protocol on shared memory, store the **length** first, or end texts with a zero.

### The conversation

Parent: writes the numbers and the text, starts the child and reads its output. Child: opens the memory, reads, writes `21 × 2` at position 4 and a text at position 300. Parent: reads both after the child ended. In a real program the two programs would run at the same time, so they need a way to say "my data is ready": a flag in the memory that the other side polls, or a named mutex or event (the tutorial [Two programs talking](tut-79-processes-talk.html)).

### A file edited in place

`CreateFromFile(path)` maps a **real file**. The view is the content of the file: `Write(4, 99)` changes four bytes of the file at position 4, and `Flush()` makes sure that the system writes the change. The program reads the file again with `ReadAllBytes` and shows that only the second of the three numbers changed. `BitConverter.GetBytes(10)` makes the four bytes of a number and `ToInt32(bytes, position)` reads one back.

This is the usual way to patch a large file, to read a huge file piece by piece, or to keep a database file that several programs use.

> [!WARNING] Two programs that write the same place at the same time can destroy each other's data. Decide who writes where, or use a lock (a `Mutex`) around the writes.

## What you learned

- named shared memory and `OpenExisting`,
- `CreateViewAccessor` for numbers and `CreateViewStream` for text,
- zero-filled memory and cutting a text,
- `CreateFromFile` for editing a file in place,
- the need for a layout and for locking.

## Exercises

1. Put a "ready" flag at position 200 and let the child wait (`Thread.Sleep` in a loop) until the parent sets it.
2. Keep a counter at position 0 that both programs increase, protected by a `Mutex`.
3. Map a text file and replace one character of it in place.
4. Store a text as *length first*: four bytes for the length, then the text.

## Next

[Tasks that wait](tut-83-tasks-waiting.html)
