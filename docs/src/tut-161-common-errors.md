---
title: "Common mistakes"
lead: Every beginner meets the same few error messages. This lesson makes each mistake on purpose, shows the message that Ring or .NET gives, says what it means and shows the fix. Keep it open the first time a program refuses to run.
---

## What you will learn

- how to tell an error of **Ring** from an error of **.NET** by its first words,
- the seven mistakes that cause most of the messages in the first weeks,
- what each message means and how to fix it,
- how to catch an error so that a program goes on.

## Two kinds of messages

| The message starts with | It comes from | Example |
|---|---|---|
| `Error (R..)` | Ring itself: the program called something that does not exist, or with the wrong number of values | `Error (R11) : Error in class name, class not found: stopwatch` |
| `DotNet Error:` | .NET: the call reached .NET and .NET refused it | `DotNet Error: System.ArgumentOutOfRangeException: Index was out of range...` |

A message of Ring is about the **shape** of the call (a name, a count of values). A message of .NET is about the **values** and the state of the objects (an index, a missing file, a text that is not a number). After `DotNet Error:` comes the name of the .NET exception, and its documentation (the tutorial [Reading the .NET documentation](tut-reading-docs.html)) tells more.

## The program

Each mistake is inside `try ... catch ... done`, so the program goes on and shows the next one. In your own program the same mistake stops the program and prints the same message with the line number.

{{file:samples/UsingDotNet/tutorials/ch13_common_errors.ring}}

{{output:samples/UsingDotNet/tutorials/ch13_common_errors.ring}}

## The mistakes, one by one

### 1. Class not found (R11)

`class not found: stopwatch` means that Ring has no class of that name. Either the name has a typing mistake, or the **namespace was not imported**. `Stopwatch` is in `System.Diagnostics`, and the program listed only `System`, `System.Text` and `System.Collections.Generic`. Add the namespace to `using { ... }` at the top. The [class reference](api.html) shows the namespace of every class.

### 2. `new Class()` with empty parentheses (R19)

`Calling function with less number of parameters` after `new StringBuilder()`: a wrapped class has one `init` that takes the first value of the constructor, and `()` passes nothing. Write `new StringBuilder` (no parentheses), `new StringBuilder(NULL)` or give the value, `new StringBuilder("x")`. For a constructor with several values use named values: `dnNew("Class",[ :name = value ])`.

### 3. An overloaded method with no argument (R19)

Most methods have several versions (overloads). Ring wraps them in **one** method with one parameter, so `oList.Sort()` has too few values. Pass `NULL` to call the version without parameters: `oList.Sort(NULL)`. A list of `:name = value` pairs calls the version with those parameter names. A method that has no overloads takes no value: `oTimer.Start()`.

### 4. A name with a typing mistake (R14 and R12)

`Calling Method without definition: ad` is a method that the class does not have, and `property not found: cuont` is a property. Ring does not mind upper and lower case, but it does mind every letter. Look the name up in the class reference. If the class is a .NET one, remember that the name in Ring is the name in .NET: a method that was `Add` in the documentation is `Add` here.

### 5. A .NET exception

`DotNet Error: System.ArgumentOutOfRangeException` is .NET telling that `Item(9)` is outside a list of two items. Other exceptions of the same family: `FileNotFoundException` (a missing file), `FormatException` (a text that is not a number), `NullReferenceException` (a call on a null). Check the condition before the call (`oList.Count`, `File.Exists`), or catch the error when the condition is not under your control (the tutorial [When things go wrong](tut-07-errors.html)).

### 6. A value of the wrong kind

`No public method System.Math.Sqrt matches the 1 argument(s)` means that .NET has a method of that name, but none that accepts **these** values: a text `"abc"` where `Sqrt` needs a number. Pass a value of the kind that the parameter has. The class reference lists the types of the parameters.

### 7. A .NET null (R50)

`GetEnvironmentVariable` returns **null** when the variable does not exist. The answer is an object, and `"text" + oVariable` is an operator that an object does not have (`Object does not support operator overloading`). Ask the object first: `oVariable.isNull()` is true for a null. Use it every time a method can return nothing (`Environment`, a dictionary lookup, a search that may not find).

## How to read a message

1. Read the **first words**: `Error (R..)` is the shape of the call, `DotNet Error:` is the values.
2. Read the **name** at the end of an R message (`stopwatch`, `ad`, `cuont`): it is the word that Ring did not know.
3. Read the **line** that Ring prints under the message: the first line is where the call is.
4. For a `DotNet Error:` read the exception name and the explanation, then look at the values that the call had.

## Check the list

| Message | Likely cause | Fix |
|---|---|---|
| `Error (R11) ... class not found` | typing mistake, or namespace not imported | the name, or `using { "Namespace" }` |
| `Error (R19) ... less number of parameters` | `new Class()`, or an overloaded method with no value | `new Class`, or `NULL` |
| `Error (R20) ... extra number of parameters` | too many values | one list of named values: `[ :a = 1, :b = 2 ]` |
| `Error (R14) ... Method without definition` | a method name that the class does not have | look up the name |
| `Error (R12) ... property not found` | a property name that the class does not have | look up the name |
| `Error (R50) ... operator overloading` | an object used as a text or a number (often a null) | `isNull()`, or read the value you need |
| `DotNet Error: ...MissingMethodException` | values of the wrong kind or count | match the types of the parameters |
| `DotNet Error: ...` another exception | the state or the values | read the exception name and check the values |

> [!TIP] When a call fails and the cause is not clear, make it **smaller**: call the same method in a short program with the plainest values. If that works, the difference between the two programs is the cause.

## What you learned

- `Error (R..)` comes from Ring and `DotNet Error:` from .NET,
- the seven common mistakes: a missing namespace, `new Class()`, an overload with no value, a typing mistake, a .NET exception, a wrong value, and a null,
- `NULL` for no values, `new Class` without parentheses, and `isNull()` for answers that can be null,
- `try ... catch ... done` shows a message without stopping the program.

## Exercises

1. Change a name in the program of an earlier lesson and read the message. Which of the seven is it?
2. Write a function `safeItem(oList, nIndex)` that returns `""` when the index is outside the list, using `try ... catch`, and another that checks `Count` first. Which one is shorter?
3. Find a .NET method that can return null (hint: ask `Environment` for a variable) and print `"missing"` when it does.
4. Call `Math.Max` with one value, with a text and with two numbers. Which messages do you get?

## Next

[A NuGet package](tut-162-nuget.html)
