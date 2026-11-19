---
title: "Tutorial 112: File patterns (globbing)"
lead: Patterns such as `**/*.ring` describe sets of files, the way a .gitignore file or a build tool does. This lesson uses the Matcher of .NET with include and exclude rules, finds files in a folder tree, and tests a plain list of paths without a disk.
---

## What you will learn

- the **glob** wildcards `*`, `**` and `?`,
- `Matcher`: `AddInclude` and `AddExclude`,
- finding files in a folder (`GetResultsInFullPath`),
- `Match` on a list of paths that are not on a disk,
- the case rule of a matcher,
- extension methods and `dnStatic`.

[Tutorial 5](tut-05-files.html) listed the files of a folder and [tutorial 29](tut-29-regex.html) used regular expressions. A **glob** is simpler than a regular expression and made for paths, so it is the language of file selection: build files, ignore files, backup rules, "which files changed".

> [!NOTE] `Microsoft.Extensions.FileSystemGlobbing` is part of the ASP.NET Core runtime, so the program has `"RingDotNet.Web"` in its `using { }` ([Getting started](getting-started.html)).

## The program

{{file:docs/tutorials/t112_globbing.ring}}

{{output:docs/tutorials/t112_globbing.ring}}

## How it works

### The wildcards

| Pattern | Matches |
|---|---|
| `*.ring` | any file name that ends with `.ring`, in **one** folder |
| `?` | exactly one character: `file?.txt` is `file1.txt` and `fileA.txt` |
| `**` | any number of folders, **also none**: `**/*.ring` is `a.ring`, `src/a.ring` and `src/util/a.ring` |
| `src/*.ring` | files in `src`, **not** in its sub-folders |
| `docs/**/*.md` | every `.md` file below `docs`, at any depth |

The separator is always `/`, on every system.

### Include and exclude

A `Matcher` collects **include** rules (`AddInclude`) and **exclude** rules (`AddExclude`). A file is in the result when at least one include rule matches it and **no** exclude rule does. In step 2, `**/*.ring` finds four files, then `tests/**` removes everything in `tests` and `**/old_*` removes every file whose name starts with `old_`, leaving two. Several include rules are joined (step 3: the code of one folder and all the documents).

### Files on a disk

`GetResultsInFullPath(matcher, folder)` walks the folder and gives the full paths of the matching files. The order is the order of the file system, which is not the same on every system, so the program sorts the names before printing. `GetResultsInFullPath` and `Match` are **extension methods** of `MatcherExtensions`, so they are called with `dnStatic(type, method, [arguments])` ([tutorial 109](tut-109-memory-cache.html)); `AddInclude` and `AddExclude` are real methods of the object. The class is made with `dnNew(type, [])` because the namespace has no generated Ring classes.

### A list of names

`Match(root, files)` applies the patterns to a **list of paths** that need not exist: the names inside an archive ([tutorial 108](tut-108-zip-in-memory.html)), the files that a version control system reports as changed, the lines of a file. It needs a root (use `"."`, an empty text is read as a missing value) and a .NET collection of texts: the program makes a `List<string>` (`stringList`), because a plain Ring list is not accepted for an `IEnumerable<string>`. The result has `HasMatches` and `Files`, each file with its `Path`.

### Case

By default a matcher **ignores case**: `*.ring` also finds `B.RING`. The constructor takes a `StringComparison`; with `Ordinal`, `**/*.RING` matches only names written in capitals (step 5). Use `Ordinal` for file systems that care about case.

## What you learned

- `*`, `**` and `?`, and why `**` also matches no folder,
- include rules and exclude rules,
- `GetResultsInFullPath` for folders, `Match` for lists of names,
- sorted output for a stable result,
- the `"."` root and the `List<string>` input.

## Exercises

1. Write `findFiles(cFolder, aInclude, aExclude)` that returns the relative names as a Ring list.
2. Read the patterns from a settings file ([tutorial 111](tut-111-configuration.html)) and use them for a backup program ([tutorial 46](tut-46-backup.html)).
3. Make a matcher that finds the images (`**/*.png`, `**/*.jpg`) but not those in a folder `thumbs`.
4. Test your patterns on a list of names with `Match` before you run them on the disk.

## Next

[Tutorial 21: A log analyzer](tut-21-log-analyzer.html)
