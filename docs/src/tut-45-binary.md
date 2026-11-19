---
title: "Tutorial 45: Binary files"
lead: Not every file is text. Pictures, archives and programs are bytes in a particular layout. This lesson writes and reads a tiny binary format, looks at its bytes with a hex dump, and learns the habits that protect against wrong files.
---

## What you will learn

- the difference between text and binary files,
- `FileStream`, `BinaryWriter`, `BinaryReader`,
- designing a small file format with a magic number,
- a hex dump,
- bytes, little endian and the type that you pass,
- closing files in every case.

## Text and binary

A **text** file is a list of characters (encoded as bytes). A **binary** file is a list of bytes with a meaning that only the *format* tells: the first four bytes are a number, the next ones a name... A program that does not know the format sees garbage. A binary format is smaller and faster to read, and exact (a number is stored as a number, not as the text `21.5`).

## The program

{{file:docs/tutorials/t45_binary.ring}}

{{output:docs/tutorials/t45_binary.ring}}

## How it works

### The format

We invented it: first the text `RDN1`, then the count (3) as a 32-bit whole number, the title as a text, then that many decimal numbers. Any reader must follow **exactly the same order**. The `BinaryWriter` writes each value in a fixed, compact way, and the `BinaryReader` reads them back with matching calls: `ReadString`, `ReadInt32`, `ReadDouble`.

### Reading the hex dump

Each line of the dump shows an offset (position), eight bytes in hexadecimal, and the same bytes as characters (`.` for unprintable ones). Read the real file:

```text
0000  04 52 44 4e 31 03 00 00  .RDN1...
```

- `04` is the **length** of the text that follows: a `BinaryWriter` writes a text as *length + characters*: `04` then `52 44 4e 31` = `R D N 1`.
- `03 00 00 00` is the whole number 3 written in 4 bytes. The **smallest byte comes first** (*little endian*): that is how Windows computers store numbers. 1000 is `E8 03 00 00`: 1000 = 3 × 256 + 232 (`E8`), which step 5 shows with `BitConverter`.
- `0c` = 12, the length of `Temperatures`.
- The three decimal numbers take 8 bytes each (`00 00 00 00 00 80 35 40` is 21.5).

### The type that you pass decides

`Write(21.5)` writes a decimal (8 bytes); `Write(23)` would write a *whole* number (4 bytes) because Ring numbers without decimals are passed as integers. If you then read it back with `ReadDouble` you get an error ("unable to read beyond the end"). When the reader and the writer disagree, the file is garbage. Keep the values of a decimal field decimal (`23.0` is still whole to Ring: add a fraction or convert the value) and test your format by reading back what you wrote.

### The magic number

The first bytes of a file say what kind of file it is: PNG files start with `89 50 4E 47`, zip files with `PK`. A reader checks them first and refuses anything else. Step 4 writes a text file over our file and `readMagic` returns something that is not `RDN1`: refused, instead of reading nonsense.

### Close files in every case

The reader and writer hold the file open. An open file cannot be deleted or replaced, and its last bytes may not be written yet. `readMagic` closes the reader **after** the `try` / `catch`, so it is closed also when reading failed. (The first version of this tutorial closed it inside `try`: the failed read left the file open and the final `Delete` failed. That is exactly the kind of mistake to look for.)

## What you learned

- binary files are bytes with a format,
- `BinaryWriter` / `BinaryReader` read and write in the same order,
- a hex dump shows the truth,
- little endian,
- magic numbers,
- always close.

## Exercises

1. Add a version number to the format, and make the reader accept versions 1 and 2.
2. Write a list of names (count, then each name) and read it back.
3. Extend `hexDump` to take a start offset and a length.
4. Read the first 8 bytes of a PNG file and check that they are `89 50 4E 47 0D 0A 1A 0A`.

## Next

[Tutorial 88: Compression](tut-88-compression.html)
