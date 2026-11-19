---
title: "Tar archives"
lead: Tar puts many files and folders into one file; it is the usual way to pack a folder on Linux and macOS, and Docker images are made of tar files. This lesson creates, lists, reads and unpacks tar archives with System.Formats.Tar.
---

## What you will learn

- what a **tar** file is and how it differs from ZIP and GZip,
- making a tar file from a folder (`TarFile.CreateFromDirectory`),
- listing the entries with `TarReader`,
- reading one file without unpacking the rest,
- unpacking (`TarFile.ExtractToDirectory`).

## ZIP, GZip and tar

| Format | What it does |
|---|---|
| **ZIP** (the tutorial [Files and folders](tut-05-files.html)) | collects files and compresses each one |
| **GZip** (the tutorial [Compression](tut-88-compression.html)) | compresses *one* stream of data |
| **tar** | collects files and folders into one file, **without** compressing |

Linux programs combine the last two: a `.tar.gz` (or `.tgz`) file is a tar archive compressed with GZip. Tar also keeps things that ZIP does not always keep, such as Unix permissions and links.

## The program

{{file:docs/tutorials/t96_tar.ring}}

{{output:docs/tutorials/t96_tar.ring}}

## How it works

### Making the archive

`TarFile.CreateFromDirectory(source folder, tar file, include the folder itself)` packs a whole folder. It is a static method of a static class, so the program calls it with `dnStatic(type, method, [arguments])` with the arguments in order. Here the folder itself is not included, so the entries are `readme.txt` and `notes/a.txt`, not `source/readme.txt`. A tar file is built from blocks of 512 bytes, which step 1 checks: the size is a multiple of 512.

### Reading the entries

A `TarReader` is made on a stream (`dnNew("TarReader",[ :archiveStream = oStream ])`). `GetNextEntry` gives the next `TarEntry`, and *null* at the end, which `isNull()` tests. Each entry has `Name`, `EntryType` (`RegularFile`, `Directory`, `SymbolicLink`, ...) and `Length`. `GetNextEntry` has two forms, so it is called with `NULL` for the plain one. The entries come in the order of the folder, which depends on the file system, so the program sorts its lines before printing them: a test must not depend on the order of a disk.

### One file from the archive

Reading is *sequential*: a tar file has no index, so to find `notes/b.txt` the reader goes through the entries until it meets the name. `DataStream` of the entry is a stream with the content, read here with a `StreamReader` (the tutorial [Streams and compression](tut-56-streams.html)). The data is available only until you ask for the next entry. For a big archive this is both the strength of tar (it can be read as it arrives, from a network or a pipe) and its weakness (no quick access to the last file).

### Unpacking

`TarFile.ExtractToDirectory(tar file, target folder, overwrite)` writes all the entries to a folder, which **must exist**. 

> [!WARNING] Never unpack an archive from an unknown source without checking the names of the entries. A bad archive can contain names such as `../../important.txt` that try to write outside the target folder (the attack is called *path traversal* or *zip slip*). `ExtractToDirectory` refuses such names, but if you write your own loop with `TarReader`, check each `Name` with `Path.GetFullPath` first (the tutorial [Paths and the environment](tut-59-paths.html)).

## What you learned

- tar collects files without compressing them,
- `CreateFromDirectory` and `ExtractToDirectory` with `dnStatic`,
- `TarReader`, `GetNextEntry`, `EntryType`, `DataStream`,
- reading is sequential,
- the danger of names that leave the target folder.

## Exercises

1. Make a `.tar.gz`: create the tar file, then compress it with `GZipStream` (the tutorial [Compression](tut-88-compression.html)).
2. Write `listTar(cFile)` that returns the names of the entries as a Ring list.
3. Write a function that adds one more file to an archive with `TarWriter`.
4. Make an archive with an empty folder and look at how it is listed.

## Next

[File patterns (globbing)](tut-112-globbing.html)
