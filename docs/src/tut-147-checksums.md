---
title: "A project: check that files did not change"
lead: A list of checksums lets anybody check, later, that no file was changed, damaged or lost. This project writes the list in the format of sha256sum, verifies a folder against it, reports changed, missing and new files, and explains why the list needs a protection of its own.
---

## What you will learn

- a **checksum**: the SHA-256 hash of the bytes of a file,
- a list in the format of the programs `sha256sum` and `shasum`,
- finding all the files of a folder and its subfolders, with relative paths,
- **verify**: *OK*, *CHANGED*, *MISSING* and *NEW*,
- why the list itself needs a checksum that is kept somewhere else.

The tutorial [A project: find duplicate files](tut-31-duplicates.html) used hashes to find files with the same content. Here the hash proves that a file is the **same as it was**.

## The program

{{file:samples/UsingDotNet/tutorials/ch05_checksums.ring}}

{{output:samples/UsingDotNet/tutorials/ch05_checksums.ring}}

> [!NOTE] This program uses a generic function (`dnStatic`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### The checksum

`SHA256.ComputeHash(bytes)` gives 32 bytes, and `Convert.ToHexString` writes them as 64 hexadecimal characters (the tutorial [Bytes as text: Base64 and hexadecimal](tut-138-base64-hex.html)). The program writes them in lower case, as `sha256sum` does. A change of one bit anywhere in the file gives a completely different checksum, and nobody can find another file with the same checksum by chance. The checksum of a file that is read as *bytes* does not depend on the encoding or the line endings: it is the file as it is.

### The list

Each line has the checksum, **two spaces** and the path with `/`, relative to the folder: `4d74…4e74  readme.txt`. This is the format that `sha256sum -c checksums.txt` reads on Linux and macOS, so the list works with other tools too. `relativeFiles` asks for all the files of the folder and its subfolders (`SearchOption = "AllDirectories"`), cuts the folder part off the front of each path, changes `\` to `/`, **sorts** the paths (the order of `GetFiles` is not defined) and leaves out the list file itself.

### Verify

`verify` reads the list back: every line gives a checksum (the first 64 characters) and a path (what comes after the two spaces). For each line the file must exist (else **MISSING**) and have the same checksum (else **CHANGED**). Then the files of the folder that are *not* in the list are **NEW**. The result says how many problems there are in how many files. A folder with no problem is reported with one line.

### Who checks the checksums?

Somebody who changes a file can also change its line in the list, and then everything is *OK*. The list proves that the files are the same as the list says, not that the list is right. So the list needs its own protection: keep the checksum **of the list** somewhere else (written in a message, on a page, in another place), and compare it before you trust the list. The last step shows that editing the list changes its checksum. For a stronger proof use a **signature** (the tutorial [Digital signatures](tut-105-signatures.html)).

> [!NOTE] A checksum finds *damage* and *changes*. It does not hide anything and it does not say who made the change.

## What you learned

- SHA-256 checksums of files,
- the sha256sum list format,
- listing files with relative paths,
- verify with changed, missing and new files,
- protecting the list.

## Exercises

1. Write the list for a folder, copy the folder, and verify the copy.
2. Print the percentage of files that are OK and the total size of the changed files.
3. Make `updateList` that adds the new files to the list and removes the missing ones, and shows what it did.
4. Use `HMACSHA256` with a secret key instead of `SHA256` (the tutorial [Protecting and signing messages](tut-78-crypto.html)) so that only the owner of the key can make a valid list.

## Where to go next

This was the last tutorial of the chapter **Files and streams**. The next chapter is **Processes and performance**: it starts with [Asking the computer](tut-74-system.html). The [Tutorials](tutorials.html) page lists all the chapters, and you can start any of them.
