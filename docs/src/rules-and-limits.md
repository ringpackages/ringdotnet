---
title: Rules and limits
lead: How Ring behaves when it works with .NET objects, why, and what to write — plus what RingDotNet does not support.
---

## Ring rules for .NET code

### Use parentheses with `new` when you pass arguments

`new StringBuilder("x")` — **with** parentheses, because Ring calls `init()` only then. A class without arguments works both ways (`new MemoryStream`, `new MemoryStream()`). For `StringBuilder`, `Random` and `Version`, which take an optional first argument, write `new StringBuilder` or `new StringBuilder("x")`, not `new StringBuilder()`.

### Strings and numbers

`"text" + number` works. `number + "text"` needs the number as text first: write `string(n) + " items"`.

### Event code can only see global variables

The code of an event (`setClickEvent("...")`) runs outside the function that set it up. Create the widgets and the program state as **globals** at the top, then assign them inside `func main`:

```ring
oForm = ""
oCount = ""
nClicks = 0

func main
	oForm = uiForm("Counter",260,130)
	oCount = uiLabel(oForm,"0",20,15,220,24)
	uiButton(oForm,"Click",20,50,100,32,"nClicks++ oCount.Text = '' + nClicks")
```

### Names inside braces belong to the object first

In `oForm { Text = cTitle }` Ring looks for `Text` and `cTitle` as members of `oForm` before it looks for variables. A variable named like a member of the object (`text`, `width`, `count`...) is then read as that member. Use prefixed names (`cText`, `nWidth`) for your variables.

### Put the program in functions

In Ring a **global variable named like an attribute** (`x`, `width`, `text`...) is read first when `obj.x` is evaluated, and a function that assigns a name that exists as a global changes that global. Write `func main` and keep only what event code needs global.

### Keywords are not available as names

`ok`, `step`, `from`, `to`, `load`, `call`, `get`, `set`, `put`, `on`, `off`... are Ring keywords, so they are not used as variable or function names, in any letter case. `oK` is `ok`. This is about your own names. In the generated classes a method that Ring reserves after a dot gets an `@` at the start (`@ForEach`, `@Next`), and a property with such a name is read with `getProp` and set with `setProp`.

Do not define your own functions named like built-ins the library uses (`isNumber`, `len`...).

### Define functions after the main code

A `func` at the top of a file takes the rest of the file as its body. Put the main code first (or put it in `func main` and call it at the end).

### `new StringBuilder(NULL)` for the parameterless constructor

Ring checks the number of arguments of `init()`. The classes whose `init` takes a value (`StringBuilder`, `Random`, `Version`) therefore use `NULL` for the parameterless constructor: `new StringBuilder(NULL)`, `new Random(NULL)`. With a value it is as usual: `new StringBuilder("Hello")`, `new Random(42)`.

### A variable name that starts like a keyword

Ring names are not case sensitive and the words `or`, `if`, `to`, `in`, `do`... are keywords. `oR = new StreamReader(...)` is read as `or = ...`, so such names are written longer (`oReader`, `oRd`).

### Using objects during definition: `x = new Class().Method(x)`

This is a **Ring feature** (since Ring 1.19, [Using objects during definition](https://ring-lang.github.io/doc1.28/oop.html#using-objects-during-definition)): in an assignment `x = new Class(...)`, the new object is stored in `x` *first*, so that it can be used while the rest of the expression is evaluated. Then the rest of the expression runs (a method call, an operator) and its result is stored in `x` again. This makes it possible to use the object (for example with an overloaded operator) during its own definition, but it means that the variable you are assigning already holds the **new object** when the arguments are evaluated:

```ring
cText = new Regex("a").Replace([ :input = cText, :replacement = "b" ])      # error: cText already holds the Regex object
cResult = new Regex("a").Replace([ :input = cText, :replacement = "b" ])    # works: a different variable
```

Write the result to a **different** variable (see the tutorial [A project: Markdown to HTML](tut-47-markdown.html)).

### A list of `[text, value]` pairs passed alone is read as named arguments

A method with overloads reads a single list of `[text, value]` pairs as **named arguments**. `Serialize([["Buy milk",1],["Walk",0]])` would look for a parameter called "Buy milk". Put something that is not a text first in each pair, or wrap the list in another list, so that it is passed as a value (the tutorial [A project: a to-do list that remembers](tut-24-todo.html)).

### Side effects inside `for ... in call()`

When the expression of a `for x in oDb.migrate()` has side effects, assign it to a variable first:

```ring
aChanges = oDb.migrate()
for cChange in aChanges
	? cChange
next
```

### `dnNull()`

`dnNull()` is the .NET null: `oPictureBox.Image = dnNull()`. A method that returns null gives an object that is the null: `dnIsNull(value)` is true for it and false for any other value, whatever its type.

## .NET rules

### Put the `using` block before the first .NET call

The runtime mode (desktop, web, both) is chosen by the `using { }` block (or by `dnUseDesktop()`, `dnUseWeb()`, `dnUseAll()`) and must come **before any other .NET call**: the first call starts the runtime and the mode does not change afterwards. If a program needs both Windows Forms/WPF and ASP.NET Core, name both in the first `using` block.

### Callbacks run on the Ring thread only

Events from timers on other threads (`System.Threading.Timer`, `Task.Run(...)`) do not run Ring code; they print a message on stderr instead. Use the Windows Forms `Timer` (`uiTimer`) or wait for tasks on the Ring thread. The web server queues requests for the same reason.

### Value types are returned by value

`oForm.Location` returns a copy of the `Point`. Change it by assigning a new value: `oForm.Location = new Point(10,20)`.

### Enums are strings

`oForm.WindowState = "Maximized"`, `oForm.FormBorderStyle = "FixedDialog"`.

### Binary data

A Ring text can hold any byte (a NUL, bytes that are not valid UTF-8), so a `byte[]` that .NET returns is a Ring text and nothing is lost; a text that is passed to a `byte[]` parameter becomes the same bytes. Only the Entity Framework layer is different: `bytes` columns are hex texts.

A method that **fills** an array that you pass in (`Stream.Read(buffer, 0, n)`, `Socket.Receive`) needs a live array, because a Ring text is copied when it goes in and a returned array is copied when it comes out. Use a byte buffer: `oBuffer = dnBuffer(1024)`, `n = oStream.Read(oBuffer, 0, 1024)`, `cBytes = dnBufferBytes(oBuffer, n)`. The same object is the way to pass a `byte[]` where the parameter has the type `object`.

### Tracked EF rows

`RingDatabase.byKey` returns the tracked row. After a raw SQL change (`execute`, `apply`) call `discard()` to read the new values.

## Limits

| Not supported | Why / what to do |
|---|---|
| Declaring .NET classes or interfaces in Ring | Ring is not compiled to .NET. Write them in C#, build a DLL and [wrap it](own-assemblies.html). |
| .NET members named like some Ring words (`Get`, `And`, `Or`, `Not`, `Next`, `End`, `If`, `For`, `New`, `Load`, `Call`, `Put`, `Give`, `See`) | Ring reserves these after a dot (others, such as `From`, `To`, `Set`, `Step`, `In`, `On`, `Off`, are fine). A method gets an `@` at the start (`@Next`, `@Call`); a property is read with `getProp("Name")` and `setProp("Name", value)`; a method that kept its name is called with `callMethod`. |
| Ring code on .NET threads | One Ring thread. Use callbacks only during calls, or queue work as the web server does. |
| Holding a `ref` struct, a `Span<T>` or a pointer in a Ring variable | They live on the stack of a call, so Ring cannot keep them. The bridge makes them for the call from values (a text, bytes, a list, an address or a buffer) and answers what they hold (an array, a text, a list of items). What a method does to a ref struct is lost, and the address of a buffer is valid during the call only: [Advanced .NET types](advanced-types.html). |
| Lambdas and expression trees written in Ring | Callbacks give delegates; EF queries are data ([Entity Framework](ef.html)). |
| Linux/macOS Windows Forms and WPF | Those frameworks are Windows-only. The rest of the bridge is tested on Linux (Ubuntu 24.04, x64) as well as on Windows; macOS is not tested yet. |
| EF providers other than SQLite and in-memory | Loaded by name from their packages; untested. |
| MVC controllers and Razor written in C# | The web server is the Ring one. |

## Troubleshooting

| Message | Cause |
|---|---|
| `Runtime Error in loading the dynamic library` | `ring_dotnet.dll` is not on the PATH. Add the package `bin` folder, or install the package into the Ring folder. |
| `DotNet Error: No generated classes for the namespace X` | the name is wrong, or the namespace is not in the manifest — see [Class generator](generator.html). |
| `Error in property name, property not found: x` | a global variable named like the attribute, or an object that is a plain `DotNetObject` (use `getProp("x")`). |
| `Calling function with less number of parameters` | a constructor that needs arguments: `new DateTime(2024,12,25)`; or an overloaded method called with no argument: write `NULL` (`oList.Sort(NULL)`). |
| `Calling function with extra number of parameters` | a method that has overloads takes one argument: a value, `NULL`, or a list of `:name = value`; for several arguments in order use `callMethod("Name",[a, b])` ([Core concepts](concepts.html#arguments-in-order-with-callmethod)). |
| `Calling Method without definition: name` | the object is a plain `DotNetObject` that has no class for its type: use `callMethod("Name",[...])` and `getProp("Name")`; or the name is a Ring keyword: use `@Name`. |
| `Object does not support operator overloading` | the value is a .NET array or collection that came back as an object: `toList()` copies it into a Ring list. |
| `Trying to destroy the object using the self reference` | an attribute of a library class has the same name as a global variable of your program. |
| An event handler does nothing | the code uses a local variable — only globals are visible; or the handler runs on another thread. |
| `The callback '...' was ignored` | a callback fired outside a call or from another thread. |

Set `RINGDOTNET_TRACE=1` to see the .NET stack trace of an error.

## Where to go next

- [Function index](reference.html) and the [Class reference](api.html): look up a function or a class.
- [Core concepts](concepts.html): the naming rules behind most of the points above.
- [Quick introduction to Ring](ring-intro.html): if the problem is the language and not .NET.
