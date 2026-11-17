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

### Always call the mode function first

`dnUseDesktop()`, `dnUseWeb()` and `dnUseAll()` must come **before any other .NET call**: the first call starts the runtime and the mode can not change afterwards.

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
| Linux/macOS Windows Forms and WPF | Those frameworks are Windows-only. The rest of the bridge is portable but only tested on Windows. |
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
