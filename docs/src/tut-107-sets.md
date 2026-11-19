---
title: "Tutorial 107: Sets"
lead: A set holds each value once and finds a value very fast. HashSet also does the operations of set theory — union, intersection, difference — and answers questions such as "is this a subset?". This lesson uses it to remove duplicates and to compare groups.
---

## What you will learn

- what a **set** is and why it is fast,
- `HashSet`: `Add`, `Remove`, `Count`,
- `UnionWith`, `IntersectWith`, `ExceptWith`, `SymmetricExceptWith`,
- `IsSubsetOf`, `IsSupersetOf`, `Overlaps`, `SetEquals`,
- a set with a comparer (case ignored),
- removing duplicates from a list.

[Tutorial 92](tut-92-data-structures.html) showed `SortedSet`, a set that keeps its values in order. `HashSet` does not keep an order, and it is faster.

## The program

{{file:docs/tutorials/t107_sets.ring}}

{{output:docs/tutorials/t107_sets.ring}}

## How it works

### One copy of each value

A set holds a value **once**. The list for set B has six words, `ring` twice, and the set has five items. `Add` answers whether the value was new (*true*) or already there (*false*); `Remove` takes a value away. There is **no order**: the items come out in an order that you must not depend on, so the program sorts them before printing. The set is stored in a **hash table**: a value is turned into a number that points at the place where it lives, so `Contains` takes the same short time for ten values and for ten million, while a list has to look at every item. When a program asks "have I seen this before?" many times, a set is the right tool.

The closed generic type is made with `dnNewGeneric("System.Collections.Generic.HashSet",["System.String"],[])` and used with `callMethod` and `getProp`; `toList()` copies the items into a Ring list ([tutorial 89](tut-89-concurrent-collections.html)).

### The operations

Take A = {dotnet, json, linq, ring, web} and B = {json, ring, tcp, udp, web}:

| Method | Meaning | Result |
|---|---|---|
| `UnionWith(B)` | in A **or** B | dotnet json linq ring tcp udp web |
| `IntersectWith(B)` | in A **and** in B | json ring web |
| `ExceptWith(B)` | in A but **not** in B | dotnet linq |
| `SymmetricExceptWith(B)` | in one of them, **not in both** | dotnet linq tcp udp |

All four **change the set they are called on**, they do not return a new set. So the program first makes a copy (a `HashSet` can be made from another collection: `copySet`) and then changes the copy. If you forget this, A is spoilt for the next step.

### Questions

`IsSubsetOf`, `IsSupersetOf`, `Overlaps` (do they share at least one item?) and `SetEquals` (the same items, whatever the order) answer yes or no and change nothing. They are what you need for rules such as *"the user has all the required permissions"* (the set of required permissions is a **subset** of the user's) or *"the two groups have nobody in common"* (they do not **overlap**).

### A comparer

The constructor of a `HashSet` can take a comparer ([tutorial 97](tut-97-comparers.html)): with `StringComparer.OrdinalIgnoreCase`, `Ann` and `ann` are the same item, so five names make three people.

### Removing duplicates

To remove the duplicates of a Ring list, add its items to a set and read the set back: the 8 numbers in step 6 give 4 different ones. Sort the result if you need an order, because the set has none. This is much faster than looking for each item in a growing list, and it needs only a few lines.

> [!NOTE] A `HashSet<T>` needs a good *hash* and *equality* for its type. Texts and numbers have them. For your own objects, give the set an equality comparer, or use a text key (such as an id).

## What you learned

- a set keeps one copy of each value and finds values fast,
- `Add` tells whether the value was new,
- union, intersection, difference and symmetric difference change the set, so copy first,
- `IsSubsetOf`, `IsSupersetOf`, `Overlaps` and `SetEquals`,
- comparers and removing duplicates.

## Exercises

1. Find the words that two text files have in common ([tutorial 5](tut-05-files.html)).
2. Check that a user has all the permissions of a list with `IsSupersetOf` ([tutorial 95](tut-95-claims.html)).
3. Count the different words of a text ([tutorial 2](tut-02-text.html)).
4. Compare `Contains` in a `HashSet` and in a Ring list with 100 000 items and a `Stopwatch`.

## Next

[Tutorial 92: More data structures](tut-92-data-structures.html)
