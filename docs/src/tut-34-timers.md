---
title: "Timers and progress"
lead: A window must never freeze. This lesson builds a stopwatch and a progress bar, and shows how to do a long job in small steps so that the window keeps responding.
---

## What you will learn

- the Windows Forms `Timer` and why it is safe,
- measuring time with `Stopwatch`,
- the progress bar,
- why a long job freezes a window, and the fix: work in small steps,
- how to test code that depends on time.

## The message loop and freezing

A window program lives in a **message loop**: it waits for something to happen (a click, a key, a repaint), runs your code, and returns to waiting. While your code runs, **nothing else happens**: the window is not repainted, buttons do not react. A job that takes five seconds, run in one go, freezes the window for five seconds, and Windows may mark it "not responding".

In languages with threads the usual answer is "do the work on another thread". Ring code runs on **one thread**, so the answer here is different: **cut the job into small parts and do one part each time a timer ticks.** Between the parts the message loop runs, the window repaints, the user can click *Cancel*.

## The program

{{file:docs/tutorials/g34_timers.ring}}

![The window with the stopwatch running and the job at 60 percent](img/shots/tut-g34.png "The stopwatch shows 0:02.5 while the job is at 60%")

{{output:docs/tutorials/g34_timers.ring --selftest}}

## How it works

### The timer

`uiTimer(50,"showTime()")` creates a Windows Forms `Timer` that calls `showTime()` every 50 milliseconds once it is started. This timer raises its `Tick` event **on the Ring thread, inside the message loop**, so the code can use Ring variables and controls freely. (The `System.Threading.Timer` of .NET ticks on another thread: Ring code cannot run there.)

### The stopwatch

A `Stopwatch` measures time exactly: `Start()`, `Stop()`, `Reset()`, `IsRunning` and `ElapsedMilliseconds`. The function `showTime` splits the milliseconds into minutes, seconds and tenths and writes them into the label. The timer only *displays* the time; the stopwatch keeps it, which is why the display is right even if a tick is late.

### The long job

`startJob` creates a second timer, every 20 ms; `jobStep` does one small part (5 percent), updates the `ProgressBar` and the text, and stops the timer at 100. The whole job takes about 400 ms, and **the stopwatch keeps running and the buttons keep working** while it runs: press *Start / Stop* during the job to see it.

How big should a part be? Small enough that one step takes well under 50 ms, so the window stays smooth.

### ProgressBar

`Minimum`, `Maximum` and `Value`. For a job of unknown length use `Style = "Marquee"`, which shows a moving bar.

### Testing time

A test cannot wait for ticks. `selfTest` stops the clock timer, calls `toggleWatch`, sleeps 150 ms with `Thread.Sleep`, stops the watch and checks that at least 100 ms were measured. It calls `jobStep()` twenty times by hand and checks that the bar is full. Design for this: put the real work in functions that a timer *calls*, so a test can call them directly.

## What you learned

- never run a long job in one go inside an event,
- a timer calls a small step again and again,
- `Stopwatch` measures, `Timer` displays,
- put the work in functions so tests can call them.

## Exercises

1. Add a **Cancel** button that stops the job.
2. Make the step size depend on how long the last step took.
3. Add a countdown: a text box with seconds, a *Start* button, and a message when it reaches zero.
4. Show the estimated time remaining next to the progress bar.

## Next

[Drawing and animation](tut-14-animation.html)
