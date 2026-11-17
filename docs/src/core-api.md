---
title: Core functions
lead: The functions for loading assemblies, creating objects without wrapper classes, calling static methods, and the DotNetObject methods that every wrapped object has.
---

## Runtime

### dnVersion()

Returns the version of the .NET runtime hosted in the process.

```ring
load "dotnetlib.ring"
? dnVersion()          # .NET 9.0.15
```

### dnUseDesktop(), dnUseWeb(), dnUseAll(), dnUseData()

Select the runtime mode before the first .NET call. See [Getting started](getting-started.html#the-startup-modes).

## Importing classes

| Function | What it does |
|---|---|
| `dnImport("System.IO")` | Loads the generated wrapper classes of a namespace (once). Returns true. Raises an error when no classes were generated for the name. |
| `using { "System" "System.Text" }` | The same as `dnImport` for each text, written like C#'s `using`. A value that is not a text raises an error. |
| `dnImportFrom("myclasses/","MyCompany.Tools")` | Loads classes generated for **your own assembly** with `wrapassembly.ring`. See [Your own assemblies](own-assemblies.html). |
| `dnRegisterClass(type, class, nInit)` | Used by the generated files: registers a Ring class for a .NET type. |

```ring
dnImport("System")
dnImport("System.Collections.Generic")
dnImport("System.Text.RegularExpressions")
```

## Loading assemblies

| Function | What it does |
|---|---|
| `dnLoad("path/to/Library.dll")` | Loads an assembly from a path and returns its name. Its dependencies are found next to it. |
| `dnLoadName("System.Xml")` | Loads an assembly by name. |

## Without wrapper classes

Any type is usable without generated classes:

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
| `dnNew("Namespace.Type", [args])` | a new object (the arguments are optional) |
| `dnStatic("Namespace.Type", "Method", [args])` | the result of a static method |
| `dnNewGeneric("System.Collections.Generic.List", ["System.Int32"], [args])` | an object of a closed generic type |
| `dnGenericName(type, [typeArguments])` | the .NET name of a closed generic type |
| `dnDescribe("Namespace.Type")` | the public API of a type (used by the generator) |
| `dnNull()` | the .NET null |

## DotNetObject

Every .NET object that Ring holds is a `DotNetObject` (the generated classes derive from it):

```ring
oObject.callMethod("Method",[arg1,arg2])    # call a method
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

`dnRequest(operation, params)` sends one request to the bridge; everything above is built on it. The operations are `type new call get set tostring typename tolist describe load loadname release version`. You normally never need it.

## Callbacks

`dnCallback(code)` passes Ring code where a delegate is expected. See [Callbacks & events](callbacks-events.html).

## Test helpers

```ring
dnAssert("name", actual, expected)      # counts a pass or prints FAIL: name expected <..> got <..>
dnTestSummary()                         # prints "TESTS: n passed, m failed"
```

`nDotNetPass` and `nDotNetFail` hold the counters. See [Testing](testing.html).
