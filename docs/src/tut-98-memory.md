---
title: "Memory and the garbage collector"
lead: .NET frees the memory of objects that nothing uses any more. This lesson looks at how that works — how much memory the program uses, when a collection happens, weak references for caches, and generations — and at what the bridge adds to the picture.
---

## What you will learn

- what the **garbage collector** (GC) does and why you rarely call it,
- `GC.GetTotalMemory`, `GC.Collect`, `GC.CollectionCount`,
- `WeakReference`: a pointer that does not keep an object alive,
- **generations** 0, 1 and 2,
- handles: how Ring frees .NET objects for you (`dnFlush()` and `release()`).

## The program

{{file:samples/UsingDotNet/tutorials/ch06_memory.ring}}

{{output:samples/UsingDotNet/tutorials/ch06_memory.ring}}

## How it works

### The garbage collector

In .NET you never free an object by hand. The GC finds the objects that no variable can reach any more and frees them. You do not choose the moment: it runs when memory gets short, or when the runtime decides. `GC.Collect()` forces a collection, and `GC.GetTotalMemory(True)` collects first and then returns the number of bytes in use. Both are useful for **learning and testing**; in a real program calling `Collect` is almost always wrong, because the GC knows better than you when to run (and a forced collection can slow the program).

The numbers (bytes in use, how many collections) differ on every computer and every run, so the program prints only statements that are always true, such as *"it grew by at least 9 MB"*.

### What the bridge adds

When a .NET method returns an object to Ring, the bridge keeps a **handle** to it in a table, because Ring only holds a number. A reference in a table keeps the object alive, so the GC could not free it. That is why every Ring object that owns a handle also owns a small **guard**: when Ring frees the object (the last variable that holds it is changed or goes away), the guard puts the handle on a list, and the list is sent to .NET in one request. After that the GC is free to take the memory. You do not have to do anything: a loop that makes 100 000 objects and drops each of them stays small.

Two things remain your job:

1. **`Dispose()`** (the tutorial [Releasing resources](tut-71-dispose.html)) frees *resources* such as files and connections at once. Dropping the object frees its memory, but only some time later.
2. **Timing.** Two things delay the release a little: Ring frees an object some moments after the last variable that held it is gone, and the handles are released in groups (the next .NET call does it when 32 are waiting). So the memory of one big object is not free at the moment you drop it. When it must go now, or before you look at the memory (`GC.GetTotalMemory`), write `callgc()` (Ring collects its garbage; it works for the function that calls it) and then `dnFlush()` (the waiting handles are released). `release()` is the other way: it releases one object immediately, and after it the object cannot be used any more.

Step 2 of the program shows the effect: a list with room for 10 million bytes makes the memory grow by 10 MB, and after the variable is set to `NULL`, `callgc()`, `dnFlush()` and a collection the memory is smaller again.

### Weak references

A normal variable keeps its object alive. A `WeakReference` points to an object **without** keeping it alive: `IsAlive` says whether the object is still there, and when the GC frees it, the answer becomes false. This is the tool for **caches**: keep the result of a slow calculation as long as memory allows, and calculate it again when it is gone. In step 4 the object is alive while Ring holds it; after the variable is set to `NULL`, `callgc()`, `dnFlush()` and a collection it is gone. (Collecting twice, with `WaitForPendingFinalizers` in between, makes the result sure in a small test; a real cache must always handle both answers.)

### Generations

The GC sorts objects by age, because most objects die young. Generation **0** holds new objects and is collected often and fast. An object that survives a collection moves to generation **1**, and later to generation **2**, which is collected rarely. `GC.GetGeneration(object)` tells the generation: a new object is in 0 and after one collection it is in 1, as step 5 shows. Big objects (more than about 85 000 bytes) go to a separate heap and are in generation 2 at once.

> [!NOTE] `GC.GetTotalMemory` counts the memory of **.NET** objects only. The memory of the Ring program itself (its lists and texts) is separate and is not in the number.

## What you learned

- the GC frees unreachable objects; you do not choose when,
- `GetTotalMemory`, `Collect` and `CollectionCount` for learning and tests,
- Ring frees the handle of a dropped object for you; `Dispose()` frees resources, `callgc()` with `dnFlush()`, or `release()`, make it immediate,
- `WeakReference` for caches,
- generations: young objects are collected often.

## Exercises

1. Make 100 000 `StringBuilder` objects with a capacity of 4000 in a loop and look at `GC.GetTotalMemory` after the loop, with and without `callgc()` and `dnFlush()`.
2. Build a small cache of results with `WeakReference` objects in a Ring list.
3. Find out how many collections of generation 0, 1 and 2 happened in your program (`CollectionCount`).
4. Read about `GCSettings.IsServerGC` and `GCSettings.LatencyMode` and print them.

## Next

[The Windows Registry](tut-118-registry.html)
