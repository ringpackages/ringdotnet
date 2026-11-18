---
title: "Tutorial 53: Speed — measure first"
lead: Programs get faster when you measure, not when you guess. This lesson times code with a Stopwatch, compares two ways of building text, adds a cache, and shows the cost of calls across the bridge.
---

## What you will learn

- measuring time with `Stopwatch`,
- why you must **measure** instead of assuming,
- a cache (*memoization*) that turns a slow function into a fast one,
- the cost of a call between Ring and .NET, and how to make fewer calls.

## The rules of speed

1. **Make it work, then make it right, then make it fast** — and only if it is too slow.
2. **Measure.** The slow part is rarely the part you suspect.
3. The biggest wins come from doing **less work** (a cache, a better algorithm, fewer calls), not from clever tricks.

## The program

{{file:docs/tutorials/t54_speed.ring}}

{{output:docs/tutorials/t54_speed.ring}}

## How it works

### Stopwatch

`new Stopwatch()`, `Start()`, `Stop()`, and then `ElapsedMilliseconds` or `Elapsed.TotalMilliseconds`. The tutorial prints *comparisons* ("which is faster?") and not the times, so that the output is the same on every computer; when you try your own code, print the numbers.

### Ring's `+=` against `StringBuilder`

In C# a `StringBuilder` is the standard answer to building a long text. In Ring the answer is different: the `+=` of Ring is already efficient, and each `Append` of a `StringBuilder` is a **call across the bridge**. Here the plain Ring version wins. This is the reason for rule 2: advice from another language can be wrong in yours. Use `StringBuilder` when you need its other features (inserting, replacing, passing it to a .NET method), not for speed.

### A cache

`fibSlow(22)` computes the same values again and again: 114,626 calls in total for two runs. `fibCached` remembers each answer (`aCache`) and needs only 44. The idea is general: **if a function always gives the same answer for the same input, remember it.** Typical uses: results of a database query, a downloaded file, a converted value, a compiled regular expression.

> [!NOTE] A cache needs a rule for when to forget. If the data can change, store a time next to the value and recompute after a while, or clear the cache when the data changes.

### Fewer calls across the bridge

Every call to .NET has a small cost. Reading 500 items with `oList.Item(i)` makes 500 calls; `oList.ToList()` makes one and gives you a Ring list. When you can ask for *a lot at once*, do it. The same applies to reading a file (`ReadAllLines` instead of one line at a time) and to filling a grid.

## What you learned

- `Stopwatch` and measuring,
- the result may be the opposite of what you expect,
- a cache saves repeated work,
- one call for many items beats many calls.

## Exercises

1. Measure `File.ReadAllLines` against `StreamReader.ReadLine` in a loop on a 10,000-line file.
2. Add a time limit to `fibCached`'s cache: forget answers older than a minute.
3. Time `new Regex(pattern)` created inside a loop and created once before the loop.

## Next

[Tutorial 54: An expression calculator](tut-54-expression.html)
