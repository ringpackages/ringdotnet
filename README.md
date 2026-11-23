# RingDotNet

Use .NET classes and methods from Ring programs.

**Documentation:** open [`docs/index.html`](docs/index.html) — a complete HTML manual with samples, real output and screenshots (rebuild it with `python docs/tools/build.py`, after `python docs/tools/dumpapi.py` when the classes changed; `docs/api.html` is the reference of every wrapped class, regenerate its data with `python docs/tools/dumpapi.py` after regenerating the classes).

The package hosts the .NET runtime inside the Ring process (through `hostfxr`) and talks to it through a small managed bridge, so any installed .NET (Core) runtime, 6.0 or newer, and any assembly (the framework or your own `.dll`) can be used.

```ring
load "dotnet.ring"

using {
	"System"
	"System.Text"
}

? dnVersion()                                   # .NET 9.0.x
? new Math().Max(3,9)                           # 9: a static method

oSB = new StringBuilder("Hello")
oSB.Append(", Ring!")
? oSB.ToString()                                # Hello, Ring!
? oSB.Length                                    # 12
```

## Learn and try

* **Documentation:** `docs/index.html` (start with *Getting started*, then *Core concepts*).
* **Tutorials:** step-by-step lessons grouped in chapters (the basics, text and data formats, numbers and dates, collections, files, processes, networking, security, databases, Windows Forms, WPF, projects, libraries and release). Each lesson has a program in `samples/UsingDotNet/tutorials`; the files are named by chapter, `chNN_name.ring` (`ch01_first_look.ring`, `ch05_watch_folder.ring`...), and a program that has a window can run its own test with `ring chNN_name.ring --selftest` (the checks are in `selftest/chNN_name.ring` next to it). Run a program from its folder: `cd samples/UsingDotNet/tutorials` and `ring ch01_first_look.ring`.
* **Samples:** `samples/UsingDotNet/introduction` (short programs for each area), `Forms` and `Wpf` (one small window program for each feature), `applications` (complete programs: calculators, an editor, games, a web API, a contacts book) and `tests` (the automated tests).

```
sh samples/UsingDotNet/tests/run.sh ring.exe          # everything (the tutorials and the samples with windows too)
sh samples/UsingDotNet/tests/run.sh ring.exe --quick  # only the tests and the introduction samples
```

## Namespaces

The wrapped namespaces are listed in `tools/dotnettools/dotnetmanifest.ring` (a whole namespace with `:all = true`, or explicit types, closed generics and nested types). `tools/dotnettools/gendotnet.ring` generates, for each namespace, `libraries/dotnetlib/generated/<Namespace>.ring` (the loader) and `<Namespace>.classes.ring` (all its classes; run it without namespace names for the library, a run with names is for trying a change), and `dnImport("Namespace")` loads them on demand, so a program only pays for what it uses. Class names are the short .NET names; a class whose name a class of another namespace already has starts with the last part of its namespace (`TimersTimer` is `System.Timers.Timer`). When an object of a type that has a generated class (but whose namespace was not imported) is returned, its namespace is imported automatically (`generated/classindex.ring`); a manifest `:uses` list also imports the namespaces a namespace normally returns (so `oProcess.StandardOutput.ReadToEnd()` works right after `dnImport("System.Diagnostics")`). Every object a method returns is wrapped by its runtime type (or the nearest base type that has a generated class) when that namespace was imported, otherwise it is a plain `DotNetObject` (use `callMethod`/`getProp`).

Other rules: enums are strings in both directions (`oForm.WindowState = "Maximized"`, `oDate.DayOfWeek` returns `"Thursday"`); methods with `out`/`ref` parameters return a list `[result, out values...]` (`aR = oDict.TryGetValue("k")`); closed generic types without a class can be created with `dnNewGeneric("System.Collections.Generic.List",["System.Int32"],[])`.

`run.sh` takes the path of `ring` (`ring.exe` on Windows) and adds the package `bin` folder to the PATH itself. Options: `--quick`, `--no-packages`, `--packages-only`, `--jobs N`, `--show` (see *Testing* in the documentation).

## Your own assemblies and NuGet packages

```
cd tools/dotnettools
ring wrapassembly.ring path/to/MyLibrary.dll ../../myclasses
```

generates Ring classes (with inheritance, properties, events, enums as strings, and the extension methods of the types) for every public class of the assembly, a loader and a class file for each namespace. Use them with:

```ring
load "dotnet.ring"
dnLoad("path/to/MyLibrary.dll")                  # dependencies are found next to the dll (dotnet publish collects a NuGet package with them)
dnImportFrom("myclasses/","MyCompany.Tools")
oCalc = new Calculator()
```

`samples/UsingDotNet/tests/UserLib` is a complete example (`samples/UsingDotNet/tests/test_userassembly.ring`). Without generated classes any assembly is usable through `dnType("Namespace.Type")`, `dnNew()` and `callMethod()`.

A NuGet package comes to Ring in four steps: a project file with a `PackageReference`, `dotnet publish -o libs` (the package, the DLLs it needs and its native libraries, which the bridge finds in `runtimes/<system>-<architecture>/native`), `wrapassembly.ring`, then `dnLoad` and `dnImportFrom`. The tutorials from *A NuGet package* on show it with Newtonsoft.Json, QRCoder, ClosedXML, SkiaSharp, PDFsharp, System.Speech, and a project with CsvHelper, LiteDB and ClosedXML. A class of the assembly with the name of a class of the library gets the prefix of its namespace (`YamlDotNet.Core.Version` is `CoreVersion`) and the generator lists the renames.

## using

`using { }` imports namespaces like C# (same as `dnImport` for each text; anything that is not a text is an error):

```ring
load "dotnet.ring"

using {
	"System"
	"System.Text"
}
```

## Simple syntax (generated classes)

Like RingQt's classes, the .NET types are wrapped by generated Ring classes (`libraries/dotnetlib/generated`) with the same method names:

```ring
load "dotnet.ring"
dnImport("System.Text")                 # load the generated classes of a namespace

oSB = new StringBuilder("Hello")        # use parentheses: Ring calls init() only with them
oSB.Append(", Ring").Append("!")        # methods that return a generated class return that class
? oSB.ToString()
? oSB.Length                            # properties and fields are attributes: oObj.Length, oObj.Text = "x"
new Console().WriteLine("Hi")
? new Math().Max(3,9)                   # static members are called on an instance
```

A Ring method has one parameter list, so a .NET method name with several overloads is **one Ring method with one parameter**: `Name(NULL)` calls the parameterless overload, `Name(value)` the overload with one parameter, and `Name([ :param = value ])` chooses the overload by the .NET parameter names (`Round([ :value = x, :digits = 2 ])`, `@Next([ :minValue = 1, :maxValue = 10 ])`). A `params` array takes a plain list (`Combine(["a","b","c"])`). `ToString()` keeps its parameterless form; its forms with parameters are `Format` (`oDate.Format("yyyy-MM-dd")`). Names that are Ring keywords start with `@` (`@New`, `@Next`, `@Load`, as C# writes `@class`). Extension methods are methods of the extended type (`oTable.AddColumn("Name")`). Constructors: `init` is the parameterless or shortest one, the others are `@New([ :param = value ])` (or `dnNew("Class",[ :param = value ])`). A name whose overloads all have the same number of parameters (`Math.Max(a,b)`) stays positional.

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

Add your own closed generic with a line like `["System.Collections.Generic.List`1[[System.Int32]]","IntList",0]` (the optional third item forces the number of `init()` parameters). To wrap more types (or your own assemblies), add them to the manifest, `tools/dotnettools/dotnetmanifest.ring` (the `:types` of the namespace, and `:assemblies` for another assembly), and run `tools/dotnettools/gendotnet.ring`.

## Named arguments

Ring passes optional, order-independent arguments as a list of `:name = value` pairs. When a method has overloads with different numbers of parameters, its plain name takes one parameter: `NULL` calls the parameterless overload, a list of `:name = value` pairs chooses the overload by the .NET parameter names (not case sensitive), anything else is the one-argument call:

```ring
? new Math().Round([ :value = 3.14159, :digits = 2 ])
oProcess = new Process().Start([ :startInfo = oInfo ])
oProcess.WaitForExit(NULL)                       # the parameterless overload of an overloaded method
oSB = new StringBuilder("Hello")                # a constructor that takes a value
```

A name whose overloads all have the same number of parameters stays positional. `ToString` and `ToList` keep their plain forms (`Format(format)` is the form of `ToString` with parameters).

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

.NET properties and fields are Ring attributes (Ring calls the generated `getName()` / `setName(value)` automatically, see "Setter and Getter" in the Ring docs), so they are read and written with the simple `oObj.Name` and `oObj.Name = value`, also inside `{ }`; `getName()` / `setName()` can still be called explicitly. Assigning a read-only property raises an error. Properties whose names are Ring keywords (`From`, `To`, `Step`, `On`...) are not attributes: use `getFrom()` / `setFrom(value)`.

```ring
oForm = new Form()
oForm.Text = "Hello"
oForm.Width = 400
? oForm.Controls.Count            # chained: Controls returns a ControlCollection
oForm { Height = 300  Text += "!" }
```

## GUI helpers and applications

`dnImport("System.Windows.Forms")` also loads `libraries/dotnetlib/gui.ring`: `uiForm()`, `uiButton()`, `uiLabel()`, `uiTextBox()`, `uiMemo()`, `uiListBox()`, `uiComboBox()`, `uiPanel()`, `uiPictureBox()`, `uiTimer()`, `uiMenu()`, dialogs (`uiMessage()`, `uiOpenFileName()`...) and a `UiCanvas` class for drawing. `applications/` has complete programs (Calculator, Notepad, games, ...) that run themselves with `--selftest`.

## Ring rules for GUI programs

* The code of an event runs outside the function that set it up: it can only use global variables (create them at the top of the program, then assign them in the function).
* Put the program in functions (`func main`, or functions called from the top) so that loop variables and temporaries are local: in Ring a global variable named like an attribute (`x`, `width`...) is read before `obj.x` is evaluated, and a function that assigns a name that exists as a global changes the global. Keep global only what the code of events needs (the widgets and the state): the code of an event can see globals only.
* Ring keywords are not used as variable or function names, in any letter case: `oK` is `ok`, `step()` is `step`, `To`, `From`, `Load`... Do not define functions named like the built-ins the library uses (`isNumber`, `len`, ...).
* Define the functions after the main code (a `func` at the top takes the rest of the file as its body).
* `dnNull()` is the .NET null (`oPictureBox.Image = dnNull()`).

## WPF

A `using { "System.Windows" ... }` block (it starts the desktop mode with `dnUseDesktop()`) with `"System.Windows"` (and `.Controls`, `.Media`, `.Shapes`, `.Data`, `.Input`, `.Documents`, `.Markup`, ...) wraps WPF: windows, panels, controls, XAML (`wpfXaml()`), data binding, shapes, brushes, animation classes. WPF class names that exist in Windows Forms/System.Drawing too start with `Wpf` (`WpfButton`, `WpfTextBox`, `WpfPoint`, `WpfBinding`); the others keep their name (`Window`, `Grid`, `StackPanel`, `Ellipse`). Helpers in `wpf.ring`: `wpfWindow`, `wpfRun`, `wpfLabel`, `wpfButton`, `wpfBrush`, `wpfXaml`, `wpfFind`, `wpfPixel`, `wpfTest`/`wpfEnd`. See `samples/UsingDotNet/tests/test_wpf.ring`, `samples/UsingDotNet/Wpf` (small samples) and the applications WpfCalculator and WpfColorMixer. In Ring, a global variable named like an attribute (`x`) is read before `obj.X`.

## Entity Framework Core

`using { "RingDotNet.Data" }` (it calls `dnUseData()`) loads Entity Framework Core 9 (SQLite and in-memory providers bundled). A Ring program cannot write C# classes, so the model is described with data (tables, columns, options) and EF Core works on it in two ways:

- `RingDatabase`: rows are lists of `[name, value]` pairs (EF shared-type entities).
- `RingEntityDb`: the tables become real .NET classes (Reflection.Emit) with navigation properties, tracked by EF like classes written in C#.

```ring
load "dotnet.ring"

using { "RingDotNet.Data" }
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

`datetime` columns are `"yyyy-MM-dd HH:mm:ss"` texts and `bytes` columns hex texts (`str2hex`/`hex2str`). `oDb.context()` is the wrapped EF `DbContext`; the classes of `Microsoft.EntityFrameworkCore(.ChangeTracking/.Infrastructure/.Metadata/.Metadata.Builders/.Storage/.Query/.Migrations/.Diagnostics)` and `Microsoft.Data.Sqlite` are wrapped too (clashing names start with `Ef`). Example: `samples/UsingDotNet/applications/Contacts`.

Not supported: classes written in C# source (the entity classes are generated from the schema; there is no C# compiler), lambdas written by hand (queries are data), migrations that alter or drop columns (use `execute`), a typed `RingEntityDb` with hooks/converters/`migrate()`, and the SQL Server / PostgreSQL / MySQL providers were not tested. The packages add about 10 MB to `bin`.

## ASP.NET Core

`using { "RingDotNet.Web" }` (it calls `dnUseWeb()`; before any other .NET call) adds the ASP.NET Core runtime. `web.ring` then gives a Kestrel web server whose requests are handled by Ring functions:

```ring
using { "RingDotNet.Web" }
oServer = new WebServer("http://localhost:5080")
oServer.onGet("/","home")
oServer.onPost("/api/echo","echo")
oServer.run()                                  # serves until stop(); or call serveOne(100) in your own loop

func home oRequest

	return "<h1>Hello</h1>" + oRequest.path()
func echo oRequest

	return [201,"text/plain","you sent " + oRequest.body()]     # or webJson(list)
```

A handler gets a request (`method()`, `path()`, `query("q")`, `body()`, `header()`, `form()`, `context()` = the ASP.NET `HttpContext`) and returns a text, `[status, contentType, text]` or `webJson(...)`. Kestrel runs on .NET threads and Ring code may only run on the Ring thread, so the requests are queued and `serveOne()` / `run()` handle them on the Ring thread. The ASP.NET classes (`Microsoft.AspNetCore.*`, `Microsoft.Extensions.*`, `Microsoft.Net.Http.Headers`; clashing names start with `Asp`) are wrapped too. `dnUseAll()` starts Windows Forms/WPF and ASP.NET together. Example: `samples/UsingDotNet/applications/WebApi` (JSON to-do API and web page), tests: `samples/UsingDotNet/tests/test_web.ring`. Not supported: MVC controllers/Razor written in C# (the web server is the Ring one), and handlers that run in parallel (one Ring thread).

## Keyboard in games

A button (or any control that takes the focus) steals the arrow keys, Space and Enter from the form: the form's `KeyDown` never sees the arrows and Space/Enter "press" the button. Use `uiGameKeys(oForm,"keyPressed(aDotNetArgs[2].KeyCode)")` after the controls were added: every control then reports the arrows as normal keys and the form handles them (Tetris, 2048, Sokoban, Snake and Pong do). In tests, `uiSendKeys(oForm,"{LEFT}12{+}30{ENTER}")` types into the focused control of the form through the real key processing (it posts window messages to your own form, so unlike `SendKeys` it can never type into another program). `samples/UsingDotNet/tests/test_keyboard.ring` shows the problem and the fix.

## Calling Ring code from .NET (callbacks)

Pass `dnCallback(cCode)` wherever a .NET delegate is expected (`Action`, `Func`, `Predicate`, `Comparison`, `EventHandler`, ...). The bridge builds a delegate of the exact type. When .NET invokes it, the Ring code runs, as in RingQt events: it can read `aDotNetArgs` (the list of delegate arguments) and set `xDotNetResult` (converted to the delegate's return type).

```ring
nTotal = 0
oList.@ForEach(dnCallback("nTotal += len(aDotNetArgs[1])"))           # ForEach is a Ring keyword, so @ForEach
oList.Sort(dnCallback("xDotNetResult = len(aDotNetArgs[1]) - len(aDotNetArgs[2])"))
oList.FindAll(dnCallback("xDotNetResult = left(aDotNetArgs[1],1) = 'a'"))
```

If the text is just a function name, that function is called with the argument list as its only parameter and its return value is the result (define the function after the main code):

```ring
oList.@ForEach(dnCallback("show"))
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

Write the `using` block first (a `System.Windows*` or `System.Drawing*` name calls `dnUseDesktop()`; it adds the Windows Desktop runtime and makes the Ring thread an STA thread). The Ring thread then runs the message loop in `Application.Run(form)`, so event code runs normally:

```ring
using { "System.Windows.Forms" }
oForm = new Form()
oButton = new Button()
oButton.setText("Click me")
oButton.setClickEvent("oForm.setText('Clicked!')")
oForm.getControls().Add(oButton)
new Application().Run(oForm)
```

Every class of `System.Windows.Forms` and `System.Drawing` has a generated class. Events must be raised on the Ring thread (UI events are; timers and tasks are not).

## Architecture

```
Ring program ── dotnetlib (Ring)  ──  ring_dotnet.dll (C, hosts the CLR)  ──  RingDotNet.Bridge.dll (C#, reflection)
```

* `extensions/ringdotnet/ring_dotnet.c` — `dotnet_start()`, `dotnet_invoke(cRequest)`, `dotnet_info()`, the callback pair (`dotnet_callbackrequest`, `dotnet_callbackresult`) and the managed pointers that release .NET objects when Ring drops them (`dotnet_guard`, `dotnet_unguard`, `dotnet_pending`, `dotnet_flush`). It finds `hostfxr` (`DOTNET_ROOT`, then the default install folder), starts the runtime with `RingDotNet.Bridge.runtimeconfig.json` and binds `Bridge.Invoke`.
* `extensions/ringdotnet/bridge` — the managed bridge. .NET objects stay in a handle table; Ring only holds numeric handles. Overloads are chosen by the values you pass (and by parameter names in a `[ :name = value ]` list); Ring numbers convert to any numeric type or enum, strings to enums/char/Guid/Type, lists to arrays.
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

## Wrapped namespaces (see tools/dotnettools/dotnetmanifest.ring)

System, System.Text(.Json/.Encodings/.RegularExpressions/.Unicode), System.IO(.Compression/.Pipes/.MemoryMappedFiles), System.Linq, System.Collections(.Generic/.Specialized/.Concurrent/.ObjectModel), System.Threading(.Tasks), System.Net(.Http/.Sockets/.NetworkInformation/.Mail/.WebSockets/.Security), System.Globalization, System.Security.(Cryptography/Principal/Claims/X509), System.Diagnostics, System.Xml(.Linq/.XPath/.Schema/.Serialization/.Xsl), System.Data(.Common/.SqlTypes), System.ComponentModel, System.Reflection, System.Runtime.InteropServices/Loader, System.Numerics, System.Timers, System.Formats.Tar, System.Resources, Microsoft.Win32, System.Drawing(.Drawing2D/.Imaging/.Text/.Printing) System.Windows.Forms(.Layout/.VisualStyles), WPF (System.Windows and its `.Controls`, `.Media`, `.Shapes`, `.Data`, `.Input`, `.Documents`, `.Markup`...), ASP.NET Core and `Microsoft.Extensions.*`, Entity Framework Core with `Microsoft.Data.Sqlite`, System.Net.Http.Json, System.Linq.Expressions, System.Transactions, System.ComponentModel.DataAnnotations and System.Runtime.Serialization. Not wrapped: packages that are not part of the .NET runtime (use `wrapassembly.ring`).

## Limits

* Ring code runs on one thread: a callback that .NET invokes from another thread is not run, and web handlers do not run in parallel (see *Rules and limits* in the documentation).
* A class written in C# cannot be declared in Ring: write it in C#, build a DLL and wrap it (`tools/dotnettools/wrapassembly.ring`).
* Windows Forms and WPF need Windows; everything else runs on Windows, Linux and macOS (macOS and arm64 are not tested yet).
* .NET objects are released when Ring drops them (a managed pointer queues the handle, and the handles are released in groups); `release()` releases one at once.

## Packaging

The package installs from one zip file, `extensions/ringdotnet.zip` (`setup.ring` extracts it into the Ring folder and `uninstall.ring` removes it), like the RingQt6 package. After changing the library, the samples, the DLLs or the tests, rebuild the zip before you commit:

```
python tools/dotnettools/makepackage.py
```

## Version and changes

The package version is in `package.ring`; the changes are in [CHANGELOG.md](CHANGELOG.md). The package is tested with Ring 1.28 and .NET 9.
