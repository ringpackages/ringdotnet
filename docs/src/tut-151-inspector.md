---
title: "A project: an object inspector"
lead: Reflection lets a program look at any object: its type, its properties, their types and their values. This project builds an inspector with a combo box of objects and a list of the properties of the chosen one, and tests it by reading the list.
---

## What you will learn

- `GetType()` and `GetProperties()` on any object,
- reading a property from an object with `GetValue`,
- skipping **indexers** (`GetIndexParameters`),
- catching properties that cannot be read,
- showing values: a text or a number as it is, an object by its `ToString`,
- filling a `ListView` and finding a value in it for a test.

The tutorial [Reflection](tut-20-reflection.html) asked a *type* what it can do. An inspector asks an *object* what it is.

## The program

{{file:samples/UsingDotNet/tutorials/g151_inspector.ring}}

![The inspector](img/shots/tut-g151.png "The inspector showing a Uri")

{{output:samples/UsingDotNet/tutorials/g151_inspector.ring --selftest}}

## How it works

### Objects of any kind

The list `aObjects` has four objects of different classes: a `Uri`, a `DateTime`, a `FileInfo` and a `StringBuilder`. The inspector does not know which is which. It takes an object, asks `GetType()` for its type and `GetProperties(NULL)` for the properties of that type, and for each property `oProperty.GetValue(oObject)` gives the value that this object has now.

### Indexers

A property with parameters is an **indexer**: the property `Chars` of a `StringBuilder` needs a number (`sb[2]`). `GetIndexParameters()` lists the parameters, and a property that has any is skipped, because `GetValue(oObject)` without an index would raise an error. The test checks that `Chars` is not in the list.

### Errors

Some properties cannot be read for an object in some states (a file that does not exist has no `Length`). The read is in `try` and `catch`, the row shows *(cannot be read)*, and the status line counts the failed ones. An inspector must not stop at the first property that raises an error.

### Values

`showValue` writes a Ring text or number as it is and an object by its `ToString()`. A `Uri` has properties that are texts (`Host`, `Scheme`), numbers (`Port`) and booleans (`IsLoopback`, shown as 0 or 1 in Ring). A `DateTime` has `Year`, `DayOfWeek` (a text: *Saturday*) and `Date` (another `DateTime`, shown as text). The type column shows the .NET type of the property, so the list also teaches which type a property has.

### The list

The rows are made as `ListViewItem` with two sub items and sorted by the name of the property (a small bubble sort with `strcmp`, as in the tutorial [A list with columns](tut-134-listview.html)). Choosing another object in the combo box runs `inspect` again, which clears the list and fills it for the new object.

### The test

`valueOf("Host")` finds the row with that name and returns its value. The test checks values that it knows: the host, the port and the scheme of the address; the year, the day of the week and the hour of the date; the name and the length (16 bytes) of the file that the program wrote; and the length of the text of the builder. It selects each object through the combo box, so the change event is part of the test too.

> [!NOTE] This is the idea of the object inspectors of every debugger. A property can have side effects (it may start work), so inspecting a *foreign* object can change it; the properties of these four objects only read.

## What you learned

- `GetType()`, `GetProperties()` and `GetValue()`,
- indexers and errors in reflection,
- showing .NET values in a list,
- a test that reads the list.

## Exercises

1. Add the fields and the methods of the type in two more lists (or one list with a kind column).
2. Add a button that changes the value of a property that can be written (`CanWrite` and `SetValue`).
3. Inspect a `Form` and look for the property `Text`; change it and see the window.
4. Add a text box that filters the properties by a part of the name.

## Next

[Expression trees](tut-87-expressions.html)
