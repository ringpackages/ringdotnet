---
title: "Expression trees"
lead: An expression tree is code stored as data. This lesson builds functions from parts — parameters, additions, comparisons, method calls — prints them as readable code, compiles them and calls them. It is how a program can run a formula that the user typed.
---

## What you will learn

- code as data: a tree of objects (`System.Linq.Expressions`),
- `Parameter`, `Add`, `Multiply`, `Constant`, `Condition`, `@Call`, `Lambda`,
- `ToString()` of a tree and `NodeType`,
- compiling a tree (`Compile`) and calling the function,
- building a tree from something the program receives at run time.

Entity Framework builds its queries the same way (the tutorial [Entity objects and migrations](tut-27-entities.html)): a condition is first a *tree*, which can be turned into SQL, and only a compiled tree is a function you can run.

## The program

{{file:samples/UsingDotNet/tutorials/ch13_expressions.ring}}

{{output:samples/UsingDotNet/tutorials/ch13_expressions.ring}}

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnStatic`, `dnNewGeneric`, `callMethod`, `getProp`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### The class name

The static factory class of the namespace is `Expression`; another namespace already has a class with that name, so in Ring it is **`ExpressionsExpression`** (see [Rules and limits](gotchas.html)). `new ExpressionsExpression()` is only a handle to reach the factory methods (`Add`, `Lambda`, …).

### Nodes

Every part of the code is a node made by a factory method:

| Node | Made by | Looks like |
|---|---|---|
| a parameter | `Parameter([ :type = ..., :name = "a" ])` | `a` |
| a number | `Constant(10.0)` | `10` |
| an operation | `Add`, `Subtract`, `Multiply`, `Divide` with `:left` and `:right` | `(a + b)` |
| a comparison | `GreaterThan([ :left = ..., :right = ... ])` | `(a > b)` |
| a decision | `Condition([ :test = ..., :ifTrue = ..., :ifFalse = ... ])` | `IIF((a > b), a, b)` |
| a call of a .NET method | `@Call([ :instance = dnNull(), :method = ..., :arguments = [...] ])` | `Sqrt(x)` |

The factory methods have several forms, so they take a list of named values ([Core concepts](concepts.html)); `Call` is a Ring keyword and becomes `@Call`. The .NET type of a parameter is a `Type`: `dnType("System.Double")` gives it, and `new Type().GetType("System.Math").GetMethod("Sqrt")` gives the method object that `@Call` needs.

### Show, compile, call

`ToString()` prints the tree as code: `(a, b) => ((a + b) * 10)`; `NodeType` names the kind of the top node (`Add`). `Lambda([ :body = …, :parameters = [oA, oB] ])` ties a body to its parameters, and `Compile(NULL)` turns the tree into a real function of the runtime. The result is a `Func<double, double, double>`; call it with `callMethod("DynamicInvoke",[[2, 3.5]])` — the list inside the list is the array of arguments. Numbers come back as Ring numbers.

> [!NOTE] A typed function like this is called with `DynamicInvoke`. Each call crosses the bridge, so the compiled function is *not* faster than Ring for a single call; the gain is for trees that run inside .NET (a LINQ filter over a million rows, an EF query) or that are called very often from .NET code.

### Built from data

Step 5 receives only the *name of an operator* (`"+"`, `"-"`, `"*"`, `"/"`) and builds the function for it. A formula parser such as the tutorial [An expression calculator](tut-54-expression.html) could produce the same kind of tree from the text of the user, and the result would be a compiled function. This is the use of expression trees: the program does not know the code in advance.

> [!WARNING] A tree built from a user's text can do whatever the nodes allow, including calling methods. Only allow the nodes that your formula language needs (arithmetic, comparisons) and never let a user choose the method of a `@Call`.

## What you learned

- code as a tree of objects,
- the factory methods and their named values,
- `ToString`, `NodeType`, `Lambda`, `Compile`, `DynamicInvoke`,
- building a function from run-time data.

## Exercises

1. Build `a * a - b` and compile it.
2. Build a function that returns `a` when `a` is positive and `0 - a` otherwise (the absolute value).
3. Extend the helper `binaryFunction` with `%` (`Modulo`) and `>` (`GreaterThan`).
4. Turn the parser of the tutorial [An expression calculator](tut-54-expression.html) into a function that returns a tree instead of a number.

## Next

[A library written in C#](tut-18-csharp-library.html)
