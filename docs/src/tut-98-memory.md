---
title: "Tutorial 98: Memory and the garbage collector"
lead: .NET frees the memory of objects that nothing uses any more. This lesson looks at how that works — how much memory the program uses, when a collection happens, weak references for caches, and generations — and at what the bridge adds to the picture.
---

## What you will learn

- what the **garbage collector** (GC) does and why you rarely call it,
- `GC.GetTotalMemory`, `GC.Collect`, `GC.CollectionCount`,
- `WeakReference`: a pointer that does not keep an object alive,
- **generations** 0, 1 and 2,
- `release()`: letting the bridge forget an object.

## The program

{{file:docs/tutorials/t98_memory.ring}}

{{output:docs/tutorials/t98_memory.ring}}

## How it works

### The garbage collector

In .NET you never free an object by hand. The GC finds the objects that no variable can reach any more and frees them. You do not choose the moment: it runs when memory gets short, or when the runtime decides. `GC.Collect()` forces a collection, and `GC.GetTotalMemory(True)` collects first and then returns the number of bytes in use. Both are useful for **learning and testing**; in a real program calling `Collect` is almost always wrong, because the GC knows better than you when to run (and a forced collection can slow the program).

The numbers (bytes in use, how many collections) differ on every computer and every run, so the program prints only statements that are always true, such as *"it grew by at least 9 MB"*.

### What the bridge adds

When a .NET method returns an object to Ring, the bridge keeps a **handle** to it in a table. A reference in a table keeps the object alive, so the GC cannot free it. Ring objects that hold such a handle do not free it automatically. When you are done with an object that is big or that holds a resource (a stream, a bitmap, a connection), do two things:

1. `Dispose()` it if its class has that method ([tutorial 71](tut-71-dispose.html)): this frees *resources* such as files and connections at once.
2. `release()` it (every wrapped object has this method): this removes the handle from the table, and after that the GC is free to take the memory. After `release()` the object cannot be used any more.

Step 2 of the program shows the effect: a list with room for 10 million bytes makes the memory grow by 10 MB, and after `release()` and a collection the memory is smaller again. A program that creates millions of short-lived objects in a loop should `release()` them, or the table of handles grows.

### Weak references

A normal variable keeps its object alive. A `WeakReference` points to an object **without** keeping it alive: `IsAlive` says whether the object is still there, and when the GC frees it, the answer becomes false. This is the tool for **caches**: keep the result of a slow calculation as long as memory allows, and calculate it again when it is gone. In step 4 the object is alive while Ring holds it; after `release()` and a collection it is gone. (Collecting twice, with `WaitForPendingFinalizers` in between, makes the result sure in a small test; a real cache must always handle both answers.)

### Generations

The GC sorts objects by age, because most objects die young. Generation **0** holds new objects and is collected often and fast. An object that survives a collection moves to generation **1**, and later to generation **2**, which is collected rarely. `GC.GetGeneration(object)` tells the generation: a new object is in 0 and after one collection it is in 1, as step 5 shows. Big objects (more than about 85 000 bytes) go to a separate heap and are in generation 2 at once.

> [!NOTE] `GC.GetTotalMemory` counts the memory of **.NET** objects only. The memory of the Ring program itself (its lists and texts) is separate and is not in the number.

## What you learned

- the GC frees unreachable objects; you do not choose when,
- `GetTotalMemory`, `Collect` and `CollectionCount` for learning and tests,
- the bridge keeps handles: `Dispose()` frees resources, `release()` lets go of the object,
- `WeakReference` for caches,
- generations: young objects are collected often.

## Exercises

1. Make 100 000 `StringBuilder` objects in a loop with and without `release()` and look at `GC.GetTotalMemory`.
2. Build a small cache of results with `WeakReference` objects in a Ring list.
3. Find out how many collections of generation 0, 1 and 2 happened in your program (`CollectionCount`).
4. Read about `GCSettings.IsServerGC` and `GCSettings.LatencyMode` and print them.

## Next

[Tutorial 99: Vectors and matrices](tut-99-vectors.html)
