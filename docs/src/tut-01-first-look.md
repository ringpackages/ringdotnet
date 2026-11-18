---
title: "Tutorial 1: A first look"
lead: Meet objects, types, properties, methods, static members, structs, collections and null with a small program that prints what it finds.
---

## What you will learn

- how to start using .NET from Ring,
- what a *type*, an *object*, a *property*, a *method* and a *static member* look like,
- how a struct and a collection look.

## Before you start

You need Ring and the RingDotNet package. Open a terminal in `docs/tutorials`. If something does not work, read [Getting started](getting-started.html). If Ring is new to you, read the [Quick introduction to Ring](ring-intro.html) in the appendix first.

## The program

Read the program first; the explanations follow. The line `using { ... }` brings classes in. `func main` is where Ring starts.

{{file:docs/tutorials/t01_first_look.ring}}

Run it:

```bash
ring t01_first_look.ring
```

{{output:docs/tutorials/t01_first_look.ring}}

## How it works, step by step

### 1. The runtime

`new Environment().Version` asks the .NET runtime that runs inside your Ring program for its version (`Environment` is a class of the `System` namespace that the `using` block opened). Nothing is installed "next to" Ring: the runtime is part of your program while it runs.

### 2. Everything is an object of some type

`new StringBuilder("Hello")` creates an object. `GetType()` is a method that every .NET object has; it returns an object that *describes* the type. Its properties `FullName`, `Namespace` and `IsClass` tell you what you are holding: a class called `System.Text.StringBuilder` in the namespace `System.Text`.

> [!NOTE] Always write the parentheses: `new StringBuilder("Hello")`. In Ring, `new X` without them does not run the constructor.

### 3. Properties and methods

`oText.Append(", .NET")` is a **method**: the object does something (it adds text to itself). `oText.Length` is a **property**: it tells you something the object knows. Properties are read without parentheses.

`ToString()` turns the object into a Ring text. Almost every .NET object has it.

### 4. Static members

`new Math().Max(3,9)` does not need *a* math object: `Max` belongs to the class. Ring still writes `new Math()` to reach it; the object is just a doorway to the class.

Ring prints the number `3.14159...` as `3.14` because Ring shows two decimals by default. The value itself is not rounded. Use `decimals(5)` at the top of a program to see more.

### 5. Structs

A `DateTime` is a *struct*: a small value. `new DateTime(2024,12,25)` is a date. `Format("yyyy-MM-dd")` formats it, and `DayOfWeek` is an enum, so Ring gets the text `Wednesday`.

> [!TIP] `ToString()` has no parameters; `Format("yyyy-MM-dd")` is its form with a pattern. A .NET method that exists in several forms becomes one Ring method that takes one value, `NULL` or a list of `:name = value` pairs; [Core concepts](concepts.html#naming-rules) explains it.

### 6. Collections

`StringList` holds texts, in order. `Add` adds one, `Count` says how many, `Item(0)` reads the first (the position starts at 0, like in .NET).

### 7. null

`dnNull()` is the .NET `null`: "no object". `isNull()` checks it. Ring prints `1` for true.

## What you learned

| Idea | Example |
|---|---|
| a runtime inside your program | `new Environment().Version` |
| create an object | `new StringBuilder("Hello")` |
| a property | `oText.Length` |
| a method | `oText.Append(", .NET")` |
| a static member | `new Math().Max(3,9)` |
| a struct and an enum | `DateTime`, `DayOfWeek` |
| a collection | `StringList` |
| no object | `dnNull()` |

## Exercises

1. Change the program to print the type of a `DateTime` object. Which namespace is it in?
2. Create a `StringBuilder` and append your name five times with a loop. What is its `Length`?
3. Use `new Math()` to print the square root of 2 and the larger of `7` and `19`.
4. Find `Environment.MachineName` in the [class reference](api.html) (namespace `System`) and print it.

## Next

[Tutorial 2: Working with text](tut-02-text.html).
