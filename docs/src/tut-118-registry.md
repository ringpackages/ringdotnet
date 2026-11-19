---
title: "The Windows Registry"
lead: Windows and many programs keep their settings in the Registry, a tree of keys that hold values. This lesson reads and writes values of every common type in HKEY_CURRENT_USER, lists values and sub-keys, and cleans up after itself. It runs on Windows only.
---

## What you will learn

- the Registry as a **tree of keys** with **values**,
- `HKEY_CURRENT_USER` and why it is the safe place to write,
- `CreateSubKey`, `OpenSubKey`, `SetValue`, `GetValue`,
- the value kinds: `String`, `DWord`, `QWord`, `MultiString`, `ExpandString`, `Binary`,
- listing values and sub-keys, deleting them,
- the rules for a program that writes to the Registry.

The tutorial [Settings](tut-32-settings.html) saved settings in a file. On Windows, programs often use the Registry for the same job, and a program that works *with* Windows (file types, start-up, system settings) must.

## The program

{{file:docs/tutorials/t118_registry.ring}}

{{output:docs/tutorials/t118_registry.ring}}

## How it works

### Keys and values

The Registry looks like a file system: **keys** are the folders, and each key holds **values**, a name with data and a type. The big branches are *hives*: `HKEY_CURRENT_USER` (HKCU) belongs to the user who is logged in, `HKEY_LOCAL_MACHINE` (HKLM) is for the whole computer, `HKEY_CLASSES_ROOT` holds the file types. The program writes only in HKCU, under its own key `Software\RingDotNetTutorial118`, because that needs **no administrator rights** and does not affect other users. HKLM needs an administrator to write.

`Registry.CurrentUser` is a static property of the class, read with `dnType("Microsoft.Win32.Registry").getProp("CurrentUser")`. `CreateSubKey(path)` makes a key (or opens it when it exists) for writing, `OpenSubKey(path)` opens an existing one for reading (and answers null when it does not exist), and `Close()` lets go of it. Paths use the backslash: in a Ring text `"Software\RingDotNetTutorial118"` is written as it is.

### The kinds of value

`SetValue(name, data, kind)` writes a value, and the **kind** says how Windows stores it:

| Kind | Data | Use |
|---|---|---|
| `String` | text | names, paths |
| `DWord` | a 32-bit whole number | sizes, flags, counters |
| `QWord` | a 64-bit whole number | big numbers (5 000 000 000 does not fit 32 bits) |
| `MultiString` | a list of texts | a list of recent files |
| `ExpandString` | text with `%NAME%` variables | a path such as `%USERPROFILE%\Data`: `GetValue` gives the text with the variable already replaced |
| `Binary` | bytes | pictures, encrypted data |

A `MultiString` needs a real `string[]`, so the program builds one from a `List<string>` with `ToArray()` (`stringArray`). A `Binary` value needs a real `byte[]` **object**; in this package a byte array that comes back from .NET is turned into a Ring text, and a Ring text goes back as a string, so a Ring program cannot hold the object to pass it. This lesson therefore does not write `Binary` values; store bytes as Base64 text in a `String` value (the tutorial [URLs and encodings](tut-64-urls.html)).

### Reading

`GetValue(name, default)` gives the data in the form that fits its kind — a Ring number for `DWord` and `QWord`, a text for `String`, a list (`toList()`) for `MultiString` — or the default when the name does not exist. `GetValueKind(name)` tells the kind, `GetValueNames()` lists the names and `GetSubKeyNames()` lists the sub-keys, and `ValueCount` counts the values. The program sorts the names, because the order of the Registry is not defined. Always give a default: a program that reads a value that is not there yet (the first run, a different version) must still work.

### Cleaning up

`DeleteValue(name)` removes one value, `DeleteSubKeyTree(path)` the key with everything inside it. The second argument `False` means *no error when the key is missing*, which the program uses to remove a key left by an earlier run. **Always clean up what a test or a sample wrote**: the Registry has no recycle bin, and old keys stay for ever.

## Rules for programs that use the Registry

- Write only under `HKCU\Software\<your company>\<your program>`. Never change keys of other programs or of Windows.
- Do not store **secrets** in plain text: any program of the same user can read HKCU. Use the Data Protection API (the tutorial [Protecting data](tut-113-data-protection.html)) or the Windows credential store.
- Read with a **default** and handle an invalid value; users and other tools edit the Registry.
- **Do not put data there that is big** (a few kilobytes is fine, megabytes are not): use a file (the tutorial [Files and folders](tut-05-files.html)).
- Prefer a **settings file** when the program must also run on Linux or macOS, or when you want the user to copy the settings to another computer (the tutorial [Configuration](tut-111-configuration.html)).
- Programs that start with Windows use the key `Software\Microsoft\Windows\CurrentVersion\Run`: add an entry only when the user asked for it, and remove it when the program is uninstalled.

> [!WARNING] Changing the Registry can break programs and sometimes Windows. Use only your own keys, check each path before you delete, and never run code from the internet that edits the Registry.

## What you learned

- the Registry is a tree of keys and values; HKCU is yours,
- `CreateSubKey`, `OpenSubKey`, `SetValue`, `GetValue`, `GetValueKind`,
- the value kinds and how they come back in Ring,
- listing and deleting, and cleaning up,
- the rules for a program that writes there.

## Exercises

1. Write a small class `Settings` with `load()` and `save()` that keeps a list of values (name, value) in a key.
2. Read the version of Windows from `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion` (`ProductName`, `CurrentBuild`); it is read-only for you.
3. Count how many sub-keys `HKCU\Software` has.
4. Write the position and size of a window of the tutorial [Your first window](tut-11-first-window.html) when it closes and restore them at the next start.

## Where to go next

This was the last tutorial of the chapter **Processes and performance**. The next chapter is **Networking and the web**: it starts with [Network tools](tut-81-network-tools.html). The [Tutorials](tutorials.html) page lists all the chapters, and you can start any of them.
