---
title: "Files and folders"
lead: Read and write text files, build paths the right way, get information about files, copy, list and zip — with Path, Directory, File, StreamReader and ZipFile.
---

## What you will learn

- why you use `Path.Combine`,
- reading a whole file, line by line, and writing and appending,
- information about a file,
- listing a folder, copying, zipping, cleaning up.

## The classes

| Class | Job |
|---|---|
| `Path` | work with *names* of files and folders (no disk access) |
| `File` | read, write, copy, delete a file in one call |
| `Directory` | create, delete, list folders |
| `FileInfo` | information about one file: size, name, dates |
| `StreamReader` / `StreamWriter` | read or write a file piece by piece (big files) |
| `ZipFile` (`System.IO.Compression`) | make and open zip files |

## The program

{{file:samples/UsingDotNet/tutorials/ch01_files.ring}}

{{output:samples/UsingDotNet/tutorials/ch01_files.ring}}

## How it works

### Paths

Never build a path by joining texts with `/` or `\`. `Path.Combine([a,b])` uses the right separator for the computer, and `Path.GetTempPath()` gives a folder where temporary files are allowed. Other `Path` helpers: `GetFileName`, `GetExtension`, `GetFileNameWithoutExtension`, `GetDirectoryName`. They only work on the *text* of a path; the file does not have to exist.

### Ask before you act

`Directory.Exists(cFolder)` and `File.Exists(cFile)` return true or false. `Directory.Delete([ :path = cFolder, :recursive = True ])` deletes a folder and everything in it. `Delete` has a version with one parameter (an empty folder only) and one with two; the list of *named arguments* chooses the second.

### Reading and writing

| Need | Call |
|---|---|
| the whole file as one text | `File.ReadAllText(path)` |
| the lines as a collection | `File.ReadAllLines(path).toList()` |
| write (overwrites) | `File.WriteAllText([ :path = p, :contents = text ])` |
| add at the end | `File.AppendAllText([ :path = p, :contents = text ])` |

`windowsnl()` is Ring's line break for Windows (carriage return plus line feed).

### Big files: a reader

`ReadAllText` loads everything into memory. For a big file use a `StreamReader`: `ReadLine()` returns the next line, `EndOfStream` is true at the end, and **`Close()` must be called** to release the file.

### Information, copy, list

`FileInfo` gives `Name`, `Length` (the size in bytes), dates. `File.Copy([ :sourceFileName = from, :destFileName = to ])`, `Directory.GetFiles(folder)` and `File.Delete(path)` do what they say. `Write` and `Copy` have several versions, so they take a list of named values, like `Round` in the last lesson.

### Zip

`ZipFile.CreateFromDirectory(folder, zipFile)` compresses a whole folder; `ZipFile.ExtractToDirectory` opens it again.

### Clean up

A program that creates temporary files deletes them at the end. This tutorial's last line checks that the folder is gone.

## What you learned

- build paths with `Path`, not with `+`,
- ask `Exists` before you read,
- use a reader for big files and always close it,
- `FileInfo` gives the facts about a file.

## Exercises

1. Write a program that counts the lines in every `.ring` file of a folder (`Directory.GetFiles(folder, "*.ring")`).
2. Copy a file to the Documents folder (`Environment.GetFolderPath("MyDocuments")`).
3. Find the biggest file in a folder with `FileInfo.Length`.
4. Write a log: each run appends a line with the date and time.

## Next

[JSON and XML](tut-06-json-xml.html)
