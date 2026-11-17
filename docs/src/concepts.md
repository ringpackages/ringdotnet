---
title: Core concepts
lead: How .NET looks from Ring — class and method names, overloads, properties, enums, struct values, generics, out parameters and errors.
---

## Classes with the same names as .NET

After `dnImport("Namespace")` every public type of that namespace is a Ring class with the **same short name** and the same members:

```ring
using { "System.Text" }

oSB = new StringBuilder("Hello")        # use parentheses: Ring calls init() only with them
oSB.Append(", Ring").Append("!")        # methods that return a wrapped class return that class
? oSB.ToString()
? oSB.Length                            # properties and fields are attributes
new Console().WriteLine("Hi")           # static members are called on an instance
? new Math().Max(3,9)
```

{{output:samples/UsingDotNet/test02_natural.ring}}

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
| `new MemoryStream(bytes)` | `new MemoryStream().New_1(bytes)` or `dnNewWith("MemoryStream",[ :buffer = bytes ])` | Constructors: `init()` is parameterless (or the shortest), the others are `New_N`. |
| `ForEach`, `Exit`, `Step`, `Call` | `ForEach_`, `Exit_` ... | A name that is a Ring keyword gets a trailing underscore. |

The bridge still **picks the real overload from the argument types**: whole numbers prefer `int`, strings prefer `string`, a .NET object prefers its own type.

## Named arguments

Ring has no optional or overloaded parameters, but it has a natural replacement: a **list of `:name = value` pairs**. Every method that has overloads or optional parameters also exists in a `With` form that takes such a list. The names are the **parameter names of the .NET method**, the order does not matter, and optional parameters can be left out. The bridge picks the overload from the names:

```ring
oMath = new Math()
? oMath.RoundWith([ :value = 3.14159, :digits = 2 ])         # 3.14
? oMath.RoundWith([ :digits = 1, :value = 2.74 ])             # 2.7 : any order

oDate = new DateTime(2024,7,4)
? oDate.ToStringWith([ :format = "yyyy-MM-dd" ])              # 2024-07-04

oProcess = new Process().StartWith([ :startInfo = oInfo ])    # instead of Start_1(oInfo)

oSB = dnNewWith("StringBuilder",[ :value = "Hello" ])         # a constructor chosen by names
oDate = dnNewWith("DateTime",[ :year = 2024, :month = 12, :day = 25 ])
```

| | |
|---|---|
| `oObject.NameWith([ :param = value, ... ])` | the method `Name`, overload chosen by the parameter names (static methods too: `new Math().RoundWith(...)`) |
| `dnNewWith("Class", [ :param = value, ... ])` | a new object; the constructor is chosen by the parameter names. `Class` is a Ring class name or a full .NET type name |

A name that matches no parameter, or a missing required parameter, raises an error that lists the names you gave. Names are not case sensitive. The parameter names are shown by the .NET documentation and by `dnDescribe`; the `_N` forms stay available.

> [!TIP] Use named arguments when the plain call would need an `_N` name, or when a call has several arguments of the same kind and the names make it readable.

## Properties and fields are attributes

.NET properties are Ring attributes. Ring calls the generated `getName()` / `setName(value)` for you, so reading and writing is natural, also inside `{ }`:

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

Ring lets you write `{ }` after an object, and everything inside is evaluated **on that object**. It is the natural way to configure a .NET object, and all the samples in this documentation use it:

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
