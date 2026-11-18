---
title: "Tutorial 56: Streams and compression"
lead: A stream is a flow of bytes that can come from memory, a file or the network. This lesson writes and reads a MemoryStream, compresses text with GZip, and shows why one pattern works for everything.
---

## What you will learn

- what a **stream** is and why .NET uses it everywhere,
- `MemoryStream`, `StreamWriter` and `StreamReader`,
- `Flush`, `Position` and `Dispose`,
- compressing and decompressing with `GZipStream`,
- the same code for memory and for files.

## Streams in one minute

A stream is like a pipe: bytes go in at one end and come out at the other. The same few classes work with every kind of pipe:

| Class | Source or target |
|---|---|
| `MemoryStream` | memory |
| `FileStream` | a file (`File.Create`, `File.OpenRead`) |
| `NetworkStream` | a socket ([tutorial 25](tut-25-sockets.html)) |
| `GZipStream` | *wraps* another stream and compresses or decompresses what passes |
| `StreamWriter` / `StreamReader` | turn text into bytes and back |

Because they wrap each other you can stack them: text → `StreamWriter` → `GZipStream` → `FileStream` → disk.

## The program

{{file:docs/tutorials/t57_streams.ring}}

{{output:docs/tutorials/t57_streams.ring}}

## How it works

### Write, rewind, read

Step 1 writes two lines into a `MemoryStream`. A `StreamWriter` keeps a buffer, so `Flush()` sends it to the stream before you look at `Length`. Step 2 sets `Position = 0` to go back to the start (after writing, the position is at the end) and reads the lines with a `StreamReader`.

### Compression

The text of step 3 repeats the same sentence 200 times: 9,000 bytes become 120. Compression removes repetition, so text compresses very well and already compressed data (a zip, a JPEG) does not. A `GZipStream` created with `"Compress"` compresses what you write into it; with `"Decompress"` it decompresses what you read from it. Enum values are written as text (`"Compress"`).

> [!WARNING] A compressing stream finishes its data only when it is **disposed**. Without `Dispose()` the end of the data is missing and the result cannot be read back. `StreamWriter.Dispose()` closes the stream under it too; the constructor option `leaveOpen = True` keeps the inner `MemoryStream` open so you can read it afterwards.

### Files are streams too

Step 5 stacks a `StreamWriter` on a `GZipStream` on a file created with `File.Create`. Disposing the writer closes everything below it. The pattern is the same as in memory.

## What you learned

- streams as pipes that can be stacked,
- `Flush`, `Position`, `Dispose`,
- `GZipStream` with `"Compress"` and `"Decompress"`,
- `dnNew("GZipStream",[ :stream = ..., :mode = ..., :leaveOpen = True ])` for a constructor with three values.

## Exercises

1. Compress a text file to `.gz` and decompress it to a new file, then compare the two with a hash ([tutorial 8](tut-08-security.html)).
2. Try `ZipArchive` to put several files in one zip.
3. Compress a text of 200 *different* lines and compare the size with the repeated text.

## Next

[Tutorial 57: Money](tut-57-money.html)
