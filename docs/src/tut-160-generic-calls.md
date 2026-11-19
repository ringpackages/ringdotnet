---
title: "The generic functions"
lead: Nearly everything in .NET has a generated class, and you write object code: new, the dot and braces. A few cases have no class, or a class that cannot be made with new. For them Ring has generic functions: dnNewGeneric, dnType, dnNew, dnStatic, dnNull and dnBuffer, and the methods callMethod and getProp. This lesson shows when each one is needed.
---

## What you will learn

- why the tutorials use **object code** first, and what a generic function does instead,
- `dnNewGeneric` with `callMethod` and `getProp`: a generic type with no class,
- `dnType`: the type object, for static members,
- `dnNew` with **named** values: a constructor that `new` cannot reach,
- `dnStatic`: a static method called by its full class name,
- `dnNull` and `dnBuffer`,
- a rule of thumb for choosing.

The earlier lessons wrote `new StringBuilder("x")`, `oText.Append("y")`, `oText.Length` and `oForm { Text = "Hello" }`. That is the way to use .NET from Ring. The generic functions below do the same work with names written as **texts**, so a program has to say more, and they are for the few cases where object code does not reach.

## The program

{{file:samples/UsingDotNet/tutorials/ch13_generic_calls.ring}}

{{output:samples/UsingDotNet/tutorials/ch13_generic_calls.ring}}

## How it works

### A generic type with no class

`List<T>`, `Dictionary<K,V>` and some others have ready classes for the common item types (`StringList`, `NumberDictionary`...). A type such as `LinkedList<string>` has no class, so `dnNewGeneric("System.Collections.Generic.LinkedList", ["System.String"], [])` makes the object, and what comes back is a plain `DotNetObject`. A plain object has no named methods, but it has two general ones: `callMethod("AddLast", ["b"])` calls a method and `getProp("Count")` reads a property. `toList()` copies a collection into a Ring list. The result of `getProp("First")` is another plain object (a node), and its `Value` is read the same way.

### The type object

`dnType("System.Math")` is the **type** itself, and `callMethod` on it calls static methods; `getProp("PI")` reads a static property. With a class the same thing is `new Math().Max(3, 9)` and `new Math().PI`: Ring makes a harmless object to reach the static members. Use `dnType` for a type that no class wraps, or whose namespace you did not name in `using`.

### Named values for a constructor

A class made with `new X(...)` runs its `init`, and `init` has one form. A class that has **no constructor without values** (`FileStream` must have a path and a mode) cannot be made with `new FileStream()`, and a constructor with several values needs a way to choose among the constructors: the **names** of their parameters. `dnNew("FileStream", [ :path = cFile, :mode = "Open", :access = "Read" ])` does it. For a class that does have a constructor without values, the object form is `new MemoryStream().New_([ :buffer = bytes ])`, which the tutorials use first.

### A static method by name

`dnStatic("System.Convert", "ToString", [255, 16])` calls the static method `Convert.ToString(255, 16)`: the text of a number in base 16. Here the method is also named like the `ToString` that **every** object has, which Ring uses for its own `toString()`, so the generated class keeps that name for the object and the static method needs the generic call. The same is true for a class that needs values to make an object and for a static method of a type that has no class.

### Null and buffers

`dnNull()` is the .NET `null`, for a parameter or a property that must be set to null (`oPictureBox.Image = dnNull()`; the program adds null to an `ArrayList`). A method that **returns** null gives an object that answers `isNull()`. `dnBuffer(n)` is a `byte[]` that .NET can fill; it was introduced with `Stream.Read` in the tutorial [Binary files](tut-45-binary.html).

### Choosing

1. First write an **object**: `new`, the dot, braces.
2. A constructor that needs values, or a class without a constructor without values: `dnNew("Class", [ :name = value ])`.
3. A static method with a name that every object has, or a type that no class wraps: `dnStatic` or `dnType`.
4. An object that has no class (a generic type, or a type that was not wrapped): `dnNewGeneric` or the object that came back, with `callMethod` and `getProp`.

> [!NOTE] The reference of all these functions is in [Core functions](core-api.html), and [Core concepts](concepts.html) explains how class names, overloads and properties look. If a class that you need is not wrapped, [Your own assemblies](own-assemblies.html) shows how to generate classes for it.

## What you learned

- object code is the normal way, and the generic functions are for the exceptions,
- `dnNewGeneric`, `callMethod` and `getProp` for objects with no class,
- `dnType` and `dnStatic` for static members,
- `dnNew` with named values,
- `dnNull` and `dnBuffer`,
- a rule for choosing.

## Exercises

1. Make a `HashSet<string>` with `dnNewGeneric`, add three names and print `Count`.
2. Call `Math.Round(2.5)` with `dnStatic` and with a class, and compare the answers.
3. Open a `FileStream` with `:mode = "Create"` and write a few bytes into it.
4. Read the `Count` of a `Queue<string>` made with `dnNewGeneric` after two `Enqueue` calls.

## Next

[Testing your programs](tut-28-testing.html)
