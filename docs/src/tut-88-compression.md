---
title: "Compression"
lead: Compression makes data smaller by finding repetition. This lesson uses the GZip, Deflate and Brotli streams to compress and decompress bytes in memory and to write and read a compressed file.
---

## What you will learn

- how a compression stream **wraps** another stream,
- `GZipStream`, `DeflateStream` and `BrotliStream`,
- compressing and decompressing bytes in a `MemoryStream`,
- why `Dispose` is needed to finish the data,
- why random data does not shrink,
- writing and reading a `.gz` file with `StreamWriter` and `StreamReader`.

The tutorial [Files and folders](tut-05-files.html) made a ZIP archive of files. This lesson compresses **data** (one stream of bytes). GZip is the format of `.gz` files and of `Content-Encoding: gzip` on the web.

## The program

{{file:samples/UsingDotNet/tutorials/ch05_compression.ring}}

{{output:samples/UsingDotNet/tutorials/ch05_compression.ring}}

## How it works

### Streams that wrap streams

A compression stream does not hold data itself: it is built **on top of** another stream and a mode (`Compress` or `Decompress`). Bytes written to a compressor are packed and written to the stream below it; bytes read from a decompressor come from the stream below it, unpacked. The stream below can be a `MemoryStream` (bytes in memory) or a `FileStream` (a file). The three classes have the same members, so the function `packer` is the only place that knows the format. It is made with `new GZipStream(oStream, "Compress")`. The mode is an enum, so it is a text.

### Compress and decompress

`compress` writes the bytes into the compressor (`Write(bytes, 0, count)`) and calls `Dispose()`. **`Dispose` matters**: it writes the end of the compressed data. If you only read the memory stream without it, the result is cut and cannot be decompressed. `decompress` opens a `MemoryStream` on the packed bytes (`[ :buffer = ... ]`), wraps it in a decompressor and copies everything to another stream with `CopyTo`. A `byte[]` is a Ring text of bytes in this package, so `len()` is the number of bytes and `cBack = aBytes` compares them.

### Sizes

The text repeats one sentence 200 times, so every format makes it tiny; Brotli is the smallest and GZip the largest here, which is common for text (Brotli is slower to compress). With normal text expect 2 to 4 times smaller, not 100. A GZip result starts with the bytes **31 139** (`1F 8B`), which is how programs recognize a `.gz` file.

### Random data

Compression needs repetition. Random bytes have none, so the result is slightly **larger** than the original (the header and the bookkeeping cost a few bytes). Data that is already compressed (JPEG, PNG, ZIP, MP4) behaves the same: compressing it twice does not help.

### A compressed file

Step 6 puts a `GZipStream` on a `FileStream` and a `StreamWriter` on the compressor. Everything written with `WriteLine` is compressed on its way to the disk. Disposing the **writer** closes the whole chain. Reading is the same chain in the other direction: `StreamReader` on `GZipStream` on `FileStream`, and `EndOfStream` tells when the lines are finished. (The tutorial [Streams and compression](tut-56-streams.html) explains streams.)

> [!NOTE] `BrotliStream` lives in another assembly (`System.IO.Compression.Brotli`); RingDotNet finds it for you. `CompressionLevel` (`"Optimal"`, `"Fastest"`, `"SmallestSize"`) is an optional second value of the constructor when the mode is `Compress`.

## What you learned

- a compression stream wraps another stream,
- `Dispose` finishes the compressed data,
- the three formats have the same members,
- repeated text shrinks, random or already compressed data does not,
- a compressed file is a `StreamWriter` on a `GZipStream` on a `FileStream`.

## Exercises

1. Compress the text of a real file (a log from the tutorial [A project: analyze a log file](tut-21-log-analyzer.html)) and print the ratio for each format.
2. Add `CompressionLevel` and compare `"Fastest"` with `"SmallestSize"` with a `Stopwatch`.
3. Write a function `gzipFile(source, target)` that uses `CopyTo` between two file streams.
4. Compress the same bytes twice and look at the size of the second result.

## Next

[ZIP archives in memory](tut-108-zip-in-memory.html)
