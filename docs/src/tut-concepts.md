---
title: .NET for Ring programmers
lead: What .NET is and the words you will meet when you use it. Read this once; come back when a word is not clear.
---

## What is .NET?

**.NET** is a large collection of ready-made code from Microsoft, plus the program that runs it. You do not write that code — you *use* it. Instead of writing your own function to read a file, compress a folder, hash a password or talk to a web server, you ask .NET to do it. RingDotNet lets a Ring program ask.

Two things make up .NET:

| Part | What it is | Analogy |
|---|---|---|
| The **runtime** | The engine that loads and runs .NET code. RingDotNet starts it *inside* your Ring program. | The Ring virtual machine |
| The **class library** | Thousands of classes: text, numbers, files, networking, windows, databases... | Ring's built-in functions, but much larger |

```ring
load "dotnet.ring"
using { "System" }
? new Environment().Version.ToString()   # the runtime that is running inside your Ring program
```

```output
9.0.15
```

## Classes and objects

Almost everything in .NET is an **object**. An object has **data** and **abilities**; the **class** is the description that the objects are made from — like a recipe and the cakes baked from it.

```ring
using { "System.Text" }

oText = new StringBuilder("Hello")      # create an object of the class StringBuilder
```

You already know this from Ring: Ring has classes and objects too (`class`, `new`). The difference is that these classes were written by Microsoft, in C#, and live in .NET.

## Properties, methods and events

An object has three kinds of members:

| Member | What it is | In Ring | Example |
|---|---|---|---|
| **Property** | something the object *knows* (a value you read or change) | `oObject.Name` and `oObject.Name = value` | `oForm.Text = "Hello"` |
| **Method** | something the object *can do* | `oObject.Name(arguments)` | `oText.Append("!")` |
| **Event** | something that *happens*, to which you react | `oObject.setNameEvent("code")` | `oButton.setClickEvent("clicked()")` |

## Static members: no object needed

Some classes are just a toolbox of functions. Their members are **static**: you call them on the class, without creating an object. `Math` is the classic example: you never create "a math".

```ring
using { "System" }
? new Math().Max(3,9)       # a static method (Ring creates a harmless helper object to call it)
? new Math().PI             # a static property
```

In the [class reference](api.html) a static member is marked *static*.

## Namespaces and assemblies

.NET has thousands of classes, so they are organized:

- A **namespace** is a folder of classes with a dotted name: `System.IO` holds the file classes, `System.Text` holds the text classes, `System.Windows.Forms` holds the window classes.
- An **assembly** is a file (a `.dll`) that contains the compiled classes. You rarely need to think about it.

In Ring you bring a namespace in with `using`:

```ring
using {
	"System.IO"
	"System.Text"
}
```

After that the classes of that namespace are available by their short name: `File`, `Path`, `StringBuilder`.

## Value types: structs and enums

Most types are classes. Two kinds of types are special:

- A **struct** is a small *value*: `DateTime` (a date and time), `TimeSpan` (a duration), `Point` (x and y). You use it like an object, but copying it copies the value.
- An **enum** is a list of named choices: the day of the week (`Monday`, `Tuesday`...), a window state (`Normal`, `Maximized`). **In Ring an enum value is a text**: `oForm.WindowState = "Maximized"`.

## null

**null** means "no object". A method that finds nothing may return null. An object that you got from .NET can be asked `oObject.isNull()`, and `dnIsNull(value)` asks it of any value.

## Exceptions

When something goes wrong — the file does not exist, the text is not a number — .NET raises an **exception**. In Ring an exception is a normal Ring error, and you catch it with `try` ... `catch`. The tutorial [When things go wrong](tut-07-errors.html) explains this.

## Generics and collections

A **collection** holds many items. .NET has a list (`List`), a dictionary (`Dictionary`), a set, a queue and a stack. They are *generic*: the same class works for any type of item (`List<string>`, `List<int>`). RingDotNet gives you ready names for the common ones: `StringList`, `NumberList`, `StringDictionary`... The tutorial [Collections and LINQ](tut-04-collections.html) shows them.

## The words around .NET

| Word | Meaning |
|---|---|
| **C#** | The main language that .NET code is written in. You do not need to learn it to use .NET from Ring, but the documentation shows C# examples. |
| **SDK** | The *software development kit*: the compiler and tools for **writing** .NET programs. You only need it to build C# code (the tutorial [A library written in C#](tut-18-csharp-library.html)) and to get NuGet packages (the tutorial [A NuGet package](tut-162-nuget.html)). |
| **Runtime** | What is needed to **run** .NET programs. RingDotNet needs the runtime (and the desktop or ASP.NET runtime for windows and web). |
| **NuGet** | The package store of .NET. A NuGet package is a set of `.dll` files that you can wrap and use: [A NuGet package](tut-162-nuget.html). |
| **BCL** | The *base class library*: the part of .NET that every program has (`System`, `System.IO`, `System.Text`...). |
| **Windows Forms / WPF** | Two ways to build windows. The tutorial [Your first window](tut-11-first-window.html) and [WPF](tut-15-wpf.html). |
| **ASP.NET Core** | The web framework. The tutorial [A web service with a database](tut-16-web-service.html). |
| **Entity Framework** | The database library. The tutorial [Databases step by step](tut-17-databases.html). |

## How Ring and .NET meet

Ring and .NET are two different systems. RingDotNet is the bridge between them:

- A Ring **text** becomes a .NET string, a Ring **number** becomes a .NET number, a Ring **list** becomes an array.
- A .NET **object** comes back to Ring as a Ring object with the same name as the .NET class.
- A .NET **enum** is a text, a .NET **bool** is `1` or `0`.
- Ring code runs on **one thread**; .NET may use many. Code that .NET wants to call back into Ring runs on the Ring thread.

Read [How it works](how-it-works.html) when you want the details.

## Next

[Reading the .NET documentation](tut-reading-docs.html) shows how to find a class on Microsoft Learn and use it from Ring.
