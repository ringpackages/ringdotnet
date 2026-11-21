---
title: "Copying a big file with progress"
lead: File.Copy copies a file in one call, but a program that shows a progress bar or can be cancelled reads and writes the file in pieces. This lesson copies 3,000,000 bytes through a 64 KB byte buffer, reports the progress, cancels half way, checks the copy with a checksum and compares buffer sizes.
---

## What you will learn

- reading and writing in **pieces** with `FileStream.Read` and `Write`,
- a **byte buffer** (`dnBuffer`) that is filled by `Read` and sent on by `Write`,
- why `Read` returns a **number** and `0` means the end,
- a **progress** report and a **cancel** that removes the half copy,
- checking the copy with the size and a SHA-256 checksum,
- the size of the buffer and the number of calls.

The tutorial [Binary files](tut-45-binary.html) introduced the byte buffer. Here the buffer does the work of a copy.

## The program

{{file:samples/UsingDotNet/tutorials/ch05_copy_progress.ring}}

{{output:samples/UsingDotNet/tutorials/ch05_copy_progress.ring}}

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnStatic`, `dnBuffer`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### The loop

`copyFile` opens the source for reading and the target for writing (`Create` makes a new file), and makes **one buffer** of 64 KB. The loop is always the same: `Read` fills the buffer and answers how many bytes it wrote, `Write` sends *those* bytes on, and the loop ends when `Read` answers `0`, the end of the file. The same buffer is used again and again, so the program needs 64 KB of memory for a file of any size.

### Read gives a number

`Read(buffer, 0, size)` may write **fewer** bytes than the buffer holds: the last piece of a file is almost always smaller (the file here has 3,000,000 bytes, and the last piece has 3,000,000 − 45 × 65,536 bytes). The program writes `nRead` bytes, not the size of the buffer; writing the whole buffer would add bytes to the end of the copy.

### No Ring text in the middle

`Write(oBuffer, 0, nRead)` takes the buffer itself: the bytes go from the file to the buffer and from the buffer to the other file inside .NET, and are never turned into a Ring text. That is faster, and it is the reason to use a buffer even though a Ring text can hold the bytes. A program that must look at the bytes (to count something, to search) reads them with `dnBufferBytes(oBuffer, nRead)`.

### Progress

After each piece the program knows how many bytes were copied and the total (`Length` of the source), so the percentage is `100 * copied / total`. The program prints a line the first time that the percentage passes 25, 50, 75 and 100. A window program sets a progress bar at this place, and handles the events of the window in the loop so that it does not freeze (the tutorial [Timers and progress](tut-34-timers.html) does the same with a timer).

### Cancel

A cancelled copy leaves a **half file**, which is worse than no file: somebody may use it. The function stops when the limit is reached, closes both streams (`Dispose`), and deletes the target. The same pattern is used for an error in the middle: close, delete, report.

### Check the copy

A copy is complete when the **size** is the same and the **checksum** is the same (the tutorial [A project: check that files did not change](tut-147-checksums.html)). The size is a quick check, and the checksum proves that every byte is the same.

### The size of the buffer

With a buffer of 4 KB the 3,000,000 bytes need 733 calls of `Read`, with 64 KB 46 calls and with 1 MB only 3. Every call crosses the bridge, so a very small buffer is slow, and a very big one wastes memory and gives the user fewer progress reports. Sizes between 16 KB and 1 MB are usual.

## What you learned

- the read and write loop with one buffer,
- `Read` answers how many bytes it wrote, and `0` at the end,
- progress and cancel, and deleting a half copy,
- checking a copy,
- the size of the buffer.

## Exercises

1. Show the speed in megabytes per second (a `Stopwatch`, the tutorial [Speed: measure first](tut-53-speed.html)).
2. Copy two files at once by taking one piece from each in turn.
3. Make `moveFile` that copies and deletes the source only after the checksums are equal.
4. Resume an interrupted copy: open the target with `Append`, seek the source to the size of the target, and go on.

## Next

[What kind of file is it?](tut-159-file-types.html)
