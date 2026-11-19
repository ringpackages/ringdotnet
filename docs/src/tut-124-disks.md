---
title: "Disks and free space"
lead: Before a program writes a big file it can ask how much room the disk has. This lesson uses DriveInfo to list the drives, read their sizes, check that a file will fit, and write a size in a form that people read easily.
---

## What you will learn

- `GetDrives()` and the drive of a path,
- `TotalSize`, `TotalFreeSpace` and **`AvailableFreeSpace`**,
- `IsReady` and `DriveType`,
- a check *will it fit?* before a big write,
- a function that shows bytes as KB, MB, GB and TB,
- why this program prints yes and no for facts about the computer.

The tutorial [Paths and the environment](tut-59-paths.html) gave the special folders and the tutorial [File information](tut-123-file-info.html) the size of one file. This lesson is about the disk that holds them.

## The program

{{file:samples/UsingDotNet/tutorials/ch05_disks.ring}}

{{output:samples/UsingDotNet/tutorials/ch05_disks.ring}}

## How it works

### Sizes for people

`formatSize` divides by 1024 until the number is smaller than 1024 and writes it with one decimal and a unit: `1610612736` bytes is `1.5 GB`. It is a good function to keep in a library of your own: every program that shows a file size or a disk size needs it. (Disk makers count 1000 per step and operating systems 1024; this program uses 1024.)

### The drives

`GetDrives()` returns one `DriveInfo` for each drive: the letters of Windows (`C:\`), or the mounted file systems of Linux and macOS. It is a static method, called through any object of the class (the program makes one for the drive of the temporary folder). A drive that is not ready (an empty card reader) answers `false` to `IsReady`, and reading its sizes raises an error, so check `IsReady` first.

### The drive of a folder

`Path.GetPathRoot(path)` gives the root of a path (`C:\` on Windows, `/` on Linux) and `dnNew("DriveInfo",[ root ])` describes that drive.

### Three sizes

`TotalSize` is the capacity, `TotalFreeSpace` all the free room, and `AvailableFreeSpace` the free room **for the current user**: a disk quota can make it smaller than the free space. Use `AvailableFreeSpace` when the question is *will it fit?*. The sizes are long whole numbers: a Ring number is a double, which keeps every digit up to about nine quadrillion (9 PB), enough for any disk.

### Will it fit?

`fits(oDrive, nBytes)` compares the size with the available space and says how much is missing when it does not fit. A program that makes a backup, a download or an export calls it first, so the user gets a clear message *before* the work and not an error in the middle of it.

### Facts of the computer

The names, the sizes and the formats of drives are different on each computer, so the program shows only what is true everywhere: there are drives, the free space is smaller than the capacity, a percentage is between 0 and 100. Do the same in tests of your own programs: test the *relation*, not the number.

## What you learned

- listing drives and finding the drive of a path,
- the three sizes and `IsReady`,
- checking the space before writing,
- a size in KB, MB, GB and TB.

## Exercises

1. Print a table of the ready drives with the type, the size and the free space in a readable form.
2. Add a bar of ten characters that shows how full each drive is.
3. Write `waitForSpace(oDrive, nBytes, nSeconds)` that checks again each second.
4. Use `formatSize` for the sizes of the files in the tutorial [File information](tut-123-file-info.html).

## Next

[Watching a folder](tut-122-watch-folder.html)
