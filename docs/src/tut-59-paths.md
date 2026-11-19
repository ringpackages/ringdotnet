---
title: "Paths and the environment"
lead: Programs that work on every computer build paths with Path.Combine, ask the system for special folders and read settings from environment variables. This lesson shows each one.
---

## What you will learn

- building and taking apart paths with the `Path` class,
- relative and absolute paths,
- cleaning a text so that it is a valid file name,
- special folders (documents, temporary files),
- environment variables with a default value,
- how .NET `null` arrives in Ring.

## Why not add strings?

`"reports" + "\" + "2024"` works on your computer only: other systems use `/`, and an extra separator or a missing one breaks the path. `Path.Combine` chooses the separator of the system and never doubles it.

## The program

{{file:docs/tutorials/t60_paths.ring}}

{{output:docs/tutorials/t60_paths.ring}}

## How it works

### Combine and split

`Path.Combine` joins parts: give a list of the parts (`Combine([a, b, c])`) or name them (`Combine([ :path1 = a, :path2 = b ])`). Careful: if a later part is **rooted** (starts with a separator or a drive), the earlier parts are dropped. That is correct behaviour but a classic surprise when the part comes from user input.

`GetFileName`, `GetFileNameWithoutExtension`, `GetExtension`, `GetDirectoryName` and `ChangeExtension` take a path apart or change one piece. Use them instead of searching for dots and slashes yourself: `summary.final.txt` has *two* dots, and only the last one starts the extension.

### Relative and absolute

`data.txt` means "in the current folder" and the current folder changes with how the program is started. `GetFullPath` makes the path complete. Programs that should find their own files build the path from a known place, not from the current folder.

### Valid names

Windows does not allow `\ / : * ? " < > |` in a name. Step 4 replaces each by `_`. (`Path.GetInvalidFileNameChars()` has the list of the current system, but it returns a .NET array of characters, so the tutorial writes the list itself.)

### Special folders

`Environment.GetFolderPath("MyDocuments")` and `Path.GetTempPath()` give folders that exist on every computer; never write `C:\Users\Ali\...` in a program.

### Environment variables

An environment variable is a named setting that lives outside the program (set by the user, a script or a server). `SetEnvironmentVariable` sets one *for this process*; `GetEnvironmentVariable` reads it. A variable that does not exist gives **null**, and .NET `null` arrives in Ring as an **object** (not a text): test it with `isobject(value)`, then use your default. Never print a password or a key that came from a variable.

## What you learned

- `Path.Combine` and the other `Path` methods,
- relative or absolute,
- valid file names,
- `GetFolderPath`, `GetTempPath`,
- environment variables and the null object.

## Exercises

1. Write `uniqueName(cFolder, cName)` that adds `(2)`, `(3)` to the name until the file does not exist.
2. Read a variable `MYAPP_FOLDER` for the data folder, with the documents folder as the default.
3. List the extensions found in a folder with how many files each has.

## Next

[Streams and compression](tut-56-streams.html)
