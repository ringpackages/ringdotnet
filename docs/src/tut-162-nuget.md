---
title: "A NuGet package"
lead: Most useful .NET libraries are NuGet packages. This lesson takes a real one, Newtonsoft.Json, from nuget.org to a Ring program in four steps - a project file, dotnet publish, the generator and new - and explains what to check for any other package.
---

## What you will learn

- what a NuGet package is and where its DLLs come from,
- a small **project file** that asks for a package, and `dotnet publish` that copies the package and what it needs into one folder,
- wrapping the DLL and loading its classes,
- calling the package like any other class,
- what to look at when a package does not work at once.

## What a package is

A **NuGet package** is a zip file with one or more DLLs (one set for each version of .NET it supports), and a list of other packages that it needs. [nuget.org](https://www.nuget.org) is the public place where packages are kept: a name and a version number find one, for example `Newtonsoft.Json` 13.0.3.

You do not unzip a package by hand. The .NET SDK does it: a **project file** names the packages, and `dotnet publish` downloads them (once; they are kept on your computer afterwards) and copies all the DLLs that the program needs into one folder. That folder is what Ring uses.

## The steps

1. **Ask for the package** in a project file.
2. **Publish**: `dotnet publish Packages -c Release -o Packages/libs` copies the package DLLs to `Packages/libs`.
3. **Wrap**: `ring wrapassembly.ring Packages/libs/Newtonsoft.Json.dll classes` writes the Ring classes.
4. **Load and use**: `dnLoad`, `dnImportFrom`, then `new ClassName`.

The earlier tutorial [A library written in C#](tut-18-csharp-library.html) does steps 3 and 4 for a library that you build yourself. Here the library comes from somebody else, so step 1 and 2 are new.

## The project file

This is all that a project needs to get a package. It is in `samples/UsingDotNet/tutorials/Packages`:

{{file:samples/UsingDotNet/tutorials/Packages/Packages.csproj}}

`PackageReference` is the line that names the package and its version. The project also needs one source file, even when you write no C#, so there is an empty class:

{{file:samples/UsingDotNet/tutorials/Packages/Empty.cs}}

To use another package, change the `Include` and `Version` values (nuget.org shows both on the page of every package), or run `dotnet add Packages package Name` and the SDK writes the line for you. You need the **.NET SDK** for this step only (`dotnet --version` prints its version); the finished program needs only the runtime and the DLLs.

## The Ring program

{{file:samples/UsingDotNet/tutorials/ch13_nuget.ring}}

{{output:samples/UsingDotNet/tutorials/ch13_nuget.ring}}

## How it works

### Why publish

The DLL of the package is in the folder where the SDK keeps packages, in a sub-folder for each .NET version it supports, and the packages that it needs are somewhere else. `dotnet publish` chooses the right DLLs for the .NET of the project and puts them **together** in `Packages/libs`. A library that is copied alone may stop at its first call because a DLL that it needs is missing. Keep the folder together, and give it to the people who use your program (the tutorial [Giving your program to others](tut-119-distribution.html)).

The DLL called `Packages.dll` that is also in the folder belongs to the empty project and is not used.

### One DLL, several namespaces

Newtonsoft.Json has the namespaces `Newtonsoft.Json` (for example `JsonConvert`) and `Newtonsoft.Json.Linq` (`JObject`, `JArray`, `JValue`). The generator writes one loader for each namespace, and `dnImportFrom(folder,"Newtonsoft.Json.Linq")` also loads the namespace that it needs. The program loads the other one too, because it uses `JsonConvert` from it.

### Static methods and overloads

`Parse` is a **static** method of `JObject`: Ring calls it on an object, `new JObject().Parse(cText)`. `Add` has several versions, so it takes a list of named values, `[ :propertyName = ..., :value = ... ]`, the same way as the methods of the C# library. A number that goes to .NET is a double, so `SerializeObject(42)` writes `42.0`. Names of parameters are in the class files that the generator wrote (`Packages/classes`) and in the documentation of the package.

## When a package does not work at once

| What you see | What to check |
|---|---|
| `dotnet publish` fails with `Unable to find package` | the name or the version, and that the computer is online the first time |
| the folder has no DLL with the name you expect | some packages are named after one name and hold DLLs with another: look in `libs` |
| `DotNet Error: Could not load file or assembly` at a call | a DLL that the package needs is not next to the others: publish again and copy the whole folder |
| a method is not found | the class that you used is in the other namespace: load it with `dnImportFrom` |
| `System.DllNotFoundException` | the package has a native library (`.dll` for Windows); it is in `libs/runtimes/...`, so keep that folder, and use the one for your system |
| the program needs a newer .NET | change `TargetFramework` in the project file to one that your computer has |

> [!TIP] Before you build a program around a package, write a ten-line Ring program that calls the one method that you need. If that works, the rest is the same work.

> [!NOTE] Look at the license of a package before you give your program to others: most are free to use, but each has its own terms, and they are shown on its page at nuget.org.

## What you learned

- a package is a set of DLLs on nuget.org, and a **project file** names the ones you need,
- `dotnet publish` copies a package with what it needs into one folder,
- wrap the DLL, load the namespaces with `dnImportFrom`, and call the classes like any other,
- a table of what to check when the first call fails.

## Exercises

1. Read the `Count` of `tags` and print every tag with a loop (`Item(0)`, `Item(1)`).
2. Read the `age` as a number, add one to it and print the result (`oObject.Item("age").ToString()` is a text; `number(...)` makes it a number).
3. Turn the text `[1,2,3]` into a `JArray` with `new JArray().Parse(...)` and print its `Count`.
4. Find another small package on nuget.org, name it in a second project file, publish it, wrap it and call one method.

## Next

[A QR code](tut-165-qr.html)
