---
title: "Collections for many threads"
lead: The classes of System.Collections.Concurrent are safe when several threads use them at the same time. This lesson shows the queue, the stack, the blocking collection and the dictionary, and how closed generic types look when no Ring class exists for them.
---

## What you will learn

- why an ordinary list is not safe for several threads,
- `ConcurrentQueue` and `ConcurrentStack`,
- `BlockingCollection`: `Add`, `Take`, `CompleteAdding`, a bounded size,
- `ConcurrentDictionary`: `TryAdd`, `TryUpdate`, `TryRemove`,
- the `Try...` methods that return a list (`[ success, value ]`),
- generic types made with `dnNewGeneric` and used with `callMethod` and `getProp`.

## Why

If two threads add to one `List` at the same moment, the list can lose an item or break. The concurrent collections do each step (add, remove, "add if missing") as **one indivisible step**. They are the tool for a producer that adds work and a consumer that takes it. The program in this lesson uses one thread, so that its output is always the same; the *calls* are the same as in a program with many threads. (The tutorial [Tasks that wait](tut-83-tasks-waiting.html) shows tasks.)

## The program

{{file:samples/UsingDotNet/tutorials/ch04_concurrent_collections.ring}}

{{output:samples/UsingDotNet/tutorials/ch04_concurrent_collections.ring}}

## How it works

### Generic types

These classes are generic (`ConcurrentQueue<T>`), so a Ring program creates a *closed* type with `dnNewGeneric(type, [type arguments], [constructor values])`. Some closed types have a Ring class and work like any object (the queue of names in step 1); for the others the object is a plain `DotNetObject` and you use `callMethod("Name", [arguments])` and `getProp("Name")` ([Core concepts](concepts.html)). The result is the same, only the way of writing differs. A dictionary item is read with `callMethod("get_Item", [key])`.

### Try methods

`TryDequeue`, `TryPop`, `TryPeek`, `TryRemove` end with an `out` value. In Ring they return a list: `[ success, value ]`; they are called **without** the out argument. When the collection is empty, `success` is 0 and the value is meaningless — check it first.

### Queue and stack

A queue is *first in, first out*; a stack is *last in, first out*: pushes of 1, 2, 3 pop as 3, 2, then 1 is left.

### BlockingCollection

`Take` **waits** when the collection is empty, which is what a consumer wants: it sleeps until a producer adds something. When the producer is finished it calls `CompleteAdding`; after that `IsCompleted` becomes true as soon as the collection is empty, and a loop `while not IsCompleted` ends cleanly. Without `CompleteAdding` the consumer would wait for ever. A **bounded** collection (capacity 2) makes `Add` wait when it is full — the producer cannot run ahead of the consumer; `TryAdd` does not wait and answers true or false.

> [!WARNING] In one thread `Take` on an empty collection that is not completed waits for ever. The loop in the program is safe because `CompleteAdding` was called first and `IsCompleted` is tested before each `Take`.

### ConcurrentDictionary

`TryAdd` adds a key only when it is missing (it answers false otherwise and keeps the old value). `TryUpdate(key, new, expected)` changes a value only if it is still the *expected* one — so two threads that both read 5 cannot both write 6 and lose a count: the second one fails and must read again. `TryRemove` returns `[ success, removed value ]`.

## What you learned

- concurrent collections do each step as one step,
- the Try methods return `[ success, value ]`,
- `BlockingCollection` and `CompleteAdding`,
- bounded collections,
- `dnNewGeneric` with `callMethod` and `getProp`.

## Exercises

1. Count the letters of a text in a `ConcurrentDictionary` with `TryAdd` and `TryUpdate`.
2. Write a function `drain(oQueue)` that returns all the items of a `ConcurrentQueue` as a Ring list.
3. Fill a bounded collection (size 3) with `TryAdd` and print what was refused.
4. Use `ConcurrentBag` (an unordered collection) and compare it with the queue.

## Next

[Enums and flags](tut-65-enums.html)
