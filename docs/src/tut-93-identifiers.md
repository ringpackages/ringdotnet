---
title: "Tutorial 93: Identifiers and versions"
lead: Guid gives unique identifiers without a central counter, and Version compares version numbers by number and not as text. This lesson uses both, and shows why "1.10" comes after "1.9".
---

## What you will learn

- `Guid`: a new identifier, its text formats, parsing, `Empty`,
- why Guids can be made anywhere without a clash,
- `Version`: its parts and its comparison,
- sorting a list of versions correctly,
- the version of the running .NET.

## The program

{{file:docs/tutorials/t93_identifiers.ring}}

{{output:docs/tutorials/t93_identifiers.ring}}

## How it works

### Guid

A `Guid` is a 128-bit number. A new one is random, with so many possible values that two programs on two computers never make the same one in practice, so no server or counter has to hand them out. That makes a Guid a good key for a record that is created offline, a name for a temporary file and an id in a message. `NewGuid()` gives a new one; the output of step 1 shows only its shape (36 characters with dashes in fixed places), because the value is different at every run.

`Parse` reads the usual text; `Format("N")` writes 32 digits without dashes, `"B"` writes with braces and `"D"` (the default) with dashes. `Guid.Empty` is all zeros: use it as "no value". `TryParse` answers `[ success, value ]` and does not raise an error for text such as `hello` ([tutorial 81](tut-81-network-tools.html) explains `out` values).

> [!WARNING] A Guid is unique, not secret. Do not use it as a password or a security token; use `RandomNumberGenerator` ([tutorial 78](tut-78-crypto.html)).

### Version

A `Version` has `Major`, `Minor`, `Build` and `Revision`. Its comparison is by **number**, part after part. Compare with the text: `strcmp("1.10.0", "1.9.0")` says that `1.10.0` is *before* `1.9.0`, because the character `1` is smaller than `9`; as `Version` objects, 1.10.0 is **later**, as everybody expects. Whenever a program shows, stores or compares software versions, use `Version`, not the text.

`Version` has no static methods that work without an object, so the program makes any `Version` first (`dnNew("Version", [ :major = 0, :minor = 0 ])`) and uses it as a handle for `Parse`.

### Sorting versions

A `List<Version>` (made with `dnNewGeneric`) sorts itself with `Sort()`, which calls `CompareTo` of every `Version`. The result is *1.2.0, 1.9.0, 1.10.0, 2.0.1, 10.0.0*. Ring's own `sort()` would give the text order.

### The running version

`Environment.Version` is the version of the .NET runtime that runs the program; the program prints only a test, because the number depends on your computer. An assembly has its own version (`Assembly.GetName().Version`), which [tutorial 20](tut-20-reflection.html) can read.

## What you learned

- `Guid`: new, parse, formats, `Empty`, `TryParse`,
- a Guid is unique but not secret,
- `Version` compares numbers, not text,
- sorting versions with a `List<Version>`.

## Exercises

1. Make 100000 Guids and check that all are different (use a `HashSet`).
2. Write `isNewer(cA, cB)` for two version texts.
3. Read the version of the bridge assembly (`RingDotNet.Bridge`) with reflection.
4. Name a file with a Guid and write a function that finds such files again by their name pattern.

## Where to go next

You have reached the end of the tutorials. Keep [Core concepts](concepts.html), the [class reference](api.html) and [Gotchas & limits](gotchas.html) at hand, and read the [applications](gallery-apps.html) for bigger programs.
