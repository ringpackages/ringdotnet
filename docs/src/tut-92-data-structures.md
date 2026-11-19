---
title: "More data structures"
lead: Lists and dictionaries are not always the best tool. This lesson shows five collections of .NET that keep order for you or save memory — a priority queue, a sorted set, a sorted dictionary, a linked list and a bit array — and when each one is the right choice.
---

## What you will learn

- `PriorityQueue`: always the most urgent item first,
- `SortedSet`: no duplicates and always sorted,
- `SortedDictionary`: keys in order,
- `LinkedList`: cheap changes at both ends and next to a node,
- `BitArray`: a million yes/no values in 125 KB, with logic operations,
- the Ring words that need `callMethod` (`Get`, `And`, `Or`).

The tutorial [Collections and LINQ](tut-04-collections.html) used `List` and `Dictionary`, and the tutorial [Collections for many threads](tut-89-concurrent-collections.html) the collections for many threads.

## The program

{{file:samples/UsingDotNet/tutorials/ch04_data_structures.ring}}

{{output:samples/UsingDotNet/tutorials/ch04_data_structures.ring}}

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnStatic`, `dnNewGeneric`, `callMethod`, `getProp`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### Closed generic types

All of them but `BitArray` are generic: `dnNewGeneric(type, [type arguments], [constructor values])` makes a closed type such as `PriorityQueue<string, int>`. Most have no Ring class, so those objects are used in the plain style: `callMethod("Add", [value])`, `getProp("Count")`, and `toList()` to copy a collection into a Ring list ([Core concepts](concepts.html)).

### PriorityQueue

`Enqueue(element, priority)` adds; `Dequeue()` returns the element with the **smallest priority number**, whatever the order of adding. It is the right tool for a to-do list by urgency, for events by time, and for algorithms such as the shortest path. It does not keep the whole list sorted (it only knows the next item), so it is faster than sorting again and again.

### SortedSet

A set holds each value once: adding 42 twice keeps one 42. A `SortedSet` also keeps the values in order, so `Min`, `Max` and a loop come for free, and `Contains` is fast even for a million items.

### SortedDictionary

Same as a `Dictionary`, with the keys in order. The loop over `Keys` gives *apple banana fig pear*. Use it when the order matters for display; use the plain `Dictionary` when only the speed of the lookup matters.

### LinkedList

Each item is a **node** that knows its neighbours (`Next`, `Previous`). `AddFirst`, `AddLast` and `AddAfter(node, value)` do not move other items, and `Remove` of a known node is quick. The price: no access by number. Take it when you add or remove in the middle of a long list all the time, for example an *undo* list or a play list.

### BitArray

One bit for each item. A million yes/no values (a sieve of primes, which seats are free, which files were seen) take 125 KB instead of megabytes. `Set(index, value)` and `Get(index)` write and read one bit (`Get` is called with `callMethod`, see below); `And`, `Or`, `Xor` and `Not` work on all the bits at once and **change the array they are called on**, so the program copies it first (`new BitArray(bits)`). In the output, `AND` has only the bit that both arrays have and `OR` has the bits of either.

> [!NOTE] Ring accepts most of its own words as method names after a dot (`Set`, `From`, `To`, `Step`, `In`, `On`, `Off`), but not `Get`, `And` and `Or` (a statement `get x` reads input, and `and`, `or` are the operators of conditions). A .NET method with one of those names is called with `callMethod("Get", [...])`.

## What you learned

- five collections and what each one is for,
- the plain style (`callMethod`, `getProp`, `toList`) for closed generic types,
- `BitArray` operations change their own array,
- the few Ring words that must be called with `callMethod`.

## Exercises

1. Make a task list with `PriorityQueue` where two tasks have the same priority: in which order do they come out? (Do not rely on it.)
2. Use a `SortedSet` of words to print the words of a text without duplicates in alphabetical order.
3. Find all primes below 1000 with a `BitArray` (the sieve of Eratosthenes).
4. Build an *undo list* of the last 5 actions with a `LinkedList`.

## Next

[Collections for many threads](tut-89-concurrent-collections.html)
