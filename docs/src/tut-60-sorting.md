---
title: "Watching sorting algorithms"
lead: Sorting is the classic example of an algorithm. This lesson records the work of three algorithms — bubble, selection and insertion — and replays it on a canvas, one step per timer tick, while counting comparisons and swaps.
---

## What you will learn

- how bubble sort, selection sort and insertion sort work,
- **recording** work as a list of steps and replaying it with a timer,
- drawing bars on a canvas and highlighting the two that are touched,
- counting comparisons and swaps to compare algorithms,
- a generator of random numbers with a fixed start.

## The program

{{file:samples/UsingDotNet/tutorials/ch12_sorting.ring}}

![The sorting window](img/shots/tut-g61.png "Bubble sort after 260 steps: the highest bars are already at the right; the two red bars are the pair being compared")

{{output:samples/UsingDotNet/tutorials/ch12_sorting.ring --selftest}}

## How it works

### Record, then replay

A sorting algorithm is a loop that finishes in a moment: you could not see it. So the three functions `bubbleSort`, `selectionSort` and `insertionSort` work on a **copy** of the bars and, instead of drawing, **record each step** in `aSteps`: `["compare", 3, 4]` or `["swap", 3, 4]`. The timer then calls `showStep` every 15 milliseconds; each call takes the next recorded step, applies a swap to the bars on screen, adds to the counters and redraws. This separation — *computing* in one place and *showing* in another — also makes the self test easy: it runs all the steps without waiting and checks the result.

### The three algorithms

| Algorithm | Idea | Work |
|---|---|---|
| **Bubble sort** | compare neighbours and swap them if they are in the wrong order; repeat, and the biggest bar "bubbles" to the end | many comparisons and many swaps |
| **Selection sort** | find the smallest of the rest and swap it to the front | many comparisons, **at most n − 1 swaps** |
| **Insertion sort** | take the next bar and slide it left until it is in the right place (like sorting playing cards in your hand) | fast when the data is already nearly sorted |

Press **Sort** with each algorithm on the same bars (**Shuffle** makes a new order) and watch the counters at the bottom. For 36 bars bubble sort needs 630 comparisons, selection sort also 630 but far fewer swaps. Fast algorithms such as *quicksort* and *merge sort* need only about `n × log n` comparisons; for 1,000,000 items that is about 20 million instead of hundreds of billions. The .NET `List.Sort` uses such an algorithm.

### Drawing

`draw` clears the canvas and draws one rectangle per bar; the height is the value, scaled to the window. A bar in `aHot` (the pair of the current step) is red. `oCanvas.show()` puts the finished picture on the screen — drawing everything first and showing it once avoids flicker (the tutorial [Drawing and animation](tut-14-animation.html)).

### Same bars every time

`nextRandom` is a tiny random generator with a fixed start (`nSeed`), so that the screenshot and the test are always the same. Use `Random` with no fixed seed when you want different bars each time.

> [!TIP] The pattern "record a list of events, then play it back" is useful in many places: a replay of a game, an undo history (the tutorial [Undo, redo and queues](tut-58-undo.html)), or a slow motion view of any algorithm.

## What you learned

- how three sorting algorithms work and how they differ,
- recording steps and replaying them with a timer,
- the canvas for bars and highlights,
- measuring work with counters.

## Exercises

1. Add a **Shell sort** or **quicksort** and compare the counters.
2. Show a bar's value as text over the bar (`oCanvas.text`).
3. Add a speed track bar that changes the timer interval.
4. Count how many comparisons insertion sort needs for bars that are already sorted.

## Next

[A maze](tut-61-maze.html)
