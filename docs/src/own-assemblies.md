---
title: Your own assemblies
lead: Wrap any .NET DLL — your own library or a NuGet package — with one command, and use its classes with the same simple syntax as the built-in ones.
---

## Two ways to use an assembly

| Way | When |
|---|---|
| **Generic calls** — `dnLoad`, `dnType`, `dnNew`, `callMethod` | a quick call, nothing to generate |
| **Generated classes** — `wrapassembly.ring` | the simple `oObj.Method()` syntax, properties, events, enums, inheritance |

## Generic calls

```ring
load "dotnet.ring"
dnLoad("path/to/MyLibrary.dll")                       # dependencies are found next to the dll

oCalc = dnNew("MyCompany.Tools.Calculator",[10])
oCalc.callMethod("Add",[5])
? oCalc.getProp("Total")                              # 15
? dnStatic("MyCompany.Tools.Calculator","Square",[7]) # 49
```

## Generated classes

Generate Ring classes for every public type of the DLL:

```bash
cd tools/dotnettools
ring wrapassembly.ring path/to/MyLibrary.dll ../../myclasses
```

This writes two files for each namespace into `myclasses/`: a loader and the classes (and `classindex.ring`, the index of the classes, when every namespace is wrapped). Use them like any other wrapped namespace:

```ring
load "dotnet.ring"
dnLoad("path/to/MyLibrary.dll")
dnImportFrom("myclasses/","MyCompany.Tools")

oCalc = new Calculator()
oCalc.Add(10).Multiply(3)                             # fluent: methods that return a wrapped class return that class
? oCalc.Total                                         # 30
oCalc.Name = "mine"                                   # a property
? new Calculator().Square(7)                          # a static method
? oCalc.Describe([ :level = "High", :prefix = "Sum" ])                      # an enum as a string, an optional parameter
aDivide = oCalc.TryDivide(4)                          # out parameters come back in a list
? aDivide[2]
```

The generated classes support the same things as the built-in ones: real inheritance, properties as attributes, `setXXXEvent()` for events, enums as strings, overloads as one method with a hash list of parameters (`Name([ :param = value ])`), optional parameters and `out` / `ref` results.

### The example in the package

`samples/UsingDotNet/tests/UserLib` is a complete example — a small C# library, the generator run on it, and a test that uses it (`samples/UsingDotNet/tests/test_userassembly.ring`).

{{source:samples/UsingDotNet/tests/UserLib/Library.cs}}

{{source:samples/UsingDotNet/tests/test_userassembly.ring}}

## NuGet packages

A NuGet package is a set of DLL files. Let the .NET SDK collect them: a project file with a `PackageReference` and `dotnet publish -o libs` copy the package and the DLLs it depends on into one folder. Then wrap and load as above:

```bash
ring wrapassembly.ring libs/Newtonsoft.Json.dll ../../json
```

```ring
dnLoad("libs/Newtonsoft.Json.dll")
dnImportFrom("json/","Newtonsoft.Json.Linq")      # a namespace that needs another namespace of the same DLL loads it from the same folder
dnImportFrom("json/","Newtonsoft.Json")
```

The tutorial [A NuGet package](tut-162-nuget.html) walks through this with a real package.

A package often needs other DLLs and, sometimes, native libraries. `dotnet publish` copies both: the native libraries are in `runtimes/<system>-<architecture>/native` next to the DLL, and the bridge finds them there. The lessons from [A NuGet package](tut-162-nuget.html) on use real packages: [A QR code](tut-165-qr.html), [Excel files](tut-167-excel.html), [Pictures on every system](tut-168-pictures.html), [PDF files](tut-169-pdf.html), [Text to speech](tut-170-speech.html), and [a project with three packages](tut-171-csv-to-excel.html).

A class of your assembly that derives from a class of a package (`PersonValidator : AbstractValidator<Person>`) derives from its Ring class when the package was wrapped into the same folder **before** your assembly, so it has the methods of the base class, and the extension methods of the interfaces that the base class implements (`oValidator.ValidateAndThrow(oPerson)`). Its loader loads the namespace of the base class first.

Two DLLs of one program can share the output folder: a class of the second one that has the name of a class that is already in the folder gets the prefix of its namespace (`Spectre.Console` and `Spectre.Console.Testing` both have a `StringExtensions`; the second is `TestingStringExtensions`). Two DLLs that have the same namespace need folders of their own, or only one of them wrapped: a DLL whose classes you do not call (an extension method that you call by `dnRequest`) only needs `dnLoad`.

Entity Framework Core is wrapped the same way — that is how its classes were generated.

## Extension methods

An extension method of a type that is wrapped in the same run is a method of the Ring class of that type, so a fluent API reads as it does in C#:

```ring
oTable = new Table()
oTable.AddColumn("Name")            # TableExtensions.AddColumn(oTable, "Name")
oTable.AddRow(["Ann","31"])
```

The classes that implement an interface get the extension methods of the interface. `wrapassembly.ring` wraps one assembly at a time, so the extension methods of a type of **another** assembly (a sink of Serilog that extends a class of Serilog itself), and of a type that has no class (a generic type, `string`), are static calls: `new StringHumanizeExtensions().Humanize("PascalCaseText")`.

## Which namespaces to wrap

`wrapassembly.ring <dll> <folder> [namespace ...]` wraps only the namespaces you list. Without names, every namespace of the assembly is wrapped.

Several assemblies can go into one folder (the index of the classes keeps the types of all of them when each one is wrapped without names), or each one into a folder of its own, as the project lesson does for its three packages. An object that comes back from a namespace that was not imported is wrapped when the folder has the index: its namespace is loaded from that folder.

## Rules

- Generated loaders use the names of the .NET classes. When a class name is also the name of a class of the library, or of another namespace of the same assembly, the generator adds the prefix of its namespace (`CoreVersion`) and lists the renames — see [Class generator](generator.html).
- Keep the DLL and its dependencies in one folder: assemblies are resolved next to the DLL you load.
- The runtime mode matters: a DLL that needs Windows Forms requires the desktop mode first (a `using` block that names `System.Windows.Forms`, or `dnUseDesktop()`).

## Where to go next

- [Class generator](generator.html): how the wrapper classes are made, and how to make more.
- The tutorial chapter [Libraries and packages](tutorials.html#libraries-and-packages).
