---
title: Core concepts
lead: How .NET looks from Ring — class and method names, overloads, properties, enums, struct values, generics, out parameters and errors.
---

## Classes with the same names as .NET

After `using { "Namespace" }` every public type of that namespace is a Ring class with the **same short name** and the same members:

```ring
using { "System.Text" }

oSB = new StringBuilder("Hello")        # use parentheses: Ring calls init() only with them
oSB.Append(", Ring").Append("!")        # methods that return a wrapped class return that class
? oSB.ToString()
? oSB.Length                            # properties and fields are attributes
new Console().WriteLine("Hi")           # static members are called on an instance
? new Math().Max(3,9)
```

{{output:samples/UsingDotNet/test02_simple.ring}}

> [!NOTE] Always write `new StringBuilder(...)` **with parentheses**. In Ring, `new X` without them does not call the constructor.

Inheritance is real: `Button` derives from `ButtonBase`, `Control` and so on, so a method defined on the base class works on every derived object.

## Naming rules

Ring has no method overloading, so overloads get predictable names:

| .NET | Ring name | Rule |
|---|---|---|
| `Append()`, `Append(string)`, `Append(char, int)` | `Append`, `Append_1`, `Append_2` | The **plain name** is the parameterless form when the type has one, otherwise the shortest overload. The others are `Name_N` where N is the number of parameters. |
| `Console.WriteLine("x")` | `WriteLine("x")` | `Write*` methods keep the shortest overload with a parameter. |
| `Next()`, `Next(int)`, `Next(int,int)` | `Next`, `Next_1`, `Next_2` | `Name_N` counts parameters. |
| `Serialize(value, options = null)` | `Serialize(value)`, `Serialize_2(value, options)` | A method with **optional parameters** is available with every number of parameters from the required ones up. |
| `new MemoryStream(bytes)` | `new MemoryStream().New_1(bytes)` or `dnNew("MemoryStream",[ :buffer = bytes ])` | Constructors: `init()` is parameterless (or the shortest), the others are `New_N`. |
| `ForEach`, `Exit`, `Step`, `Call` | `ForEach_`, `Exit_` ... | A name that is a Ring keyword gets a trailing underscore. |

The bridge still **picks the real overload from the argument types**: whole numbers prefer `int`, strings prefer `string`, a .NET object prefers its own type.

## Named arguments

Ring has no optional or overloaded parameters, but it has a simple replacement: a **list of `:name = value` pairs**. When a method has overloads with different numbers of parameters, its plain name takes **one parameter** and looks at what you pass:

| You pass | What happens |
|---|---|
| `NULL` (an empty string) | the **parameterless** overload is called: `oProcess.Start(NULL)` |
| a list of `:name = value` pairs | the overload is chosen by the **parameter names** of the .NET method; the order does not matter and optional parameters can be left out |
| anything else | the overload with **one parameter** is called: `oMath.Round(2.5)` |

```ring
oMath = new Math()
? oMath.Round(2.5)                                            # one argument
? oMath.Round([ :value = 3.14159, :digits = 2 ])              # 3.14
? oMath.Round([ :digits = 1, :value = 2.74 ])                 # 2.7 : any order

oProcess = new Process()
oProcess.Start(NULL)                                          # no arguments: the parameterless Start()
oProcess = new Process().Start([ :startInfo = oInfo ])        # by name

oSB = new StringBuilder("a")
oSB.Append([ :value = "b" ])

oSB = dnNew("StringBuilder",[ :value = "Hello" ])             # a constructor chosen by names
oDate = dnNew("DateTime",[ :year = 2024, :month = 12, :day = 25 ])
```

Rules and limits:

- **`NULL` for no arguments.** Ring needs the right number of arguments, so on an overloaded method call the parameterless form with `NULL`: `oTask.Wait(NULL)`, `oList.Sort(NULL)`. A method that has no overloads still takes no argument: `oTimer.Start()`. The function index and the class files show which is which.
- **The plain name takes more than one parameter, or all overloads have the same number of parameters** (`Path.Combine(a,b)`, `Math.Max(a,b)`): the method stays positional. The bridge already picks among same-arity overloads by the types of the values.
- **`ToString` and `ToList` keep their plain forms**, because every object already has `toString()` / `toList()`. Use `ToString_1(format)`.
- A name that matches no parameter, or a missing required parameter, raises an error that lists the names you gave. Names are not case sensitive.
- A list of `[string, value]` pairs passed as the single argument is read as named arguments.
- Names that are Ring keywords end with `_`: `oRnd.Next_([ :minValue = 1, :maxValue = 10 ])`.
- `dnNew("Class", ...)` takes a Ring class name or a full .NET type name.

## Properties and fields are attributes

.NET properties are Ring attributes. Ring calls the generated `getName()` / `setName(value)` for you, so reading and writing is simple, also inside `{ }`:

```ring
oForm = new Form() {
	Text = "Hello"
	Width = 400
}
? oForm.Controls.Count                 # chained: Controls returns a ControlCollection
oForm { Height = 300  Text += "!" }
```

Assigning a read-only property raises an error. Properties whose names are Ring keywords (`From`, `To`, `Step`, `On` ...) are not attributes: use `getFrom()` / `setFrom(value)`.

{{output:samples/UsingDotNet/test07_properties.ring}}

## Braces instead of the dot operator

Ring lets you write `{ }` after an object, and everything inside is evaluated **on that object**. It is a simple way to configure a .NET object, and all the samples in this documentation use it:

```ring
oInfo = new ProcessStartInfo() {
	FileName = "cmd"
	Arguments = "/c ver"
	RedirectStandardOutput = True
	UseShellExecute = False
	CreateNoWindow = True
}
```

This is exactly the same as writing `oInfo.FileName = "cmd"` line by line. Inside the braces you can assign properties, call methods (`setClickEvent("...")`, `Controls.Add(oButton)`) and use `+=`. Use it on any object: `oForm { Height = 300 }`.

Use `True` and `False` for logical values; they are the numbers `1` and `0`, which is what .NET booleans become in Ring.

> [!WARNING] Inside the braces a **name is first looked up as a member of the object**. If a variable of your program has the same name as a property of the object (a global called `text`, `width` or `count`), the braces use the property, not your variable. Keep your own names Hungarian-style (`cText`, `nWidth`) and the problem never appears.

## Enums are strings

Enum values are strings in **both directions**:

```ring
oForm {
	WindowState = "Maximized"
	FormBorderStyle = "FixedDialog"
}
oDate = new DateTime(2024,12,25)
? oDate.DayOfWeek                       # "Wednesday"
oLabel.TextAlign = "MiddleCenter"
```

Flag combinations use the .NET text form: `"Top, Left"`.

## Value types and `dnNull()`

Structs (`Point`, `Size`, `Color`, `DateTime`) are objects like any other. Their constructors take the numbers: `new Point(10,20)`, `new DateTime(2024,12,25)`:

```ring
oButton {
	Location = new Point(10,20)
	Size = new Size(100,30)
}
oPictureBox.Image = dnNull()           # the .NET null
```

`dnNull()` is the .NET `null`. A .NET method that returns null gives an object whose `isNull()` is true.

## `out` and `ref` parameters

A method with `out` or `ref` parameters returns a **list**: `[result, out values...]`:

```ring
aResult = oDict.TryGetValue("key")      # [1, value] or [0, ""]
if aResult[1]
	? aResult[2]
ok

aParsed = new Int32().TryParse("123")   # [1, 123]
```

## Generics

The most useful closed generic types have classes: `StringList`, `NumberList`, `ObjectList` (`List<T>`), `StringDictionary`, `NumberDictionary`, `ObjectDictionary` (`Dictionary<string,T>`), `StringSet`, `StringQueue`, `StringStack`. See [Collections & LINQ](collections-linq.html).

Any other closed generic type can be created without a class:

```ring
oList = dnNewGeneric("System.Collections.Generic.List",["System.Int32"],[])
oList.callMethod("Add",[5])
```

Generic **methods** work too (the bridge infers the type arguments from the values), which is what makes LINQ possible.

## Return values

| .NET returns | Ring gets |
|---|---|
| `string` | string |
| numbers (`int`, `long`, `double`, `decimal` ...) | number |
| `bool` | `1` / `0` |
| enum | string |
| `byte[]` | string (binary safe) |
| arrays and collections of simple values | list (use `toList()` on a collection object) |
| any other object | a wrapped object (generated class, or a plain `DotNetObject`) |
| `null` | an object whose `isNull()` is true |

## Errors

A .NET exception becomes a Ring error and can be caught with `try` / `catch`:

```ring
try
	new Int32().Parse("abc")
catch
	? cCatchError
done
```

```output
DotNet Error: System.FormatException: The input string 'abc' was not in a correct format.
```

Set the environment variable `RINGDOTNET_TRACE=1` to get the .NET stack trace in the message.

## Plain objects

When no class exists for a type, or when you want the generic style, every wrapped object is also a `DotNetObject` and has:

| Method | What it does |
|---|---|
| `callMethod(name, [args])` | call a method |
| `getProp(name)` / `setProp(name, value)` | read or write a property or field |
| `toString()` | `ToString()` of the object |
| `typeName()` | full .NET type name |
| `toList()` | copy an array or collection into a Ring list |
| `isNull()` | true for the .NET null |
| `release()` | release the handle (rarely needed) |
