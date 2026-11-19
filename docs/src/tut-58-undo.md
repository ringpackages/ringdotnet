---
title: "Undo, redo and queues"
lead: Stacks and queues are two of the most useful data structures. This lesson builds undo and redo from two stacks and a job queue that serves the oldest job first.
---

## What you will learn

- **stack**: last in, first out; **queue**: first in, first out,
- `Push`, `Pop`, `Peek`, `Enqueue`, `Dequeue`, `Count`,
- building undo and redo with two stacks,
- what happens when you take from an empty collection.

## Two ways to wait

A **stack** is a pile of plates: you put on top and take from the top. A **queue** is a line at a shop: the first to arrive is served first.

| | Stack | Queue |
|---|---|---|
| add | `Push(x)` | `Enqueue(x)` |
| take | `Pop()` | `Dequeue()` |
| look | `Peek()` | `Peek()` |
| size | `Count` | `Count` |
| used for | undo, the Back button, parsing, the call stack | print jobs, tasks to do, messages |

The ready-made Ring classes are `StringStack` and `StringQueue` (see [Collections](collections-linq.html)).

## The program

{{file:samples/UsingDotNet/tutorials/ch04_undo.ring}}

{{output:samples/UsingDotNet/tutorials/ch04_undo.ring}}

## How it works

### Undo and redo

`TextHistory` keeps the current text and two stacks. Each change **pushes the old text on the undo stack**. `undo` pushes the current text on the redo stack and pops the previous text from the undo stack. `redo` does the reverse. The most recent change is always on top, which is exactly the order a user expects.

A *new* change after an undo clears the redo stack (`Clear()`): the old future no longer exists. The last line of step 2 shows `can redo now? no`.

The same idea works for a drawing program (push each shape), a browser (the Back and Forward buttons are two stacks), or a calculator (the operands).

### The queue

Step 3 adds three jobs and serves them in the order they came. A worker program often has a loop `while queue.Count > 0` that takes the next job.

### Empty collections

`Dequeue()` or `Pop()` on an empty collection raises an error (the last lines of the output). Look at `Count` first, or wrap the call in `try` / `catch` (the tutorial [When things go wrong](tut-07-errors.html)).

## What you learned

- stacks and queues and when to use each,
- undo and redo with two stacks,
- always check `Count`.

## Exercises

1. Add a limit of 100 undo steps: when the undo stack is full, drop the oldest entry (hint: use a list).
2. Make a job queue with *priorities*: urgent jobs first (hint: two queues).
3. Check that parentheses in `(a + [b]) * c` are balanced, using a stack.

## Next

[Recursion](tut-75-recursion.html)
