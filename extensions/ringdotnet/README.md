# RingDotNet

Use .NET classes and methods from Ring programs.

The package hosts the .NET runtime inside the Ring process (through `hostfxr`) and talks to it through a small managed bridge, so any installed .NET (Core) runtime, 6.0 or newer, and any assembly (the framework or your own `.dll`) can be used.

```ring
load "dotnetlib.ring"

? dnVersion()                                   # .NET 9.0.x
dnType("System.Console").callMethod("WriteLine",["Hello from .NET"])
? dnStatic("System.Math","Max",[3,9])           # 9

oSB = dnNew("System.Text.StringBuilder",["Hello"])
oSB.callMethod("Append",[", Ring!"])
? oSB.toString()                                # Hello, Ring!
? oSB.getProp("Length")                         # 12
```

## Namespaces

The wrapped namespaces are listed in `tools/dotnetmanifest.ring` (a whole namespace with `:all = true`, or explicit types, closed generics and nested types). `tools/gendotnet.ring [namespace ...]` generates `libraries/dotnetlib/generated/<Namespace>.ring` plus one file per class, and `dnImport("Namespace")` loads them on demand, so a program only pays for what it uses. Class names are the short .NET names; when two namespaces have the same name, the later one gets the namespace as a prefix (`TimersTimer`). A method returns a generated class only if its namespace was imported, otherwise a plain `DotNetObject` (use `callMethod`/`getProp`).

Other rules: enums are strings in both directions (`oForm.WindowState = "Maximized"`, `oDate.DayOfWeek` returns `"Thursday"`); methods with `out`/`ref` parameters return a list `[result, out values...]` (`aR = oDict.TryGetValue("k")`); closed generic types without a class can be created with `dnNewGeneric("System.Collections.Generic.List",["System.Int32"],[])`.

Run `tests/run.sh` (it needs `ring.dll` on the PATH) to execute the tests and samples.

## Natural syntax (generated classes)

Like RingQt's classes, the .NET types are wrapped by generated Ring classes (`libraries/dotnetlib/generated`) with the same method names:

```ring
load "dotnetlib.ring"
dnImport("System.Text")                 # load the generated classes of a namespace

oSB = new StringBuilder("Hello")        # use parentheses: Ring calls init() only with them
oSB.Append(", Ring").Append("!")        # methods that return a generated class return that class
? oSB.ToString()
? oSB.Length                            # properties and fields are attributes: oObj.Length, oObj.Text = "x"
new Console().WriteLine("Hi")
? new Math().Max(3,9)                   # static members are called on an instance
```

Ring has no overloading, so for each name the overload arity with the most overloads gets the plain name (`Append`, `WriteLine`) and the others get `Name_N` (`Next_2(1,10)`); constructors work the same way (`init` plus `New_N`). Names that are Ring keywords get a trailing `_` (`Exit_`). The bridge still picks the real overload from the argument types.

Types with classes: see the manifest. Among them the closed generic collections StringList, NumberList, ObjectList (`List<T>`), StringDictionary, NumberDictionary, ObjectDictionary (`Dictionary<string,T>`), StringSet, StringQueue, StringStack. Indexers become `Item(index)` / `SetItem(index,value)`; `toList()` copies a collection to a Ring list:

```ring
oList = new StringList()
oList.Add("banana") oList.Add("apple")
oList.Sort()
for cItem in oList.toList() ? cItem next

oDict = new StringDictionary()
oDict.SetItem("two","2")
? oDict.Item("two")
```

Add your own closed generic with a line like `["System.Collections.Generic.List`1[[System.Int32]]","IntList",0]` (the optional third item forces the number of `init()` parameters). To wrap more types (or your own assemblies), add them to `aTypes` in `tools/gendotnet.ring` and run it (it can `dnLoad` an assembly first).

## Properties

.NET properties and fields are Ring attributes (Ring calls the generated `getName()` / `setName(value)` automatically, see "Setter and Getter" in the Ring docs), so they read and write naturally, also inside `{ }`; `getName()` / `setName()` can still be called explicitly. Assigning a read-only property raises an error.

```ring
oForm = new Form()
oForm.Text = "Hello"
oForm.Width = 400
? oForm.Controls.Count            # chained: Controls returns a ControlCollection
oForm { Height = 300  Text += "!" }
```

## Calling Ring code from .NET (callbacks)

Pass `dnCallback(cCode)` wherever a .NET delegate is expected (`Action`, `Func`, `Predicate`, `Comparison`, `EventHandler`, ...). The bridge builds a delegate of the exact type. When .NET invokes it, the Ring code runs, as in RingQt events: it can read `aDotNetArgs` (the list of delegate arguments) and set `xDotNetResult` (converted to the delegate's return type).

```ring
nTotal = 0
oList.ForEach_(dnCallback("nTotal += len(aDotNetArgs[1])"))           # ForEach is a Ring keyword, so ForEach_
oList.Sort_1(dnCallback("xDotNetResult = len(aDotNetArgs[1]) - len(aDotNetArgs[2])"))
oList.FindAll(dnCallback("xDotNetResult = left(aDotNetArgs[1],1) = 'a'"))
```

If the text is just a function name, that function is called with the argument list as its only parameter and its return value is the result (define the function after the main code):

```ring
oList.ForEach_(dnCallback("show"))
func show aArgs
	? aArgs[1]
```

Errors raised by the Ring code reach the .NET caller as an exception (and then your Ring `try/catch`). Callbacks run synchronously on the Ring thread during a call; a callback fired later or from another thread (timers, tasks) is ignored with a message on stderr.

## Events (like Click)

Every public .NET event gets `setXXXEvent(cRingCode)` and `clearXXXEvent()` methods, as in RingQt. The code runs when the event is raised and can read `aDotNetArgs` (`[sender, eventArgs]`, both .NET objects). Each event has one handler; setting it again replaces it.

```ring
oList = new ObservableStringList()
oList.setCollectionChangedEvent("? 'changed: ' + aDotNetArgs[2].getProp('Action')")
oList.Add("one")
```

### Windows Forms

Call `dnUseDesktop()` first (it adds the Windows Desktop runtime and makes the Ring thread an STA thread). The Ring thread then runs the message loop in `Application.Run(form)`, so event code runs normally:

```ring
dnUseDesktop()
oForm = new Form()
oButton = new Button()
oButton.setText("Click me")
oButton.setClickEvent("oForm.setText('Clicked!')")
oForm.getControls().Add(oButton)
new Application().Run(oForm)
```

Generated desktop classes: Application, MessageBox, Form, Button, Label, TextBox, CheckBox, ListBox, ControlCollection (add more in `tools/gendotnet.ring`). Events must be raised on the Ring thread (UI events are; timers and tasks are not).

## Architecture

```
Ring program ── dotnetlib (Ring)  ──  ring_dotnet.dll (C, hosts the CLR)  ──  RingDotNet.Bridge.dll (C#, reflection)
```

* `extensions/ringdotnet/ring_dotnet.c` — three functions: `dotnet_start()`, `dotnet_invoke(cRequest)`, `dotnet_info()`. It finds `hostfxr` (`DOTNET_ROOT`, then the default install folder), starts the runtime with `RingDotNet.Bridge.runtimeconfig.json` and binds `Bridge.Invoke`.
* `extensions/ringdotnet/bridge` — the managed bridge. .NET objects stay in a handle table; Ring only holds numeric handles. Overloads are chosen by argument count and convertibility (Ring numbers convert to any numeric type or enum, strings to enums/char/Guid/Type, lists to arrays).
* `libraries/dotnetlib` — the Ring API (`functions.ring`, `classes.ring`) and the wire-format packing.

Wire format: a sequence of `<tag><byte length>:<data>` items (`s` string, `n` number, `b` boolean, `z` null, `o` object handle, `l` list, `e` error).

## API

| Function | Description |
|----------|-------------|
| `dnVersion()` | Hosted runtime description |
| `dnLoad(cPath)` / `dnLoadName(cName)` | Load an assembly from a file / by name |
| `dnType(cTypeName)` | Type object (for static members) |
| `dnNew(cTypeName, aParameters)` | Create an object |
| `dnStatic(cTypeName, cMethod, aParameters)` | Call a static method |

`DotNetObject` methods: `callMethod(cMethod, aParameters)`, `getProp(cName)`, `setProp(cName, xValue)`, `toString()`, `typeName()`, `toList()`, `release()`, `isNull()`.

Return values: strings, numbers (all numeric types), booleans (1/0) and `null` map to Ring values; arrays/collections and other objects are returned as `DotNetObject`. .NET exceptions are raised as Ring errors.

## Build

Windows (clang): `extensions/ringdotnet/buildclang_win.bat`; Visual Studio: `buildvc_x64.bat`; Linux: `buildgcc.sh`; macOS: `buildclang.sh`. The .NET SDK builds the bridge. Copy `ring_dotnet.dll` and the `RingDotNet.Bridge.*` files to the same folder (`ring/bin`).

## Not yet supported (ideas)

* Callbacks from other threads or after the call returned, generic methods, `ref`/`out` parameters, indexers
* Automatic release of handles (use `release()`)
