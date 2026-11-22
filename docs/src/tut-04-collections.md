---
title: "Collections and LINQ"
lead: Lists, dictionaries, sets, queues and stacks, how to sort them, and how to ask questions about them with LINQ.
---

## What you will learn

- the five common collections and when to use each,
- how to get a collection's items back into a Ring list,
- LINQ: filter, sort and summarize with a few calls.

## Which collection?

| Collection | Use it when... | Ring class |
|---|---|---|
| **List** | you need items in order, and to find them by position | `StringList`, `NumberList`, `ObjectList` |
| **Dictionary** | you look items up by a key (a name, an id) | `StringDictionary`, `NumberDictionary`, `ObjectDictionary` |
| **Set** | each value may appear only once | `StringSet` |
| **Queue** | first in, first out (a line of customers) | `StringQueue` |
| **Stack** | last in, first out (undo) | `StringStack` |

Ring lists are flexible and fine for most programs. Use .NET collections when you need their special behavior (a set, a queue), speed with big data, or when a .NET method asks for one.

## The program

{{file:samples/UsingDotNet/tutorials/ch01_collections.ring}}

{{output:samples/UsingDotNet/tutorials/ch01_collections.ring}}

## How it works

### A list

`Add` adds, `Count` counts, `Item(1)` reads by position (the first item is position `0`), `Sort(NULL)` sorts in place, `Contains` and `IndexOf` search. `toList()` copies the items into a Ring list, so you can use `for ... in`.

> [!NOTE] `Sort(NULL)`: `Sort` has several versions (with a comparer, with a range...). `NULL` means "the version without parameters".

### A dictionary

`SetItem("Ann",31)` stores a value under a key; `Item("Ann")` reads it. `TryGetValue("Cy")` asks *without failing* when the key is missing, and returns the list `[found, value]`.

### A set

Adding `"red"` twice leaves one `"red"`. Sets also have `Union`, `Intersect` and `Except` for combining.

### Queue and stack

A queue gives back the **first** item added (`Enqueue`, `Dequeue`); a stack gives back the **last** (`Push`, `Pop`).

### LINQ

*LINQ* means *language integrated query*: ask a collection a question. In RingDotNet, `dnQuery(aList)` wraps any Ring list or .NET collection. Each step is a call; the **code of a question is Ring code in a text**: it reads the item as `aDotNetArgs[1]` and writes its answer into `xDotNetResult`.

```ring
aBig = dnQuery(aSales).Where("xDotNetResult = aDotNetArgs[1] >= 100").OrderByDescending("xDotNetResult = aDotNetArgs[1]").ToList()
```

Read it as: from `aSales`, *where* the item is at least 100, *order by* the item, descending, then give a Ring list. Other questions: `Count()`, `Sum("")`, `Max("")`, `Average("")`, `Any(code)`, `Select(code)`, `Take(n)`, `Skip(n)`, `Distinct()`. An empty `""` means "the item itself". The complete list is in [Collections & LINQ](collections-linq.html).

## What you learned

- choose the collection by the question you ask of it,
- `toList()` brings a .NET collection to Ring,
- `TryGetValue` and `NULL` for methods with several versions,
- LINQ answers questions in one chain.

## Exercises

1. Put the numbers `5, 3, 8, 3, 1` into a `NumberList`, sort it, and print it.
2. Count how many times each word appears in a sentence with a `NumberDictionary`.
3. Use a `StringStack` to reverse the letters of a word.
4. With LINQ: from `[3,8,12,5,20]` get the numbers above 4, doubled (`Select`), and their sum.

## Next

[Files and folders](tut-05-files.html)
