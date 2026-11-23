---
title: Core concepts
lead: How .NET looks from Ring — class and method names, overloads, properties, enums, struct values, generics, out parameters and errors. The types that need more are on the page Advanced .NET types.
---

## Classes with the same names as .NET

After `using { "Namespace" }` every public type of that namespace is a Ring class with the **same short name** and the same members:

```ring
using { "System.Text" }

oSB = new StringBuilder("Hello")        # with arguments: parentheses (Ring calls init() only with them)
oSB.Append(", Ring").Append("!")        # methods that return a wrapped class return that class
? oSB.ToString()
? oSB.Length                            # properties and fields are attributes
new Console().WriteLine("Hi")           # static members are called on an instance
? new Math().Max(3,9)
```

{{output:samples/UsingDotNet/introduction/test02_simple.ring}}

> [!NOTE] **With arguments, write the parentheses**: `new StringBuilder("Hello")`. Ring calls `init()` only when they are there. A class that needs no argument can be written with or without them, `new MemoryStream` or `new MemoryStream()`: Ring runs the code of the class body in both cases, and the class makes its default .NET object there. A few classes have a first constructor parameter that you may leave out (`StringBuilder`, `Random`, `Version`): for them write `new StringBuilder` (the default object) or `new StringBuilder("text")`; `new StringBuilder()` with empty parentheses is an error ("less number of parameters").

Inheritance is real: `Button` derives from `ButtonBase`, `Control` and so on, so a method defined on the base class works on every derived object.

When two namespaces have a class with the same short name, the later one gets the last part of its namespace as a prefix (`WpfButton`, `TimersTimer`): the [Class reference](api.html) shows the name of every class, and [Class generator](generator.html) explains the rule.

## Short names for static classes

A class such as `Math`, `Path` or `File` has only static members, so `new Math()` just makes an object that gives access to them. If you prefer the .NET style, make that object once at the top of the program and give it the name of the class:

```ring
load "dotnet.ring"

using { "System" "System.IO" }

Math = new Math()
Path = new Path()

func main

	? Math.Max(3,9)                          # 9
	? Path.Combine(["a","b"])                # a\b
	? new Math().Min(3,9)                    # the class is still there: 3
```

The names of Ring variables are not case sensitive, so a variable `path` is the same name as `Path`, and a local variable with that name **hides** the object in its function:

```ring
func fileName

	path = "C:/temp/x.txt"
	return Path.GetFileName(path)            # Error (R13): Object is required (Path is now the text)
```

Names such as `Path`, `File`, `Directory`, `Console`, `Environment` and `Convert` are also the names that programs use for variables, so use this style only when you keep those names for the .NET classes. Only classes that have just static members suit it: `DateTime`, `String`, `Task` and `Process` also have instance members, and `new DateTime(...)` is how you make a value.

## Naming rules

A Ring method has one name and one parameter list, so a .NET method name that has **several overloads** becomes **one Ring method with one parameter**; you choose the overload with the value you pass (see *Named arguments* below). A name with a single form keeps the .NET parameters.

| .NET | Ring | Rule |
|---|---|---|
| `Append()`, `Append(string)`, `Append(char, int)` | `Append(NULL)`, `Append("x")`, `Append([ :value = "x", :repeatCount = 3 ])` | One method: `NULL` = no parameters, a value = one parameter, a **list of `:name = value`** = the overload with those parameter names. |
| `Math.Max(a, b)` | `Max(3,9)` | A name with only one number of parameters stays positional. |
| `Console.WriteLine("x")` | `WriteLine("x")` | An overloaded name works like `Append`. |
| `Next()`, `Next(int)`, `Next(int,int)` | `@Next(NULL)`, `@Next(10)`, `@Next([ :minValue = 1, :maxValue = 10 ])` | A name that is a Ring keyword gets an `@` at the start. |
| `Serialize(value, options = null)` | `Serialize(value)`, `Serialize([ :value = v, :options = o ])` | **Optional parameters** can be left out of the list. |
| `Path.Combine(a, b, c)` | `Combine([ :path1 = a, :path2 = b ])` or `Combine([a, b, c])` | A `params` array takes a plain list, a single value (an array of one item), or nothing (it is empty). |
| `new MemoryStream(bytes)` | `new MemoryStream().@New([ :buffer = bytes ])` or `dnNew("MemoryStream",[ :buffer = bytes ])` | Constructors: `init()` is the parameterless (or shortest) one; the others are chosen by name with `@New`. |
| `date.ToString("yyyy-MM-dd")` | `oDate.Format("yyyy-MM-dd")` or `oDate.Format([ :format = "d", :provider = oCulture ])` | `ToString()` keeps its plain form; its forms with parameters are `Format`. |

The bridge still **picks the real overload from the argument types**: whole numbers prefer `int`, strings prefer `string`, a .NET object prefers its own type.

## Named arguments

Optional and overloaded parameters are written in Ring as a **list of `:name = value` pairs**. When a method has overloads with different numbers of parameters, its plain name takes **one parameter** and looks at what you pass:

| You pass | What happens |
|---|---|
| `NULL` (an empty string) | the **parameterless** overload is called: `oProcess.Start(NULL)` |
| a list of `:name = value` pairs | the overload is chosen by the **parameter names** of the .NET method; the order does not matter and optional parameters can be left out |
| anything else | the overload with **one parameter** is called: `oMath.Round(2.5)` |

```ring
oMath = new Math()
? oMath.Round(2.5)                                            # one argument: 2 (Round goes to the even neighbor)
? oMath.Round([ :value = 3.14159, :digits = 2 ])              # 3.14
? oMath.Round([ :digits = 1, :value = 2.74 ])                 # 2.70 : any order (Ring shows two decimals; the value is 2.7)

oRandom = new Random(42)
? oRandom.@Next(NULL)                                         # no arguments: the parameterless Next()
? oRandom.@Next([ :maxValue = 10 ])                           # by name: a number from 0 to 9

oSB = new StringBuilder("a")
oSB.Append([ :value = "b" ])
? oSB.ToString()                                              # ab

oTime = new TimeSpan().@New([ :hours = 1, :minutes = 2, :seconds = 3 ])   # a constructor chosen by names
? oTime.ToString()                                            # 01:02:03
oSB = dnNew("StringBuilder",[ :value = "Hello" ])             # the same with the generic function (it names the class as a text)
```

Rules and limits:

- **`NULL` for no arguments.** A Ring call passes the number of arguments the method declares, so on an overloaded method the parameterless form is called with `NULL`: `oTask.Wait(NULL)`, `oList.Sort(NULL)`. A method that has no overloads still takes no argument: `oTimer.Start()`. The same rule holds for **constructors**: `init()` has one parameter list, so a class whose `init` takes one value (`StringBuilder`, `Random`, `Version`) creates the parameterless object with `NULL`: `new StringBuilder(NULL)`, `new Random(NULL)`, `new Version(NULL)`. Other constructors: `@New([ :name = value ])`, `dnNew("Class",[ :name = value ])`, or `dnNew("Class",[ value1, value2 ])` with the values in order (`dnNew("TimeSpan",[1,2,3])` is `new TimeSpan(1,2,3)`). The function index and the class files show which is which.
- **A name whose overloads all have the same number of parameters** (`Math.Max(a,b)`) stays positional. The bridge picks among same-arity overloads by the types of the values.
- **`ToString` and `ToList` keep their plain forms**, because every object already has `toString()` / `toList()`. The forms of `ToString` with parameters are `Format`.
- A method whose Ring name would clash with the getter or setter of a property (the static `GetValue(property)` of a WPF element next to a property `Value`) gets an `@` at the start: `@GetValue(property)`.
- A name that matches no parameter, or a missing required parameter, raises an error that lists the names you gave. Names are not case sensitive.
- A list of `[string, value]` pairs passed as the single argument is read as named arguments.
- Names that are Ring keywords start with `@`, as C# writes `@class`: `oRnd.@Next([ :minValue = 1, :maxValue = 10 ])`, and so does `Init` (`init` is the constructor of a generated class): `oCipher.@Init(1,oParams)`. The words that Ring uses itself (`Get`, `Set`, `Call`) are called with `callMethod`.
- `dnNew("Class", ...)` takes a Ring class name or a full .NET type name.

## Arguments in order with `callMethod`

The plain name of an overloaded method takes one argument (`NULL`, a value or a named list). To pass several arguments in order, call the method with `callMethod(name, [arguments])`: the bridge chooses the overload from the arguments, as C# does.

```ring
oSB = new StringBuilder("")
oSB.callMethod("Append",["a",3])                             # Append(char, int): two arguments in order
? oSB.ToString()                                             # aaa
oRegistry.callMethod("SetValue",["Port",8080,"DWord"])       # three arguments in order (a Registry key, the tutorial "The Windows Registry")
oQuery.callMethod("Where",["Age",">",18])                    # the SqlKata package: a query that is built with calls in order
oRequest.callMethod("AddParameter",["page","2"])             # the RestSharp package: an extension method with the name of a method of the object
```

`callMethod` works on every object, also on one that has no generated class (a generic type), and finds the extension methods too. An extension method with the same name as a method of the object (`RestRequest.AddParameter(Parameter)` next to the extension `AddParameter(name, value)`) is not a method of the generated class, because an extension method never changes the signature of a method that the class already has; `callMethod` reaches it. `dnStatic(type, name, [arguments])` is the same call for a static method, and `getProp` and `setProp` read and write a property of an object that has no class.

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

Assigning a read-only property raises an error. Most properties named like Ring words (`From`, `To`, `Step`, `On`...) are read and set like any other (`oMessage.From = ...`). The few that Ring reserves after a dot (`Get`, `Next`, `End`, `Load`...) are read with `getProp("Name")` and set with `setProp("Name", value)`.

{{output:samples/UsingDotNet/introduction/test07_properties.ring}}

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

`dnNull()` is the .NET `null`. A .NET method that returns null gives an object whose `isNull()` is true, and `dnIsNull(value)` asks the same of any value: it is true for a null object and false for everything else (a number, a text, a list, an object that is not null), so it needs no check of the type first.

```ring
oValue = new Environment().GetEnvironmentVariable("NO_SUCH_VARIABLE")
if dnIsNull(oValue)
	? "not set"
ok
```

## `out` and `ref` parameters

A method with `out` or `ref` parameters returns a **list**: `[result, out values...]`:

```ring
aResult = oDict.TryGetValue("key")      # [1, value] or [0, the default of the type: 0 for a number, the null for a text]
if aResult[1]
	? aResult[2]
ok

aParsed = new Int32().TryParse("123")   # [1, 123]
```

## Extension methods

An extension method is a static method that C# writes as if it were a method of another type: `table.AddColumn("Name")` is `TableExtensions.AddColumn(table, "Name")` (this one is from the Spectre.Console package, which has to be wrapped first: [Your own assemblies](own-assemblies.html)). The generated Ring class of the extended type has a method for each extension method that is in the same generated set, so it is called like any method of the object. The classes that implement an interface get the extension methods of the interface, and so do the interfaces that inherit it (`oServices.BuildServiceProvider(NULL)` on a `ServiceCollection`, an extension of `IServiceCollection`):

```ring
oTable = new Table()
oTable.AddColumn("Name")                # TableExtensions.AddColumn(oTable, "Name")
oTable.AddRow(["Ann","31"])
```

An extension method of a **generic interface** (`ValidateAndThrow` extends `IValidator<T>`) is a method of the classes that implement it, and of the class of a generic type that derives from it; the generic interfaces of `System` (`IEnumerable<T>`, the LINQ methods) are not added to every collection class, they are called with `dnQuery` or `callMethod`.

An extension method of a **struct that it takes by reference** (`this in S`, as in the Sep library) and one of a **delegate type** (Sprache's `Parser<T>`, whose `AtLeastOnce()` and `Text()` are extension methods) are methods of the generated classes too: a delegate type has a Ring class only when extension methods extend it.

The methods of the object itself come first, and an extension method never changes how a method that the class already has is called: it is added to a name that the class has only when it takes a number of parameters that the method already takes. An extension method has the same rule of names as every method: when it has several forms, the name takes one parameter and the names of the parameters choose the form. Extension methods that have no class to join (a type of another assembly than the one that is wrapped, a generic type, `string`, `object` and the numbers) are static calls on the class that holds them: `new StringHumanizeExtensions().Humanize("PascalCaseText")`. A generic extension method whose type cannot be known from its parameters (`Cast<T>`) cannot be called from Ring.

## Interfaces and classes that are not public

Many methods return an interface (`IServiceScope`, `ICollection`) or an object of a class that is not public (a row of a database library, for example). The object is wrapped as the **interface named after the class** when there is one (`XLWorksheet` comes back as `IXLWorksheet`), otherwise as the most specific interface that has a Ring class. A wrapped interface has the members that it inherits from other interfaces (`oScope.Dispose()` from `IDisposable`, `oKeys.GetEnumerator()` on an `ICollection`), and the methods that a class implements explicitly are found through its public interfaces.

A parameter of the type `System.Enum` does not say which enum it takes, so the text gives the full name of the member: `"System.DayOfWeek.Friday"`.

## Generics

The most useful closed generic types have classes: `StringList`, `NumberList`, `ObjectList` (`List<T>`), `StringDictionary`, `NumberDictionary`, `ObjectDictionary` (`Dictionary<string,T>`), `StringSet`, `StringQueue`, `StringStack`. See [Collections & LINQ](collections-linq.html).

Any other closed generic type can be created without a class:

```ring
oList = dnNewGeneric("System.Collections.Generic.List",["System.Int32"],[])
oList.callMethod("Add",[5])
```

A generic type has a class of its own too (`new HashSet([ :typeArguments = ["System.Int32"] ])`), and a generic method whose type argument only the result shows takes `:typeArguments`. These, and the other types that need more than a plain class (nested types, operators, spans, ref structs, pointers, asynchronous streams), are on the page [Advanced .NET types](advanced-types.html).

## Numbers for an object

Ring has one kind of number. Where a .NET parameter has a type (`int`, `double`, `long`) the number becomes that type; where the parameter is an `object` (an argument of `String.Format`, an item of `params object[]`, a value of a `Dictionary<string, object>`), a **whole number is an `Int32`** and any other number is a `Double`. That is what `"{0:D3}"` and `"{0:X}"` need, and what JSON and a database write as `5`. A number beyond the range of `Int32` is a `Double`. For another exact type, `dnBox` makes the value:

```ring
? dnStatic("System.String","Format",["{0:D3} {1:X}",[7,255]])            # 007 FF
oTen = dnBox("System.Double",10)                                        # the Double 10, for a parameter of type object
oExpression.Constant(oTen)                                              # a constant of type double
```

## Return values

| .NET returns | Ring gets |
|---|---|
| `string` | string |
| numbers (`int`, `long`, `double`, `decimal` ...) | number |
| `bool` | `1` / `0` |
| enum | string |
| `byte[]` | string: a Ring text of bytes, binary safe (a copy) |
| arrays and collections (`string[]`, `List<T>`...) | a wrapped object; `toList()` copies it into a Ring list |
| any other object | a wrapped object (generated class, or a plain `DotNetObject`) |
| `null` | an object whose `isNull()` is true |

## Bytes and byte buffers

A Ring text can hold any byte, so a `byte[]` that .NET returns is a Ring text (`oStream.ToArray()`, `File.ReadAllBytes`, `BitConverter.GetBytes`), and a text that you pass to a `byte[]` parameter becomes the same bytes (`File.WriteAllBytes(path, cBytes)`, `stream.Write(cBytes, 0, len(cBytes))`). Both are **copies**.

A method that **fills** an array that you pass in has to work on the array itself, so it needs a byte buffer: an object that holds a live `byte[]`.

```ring
oBuffer = dnBuffer(1024)                  # a byte[] of 1024 bytes
n = oStream.Read(oBuffer, 0, 1024)        # .NET writes into the array
cBytes = dnBufferBytes(oBuffer, n)        # the first n bytes as a Ring text
```

`dnBuffer(text)` makes a buffer with the bytes of a text, and `dnBufferSize(oBuffer)` is its size. A buffer is accepted by every parameter of type `byte[]`, and by a parameter of type `object` (as the data of a registry `Binary` value). The test `test_binary.ring` shows `MemoryStream`, `FileStream` and a TCP stream.

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
| `callMethod(name, [args])` | call a method; the values are in order, also for a name that has several forms (`oKey.callMethod("SetValue",["Port",8080,"DWord"])`) |
| `getProp(name)` / `setProp(name, value)` | read or write a property or field |
| `toString()` | `ToString()` of the object |
| `typeName()` | full .NET type name |
| `toList()` | copy an array or collection into a Ring list |
| `isNull()` | true for the .NET null |
| `release()` | release the handle at once (Ring does it for you when the object is dropped; the object is not used after this) |

## Where to go next

- [Core functions](core-api.html): every function of the bridge in one place.
- [Advanced .NET types](advanced-types.html): generic types and methods, operators, spans, ref structs, pointers.
- [Collections & LINQ](collections-linq.html) and [Callbacks & events](callbacks-events.html): the two topics that need the most explanation.
- [Rules and limits](rules-and-limits.html): read it before a long program.
