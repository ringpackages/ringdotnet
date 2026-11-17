# RingDotNet

Use .NET classes and methods from Ring programs.

**Documentation:** open [`docs/index.html`](docs/index.html) — a complete HTML manual with samples, real output and screenshots (rebuild it with `python docs/tools/build.py`).

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

The wrapped namespaces are listed in `tools/dotnetmanifest.ring` (a whole namespace with `:all = true`, or explicit types, closed generics and nested types). `tools/gendotnet.ring [namespace ...]` generates `libraries/dotnetlib/generated/<Namespace>.ring` plus one file per class, and `dnImport("Namespace")` loads them on demand, so a program only pays for what it uses. Class names are the short .NET names; when two namespaces have the same name, the later one gets the namespace as a prefix (`TimersTimer`). When an object of a type that has a generated class (but whose namespace was not imported) is returned, its namespace is imported automatically (`generated/classindex.ring`); a manifest `:uses` list also imports the namespaces a namespace normally returns (so `oProcess.StandardOutput.ReadToEnd()` works right after `dnImport("System.Diagnostics")`). Every object a method returns is wrapped by its runtime type (or the nearest base type that has a generated class) when that namespace was imported, otherwise it is a plain `DotNetObject` (use `callMethod`/`getProp`). The manifest `:prefer = ["Namespace.Type.Method=arity"]` chooses which overload gets the plain name.

Other rules: enums are strings in both directions (`oForm.WindowState = "Maximized"`, `oDate.DayOfWeek` returns `"Thursday"`); methods with `out`/`ref` parameters return a list `[result, out values...]` (`aR = oDict.TryGetValue("k")`); closed generic types without a class can be created with `dnNewGeneric("System.Collections.Generic.List",["System.Int32"],[])`.

Run `tests/run.sh` (it needs `ring.dll` on the PATH) to execute the tests and samples.

## Your own assemblies and NuGet packages

```
cd tools
ring wrapassembly.ring path/to/MyLibrary.dll ../myclasses
```

generates Ring classes (with inheritance, properties, events, enums as strings) for every public class of the assembly, one loader per namespace. Use them with:

```ring
load "dotnetlib.ring"
dnLoad("path/to/MyLibrary.dll")                  # dependencies are found next to the dll (copy a NuGet package's dll files there)
dnImportFrom("myclasses/","MyCompany.Tools")
oCalc = new Calculator()
```

`tests/UserLib` is a complete example (`tests/test_userassembly.ring`). Without generated classes any assembly is usable through `dnType("Namespace.Type")`, `dnNew()` and `callMethod()`.

## using

`using { }` imports namespaces like C# (same as `dnImport` for each text; anything that is not a text is an error):

```ring
load "dotnetlib.ring"
using {
	"System"
	"System.Text"
}
```

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

Ring has no overloading, so the plain name of a method is its parameterless form when it has one, otherwise its shortest overload (`Append`, `WriteLine`, `Join`); the other arities are `Name_N` (`Next_2(1,10)`, `Round_2(x,2)`). Overloads whose parameters are arrays (except `byte[]`/`char[]`), delegates, comparers or spans never decide the plain name. The parameterless form wins when the type has one (`Cancel()`, `Wait()`, `Reverse()`), except `Write*` methods (`WriteLine("x")`); `ToString()` keeps its parameterless form. A method with optional parameters is available with every number of parameters from the required ones up (`Serialize(value)`, `Serialize_2(value,options)`). Static and instance methods with the same name and arity are one method (a class used without an object calls the static one). Constructors work the same way: `init()` is parameterless when the type has such a constructor (structs always do), otherwise the shortest one, and the other constructors are `New_N` (`new MemoryStream().New_1(bytes)`); user defined implicit conversions are applied to arguments (a string becomes an `XName`); `tools/dotnetmanifest.ring` can choose another `init` size per type. Names that are Ring keywords get a trailing `_` (`ForEach_`, `Exit_`). The bridge still picks the real overload from the argument types (whole numbers prefer `int`). Binary data (`byte[]`) travels as Ring strings.

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

## Named arguments

Ring passes optional, order-independent arguments as a list of `:name = value` pairs. When a method has overloads with different numbers of parameters, its plain name takes one parameter: `NULL` calls the parameterless overload, a list of `:name = value` pairs chooses the overload by the .NET parameter names (not case sensitive), anything else is the one-argument call:

```ring
? new Math().Round([ :value = 3.14159, :digits = 2 ])
oProcess = new Process().Start([ :startInfo = oInfo ])
oProcess.WaitForExit(NULL)                       # the parameterless overload of an overloaded method
oSB = dnNew("StringBuilder",[ :value = "Hello" ])
```

Methods whose plain form takes two or more parameters, or whose overloads all have the same number of parameters, stay positional. `ToString` and `ToList` keep their plain forms (`ToString_1(format)`).

## LINQ

`dnImport("System.Linq")` loads `Enumerable` (generic methods work: the bridge infers the type arguments from the values, callbacks become `Func<object,...>`) and a fluent wrapper that accepts Ring lists or any .NET collection:

```ring
aTop = dnQuery(aSales).Where("xDotNetResult = aDotNetArgs[1] >= 100").OrderByDescending("xDotNetResult = aDotNetArgs[1]").Take(3).ToList()
? dnQuery(aSales).Sum("") + " " + dnQuery(aSales).Average("")
```

## Braces

`{ }` after an object evaluates everything inside on that object, which keeps configuration code short (`True` / `False` are the logical values):

```ring
oInfo = new ProcessStartInfo() {
	FileName = "cmd"
	Arguments = "/c ver"
	RedirectStandardOutput = True
	UseShellExecute = False
	CreateNoWindow = True
}
```

Inside the braces a name is looked up as a member of the object first: do not name a variable `text`, `width`...

## Properties

.NET properties and fields are Ring attributes (Ring calls the generated `getName()` / `setName(value)` automatically, see "Setter and Getter" in the Ring docs), so they read and write naturally, also inside `{ }`; `getName()` / `setName()` can still be called explicitly. Assigning a read-only property raises an error. Properties whose names are Ring keywords (`From`, `To`, `Step`, `On`...) are not attributes: use `getFrom()` / `setFrom(value)`.

```ring
oForm = new Form()
oForm.Text = "Hello"
oForm.Width = 400
? oForm.Controls.Count            # chained: Controls returns a ControlCollection
oForm { Height = 300  Text += "!" }
```

## GUI helpers and applications

`dnImport("System.Windows.Forms")` also loads `libraries/dotnetlib/gui.ring`: `uiForm()`, `uiButton()`, `uiLabel()`, `uiTextBox()`, `uiMemo()`, `uiListBox()`, `uiComboBox()`, `uiPanel()`, `uiPictureBox()`, `uiTimer()`, `uiMenu()`, dialogs (`uiMessage()`, `uiOpenFileName()`...) and a `UiCanvas` class for drawing. `applications/` has complete programs (Calculator, Notepad, games, ...) that run themselves with `--selftest`.

## Ring gotchas when writing GUI programs

* `"text" + number` works, `number + "text"` is an error (`string(n) + " items"`).
* Do not call a method on a new object on the right side of an attribute assignment (`oForm.Text = new Path().GetFileName(f)`): Ring loses the assignment. Use a variable first (`oPath = new Path()` then `oForm.Text = oPath.GetFileName(f)`).
* The code of an event runs outside the function that set it up: it can only use global variables (create them at the top of the program, then assign them in the function).
* Put the program in functions (`func main`, or functions called from the top) so that loop variables and temporaries are local: in Ring a global variable named like an attribute (`x`, `width`...) makes `obj.x` fail, and a function that assigns a name that exists as a global changes the global. Keep global only what the code of events needs (the widgets and the state): the code of an event can see globals only.
* Ring keywords can't be variable or function names, in any case: `oK` is `ok`, `step()` is `step`, `To`, `From`, `Load`... Do not define functions named like the built-ins the library uses (`isNumber`, `len`, ...).
* Define the functions after the main code (a `func` at the top would swallow the rest of the file).
* `dnNull()` is the .NET null (`oPictureBox.Image = dnNull()`).

## WPF

`dnUseDesktop()` then `dnImport("System.Windows")` (and `.Controls`, `.Media`, `.Shapes`, `.Data`, `.Input`, `.Documents`, `.Markup`, ...) wraps WPF: windows, panels, controls, XAML (`wpfXaml()`), data binding, shapes, brushes, animation classes. WPF class names that exist in Windows Forms/System.Drawing too start with `Wpf` (`WpfButton`, `WpfTextBox`, `WpfPoint`, `WpfBinding`); the others keep their name (`Window`, `Grid`, `StackPanel`, `Ellipse`). Helpers in `wpf.ring`: `wpfWindow`, `wpfRun`, `wpfLabel`, `wpfButton`, `wpfBrush`, `wpfXaml`, `wpfFind`, `wpfPixel`, `wpfTest`/`wpfEnd`. See `tests/test_wpf.ring`, `samples/Wpf` (10 samples) and the applications WpfCalculator and WpfColorMixer. Ring gotcha: a global variable named like an attribute (`x`) breaks `obj.X`.

## Entity Framework Core

`dnUseData()` loads Entity Framework Core 9 (SQLite and in-memory providers bundled). A Ring program cannot write C# classes, so the model is described with data (tables, columns, options) and EF Core works on it in two ways:

- `RingDatabase`: rows are lists of `[name, value]` pairs (EF shared-type entities).
- `RingEntityDb`: the tables become real .NET classes (Reflection.Emit) with navigation properties, tracked by EF like classes written in C#.

```ring
load "dotnetlib.ring"
dnUseData()
oDb = new RingDatabase("Data Source=people.db",[
	["Customers",[ ["Id","int",1], ["Name","string",0,[["required",1],["unique",1],["maxlength",40]]], ["Age","int",0,[["nullable",1]]], ["City","string",0,[["index",1]]] ]]
])
nId = oDb.insert("Customers",[["Name","Ann"],["Age",31],["City","Cairo"]])
? dbValue(oDb.byKey("Customers",nId),"Name")
for aRow in oDb.where("Customers","Age > {0} AND City = {1}",[18,"Cairo"])		# real SQL parameters
	? dbValue(aRow,"Name")
next
oDb.update("Customers",nId,[["Age",32]])
oDb.remove("Customers",nId)
oDb.close()
```

| Feature | How | Test |
|---|---|---|
| Column options | 4th item of a column: `required nullable unique index maxlength default`; several key columns = composite key (`byKey("T",[1,2])`) | `test_data_schema.ring` |
| Relationships | `["references","Authors"]`, `["ondelete","cascade"/"restrict"/"setnull"]`; `children()`, `parent()`, `include()` | `test_data_relations.ring` |
| Transactions, async | `begin()` `commit()` `rollback()`, `autoSave(false)` + `save()`, `insertAsync()` `allAsync()` ... + `dbWait(task)` | `test_data_transactions.ring` |
| Migrations | `migrate()` adds the missing tables, columns and indexes of an existing SQLite database; `apply("name",sql)` runs a change once | `test_data_migrations.ring` |
| Providers | `"Data Source=..."` SQLite, `"inmemory:name"`; `"sqlserver:..."`, `"postgres:..."`, `"mysql:..."` load the EF provider package from the DLLs folder (not bundled, not tested here) | `test_data_providers.ring` |
| Queries | `query("T",[["where",["and",["Age",">",30],["City","in",["A","B"]]]],["orderby",[["Age","desc"]]],["skip",1],["take",5],["select",["Name"]]])` builds a LINQ expression tree (all providers); `sum/min/max/average/countWhere/groupCount`; `sqlRows(sql,params)` any SELECT shape | `test_data_queries.ring` |
| Hooks | `onSaving(dnCallback("f"))` (return a text to cancel), `onSaved`, `onLog` (SQL text), `pendingChanges()`; table option `["filter",cond]` = global query filter; column option `["convert","upper"]` or `["convert",[dnCallback("toDb"),dnCallback("fromDb")]]` | `test_data_hooks.ring` |
| Entity classes | `RingEntityDb`: `newEntity`, `add`, `remove`, `find`, `query` (with `["include",["Author"]]`), tracked changes saved by `save()`, `getProp/setProp`, navigation properties | `test_data_entities.ring` |

`datetime` columns are `"yyyy-MM-dd HH:mm:ss"` texts and `bytes` columns hex texts (`str2hex`/`hex2str`). `oDb.context()` is the wrapped EF `DbContext`; the classes of `Microsoft.EntityFrameworkCore(.ChangeTracking/.Infrastructure/.Metadata/.Metadata.Builders/.Storage/.Query/.Migrations/.Diagnostics)` and `Microsoft.Data.Sqlite` are wrapped too (clashing names start with `Ef`). Example: `applications/Contacts`.

Not supported: classes written in C# source (the entity classes are generated from the schema; there is no C# compiler), lambdas written by hand (queries are data), migrations that alter or drop columns (use `execute`), a typed `RingEntityDb` with hooks/converters/`migrate()`, and the SQL Server / PostgreSQL / MySQL providers were not tested. The packages add about 10 MB to `bin`.

## ASP.NET Core

`dnUseWeb()` (before any other .NET call) adds the ASP.NET Core runtime. `web.ring` then gives a Kestrel web server whose requests are handled by Ring functions:

```ring
dnUseWeb()
oServer = new WebServer("http://localhost:5080")
oServer.onGet("/","home")
oServer.onPost("/api/echo","echo")
oServer.run()                                  # serves until stop(); or call serveOne(100) in your own loop

func home oRequest
	return "<h1>Hello</h1>" + oRequest.path()
func echo oRequest
	return [201,"text/plain","you sent " + oRequest.body()]     # or webJson(list)
```

A handler gets a request (`method()`, `path()`, `query("q")`, `body()`, `header()`, `form()`, `context()` = the ASP.NET `HttpContext`) and returns a text, `[status, contentType, text]` or `webJson(...)`. Kestrel runs on .NET threads and Ring code may only run on the Ring thread, so the requests are queued and `serveOne()` / `run()` handle them on the Ring thread. The ASP.NET classes (`Microsoft.AspNetCore.*`, `Microsoft.Extensions.*`, `Microsoft.Net.Http.Headers`; clashing names start with `Asp`) are wrapped too. `dnUseAll()` starts Windows Forms/WPF and ASP.NET together. Example: `applications/WebApi` (JSON to-do API and web page), tests: `tests/test_web.ring`. Not supported: MVC controllers/Razor written in C# (the web server is the Ring one), and handlers that run in parallel (one Ring thread).

## Keyboard in games

A button (or any control that takes the focus) steals the arrow keys, Space and Enter from the form: the form's `KeyDown` never sees the arrows and Space/Enter "press" the button. Use `uiGameKeys(oForm,"keyPressed(aDotNetArgs[2].KeyCode)")` after the controls were added: every control then reports the arrows as normal keys and the form handles them (Tetris, 2048, Sokoban, Snake and Pong do). In tests, `uiSendKeys(oForm,"{LEFT}12{+}30{ENTER}")` types into the focused control of the form through the real key processing (it posts window messages to your own form, so unlike `SendKeys` it can never type into another program). `tests/test_keyboard.ring` shows the problem and the fix.

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

The code of a callback is compiled once into a function (`dncallbackN`, the same text reuses it), so using it in a loop or a timer costs nothing extra. Errors raised by the Ring code reach the .NET caller as an exception (and then your Ring `try/catch`). Callbacks run synchronously on the Ring thread during a call; a callback fired later or from another thread (timers, tasks) is ignored with a message on stderr.

## Events (like Click)

Every public .NET event gets `setXXXEvent(cRingCode)` and `clearXXXEvent()` methods, as in RingQt. The code runs when the event is raised and can read `aDotNetArgs` (`[sender, eventArgs]`, both .NET objects). Each event has one handler; setting it again replaces it.

```ring
oList = new ObservableStringList()
oList.setCollectionChangedEvent("? 'changed: ' + aDotNetArgs[2].getProp('Action')")
oList.Add("one")
```

### Windows Forms

All of `System.Windows.Forms` and `System.Drawing*` are wrapped (`dnImport("System.Windows.Forms")`, `dnImport("System.Drawing")`). `dnUseDesktop()` also makes errors in event handlers raise out of `Application.Run()` (so a Ring `try/catch` sees them, no dialog). Remember that in Ring `number + string` is an error: write `string(n) + " items"`.

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

## Wrapped namespaces (see tools/dotnetmanifest.ring)

System, System.Text(.Json/.Encodings/.RegularExpressions/.Unicode), System.IO(.Compression/.Pipes/.MemoryMappedFiles), System.Linq, System.Collections(.Generic/.Specialized/.Concurrent/.ObjectModel), System.Threading(.Tasks), System.Net(.Http/.Sockets/.NetworkInformation/.Mail/.WebSockets/.Security), System.Globalization, System.Security.(Cryptography/Principal/Claims/X509), System.Diagnostics, System.Xml(.Linq/.XPath/.Schema/.Serialization/.Xsl), System.Data(.Common/.SqlTypes), System.ComponentModel, System.Reflection, System.Runtime.InteropServices/Loader, System.Numerics, System.Timers, System.Formats.Tar, System.Resources, Microsoft.Win32, System.Drawing(.Drawing2D/.Imaging/.Text/.Printing) and System.Windows.Forms(.Layout/.VisualStyles). Not wrapped: other packages that are not part of the base runtime (use `wrapassembly.ring`).

## Not yet supported (ideas)

* Callbacks from other threads or after the call returned, generic methods, `ref`/`out` parameters, indexers
* Automatic release of handles (use `release()`)
