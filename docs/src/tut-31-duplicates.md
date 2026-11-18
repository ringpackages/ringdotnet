---
title: "Tutorial 31: A project: find duplicate files"
lead: Which files in this folder are copies of each other? A hash of the content answers it, even when the names differ. A project that combines folders, hashing and dictionaries.
---

## What you will learn

- recursive folder listing,
- content hashes as fingerprints,
- grouping with a dictionary,
- a report that is useful,
- cleaning up after a demo.

## The idea

Two files are the same when their **content** is the same, whatever their names. Comparing every pair of files byte by byte is slow. A **hash** (SHA-256) is a short fingerprint of the content: the same content always gives the same hash and different content (practically) never does. So:

1. compute the hash of every file,
2. put the files in a dictionary **keyed by the hash**,
3. every key with more than one file is a set of duplicates.

## The program

{{file:docs/tutorials/t31_duplicates.ring}}

{{output:docs/tutorials/t31_duplicates.ring}}

## How it works

### Step 1: make test data

The program creates its own folder with files: three with the same text (one in a subfolder, one with a different name), two with the same other text, and one unique file. A demo that makes its own data runs anywhere and can be checked: the answer is known.

### Step 2: list recursively

`Directory.GetFiles_3(folder, "*.txt", "AllDirectories")` returns the files of the folder and of every subfolder. `"TopDirectoryOnly"` would skip the subfolders. The third parameter is an enum, written as a text.

### Step 3: hash and group

`hashOf(cFile)` reads the bytes (`File.ReadAllBytes`), hashes them (`SHA256.HashData`) and writes the hash as hexadecimal text. A `StringDictionary` maps *hash → paths* with the paths joined by `|`: if the hash is known, append the path, else start a new entry. `TryGetValue` tells which.

### Step 4: report

For each hash with more than one path the program prints the copies and sums the **wasted space** — the size times the number of *extra* copies. Sorting the paths makes the report stable.

### Cheaper first

A real tool avoids hashing every file: files with different **sizes** cannot be equal, so group by size first and hash only the groups with several files. That is exercise 1.

## What you learned

- a hash identifies content,
- a dictionary groups by key,
- recursive listing,
- tests with data that you made yourself.

## Exercises

1. Group by file size first; hash only the files whose size occurs more than once.
2. Also compare the first 1 MB only for a quick check of very big files.
3. Add an option to *move* duplicates to a `duplicates` folder instead of just reporting.
4. Make it a window: a folder box, a *Scan* button, and the result in a `TreeView` ([tutorial 23](tut-23-layout.html)).

## Next

[Tutorial 32: Settings](tut-32-settings.html).
