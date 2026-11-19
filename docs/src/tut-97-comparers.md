---
title: "Comparing text"
lead: Is "apple" equal to "APPLE"? Which comes first, "Zebra" or "apple"? The answers depend on how you compare. This lesson shows ordinal and culture-aware comparison, comparers for sorting, dictionaries and sets that ignore case, and the famous Turkish "i".
---

## What you will learn

- **ordinal** comparison (the code of each character) and **culture-aware** comparison (the rules of a language),
- ignoring case,
- `String.Compare` and what its result means,
- `StringComparer`: a comparer that you give to `Sort`, a dictionary or a set,
- why `"TITLE".ToLower()` can be wrong in Turkish.

The tutorial [Cultures](tut-33-cultures.html) formatted numbers and dates for a culture, and the tutorial [Unicode and encodings](tut-52-unicode.html) looked at characters. This lesson is about *comparing* text, which every search box, sort order and dictionary of names needs.

## The program

{{file:samples/UsingDotNet/tutorials/ch02_comparers.ring}}

{{output:samples/UsingDotNet/tutorials/ch02_comparers.ring}}

## How it works

### Ordinal and culture

**Ordinal** comparison looks at the number (code) of every character. It is exact and fast and gives the same answer on every computer, so it is the right choice for *technical* text: file names, identifiers, keys, protocols. **Culture** comparison follows the rules of a language: letters with accents are close to their base letters and `a` and `A` are neighbours. Use it for text that people read, such as a sorted list of names on the screen. The comparison type is an enum, so it is a text: `"Ordinal"`, `"OrdinalIgnoreCase"`, `"InvariantCulture"`, `"InvariantCultureIgnoreCase"`, `"CurrentCulture"`.

### The result of Compare

`String.Compare` returns a number: **negative** when the first text comes first, **zero** when they are equal, **positive** when it comes second. Test only the sign (`< 0`, `= 0`, `> 0`) — the size is not defined. The method has many forms, so it takes named values (`:strA`, `:strB`, `:comparisonType`).

### Sorting with a comparer

A `StringComparer` object is a comparer: `Sort(comparer)` of a `List` uses it. In the **ordinal** order all capital letters come before all small ones (*Apple Banana Cherry apple banana cherry*), because the code of `Z` is smaller than the code of `a`. The **culture** order is the one that people expect (*apple Apple banana Banana ...*). With `OrdinalIgnoreCase`, `apple` and `Apple` are equal, so their order is not defined.

> [!NOTE] The culture order comes from the operating system or the ICU library. It can differ a little between Windows, Linux and macOS, so a test or a file format must not depend on it.

### Dictionaries and sets

The constructor of a `Dictionary` or a `SortedSet` can take a comparer, and then *all* its lookups use it: with `OrdinalIgnoreCase` the key `ANN` finds `Ann`, and `Apple`, `apple` and `APPLE` count as one word in the set (the first one stays). This is the usual way to make a case-insensitive lookup table; it is much better than changing the case of every key by hand.

### The Turkish i

In Turkish there are two letters `i`: the one with a dot and the one without. The capital of `i` is `İ` (with a dot) and the small letter of `I` is `ı`. So `"title".ToUpper()` with the Turkish culture gives `TİTLE`, which is **not equal** to `TITLE`. A program that decides things by changing the case of text (a command name, a file extension) breaks on a Turkish computer if it uses the culture of the user. The rule: for technical comparison use **ordinal** comparison, or change the case with the **invariant** culture.

## What you learned

- ordinal for technical text, culture for text that people read,
- the sign of the result of `Compare`,
- `StringComparer` for sorting, dictionaries and sets,
- case-insensitive lookups with `OrdinalIgnoreCase`,
- the Turkish `i` and why the invariant culture is safer.

## Exercises

1. Sort the file names of a folder (the tutorial [Files and folders](tut-05-files.html)) in ordinal order and in culture order and look at the difference.
2. Build a case-insensitive `Dictionary` of settings (the tutorial [Settings](tut-32-settings.html)).
3. Compare `"Straße"` and `"STRASSE"` with the four comparison types.
4. Write `sameName(a, b)` for user names that must ignore case and accents (look at `CompareOptions`).

## Next

[Text readers and writers](tut-104-text-readers-writers.html)
