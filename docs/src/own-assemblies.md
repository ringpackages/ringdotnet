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
load "dotnetlib.ring"
dnLoad("path/to/MyLibrary.dll")                       # dependencies are found next to the dll

oCalc = dnNew("MyCompany.Tools.Calculator",[10])
oCalc.callMethod("Add",[5])
? oCalc.getProp("Total")                              # 15
? dnStatic("MyCompany.Tools.Calculator","Square",[7]) # 49
```

## Generated classes

Generate Ring classes for every public type of the DLL:

```bash
cd tools
ring wrapassembly.ring path/to/MyLibrary.dll ../myclasses
```

This writes one loader per namespace and one file per class into `myclasses/`. Use them like any other wrapped namespace:

```ring
load "dotnetlib.ring"
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

The generated classes support the same things as the built-in ones: real inheritance, properties as attributes, `setXXXEvent()` for events, enums as strings, overload naming (`Name`, `Name_N`), optional parameters and `out` / `ref` results.

### The example in the package

`tests/UserLib` is a complete example — a small C# library, the generator run on it, and a test that uses it (`tests/test_userassembly.ring`).

{{source:tests/UserLib/Library.cs}}

{{source:tests/test_userassembly.ring}}

## NuGet packages

A NuGet package is a set of DLL files. Copy the DLLs of the package (for example from `~/.nuget/packages/<name>/<version>/lib/net8.0/`) and the DLLs it depends on next to each other, then wrap and load as above:

```bash
ring wrapassembly.ring Newtonsoft.Json.dll ../json
```

```ring
dnLoad("Newtonsoft.Json.dll")
dnImportFrom("json/","Newtonsoft.Json")
```

Entity Framework Core is wrapped the same way — that is how its classes were generated.

## Which namespaces to wrap

`wrapassembly.ring <dll> <folder> [namespace ...]` wraps only the namespaces you list. Without names, every namespace of the assembly is wrapped.

## Rules

- Generated loaders use the names of the .NET classes. When a class name is also a name Ring or another namespace already uses, the generator can add a prefix — see [Class generator](generator.html).
- Keep the DLL and its dependencies in one folder: assemblies are resolved next to the DLL you load.
- The runtime mode matters: a DLL that needs Windows Forms requires `dnUseDesktop()` first.
