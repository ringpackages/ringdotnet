---
title: "ZIP archives in memory"
lead: A ZIP archive does not have to be a file. ZipArchive works on any stream, so a MemoryStream can hold a whole archive in memory — useful for a download that a web program sends, or for a test that leaves no files behind. This lesson creates, reads, compresses and updates an archive.
---

## What you will learn

- `ZipArchive` on a `MemoryStream` (modes `Create`, `Read`, `Update`),
- `CreateEntry`, `Entries`, `GetEntry`, `Delete`,
- why `Dispose` is needed,
- compression levels,
- checking the names of entries.

The tutorial [Files and folders](tut-05-files.html) made a ZIP file from a folder, the tutorial [Compression](tut-88-compression.html) compressed streams and the tutorial [Tar archives](tut-96-tar.html) made tar archives. This lesson works with the entries of an archive one by one.

## The program

{{file:samples/UsingDotNet/tutorials/ch05_zip_in_memory.ring}}

{{output:samples/UsingDotNet/tutorials/ch05_zip_in_memory.ring}}

## How it works

### The stream

`ZipArchive` is made on a stream and a mode: `dnNew("ZipArchive",[ :stream = oMemory, :mode = "Create", :leaveOpen = True ])`. `leaveOpen = True` keeps the `MemoryStream` open when the archive is closed, so the program can read the bytes afterwards (`ToArray()`), send them or open the archive again. Without it, closing the archive also closes the stream. The mode is an enum, so it is a text.

### Creating entries

`CreateEntry("data/names.txt")` makes an entry (a file inside the archive; folders are just a `/` in the name) and `Open()` gives a stream to write its content, here a `StreamWriter`. **`Dispose()` of the archive is required**: it writes the *central directory* at the end of the archive. A ZIP file or stream that was not disposed is incomplete and other programs cannot read it.

### Reading

Open the stream again (`Position = 0`) in `Read` mode. `Entries` lists every entry with `FullName`, `Length` (the original size) and `CompressedLength`. `GetEntry(name)` finds one by name and gives a null object when it is missing (`isNull()`); `Open()` returns a stream with the content. A very small file may become **bigger** in the archive (the `names.txt` of 10 bytes), because every entry has a header; compression helps when there is something to compress, like the repeated text of 5500 characters.

### Compression levels

`CompressionLevel` (`NoCompression`, `Fastest`, `Optimal`, `SmallestSize`) is a second value of `CreateEntry`. `NoCompression` stores the data as it is, `Fastest` gives a good result quickly and `SmallestSize` takes more time for a smaller result. The size of an entry can be read **after** the archive is closed (`CompressedLength` raises *"Length properties are unavailable once an entry has been opened for writing"* before that), so the program measures the length of the `MemoryStream`. The exact numbers depend on the version of the compression library, which is why the output only compares them.

### Updating

`Update` mode opens an existing archive for changes: add entries, `Delete()` others. Everything is written when the archive is disposed. For a big archive, `Update` copies data around; if you only *append*, it is cheaper to read the old archive and write a new one.

### Names

An entry name is just text, and a bad archive can contain `../../etc/passwd`. A program that unpacks entries by hand must check every name: no `..` part, no leading `/` or `\`, and the full path of the target must stay inside the target folder (the tutorial [Paths and the environment](tut-59-paths.html)). `ZipFile.ExtractToDirectory` does this check for you; your own loop does not.

## What you learned

- `ZipArchive` on a `MemoryStream` with `leaveOpen`,
- `CreateEntry`, `Entries`, `GetEntry`, `Open`, `Delete`,
- the archive must be disposed to be complete,
- compression levels, and small files that grow,
- check entry names before you unpack.

## Exercises

1. Write `zipFiles(aNames)` that returns the bytes of an archive and send them in the web server of the tutorial [A tiny web framework](tut-55-miniweb.html).
2. Write `listArchive(oStream)` that returns the entry names as a Ring list.
3. Compare the five levels for a real text file and a JPEG picture.
4. Add a comment to an entry (`Comment`) and read it back.

## Next

[Tar archives](tut-96-tar.html)
