---
title: "Recursion"
lead: A recursive function solves a problem by solving a smaller copy of the same problem. This lesson uses it for factorials, the Towers of Hanoi, all the orders of a list, a folder tree and a paint-bucket fill.
---

## What you will learn

- what recursion is and the two parts every recursive function needs,
- how the calls pile up (depth),
- classic problems that become short with recursion,
- walking a **tree** (folders),
- the danger of recursion without an end.

## The idea

Russian dolls: to open a doll you open the outer doll, and then you do the same job for the doll inside, until you reach the smallest doll that cannot be opened. A recursive function has the same two parts:

1. **the stop** (the *base case*): a case that is answered directly — `factorial(1)` is 1;
2. **the step**: a call of itself with a *smaller* problem — `factorial(n)` is `n * factorial(n − 1)`.

If the step does not get closer to the stop, the function calls itself until the program runs out of memory.

## The program

{{file:samples/UsingDotNet/tutorials/t75_recursion.ring}}

{{output:samples/UsingDotNet/tutorials/t75_recursion.ring}}

## How it works

### 1–2. Factorial and the depth

`factorial(5)` waits for `factorial(4)`, which waits for `factorial(3)` … until `factorial(1)` returns 1; then every call finishes in reverse order. Step 2 prints one line for each call, indented by its depth: the calls pile up like a stack of plates (the tutorial [Undo, redo and queues](tut-58-undo.html)) and are removed in the opposite order.

### 3. Towers of Hanoi

To move *n* discs from A to C: move *n − 1* discs from A to B (using C), move the biggest disc to C, then move the *n − 1* discs from B to C. That is the whole solution; you never have to think about the individual moves. The number of moves is 2ⁿ − 1: 7 for 3 discs, 1,023 for 10, and about 18 quintillion for 64 — recursion is elegant but **not free**.

### 4. Permutations

All orders of `[a, b, c]`: choose each item as the first one and put it in front of every order of the *rest*. The six results appear without any loop that knows how many items there are.

### 5. A tree of folders

A folder contains files and other folders, each of which contains... `showTree` prints a folder, then calls itself for each subfolder with one more level of indentation; `folderSize` adds the size of the files and of the subfolders. Recursion is the natural way to walk any tree: folders, XML (the tutorial [XML in depth](tut-72-xml.html)), a menu, a family tree.

> [!TIP] .NET can also list all files below a folder in one call (`Directory.GetFiles([ :path = path, :searchPattern = "*", :searchOption = "AllDirectories" ])`). Write the recursion yourself when you need to do something at each level.

### 6. Flood fill

The paint bucket: if the cell is empty, fill it and do the same for the cell above, below, left and right. The stop cases come first: outside the picture, or not an empty cell. The frame stops the fill, so the outside stays empty.

## When not to use recursion

- Ring (like most languages) keeps each call in memory; a depth of hundreds of thousands can exhaust it. A loop uses no extra memory.
- A recursion that repeats the same work (the naive Fibonacci in the tutorial [Speed — measure first](tut-53-speed.html)) needs a cache.

Use recursion when the problem has the shape of a **tree** or *"the same problem, but smaller"*; use a loop for simple repetition.

## What you learned

- stop and step,
- depth and the call stack,
- Hanoi, permutations, folder trees, flood fill,
- when a loop is better.

## Exercises

1. Write `power(base, exponent)` recursively.
2. Print all subsets of `[1,2,3]`.
3. Count the files of each extension below a folder with a recursive function.
4. Write `reverse(text)` recursively (the last letter + the reverse of the rest).

## Next

[An expression calculator](tut-54-expression.html)
