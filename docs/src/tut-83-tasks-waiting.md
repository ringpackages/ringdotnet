---
title: "Tasks that wait"
lead: A Task is something that finishes later. .NET can start many of them at once, wait for all or for the first, give up after a time limit, and cancel the ones that are no longer needed. This lesson uses delays to show it, without any threads of your own.
---

## What you will learn

- what a `Task` is and what `Wait` does,
- `Task.Delay`: a wait that does not block a thread,
- `WhenAll` and `WhenAny`,
- a time limit with `Wait(milliseconds)`,
- cancelling with `CancellationTokenSource` and a token,
- why many waits together take the time of the longest, not the sum.

## Tasks and Ring

In .NET a **task** is a promise: a piece of work that is running or waiting and will be *finished*, *failed* or *cancelled*. `HttpClient.GetAsync`, `File.ReadAllTextAsync` and `Process.WaitForExitAsync` all return tasks. Ring runs your code on one thread, and **Ring code cannot run on other threads** ([Core concepts](concepts.html)), so you do not write the work of a task in Ring. You use the tasks that .NET provides, start several, and wait for them in Ring. `Task.Delay` is the simplest such task: it finishes after a time and does nothing else, which makes the rules visible.

## The program

{{file:samples/UsingDotNet/tutorials/t83_tasks_waiting.ring}}

{{output:samples/UsingDotNet/tutorials/t83_tasks_waiting.ring}}

The output prints *yes* and *no* instead of the exact milliseconds, so that it is the same on every computer. When you try it yourself, print `ElapsedMilliseconds`.

## How it works

### Delay and Wait

`Task.Delay(300)` returns **at once** with a task that is not finished yet (`IsCompleted` is false). `Wait(NULL)` blocks the Ring program until the task is finished; its `Status` is then `RanToCompletion`. Making the task and waiting for it are two separate steps — that separation is what lets you start many tasks first.

### WhenAll and WhenAny

`Task.WhenAll([t1, t2, t3])` is a new task that finishes when **all** of them did. Three delays of 300 ms started together are over after about 300 ms, not 900. The same idea turns a hundred slow downloads into one wait. `Task.WhenAny([…])` finishes with the **first** one: here the fast delay finishes and the slow one is still running.

The tasks go into a Ring list, which `WhenAll` and `WhenAny` take as an array of tasks.

### A time limit

`oTask.Wait(200)` waits at most 200 ms and answers **true** if the task finished, **false** if the time ran out. The task keeps running; you only stopped waiting. Use it so that a missing server cannot block your program for ever; `Wait(NULL)` waits without a limit.

### Cancellation

A `CancellationTokenSource` is a switch. `CancelAfter(100)` turns it on after 100 ms. Its `Token` goes with the work: `Task.Delay([ :millisecondsDelay = 5000, :cancellationToken = oSource.Token ])` is a delay of five seconds that ends *cancelled* when the switch turns on. Waiting for a cancelled task raises an error (the `catch` sees it), `IsCanceled` is true and `Status` is `Canceled`. Most asynchronous methods of .NET accept a token as their last parameter, for example `HttpClient.GetAsync` (the tutorial [HttpClient in depth](tut-84-http-client.html)).

> [!TIP] Dispose a `CancellationTokenSource` when you are done with it (`oSource.Dispose()`).

### Many waits, one result

Step 6 starts five delays and waits for them with one `WhenAll`: the total is about 200 ms (the longest), not the 480 ms that they add up to.

## What you learned

- `Task.Delay`, `Wait`, `Status`, `IsCompleted`,
- `WhenAll` and `WhenAny` with a Ring list of tasks,
- `Wait(ms)` as a time limit,
- `CancellationTokenSource`, `CancelAfter` and the token,
- tasks wait together.

## Exercises

1. Start three `HttpClient` requests (the tutorial [HttpClient in depth](tut-84-http-client.html)) and wait for all with `WhenAll`; compare the time with doing them one after another.
2. Print the elapsed milliseconds for each step and see how close they are to the delays.
3. Use `WhenAny` with a delay as a **timeout**: whichever of a request and a 2-second delay ends first wins.
4. Cancel a `Process.WaitForExitAsync` of a program that runs for a minute.

## Next

[Releasing resources](tut-71-dispose.html)
