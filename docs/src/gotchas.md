---
title: Gotchas & limits
lead: The things that surprise people the first time, why they happen, and what to do — plus what RingDotNet does not support.
---

## Ring gotchas

### Use parentheses with `new`

`new StringBuilder("x")` — **with** parentheses. Without them Ring does not call `init()`.

### Strings and numbers

`"text" + number` works. `number + "text"` is an error. Write `string(n) + " items"`.

### Do not call a method on a new object on the right of an attribute assignment

```ring
oForm.Text = new Path().GetFileName(cFile)        # Ring loses the assignment!
```

Use a variable first:

```ring
oPath = new Path()
oForm.Text = oPath.GetFileName(cFile)
```

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

In `oForm { Text = cTitle }` Ring looks for `Text` and `cTitle` as members of `oForm` before it looks for variables. A variable named like a member of the object (`text`, `width`, `count`...) is then not what you expect. Use prefixed names (`cText`, `nWidth`) for your variables.

### Put the program in functions

In Ring a **global variable named like an attribute** (`x`, `width`, `text`...) makes `obj.x` fail, and a function that assigns a name that exists as a global changes the global. Write `func main` and keep only what event code needs global.

### Keywords can not be names

`ok`, `step`, `from`, `to`, `load`, `call`, `get`, `set`, `put`, `on`, `off`... can not be variable or function names, in any letter case. `oK` is `ok`. Names that are keywords get a trailing `_` in the generated classes (`ForEach_`, `Exit_`) and properties with a keyword name use `getFrom()` / `setFrom(value)`.

Do not define your own functions named like built-ins the library uses (`isNumber`, `len`...).

### Define functions after the main code

A `func` at the top of a file swallows the rest of the file into its body. Put the main code first (or put it in `func main` and call it at the end).

### `new StringBuilder()` needs `NULL`

Ring checks the number of arguments of `init()`. The classes whose `init` takes a value (`StringBuilder`, `Random`, `Version`) therefore need `NULL` for the parameterless constructor: `new StringBuilder(NULL)`, `new Random(NULL)`. With a value it is as usual: `new StringBuilder("Hello")`, `new Random(42)`.

### A variable name that starts like a keyword

Ring names are not case sensitive and the words `or`, `if`, `to`, `in`, `do`... are keywords. `oR = new StreamReader(...)` is read as `or = ...` and gives a syntax error. Use longer names (`oReader`, `oRd`).

### Using objects during definition: `x = new Class().Method(x)`

This is a **Ring feature** (since Ring 1.19, [Using objects during definition](https://ring-lang.github.io/doc1.28/oop.html#using-objects-during-definition)): in an assignment `x = new Class(...)`, the new object is stored in `x` *first*, so that it can be used while the rest of the expression is evaluated. Then the rest of the expression runs (a method call, an operator) and its result is stored in `x` again. This makes it possible to use the object (for example with an overloaded operator) during its own definition, but it means that the variable you are assigning already holds the **new object** when the arguments are evaluated:

```ring
cText = new Regex("a").Replace(cText,"b")       # cText is already the Regex object: no method matches the 2 arguments
cResult = new Regex("a").Replace(cText,"b")     # works: a different variable
```

Write the result to a **different** variable ([tutorial 47](tut-47-markdown.html)).

### A list of `[text, value]` pairs passed alone is read as named arguments

A method with overloads reads a single list of `[text, value]` pairs as **named arguments**. `Serialize([["Buy milk",1],["Walk",0]])` would look for a parameter called "Buy milk". Put something that is not a text first in each pair, or wrap the list in another list, so that it is passed as a value ([tutorial 24](tut-24-todo.html)).

### Side effects inside `for ... in call()`

When the expression of a `for x in oDb.migrate()` has side effects, assign it to a variable first:

```ring
aChanges = oDb.migrate()
for cChange in aChanges
	? cChange
next
```

### `dnNull()`

`dnNull()` is the .NET null: `oPictureBox.Image = dnNull()`.

## .NET gotchas

### Put the `using` block before the first .NET call

The runtime mode (desktop, web, both) is chosen by the `using { }` block (or by `dnUseDesktop()`, `dnUseWeb()`, `dnUseAll()`) and must come **before any other .NET call**: the first call starts the runtime and the mode can not change afterwards. If a program needs both Windows Forms/WPF and ASP.NET Core, name both in the first `using` block.

### Callbacks run on the Ring thread only

Events from timers on other threads (`System.Threading.Timer`, `Task.Run(...)`) can not run Ring code; they print a message on stderr and do nothing. Use the Windows Forms `Timer` (`uiTimer`) or wait for tasks on the Ring thread. The web server queues requests for the same reason.

### Value types are returned by value

`oForm.Location` returns a copy of the `Point`. Change it by assigning a new value: `oForm.Location = new Point(10,20)`.

### Enums are strings

`oForm.WindowState = "Maximized"`, `oForm.FormBorderStyle = "FixedDialog"`.

### Binary data

`byte[]` travels as a Ring string, so it is binary safe — except through the Entity Framework layer, where `bytes` columns are hex texts.

### Tracked EF rows

`RingDatabase.byKey` returns the tracked row. After a raw SQL change (`execute`, `apply`) call `discard()` to read the new values.

## Limits

| Not supported | Why / what to do |
|---|---|
| Declaring .NET classes or interfaces in Ring | Ring is not compiled to .NET. Write them in C#, build a DLL and [wrap it](own-assemblies.html). |
| Ring code on .NET threads | One Ring thread. Use callbacks only during calls, or queue work as the web server does. |
| `ref` struct and pointer parameters, `Span<T>` | The bridge converts values, not memory. Use arrays and strings. |
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
| `Calling function with less number of parameters` | a constructor that needs arguments: `new DateTime(2024,12,25)`. |
| `Trying to destroy the object using the self reference` | an attribute of a library class has the same name as a global variable of your program. |
| An event handler does nothing | the code uses a local variable — only globals are visible; or the handler runs on another thread. |
| `The callback '...' was ignored` | a callback fired outside a call or from another thread. |

Set `RINGDOTNET_TRACE=1` to see the .NET stack trace of an error.
