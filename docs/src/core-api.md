---
title: Core functions
lead: The functions for loading assemblies, creating objects without wrapper classes, calling static methods, and the DotNetObject methods that every wrapped object has.
---

## Runtime

### dnVersion()

Returns the version of the .NET runtime hosted in the process.

```ring
load "dotnet.ring"
? dnVersion()          # .NET 9.0.15
```

### dnUseDesktop(), dnUseWeb(), dnUseAll(), dnUseData()

Select the runtime mode before the first .NET call. You normally do not call them: the `using { }` block calls the right one when it sees the namespaces (see [Getting started](getting-started.html#the-startup-modes)).

## Importing classes

| Function | What it does |
|---|---|
| `using { "System" "System.Text" }` | Loads the generated wrapper classes of each namespace (once), like C#'s `using`. A value that is not a text raises an error. |
| `dnImport("System.IO")` | The function behind `using`, handy when the name is computed. Returns true. Raises an error when no classes were generated for the name. |
| `dnImportFrom("myclasses/","MyCompany.Tools")` | Loads classes generated for **your own assembly** with `wrapassembly.ring`; the other namespaces of that assembly are loaded from the same folder when an object of one of their types comes back. See [Your own assemblies](own-assemblies.html). |
| `dnRegisterClass(type, class, nInit)` | Used by the generated files: registers a Ring class for a .NET type. |

```ring
using {
	"System"
	"System.Collections.Generic"
	"System.Text.RegularExpressions"
}
```

## Loading assemblies

| Function | What it does |
|---|---|
| `dnLoad("path/to/Library.dll")` | Loads an assembly from a path and returns its name. Its dependencies are found next to it. |
| `dnLoadName("System.Xml")` | Loads an assembly by name. |

## Without wrapper classes

Any type is usable without generated classes. The generated classes (`new X(...)`, `oObject.Method()`, braces) are the usual way to write code; these functions are for a type that has no class, or a constructor that `new` cannot choose:

```ring
# a type, for static members
oConsole = dnType("System.Console")
oConsole.callMethod("WriteLine",["Hello from .NET"])

# a static call in one line
? dnStatic("System.Math","Max",[3,9])                 # 9

# a new object
oSB = dnNew("System.Text.StringBuilder",["Hello"])
oSB.callMethod("Append",[", Ring!"])
? oSB.toString()                                      # Hello, Ring!
? oSB.getProp("Length")                               # 12
oSB.setProp("Capacity",64)
```

| Function | Returns |
|---|---|
| `dnType("Namespace.Type")` | a type object: use `callMethod` / `getProp` for static members |
| `dnNew("Namespace.Type", [args])` | a new object (the arguments are optional). The arguments may be **named**: `dnNew("DateTime",[ :year = 2024, :month = 12, :day = 25 ])` (see [Named arguments](concepts.html#named-arguments)), or the values in order: `dnNew("TimeSpan",[1,2,3])`; the type is a .NET type name or a Ring class name |
| `dnStatic("Namespace.Type", "Method", [args])` | the result of a static method (with no arguments, a static property or field of that name too: `dnStatic("System.Math","PI",[])`) |
| `dnNewGeneric("System.Collections.Generic.List", ["System.Int32"], [args])` | an object of a closed generic type |
| `dnGenericName(type, [typeArguments])` | the .NET name of a closed generic type |
| `dnDescribe("Namespace.Type")` | the public API of a type (used by the generator) |
| `dnNull()` | the .NET null |
| `dnBuffer(size)` / `dnBuffer(bytes)` | a byte buffer: a .NET object with a live `byte[]`, for methods that fill an array (`Stream.Read`) |
| `dnBufferBytes(oBuffer, nCount)` | the first `nCount` bytes of a buffer as a Ring text |
| `dnBufferSize(oBuffer)` | the size of a buffer in bytes |

## DotNetObject

Every .NET object that Ring holds is a `DotNetObject` (the generated classes derive from it):

```ring
oObject.callMethod("Method",[arg1,arg2])    # call a method
oObject.callGeneric("Method",["System.Int32"],[arg1])    # a generic method with its type arguments
oObject.getProp("Name")                      # read a property or field
oObject.setProp("Name",value)                # write it
oObject.toString()                           # ToString()
oObject.typeName()                           # "System.Text.StringBuilder"
oObject.toList()                             # an array or a collection as a Ring list
oObject.isNull()                             # true for the .NET null
oObject.release()                            # release the handle
```

`oObject.nHandle` is the handle number.

## dnRequest

`dnRequest(operation, params)` sends one request to the bridge; everything above is built on it. The operations include `type new newnamed call callnamed get set tostring typename tolist describe load loadname release version`, among others that the generated classes use. You normally never need it. The generated methods do not even go through it for the common calls: they use the native functions `dotnet_call`, `dotnet_callv` and `dotnet_callo` ([How it works](how-it-works.html)).

## Callbacks

`dnCallback(code)` passes Ring code where a delegate is expected. See [Callbacks & events](callbacks-events.html).

## Test helpers

```ring
dnAssert("name", actual, expected)      # counts a pass or prints FAIL: name expected <..> got <..>
dnTestSummary()                         # prints "TESTS: n passed, m failed"
```

`nDotNetPass` and `nDotNetFail` hold the counters. See [Testing](testing.html).

## Where to go next

- [Collections & LINQ](collections-linq.html): lists, dictionaries and queries.
- [Callbacks & events](callbacks-events.html): passing Ring code to .NET.
- The tutorial [The generic functions](tut-160-generic-calls.html) shows when each of these functions is needed; the programs of the tutorials otherwise use the generated classes (`new`, the dot and braces).
