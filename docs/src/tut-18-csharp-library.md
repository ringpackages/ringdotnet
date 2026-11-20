---
title: "A library written in C#"
lead: Someone wrote a library in C# — a colleague, or a NuGet package. This lesson builds a tiny C# library and shows how to wrap it and use it from Ring like any other class.
---

## What you will learn

- the steps to use any .NET library from Ring,
- what a C# class looks like, so you can read the ones you meet,
- how properties, methods, overloads, static methods, `out` parameters, events and enums arrive in Ring.

## The steps

1. **Get the library** as a `.dll` (build it, or copy it from a NuGet package).
2. **Wrap it**: `ring wrapassembly.ring Library.dll classes` writes a Ring class for every public C# class.
3. **Load it**: `dnLoad("Library.dll")` and `dnImportFrom("classes/","Namespace")`.
4. **Use it**: `new ClassName()`, exactly like the built-in classes.

## The C# library

You do not have to write C#, but reading a little helps. This library is in `samples/UsingDotNet/tutorials/Greeter`:

{{file:samples/UsingDotNet/tutorials/Greeter/Greeter.cs}}

The project file lists what to build:

{{file:samples/UsingDotNet/tutorials/Greeter/Greeter.csproj}}

To build it you need the **.NET SDK** (`dotnet --version` prints its version):

```bash
dotnet build Greeter -c Release -o Greeter/bin
```

## The Ring program

{{file:samples/UsingDotNet/tutorials/ch13_use_library.ring}}

{{output:samples/UsingDotNet/tutorials/ch13_use_library.ring}}

## How C# members look in Ring

| In C# | In Ring |
|---|---|
| `public string Name { get; set; }` | `oGreeter.Name` and `oGreeter.Name = "Ring"` |
| `public int Greetings { get; private set; }` | `oGreeter.Greetings` — read only |
| `Hello()` and `Hello(string name, Style style)` | `Hello(NULL)` and `Hello([ :name = "Ann", :style = "Casual" ])` |
| `public enum Style { Polite, Casual, Shout }` | the texts `"Polite"`, `"Casual"`, `"Shout"` |
| `public static int Add(int a, int b)` | `new Greeter().Add(20,22)` |
| `bool TryDivide(double a, double b, out double result)` | a list `[worked, result]` |
| `public event EventHandler<string> Greeted;` | `oGreeter.setGreetedEvent("code")` |

### Overloads and named arguments

`Hello` has two versions. The plain name `Hello` takes **one parameter**: `NULL` calls the version without parameters; a list of `:name = value` calls the version with those parameter names. The `style` parameter is optional in C# (`Style style = Style.Polite`), so you may leave it out: `Hello([ :name = "Cy" ])`.

### Events

`setGreetedEvent("nTimes++ ? ...")` gives Ring code to run each time the C# code raises `Greeted`. The code reads `aDotNetArgs`, which is `[sender, eventArgs]`: here the event argument is the greeting text. Remember that event code sees only global variables (`nTimes` is global at the top of the program).

### What the wrapper made

Open `Greeter/classes/Tutorial.Greetings/Greeter.ring`: it is a plain Ring class with one method per C# method. Nothing is hidden.

## Using a NuGet package

A package is a set of `.dll` files, and the .NET SDK can get it and its dependencies for you with a project file and `dotnet publish`. The tutorial [A NuGet package](tut-162-nuget.html) shows it for a real package, and then the steps are the same: `wrapassembly.ring`, `dnLoad`, `dnImportFrom`. See also [Your own assemblies](own-assemblies.html).

## What you learned

- wrap → load → use,
- C# properties, overloads, statics, `out`, events and enums map to Ring as shown,
- you can use any .NET library without writing C#.

## Exercises

1. Add a property `Prefix` (default `"Hello"`) to `Greeter` and use it in `Hello`. Rebuild, rewrap, run.
2. Add a method `Repeat(string text, int times)` and call it with named arguments.
3. Find a small NuGet package (for example a text or math helper), copy its DLL, wrap it and call one method.

## Next

[The generic functions](tut-160-generic-calls.html)
