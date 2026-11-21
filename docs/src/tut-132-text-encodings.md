---
title: "Text files and encodings"
lead: A file holds bytes, and an encoding says which bytes are which characters. This lesson shows the bytes of one text in UTF-8, UTF-16, Latin-1 and ASCII, the byte order mark, how to read a file in the right encoding, and how a program can find out which encoding a file has.
---

## What you will learn

- the **bytes** of a text in four encodings,
- the **byte order mark** (BOM),
- what `File.WriteAllText` and `File.ReadAllText` do about encodings,
- reading a file that has no BOM and an old encoding (Latin-1),
- **strict** decoding with `UTF8Encoding(False, True)`,
- a simple order of tests to detect an encoding,
- Windows and Unix line endings.

The tutorial [Unicode and encodings](tut-52-unicode.html) explained characters, code points and the .NET string. This lesson is about files: the bytes on the disk.

## The program

{{file:samples/UsingDotNet/tutorials/ch02_text_encodings.ring}}

{{output:samples/UsingDotNet/tutorials/ch02_text_encodings.ring}}

> [!NOTE] This program uses a generic function (`dnNew`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### Bytes and encodings

The text `Café €` has six characters. In **UTF-8** it has 9 bytes: the letters of English take 1 byte each, `é` takes 2 and `€` takes 3. In **UTF-16** (called *Unicode* by .NET) each character takes 2 bytes here: 12 bytes. **Latin-1** has one byte for each of 256 characters, so the text takes 6 bytes, and the euro sign, which Latin-1 does not have, becomes `?`. **ASCII** has only 128 characters, so `é` and `€` both become `?`. A `byte[]` is a Ring text of bytes in this package, and the function `toHex` shows each byte with `ascii` and `hex`.

### The byte order mark

A **BOM** is a few bytes at the start of a file that say which encoding it has: `EF BB BF` for UTF-8, `FF FE` for UTF-16 little endian (and `FE FF` for big endian). UTF-8 has no byte order problem, so most programs write no BOM, and `File.WriteAllText` writes none. Some programs (older Windows tools) need it, and `UTF8Encoding(True)` writes it. UTF-16 files almost always have it.

### Reading

`File.ReadAllText` looks at the first bytes. When it finds a BOM it uses that encoding, **even when you give another one**: the UTF-16 file reads back correctly in step 3. Without a BOM it uses the encoding you give, and UTF-8 when you give none.

### A file without a BOM

The bytes of a Latin-1 file `Café` are `43 61 66 E9`. `E9` alone is not valid UTF-8, so a UTF-8 reader replaces it with the **replacement character** (`EF BF BD`) and the accent is lost for ever. Nothing in the file tells that it is Latin-1: the program or the user has to know. Windows programs of older times wrote the code page of the computer, and Latin-1 is a good first guess for Western Europe.

### Strict decoding

`UTF8Encoding(False, True)` has a second value that makes it **raise an error** for bytes that are not valid UTF-8, instead of replacing them. Wrapping `GetString` in `try` gives the function `isValidUtf8`. A text with accents that is valid UTF-8 is almost certainly UTF-8: the other encodings produce byte patterns that are very unlikely to be valid UTF-8 by chance. A plain English file is valid in all of them, so it does not matter which one you choose.

### The order of the tests

`detect` follows the usual order: (1) a BOM says the encoding; (2) valid UTF-8 means UTF-8; (3) otherwise use a default and let the user change it. Real programs add a menu *Encoding* for the last case. And a program that **writes** files should write UTF-8, with a BOM only for the programs that need it.

### Line endings

Windows uses two characters at the end of a line (13 10), Unix and macOS use one (10). `File.ReadAllLines` understands both and also a mix, so the file here has three lines. When a program writes a file for another system it chooses the line ending explicitly.

## What you learned

- the bytes of a text in four encodings,
- the BOM and its effect on reading,
- the loss of data when the encoding is wrong,
- strict decoding and a way to detect UTF-8,
- the two kinds of line ending.

## Exercises

1. Write a text with the characters `ü` and `ß` in UTF-8 and in Latin-1 and compare the sizes.
2. Write `convertFile(source, target, fromEncoding, toEncoding)` that changes the encoding of a file.
3. Make a function that counts how many replacement characters a text has, and use it to check a file after reading.
4. Read a Windows file with `ReadAllLines` and write it back with Unix line endings (join the lines with `char(10)`).

## Next

[Comparing text](tut-97-comparers.html)
