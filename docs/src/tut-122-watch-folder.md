---
title: "Watching a folder"
lead: A program can wait until something happens in a folder — a file is created, changed, renamed or deleted — instead of looking at the folder again and again. This lesson uses FileSystemWatcher, with a second copy of the program that makes the changes.
---

## What you will learn

- what a `FileSystemWatcher` reports: **Created**, **Changed**, **Renamed** and **Deleted**,
- the folder, the **filter** (`*.txt`) and the subfolders,
- `WaitForChanged` with a time limit,
- why a change that happens while the program is not waiting is not reported,
- a child program that makes the changes (the pattern of the tutorial [Two programs talking](tut-79-processes-talk.html)).

Programs that watch folders are everywhere: a build tool that starts when a file is saved, an editor that notices that a file was changed by another program, a program that processes the files that other programs drop into an *inbox* folder.

## The program

{{file:docs/tutorials/t122_watch_folder.ring}}

{{output:docs/tutorials/t122_watch_folder.ring}}

## How it works

### Two programs

A watcher has nothing to report if nobody changes the folder, and the program that waits cannot change it at the same moment. So the program starts a second copy of itself with `--child` and the name of the folder. The child waits a second, then creates `note.txt`, appends to it, renames it to `done.txt`, writes a file that the filter does not match, and deletes `done.txt`, with a pause between the steps. The parent only watches.

### The watcher

`dnNew("FileSystemWatcher",[ :path = cFolder, :filter = "*.txt" ])` watches one folder. The filter is a file name pattern: only the names that match it are reported (it has `*` and `?`; the tutorial [File patterns (globbing)](tut-112-globbing.html) shows richer patterns for your own code). `IncludeSubdirectories = True` watches the folders below as well. Each change is a **kind** (`Created`, `Changed`, `Renamed`, `Deleted`) and the name of the file; a rename also has the old name.

### Waiting for a change

`WaitForChanged([ :changeType = "All", :timeout = 4000 ])` waits for the next change and returns an object with `ChangeType`, `Name`, `OldName` and `TimedOut`. After four seconds without a change `TimedOut` is true and the loop ends. The `ignored.log` file does not match the filter, so the parent sees nothing for it.

> [!NOTE] A watcher reports only the changes that happen **while the program waits for them**. Between two calls of `WaitForChanged` a change is not reported, so this style fits a loop that does nothing else, and tests. A program with a window or a server can use the *events* of the watcher (`Created`, `Changed`, `Deleted`, `Renamed`), which .NET raises on its own threads; Ring code runs on the Ring thread only, so such a program uses a timer and looks at the folder (the tutorial [Timers and progress](tut-34-timers.html)).

### One write, several events

Saving a file can raise more than one `Changed` event (the content and the time are written separately). The program prints a line only when it differs from the last one. Real programs do the same, and often wait a little (a *debounce*) so that a big save counts as one change.

### Clean up

`Dispose()` ends the watching. The program deletes the folder it made with `Directory.Delete([ :path = ..., :recursive = True ])`.

## What you learned

- a watcher reports created, changed, renamed and deleted files,
- the filter and the subfolders,
- `WaitForChanged` and its time limit,
- one change can raise several events,
- a child program is a good way to test a watcher.

## Exercises

1. Remove the filter (`*`) and look at the extra event for `ignored.log`.
2. Set `IncludeSubdirectories = True` and make the child write into a subfolder.
3. Make a loop that copies each new `.txt` file of an inbox folder to an `archive` folder.
4. Count the `Changed` events for one `AppendAllText` call.

## Next

[A project: analyze a log file](tut-21-log-analyzer.html)
