---
title: "Callbacks and events"
lead: Many .NET methods ask you for a piece of code: how to compare, which items to keep, what to do when something happens. This lesson shows the three ways to give Ring code to .NET and the rules that keep it working.
---

## What you will learn

- what a *callback* (a *delegate*) is,
- the three ways to write one: a function name, a text of code, an event handler,
- the argument and result convention: `aDotNetArgs` and `xDotNetResult`,
- what happens with errors inside a callback,
- why callbacks must run on the Ring thread.

## What is a callback?

Sometimes a .NET method does not know *what exactly* to do:

| Method | The part it does not know |
|---|---|
| `List.Sort` | how to compare two items |
| `List.FindAll` | which items to keep |
| `List.ForEach` | what to do with each item |
| an event such as `Click` | what to do when it happens |

You give it a **callback**: code that .NET *calls back* when it needs the answer. In .NET the type of such a thing is a **delegate** (`Action`, `Func`, `Predicate`, `Comparison`, `EventHandler`...). In Ring you create one with `dnCallback(...)`.

## The program

{{file:docs/tutorials/t19_callbacks.ring}}

{{output:docs/tutorials/t19_callbacks.ring}}

## How it works

### 1. A function name

`dnCallback("showItem")` is the simplest form: the **name** of a Ring function. .NET calls it once per item. The function gets **one parameter, a list of the arguments** that .NET passes, and returns the result:

```ring
func showItem aArgs
	? "   item: " + aArgs[1]
```

`ForEach_` ends with `_` because `ForEach` is a Ring keyword.

### 2. A callback that decides

`Sort([ :comparison = dnCallback("compareLength") ])` passes a comparison. .NET gives the function two items (`aArgs[1]`, `aArgs[2]`); it returns a negative number if the first goes first, a positive one if the second goes first, and `0` for equal. Subtracting the lengths does exactly that: `fig, pear, apple, avocado`.

`FindAll` and `Exists` take a *predicate*: a function that returns true or false for an item.

### 3. A piece of code in a text

If the text is not just a function name, it is **Ring code**. It reads the arguments in `aDotNetArgs` and writes its answer into `xDotNetResult`:

```ring
oWords.ForEach_(dnCallback("nLetters += len(aDotNetArgs[1])"))
oWords.Sort([ :comparison = dnCallback("xDotNetResult = len(aDotNetArgs[2]) - len(aDotNetArgs[1])") ])
```

This is handy for one-liners. The code is compiled once, the first time, so using it in a loop costs nothing extra.

### 4. Events

An *event* is a delegate that .NET stores and calls later, possibly many times. `setCollectionChangedEvent("code")` sets the handler of the event `CollectionChanged`; `clearCollectionChangedEvent()` removes it. The code gets `aDotNetArgs = [sender, eventArgs]`: `aDotNetArgs[2].getProp('Action')` says what happened (`Add`, `Remove`). After the handler was cleared, the third change raised no event.

The same works for every event of every class: a button's `Click`, a text box's `TextChanged`, a form's `FormClosing`.

### 5. Errors

An error raised inside a callback (`raise(...)`) travels back through .NET and comes out of the method that called it, so your `try` / `catch` around `ForEach_` catches it.

## The rules

> [!WARNING] **Code in a callback sees only global variables.** It runs later, outside the function that created it. `nLetters` and `nChanges` are global in the program. A local variable of `main` would be unknown to the callback.

> [!WARNING] **Callbacks run on the Ring thread, during a call.** A callback that .NET tries to run from another thread (a thread-pool timer, a task) is ignored with a message on `stderr`. Use Windows Forms timers (`uiTimer`) for repeating work, and wait for tasks on the Ring thread.

## What you learned

| Idea | Example |
|---|---|
| a callback by function name | `dnCallback("showItem")` |
| arguments and result | `aArgs[1]`, `return` |
| code in a text | `aDotNetArgs[1]`, `xDotNetResult` |
| an event | `setCollectionChangedEvent("...")`, `clear...Event()` |
| errors travel back | `try` around the .NET call |

## Exercises

1. Sort the words alphabetically by their *last* letter.
2. Use `FindAll` to keep the words with more than four letters, and `ForEach_` to print them in upper case.
3. Make a handler for `CollectionChanged` that prints the new item (`aDotNetArgs[2].getProp('NewItems')`).
4. Set the same event twice and see that the second handler replaces the first.

## Next

[Exploring .NET with reflection](tut-20-reflection.html)
