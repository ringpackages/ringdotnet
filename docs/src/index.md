---
title: RingDotNet
lead: Use .NET classes and methods from Ring programs
---

<div class="hero">
<h1>RingDotNet</h1>
<p>Call any .NET class from Ring with simple syntax. Build Windows Forms and WPF programs, web servers with ASP.NET Core, and databases with Entity Framework — all in Ring.</p>
<div class="btns"><a class="btn primary" href="getting-started.html">Get started</a><a class="btn ghost" href="gallery-apps.html">See the applications</a><a class="btn ghost" href="reference.html">Function index</a></div>
</div>

{{stats}}

## A first taste

```ring
load "dotnet.ring"
using {
	"System"
	"System.Text"
}

oSB = new StringBuilder("Hello")
oSB.Append(", ").Append("Ring!")
? oSB.ToString()                   # Hello, Ring!
? oSB.Length                       # 12

? new Math().Max(3,9)              # 9
? new Math().Sqrt(144)             # 12
```

The classes are real Ring classes with the same method names as the .NET ones — like RingQt for Qt — so code completion, inheritance and ordinary Ring syntax just work. There is no `eval` and no string-based dispatch in your code.

## What is inside

<div class="cards">
<a class="card" href="concepts.html"><div class="ic">🔌</div><b>Simple syntax</b><span>oObj.Method(), oObj.Property = x, enums as strings, events with setClickEvent().</span></a>
<a class="card" href="foundation.html"><div class="ic">📚</div><b>The class library</b><span>Strings, dates, files, regex, networking, crypto, XML, JSON, reflection, LINQ and more.</span></a>
<a class="card" href="callbacks-events.html"><div class="ic">🔁</div><b>Callbacks and events</b><span>Pass Ring code wherever .NET expects a delegate, as RingQt does with events.</span></a>
<a class="card" href="winforms.html"><div class="ic">🪟</div><b>Windows Forms</b><span>All controls wrapped, plus short helpers: uiForm(), uiButton(), UiCanvas for drawing.</span></a>
<a class="card" href="wpf.html"><div class="ic">🎨</div><b>WPF</b><span>Windows, XAML, data binding, shapes, brushes and animation.</span></a>
<a class="card" href="aspnet.html"><div class="ic">🌐</div><b>ASP.NET Core</b><span>A Kestrel web server whose routes are Ring functions. JSON in one call.</span></a>
<a class="card" href="ef.html"><div class="ic">🗄️</div><b>Entity Framework Core</b><span>Tables, relations, migrations, queries as expression trees, typed entities.</span></a>
<a class="card" href="api.html"><div class="ic">📖</div><b>Class reference</b><span>Every wrapped class: constructors, properties, methods with their Ring calls, events — @CLASSES@ types.</span></a>
<a class="card" href="own-assemblies.html"><div class="ic">📦</div><b>Your own assemblies</b><span>Wrap any DLL or NuGet package with one command and use it like the built-in classes.</span></a>
<a class="card" href="gallery-apps.html"><div class="ic">🎮</div><b>@APPS@ applications</b><span>Calculator, Notepad, Paint, Tetris, Sudoku, Minesweeper and more — each tests itself.</span></a>
</div>

## See it running

<div class="cards" style="grid-template-columns:repeat(auto-fill,minmax(210px,1fr))">
<a class="card" href="gallery-apps.html#calculator"><img src="img/shots/app-Calculator.png" alt="Calculator" style="max-width:100%;border-radius:8px"></a>
<a class="card" href="gallery-apps.html#notepad"><img src="img/shots/app-Notepad.png" alt="Notepad" style="max-width:100%;border-radius:8px"></a>
<a class="card" href="gallery-apps.html#tetris"><img src="img/shots/app-Tetris.png" alt="Tetris" style="max-width:100%;border-radius:8px"></a>
<a class="card" href="gallery-wpf.html"><img src="img/shots/wpf-03_binding_slider.png" alt="WPF binding" style="max-width:100%;border-radius:8px"></a>
</div>

## How the package is organised

| Folder | Contents |
|---|---|
| `bin/` | `ring_dotnet.dll` (the C extension), the managed bridge, ASP.NET and EF assemblies |
| `libraries/dotnetlib/` | The Ring library: functions, the generated wrapper classes, GUI/WPF/web/data helpers |
| `extensions/ringdotnet/` | C source of the extension and C# source of the bridge, web server and data layer |
| `samples/` | 32 Windows Forms samples, 10 WPF samples and console samples |
| `applications/` | Complete programs |
| `samples/UsingDotNet/tests/` | Automated tests (`run.sh`) |
| `tools/` | The class generators (`gendotnet.ring`, `wrapassembly.ring`) and the manifest |

> [!TIP] New here? Read **Getting started**, then **Core concepts**. Everything after that is a topic you can read in any order.
