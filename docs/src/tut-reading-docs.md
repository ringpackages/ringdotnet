---
title: Reading the .NET documentation
lead: Everything .NET can do is documented on Microsoft Learn. This page shows how to find a class there and turn what you read into Ring code.
---

## Where the documentation is

The official reference is **Microsoft Learn → .NET API browser** (search for "learn.microsoft.com dotnet api"). Every class has a page. For example the page of `System.Text.StringBuilder` lists its constructors, properties, methods and events, with a short description and a C# example for each.

RingDotNet also has its own [class reference](api.html) with the same information written for Ring: every member shows **how to call it from Ring**. Use it first; use Microsoft Learn when you want the long explanation.

## How to find the class you need

1. **Think about the job**: "read a file" → files; "split a date" → dates; "send a web request" → HTTP.
2. **Search by words** in the search box of this site (press `/`) or on Microsoft Learn: `read text file C#`. The answer almost always names a class: `File`, `StreamReader`...
3. **Look at the namespace** shown on the page title: `System.IO.File` means the namespace is `System.IO`.
4. **Check that the class is wrapped**: open `api/System.IO.html` in the [class reference](api.html), or search the class name.

## Reading a class page

A Microsoft page for a method looks like this (shortened):

```text
File.ReadAllText(String)          → String
File.ReadAllText(String, Encoding) → String
```

and a C# example:

```csharp
string text = File.ReadAllText(@"C:\notes.txt");
Console.WriteLine(text);
```

### From C# to Ring

| In C# | In Ring |
|---|---|
| `using System.IO;` | `using { "System.IO" }` |
| `var f = new FileInfo(path);` | `oFile = new FileInfo(cPath)` |
| `File.ReadAllText(path)` | `new File().ReadAllText(cPath)` (a static method is called on `new File()`) |
| `text.Length` (a property) | `oText.Length` |
| `list.Add("x")` (a method) | `oList.Add("x")` |
| `button.Click += handler;` (an event) | `oButton.setClickEvent("handler()")` |
| `DayOfWeek.Monday` (an enum) | `"Monday"` (a text) |
| `Math.Round(x, 2)` | `oMath.Round([ :value = x, :digits = 2 ])` |
| `int.TryParse(s, out n)` (an `out` parameter) | `aResult = new Int32().TryParse(cText)` → `[worked, number]` |
| `null` | `dnNull()` |
| `new DateTime(2024, 12, 25)` | `new DateTime(2024,12,25)` |
| `new Point { X = 1, Y = 2 }` | `new Point(1,2)` |

### Overloads: one name, different parameters

C# lets the same method name have several versions (*overloads*) with different parameters. Ring does not. RingDotNet handles it like this:

- a name with several forms becomes **one method that takes one value**: `NULL` for the form without parameters, a value for the form with one parameter, and
- a list of **named arguments** for the others: `oMath.Round([ :value = 3.14159, :digits = 2 ])`. The names are the parameter names that you read in the documentation.

The [class reference](api.html) shows, for every method, the **Ring calls** next to the **.NET overloads**, so you never have to guess. [Core concepts](concepts.html#naming-rules) lists the rules.

## A complete example

Task: "get the file name from a path". Search → `Path.GetFileName` in `System.IO`.

The documentation says: `public static string GetFileName(string path)`. It is *static*, so on a `new Path()` object, and it takes one text:

```ring
using { "System.IO" }

oPath = new Path()
? oPath.GetFileName("c:/work/report.txt")       # report.txt
```

## When a class is not wrapped

Everything in the base library and in Windows Forms, WPF, ASP.NET and Entity Framework is wrapped. Other packages can be wrapped in one command: [Your own assemblies](own-assemblies.html). Without wrapping, `dnType("Namespace.Type")` and `dnNew(...)` still reach any .NET type: [Core functions](core-api.html).

## Next

Start the first lesson: [A first look](tut-01-first-look.html).
