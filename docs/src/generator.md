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
	classindex.ring                 # [type, namespace] of every class: automatic imports
```

The class files are plain Ring: a `Class X from Base` with a method per .NET method, `getX`/`setX` for properties, `setXEvent` / `clearXEvent` for events and registration with `dnRegisterClass`. The files are generated: **do not edit them**.

## Regenerate

```bash
cd tools/dotnettools
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

The generator names the methods of a class like this:

- a name with overloads of **several parameter counts** is one method that takes one parameter: `NULL` calls the parameterless overload, a list of `:name = value` pairs chooses the overload by the parameter names, and any other value calls the overload with one parameter;
- a name with **one parameter count** keeps its parameters (`Math.Max(a, b)`); the bridge picks among overloads with the same count by the types of the values;
- the constructors other than `init` are `New_`;
- `ToString()` keeps its parameterless form, and its forms with parameters are `Format`;
- a method with optional parameters is available with every number of parameters from the required ones up;
- a static and an instance method with the same name and arity are one method;
- names that are Ring keywords get a trailing `_`, and so does a method whose name would be the getter or setter of a property (`GetValue_`).

## How a wrapper class looks

```ring
Class StringBuilder from Object

	Func Append P1
		dn_nTarget = nHandle
		return dnRequest("call",[new DotNetObject(dn_nTarget),"Append",P1])

	Func getLength
		return dnRequest("get",[self,"Length"])

	Func setLength P1
		dnRequest("set",[self,"Length",P1])
```

Ring calls `getLength()` when you read `oSB.Length`, and `setLength(value)` when you assign to it. A method makes its target from a **local copy** of the handle (`dn_nTarget`): the arguments of `new DotNetObject(...)` are read together with the new object, and a name that is an attribute of both objects (`nHandle`) could be looked up in the wrong one after an error that was caught. A property accessor passes `self`, so it needs no copy.

## Wrapping your own assembly

`tools/dotnettools/wrapassembly.ring` uses the same generator for a single DLL: [Your own assemblies](own-assemblies.html).

## Where to go next

- [Testing](testing.html): how the package and your own programs are tested.
- [Function index](reference.html) and the [Class reference](api.html): what has been generated.
