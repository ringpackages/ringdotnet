---
title: Class generator
lead: How the wrapper classes are made, how to add namespaces and closed generic types, how the overloads are named, and how to regenerate them.
---

## What the generator does

`tools/dotnettools/gendotnet.ring` reads the **manifest** (`tools/dotnettools/dotnetmanifest.ring`), loads the assemblies, and uses reflection to write Ring source:

```text
libraries/dotnetlib/generated/
	System.ring                     # the namespace loader: imports, registrations
	System.classes.ring             # all the classes of the namespace (one file: loading and installing thousands of small files is slow)
	System.IO.ring
	System.IO.classes.ring
	...
	classindex.ring                 # [type, namespace] of every class, one call with the whole list: automatic imports (loaded when first needed)
```

The class files are plain Ring: a `Class X from Base` with a method per .NET method, `getX`/`setX` for properties, `setXEvent` / `clearXEvent` for events and registration with `dnRegisterClass`. The files are generated: **do not edit them**.

## Regenerate

```bash
cd tools/dotnettools
ring gendotnet.ring                       # every namespace of the manifest
ring gendotnet.ring System.Text System.IO # only these
```

A run with names writes only those namespaces, and the base classes of the other namespaces are left out of its files: a class that derives from `Object` (the class of `System.Object`) derives from `DotNetObject` instead, and the line `dnImport("System")` is not written. The files of such a run are not the files of the full run, so run the command **without names** before you use or commit the result.

## Check a change of the generator

A rule of the generator, a change of the bridge or a new namespace changes the generated files, sometimes by thousands of lines. `checkgenerator.ring` makes the library again and checks the result before you commit it:

```
ring tools/dotnettools/checkgenerator.ring
```

It takes about a minute and a half. The checks:

1. the whole library is generated, without errors;
2. **the size of the change** of the generated files: files and lines against the last commit, and the kinds of line that changed. A small fix changes a few files; a rule that copies the methods of a base class into every derived class shows as hundreds of added lines. The limits are 15 files and 600 lines, and `--allow-large` is for a change that is meant to be big (a new rule). Read the kinds of line before you accept it;
3. `importall.ring` imports every namespace of the manifest, so every generated file loads;
4. the tests that use the generated classes the most (the library, extension methods, generic collections, keywords, your own assembly);
5. four package tests whose classes are made again by the new generator (fluent calls inside callbacks, a generic pipeline, properties named like Ring words, generic extension methods); `--all-packages` runs all of them;
6. the number of public types that have no class and are not left out on purpose (`auditcoverage.ring`: enums, delegates, ref structs and obsolete types need none) must not grow: it is 0 now, and the baseline is `tools/dotnettools/coverage-baseline.txt` (`--update-baseline` writes a new one). A type that is listed is usually in another assembly of a namespace that the manifest has: add that assembly to `:assemblies` of the namespace.

The exit code is 0 only when everything passed. Without a change, the generator makes exactly the files that are committed: a check that finds a difference in a clean tree means that the committed library is not the one of the generator.

## The manifest

Each entry describes one namespace:

| Key | Meaning |
|---|---|
| `:namespace` | the .NET namespace, also the name used with `using { "..." }` |
| `:assemblies` | assemblies that contain the types (default `System.Private.CoreLib`) |
| `:all` | `true` wraps every public class and struct of the namespace |
| `:exclude` | type names that `:all` must skip |
| `:types` | explicit or extra types: `[.NET name, Ring class name, init() parameter count]` — closed generic types and nested types go here |
| `:uses` | namespaces imported together with this one (their classes are returned by its methods) |
| `:extra` | Ring files the loader also loads (for example `linq.ring`) |
| `:prefix` | prefix for class names that clash with another namespace (default: the last part of the namespace) |
| `:desktop` | `true` when the namespace needs the Windows Desktop runtime |
| `:web`, `:data` | the namespace needs ASP.NET Core / the Entity Framework assemblies |

```ring
[ :namespace = "System.IO.Compression",
  :uses = ["System.IO"],
  :assemblies = ["System.IO.Compression","System.IO.Compression.ZipFile"],
  :all = true ],
```

## Closed generic types

The generic collections have classes through `:types`. Add your own with a line like:

```ring
["System.Collections.Generic.List`1[[System.Int32]]","IntList",0]
```

The third item forces the number of parameters of `init()` (0 here). After regenerating, `new IntList()` is a `List<int>`.

## Name clashes

The Ring class names are global. `wrapassembly.ring` (see [Your own assemblies](own-assemblies.html)) reserves the names of the library first, so a class of your assembly with the name of a class of the library gets the prefix of its namespace: `YamlDotNet.Core.Version` is `CoreVersion`, because `System.Version` is a class of the library. The generator lists the renames when it runs.

When two namespaces contain a class with the same short name, the later one gets a prefix: `System.Timers.Timer` becomes `TimersTimer`, WPF's `Button` becomes `WpfButton`, ASP.NET's `MediaTypeHeaderValue` becomes `AspMediaTypeHeaderValue`, EF's clashing names start with `Ef`.

## Overload rules

The generator names the methods of a class like this:

- a name with overloads of **several parameter counts** is one method that takes one parameter: `NULL` calls the parameterless overload, a list of `:name = value` pairs chooses the overload by the parameter names, and any other value calls the overload with one parameter;
- a name with **one parameter count** keeps its parameters (`Math.Max(a, b)`); the bridge picks among overloads with the same count by the types of the values;
- the constructors other than `init` are `@New`;
- `ToString()` keeps its parameterless form, and its forms with parameters are `Format`;
- a method with optional parameters is available with every number of parameters from the required ones up;
- a static and an instance method with the same name and arity are one method;
- names that are Ring keywords get an `@` at the start (a property too: the attribute `@Next` has the accessors `get@Next` and `set@Next`), and so does a method whose name would be the getter or setter of a property (`@GetValue`);
- an **extension method** of a type that has a class in the same run is a method of that class (`oTable.AddColumn("Name")` is `TableExtensions.AddColumn(table, "Name")`). The methods of the type come first, and an extension never changes how a method that the class already has is called: it is added to a name that the class has only when it takes a number of parameters that the method already takes. The classes that implement an interface get the extension methods of the interface, and so do the interfaces that inherit it. Generic extension methods whose type cannot be known from their parameters (`Cast<T>`) are left out. Extensions of types with no class in the run (generic types, `string`, types of another assembly in a run of `wrapassembly.ring`) stay static calls on their own class. A **delegate type** has a class only when extension methods extend it (a closed generic delegate such as Sprache's `Parser<IEnumerable<char>>` extends the class of its definition), and an extension method that takes its struct by reference (`this in S`) is a method of the struct's class.

## How a wrapper class looks

```ring
Class StringBuilder from Object

	Capacity
	MaxCapacity
	Length

	Func Equals P1

		dn_x = dotnet_call("s4:call",nHandle,"s6:Equals",P1)
		if islist(dn_x) return dnFinish(dn_x[2]) ok
		return dn_x

	Func Append P1

		if dotnet_isnamed(P1)
			dn_x = dotnet_calla("s9:callnamed",nHandle,"s6:Append",P1)
		if islist(dn_x) return dnAny(dn_x) ok
		return dn_x
		ok
		return dnObj(dotnet_callo("s4:call",nHandle,"s6:Append",P1))

	Func getLength

		dn_x = dotnet_call("s3:get",nHandle,"s6:Length")
		if islist(dn_x) return dnFinish(dn_x[2]) ok
		return dn_x
```

This is an extract of the class that is in `libraries/dotnetlib/generated/System.Text.classes.ring` (the real class has a method for every .NET method, an `init`, and the registration of the default object). Ring calls `getLength()` when you read `oSB.Length`, and `setLength(value)` when you assign to it. A generated method does not make a target object or a list for the request: it passes the handle as a number and the parts that never change (the operation `call` and the name) as ready wire items, and a C function of the extension packs the arguments, calls .NET and reads the answer:

- `dotnet_call` for a method that returns a **text, a number or a yes/no**: the answer is that Ring value.
- `dotnet_callv` for a method that returns **nothing**.
- `dotnet_callo` for a method that returns an **object**: it answers the type and the handle, and the Ring function `dnObj` makes the object of the generated class.
- The arguments can be texts, numbers, lists, .NET objects and callbacks; an error of .NET is raised as a Ring error. An answer that the function does not expect (null, for example) comes back as a list that `dnFinish` reads.
- The method of an **overloaded name** first asks the C function `dotnet_isnamed` whether the argument is a list of `[name, value]` pairs. If it is, the call is made with the operation `callnamed` (the bridge chooses the overload by the names), by `dotnet_call`, `dotnet_callv`, `dotnet_callo` or, when the overloads answer in different ways (a text for one, an object or a list for another), `dotnet_calla`.
- `dnSend` (the same request made in Ring) is used only for the methods that the generator finds no overload for.

## Wrapping your own assembly

`tools/dotnettools/wrapassembly.ring` uses the same generator for a single DLL: [Your own assemblies](own-assemblies.html).

## What the generator cannot wrap

`tools/dotnettools/auditassembly.ring` reports, for one or more assemblies, how much of their public API Ring can use and what gets in the way. It applies the rules of the bridge itself, so it says what the generator does:

```bash
ring auditassembly.ring Library.dll
```

Each line has a count, a tag and an example. The tags are `OK` (supported: wrapped classes, enums as texts, delegates as callbacks, extension methods, events), `INFO` (facts) or `GAP` (not usable today): operators that Ring has no syntax for (`++`, `op_True`) and the members of a ref struct that no value can make (a ref struct has to be made for the call from a text, bytes, a list or an object: [Advanced .NET types](advanced-types.html)). Spans, pointers, ref returns and asynchronous streams are `OK`. `tools/dotnettools/auditpackages.ring` restores a list of NuGet packages (`packages.txt`) and audits all of them together; `audit-baseline.txt` has the result of the last run.

## Where to go next

- [Testing](testing.html): how the package and your own programs are tested.
- [Function index](reference.html) and the [Class reference](api.html): what has been generated.
