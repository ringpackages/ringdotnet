---
title: "Random access and file locks"
lead: A file of records with the same size can be used like a table: the program goes straight to record 3, changes it in place and adds one at the end. This lesson uses FileStream with Seek, Write, SetLength and FileShare, and shows how a lock keeps two writers away from one file.
---

## What you will learn

- **fixed-size records** and the position of record *n*,
- `FileStream` with a mode, an access and a share,
- `Seek`, `Position`, `Length` and `SetLength`,
- changing one record **in place** and adding one at the end,
- `Flush`,
- locking a file with `FileShare` and the `IOException` of a file that is in use.

The tutorial [Binary files](tut-45-binary.html) wrote and read a file from the first byte to the last. This lesson jumps to a place in the file.

## The program

{{file:samples/UsingDotNet/tutorials/ch05_random_access.ring}}

{{output:samples/UsingDotNet/tutorials/ch05_random_access.ring}}

## How it works

### Records of a fixed size

Every record of the file has 20 bytes: the name in 12 characters (spaces fill the rest), the quantity in 4 digits (zeros in front) and 4 spaces. With a fixed size, record number *n* (counted from 1) starts at byte `(n - 1) * 20`. The program needs no index and does not read the records before it. Real formats of this kind use binary numbers (the tutorial [Binary files](tut-45-binary.html)); text fields are used here so that the file can be read by eye.

### Opening a FileStream

`dnNew("FileStream",[ :path = ..., :mode = "Create", :access = "ReadWrite", :share = "None" ])` has three important values. The **mode** says what happens when the file exists: `Create` makes a new empty file, `Open` opens an existing one, `OpenOrCreate` does either, `Append` writes at the end. The **access** says what this stream may do (`Read`, `Write`, `ReadWrite`). The **share** says what *others* may do while the stream is open.

### Seek and Position

`Seek(offset, "Begin")` moves the position to a byte counted from the start (`"Current"` and `"End"` are the other origins). `Position` is where the next read or write happens: after reading record 3 it is `60`, right after the record. `Write(text, 0, count)` writes `count` bytes of a text. `Read(buffer, 0, count)` reads them into a **byte buffer** (`dnBuffer(count)`), a .NET array that Ring holds, and gives the number of bytes it wrote; `dnBufferBytes(buffer, n)` copies them into a Ring text (the tutorial [Binary files](tut-45-binary.html)).

### In place

To change a record the program seeks to it and writes 20 new bytes over the old ones. Nothing else moves, so changing one record is as fast in a big file as in a small one. This only works because the new record has *exactly* the same size. To add a record the program seeks to the end (`n = 6`, the byte 100) and writes there; the file becomes longer.

### Flush and SetLength

A stream keeps some bytes in memory before it gives them to the system. `Flush` writes them at once; `Dispose` flushes and closes. `SetLength` cuts the file (the program keeps three records) or makes it longer (the new bytes are zeros).

### Locks

`FileShare.None` says that nobody else may open the file. A second open, from another program or from another stream of the same program, raises `System.IO.IOException`, because the file is in use. Closing the first stream (`Dispose`) releases the lock. `FileShare.Read` lets other streams read but not write: two readers are fine, a writer is refused. A program that updates a data file opens it with `None`, so two copies of the program cannot damage it by writing at the same time.

> [!NOTE] On Linux and macOS .NET uses advisory locks: they work between programs that use .NET, but another program can still open the file. Use a lock file or a database when the other programs are not yours.

## What you learned

- fixed-size records and the position of a record,
- `FileStream` modes, access and share,
- `Seek`, `Position`, `Flush` and `SetLength`,
- changing a record in place and adding one,
- locking a file against other writers.

## Exercises

1. Write `findRecord(oStream, cName)` that reads the records one by one until it finds the name.
2. Add a function `deleteRecord(n)` that copies the last record over record *n* and cuts the file by one record.
3. Make the record size 24 and add a price of 8 characters, and write a program that converts the old file.
4. Open the file with `FileShare.None` in one program and try to open it in a second program (the tutorial [Two programs talking](tut-79-processes-talk.html)).

## Next

[Copying a big file with progress](tut-157-copy-progress.html)
