---
title: Class generator
lead: How the wrapper classes are made, how to add namespaces, closed generic types and overload preferences, and how to regenerate them.
---

## What the generator does

`tools/gendotnet.ring` reads the **manifest** (`tools/dotnetmanifest.ring`), loads the assemblies, and uses reflection to write Ring source:

```text
libraries/dotnetlib/generated/
	System.ring                     # the namespace loader: imports, registrations
	System.classes.ring             # all the classes of the namespace (one file: loading and installing thousands of small files is slow)
	System.IO.ring
	System.IO.classes.ring
	...
	classindex.ring                 # [type, namespace] of every class: automatic imports
```

The class files are plain Ring: a `Class X from Base` with a method per .NET method, `getX`/`setX` for properties, `setXEvent` / `clearXEvent` for events and registration with `dnRegisterClass`. The files are generated: **do not edit them**.

## Regenerate

```bash
cd tools
ring gendotnet.ring                       # every namespace of the manifest
ring gendotnet.ring System.Text System.IO # only these
```

## The manifest

Each entry describes one namespace:

| Key | Meaning |
|---|---|
| `:namespace` | the .NET namespace, also the name used with `using { "..." }` |
| `:assemblies` | assemblies that contain the types (default `System.Private.CoreLib`) |
| `:all` | `true` wraps every public class and struct of the namespace |
| `:exclude` | type names that `:all` must skip |
| `:types` | explicit or extra types: `[.NET name, Ring class name, init() parameter count]` — closed generic types and nested types go here |
| `:prefer` | `["Namespace.Type.Method=arity"]` — the overload that gets the plain name |
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

When two namespaces contain a class with the same short name, the later one gets a prefix: `System.Timers.Timer` becomes `TimersTimer`, WPF's `Button` becomes `WpfButton`, ASP.NET's `MediaTypeHeaderValue` becomes `AspMediaTypeHeaderValue`, EF's clashing names start with `Ef`.

## Overload rules

The generator names overloads so that the **plain name** is the most useful one:

- the parameterless form wins when the type has one (`Cancel()`, `Wait()`, `Reverse()`), except `Write*` methods;
- otherwise the shortest overload is the plain name;
- overloads whose parameters are arrays (except `byte[]` / `char[]`), delegates, comparers or spans never decide the plain name;
- all other overloads are `Name_N` where N is the parameter count;
- `ToString()` keeps its parameterless form;
- a method with optional parameters is available with every number of parameters from the required ones up;
- a static and an instance method with the same name and arity are one method;
- names that are Ring keywords get a trailing `_`.

`:prefer` overrides the choice for a method.

## How a wrapper class looks

```ring
Class StringBuilder from Object

	Func Append P1
		return dnRequest("call",[self,"Append",P1])

	Func getLength
		return dnRequest("get",[self,"Length"])

	Func setLength P1
		dnRequest("set",[self,"Length",P1])
```

Ring calls `getLength()` when you read `oSB.Length`, and `setLength(value)` when you assign to it.

## Wrapping your own assembly

`tools/wrapassembly.ring` uses the same generator for a single DLL: [Your own assemblies](own-assemblies.html).
