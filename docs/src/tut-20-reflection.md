---
title: "Exploring .NET with reflection"
lead: You do not have to guess what a class can do. A program can ask: this lesson lists the properties, methods and parameters of a class, and shows where to find the same information in the manual.
---

## What you will learn

- what *reflection* is,
- how to get a `Type` from a name or from an object,
- listing properties, methods and their parameters,
- enums and their values,
- where the manual gets its class reference from.

## Reflection

*Reflection* means that a program looks at its own types: names, members, parameters. .NET offers it in the class `Type` and the namespace `System.Reflection`. It is how the class reference of this manual was made: a Ring program asked every wrapped class what it contains.

## The program

{{file:samples/UsingDotNet/tutorials/t20_reflection.ring}}

{{output:samples/UsingDotNet/tutorials/t20_reflection.ring}}

## How it works

### A Type

A `Type` describes a class. Two ways to get one:

```ring
oType = new Type().GetType([ :typeName = "System.Text.StringBuilder" ])    # from the full name
oType = oObject.GetType()                                               # from an object that exists
```

Its properties say what it is: `FullName`, `Namespace`, `IsClass`, `BaseType`, `Assembly`.

### Properties and methods

`GetProperties(NULL)` and `GetMethods(NULL)` return arrays of `PropertyInfo` and `MethodInfo`; `toList()` turns an array into a Ring list. Each has a `Name`. A `PropertyInfo` has `PropertyType` and `CanWrite`; a `MethodInfo` has `GetParameters()`, whose items have `ParameterType` and `Name`.

A method name appears **once per overload**, so the program collects *distinct* names. `StringBuilder.Append` has 20 versions with one parameter alone: one per type that can be appended. This is why Ring offers one `Append(value)`: the bridge looks at your value and calls the right version.

### Enums

`Enum.GetNames(oType)` lists the names of an enum type. These are exactly the texts that you use in Ring: `"Monday"`, `"Sunday"`.

### dnDescribe

`dnDescribe("System.Math")` is what the class generator uses. It returns lists: the constructors, methods, members, the indexer and events. You rarely need it; the reflection classes above are friendlier.

## Using the manual instead

You often need only to *look*. The [class reference](api.html) shows, for every wrapped class, its constructors, properties, methods with the **Ring calls**, and events — produced by exactly this kind of reflection. Use search (`/`) to jump to a class by name.

## What you learned

- reflection lets a program inspect types,
- `GetProperties`, `GetMethods`, `GetParameters`,
- overloads show up as repeated names,
- the class reference is made from reflection.

## Exercises

1. List the public properties of `System.IO.FileInfo` and which of them can be written.
2. Print every overload of `Math.Round` with its parameter types and names. How many are there?
3. List the values of `System.IO.FileAttributes`.
4. Write a function `describe(cTypeName)` that prints the name, the base type and the number of methods and properties of any type.

## Next

[A project: an object inspector](tut-151-inspector.html)
