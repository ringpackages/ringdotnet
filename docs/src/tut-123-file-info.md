---
title: "File information"
lead: A file has more than its content — a size, times, attributes, a folder. This lesson reads and changes them with File and FileInfo: the size, the last write time, the read-only flag, copying with and without overwriting, and temporary files.
---

## What you will learn

- `FileInfo`: name, extension, size and whether the file exists,
- the **times** of a file and `Refresh()`,
- **attributes** and the read-only flag,
- the errors of a read-only file and of copying over an existing file,
- temporary files (`GetTempFileName`),
- `DirectoryInfo` and the sizes of the files in a folder.

The tutorial [Files and folders](tut-05-files.html) read and wrote the content of files. Here the file is the *thing*: how big it is, when it was written, whether it can be changed.

## The program

{{file:samples/UsingDotNet/tutorials/ch05_file_info.ring}}

{{output:samples/UsingDotNet/tutorials/ch05_file_info.ring}}

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnStatic`, `dnNewGeneric`, `callMethod`, `getProp`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### File and FileInfo

`File` has static methods that take a path (`File.Exists`, `File.Copy`, `File.Delete`...). `FileInfo` is an object made from a path: it gives `Name`, `Extension`, `Length` (bytes), `Exists`, `IsReadOnly`, the times and more, and it has the same actions as methods. `FileInfo` reads the information once and keeps it: when the file changes, `Refresh()` reads it again (step 2 needs it after the time was set).

### Times

A file has a creation time, a last write time and a last access time (each also in UTC). `File.SetLastWriteTime(path, time)` changes one; the program sets a known moment so that the output is the same every time. Backup tools and build tools compare the last write time of a source and its target to decide what is old.

### Attributes

`GetAttributes` returns the flags of a file as one text: `Archive` is set on Windows when a file was changed since the last backup, `ReadOnly` protects the file, `Hidden` hides it. Several flags are written with commas (`ReadOnly, Archive`). `SetAttributes(path, "ReadOnly")` replaces them all, so `"Normal"` removes the flags. On Linux and macOS the read-only flag follows the file permissions, and the output of step 3 differs a little there.

### Errors

Writing to a read-only file raises `System.UnauthorizedAccessException`. `File.Copy` onto an existing target raises `System.IO.IOException` unless the overwrite value is `True`. The message of such an error contains the full path, which is different on each computer, so the program prints only the *kind* of the error (the name of the exception) with the function `errorKind`.

### Temporary files

`Path.GetTempFileName()` creates an empty file with a unique name in the folder for temporary files and gives its path. The program that asked for it deletes it. For a whole work folder the program makes a name with `Path.GetRandomFileName()` and deletes the folder at the end, as this program does.

### A folder and its files

`DirectoryInfo` is to a folder what `FileInfo` is to a file. `GetFiles(NULL)` returns its files as `FileInfo` objects. The names are sorted before they are printed, because .NET does not define the order of the files it returns.

## What you learned

- `FileInfo` and `DirectoryInfo`,
- times, `Refresh()` and the attributes,
- read-only files and the exceptions of files,
- temporary files and folders.

## Exercises

1. Write `isOlderThan(cFile, nDays)` and use it to list the files of a folder that were not changed for a month.
2. Set the `Hidden` attribute and find the hidden files of a folder (`GetFiles` and `Attributes`).
3. Copy a file and compare the last write times of the two.
4. Write `totalSize(cFolder)` for a folder and all its subfolders.

## Next

[Disks and free space](tut-124-disks.html)
