---
title: How it works
lead: The Ring process hosts the .NET runtime and talks to it through a small managed bridge. This page explains the pieces, so the rest of the documentation makes sense.
---

## The layers

<svg viewBox="0 0 760 330" style="width:100%;max-width:760px;display:block;margin:20px auto" role="img" aria-label="Architecture of RingDotNet">
<defs><linearGradient id="g1" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#5b3fd1"/><stop offset="1" stop-color="#00a3b4"/></linearGradient></defs>
<g font-family="Segoe UI, system-ui, sans-serif" font-size="14">
<rect x="20" y="10" width="720" height="54" rx="12" fill="var(--accent-soft)" stroke="var(--accent)"/>
<text x="380" y="34" text-anchor="middle" fill="var(--text)" font-weight="700">Your Ring program</text>
<text x="380" y="53" text-anchor="middle" fill="var(--muted)" font-size="12.5">oSB = new StringBuilder("Hi")   ·   oForm.Text = "Hello"   ·   oBtn.setClickEvent("...")</text>
<rect x="20" y="84" width="720" height="54" rx="12" fill="var(--soft)" stroke="var(--line)"/>
<text x="380" y="108" text-anchor="middle" fill="var(--text)" font-weight="700">dotnetlib (Ring library)</text>
<text x="380" y="127" text-anchor="middle" fill="var(--muted)" font-size="12.5">generated wrapper classes · using · dnCallback · gui.ring · wpf.ring · web.ring · data.ring</text>
<rect x="20" y="158" width="720" height="54" rx="12" fill="var(--soft)" stroke="var(--line)"/>
<text x="380" y="182" text-anchor="middle" fill="var(--text)" font-weight="700">ring_dotnet.dll (C extension)</text>
<text x="380" y="201" text-anchor="middle" fill="var(--muted)" font-size="12.5">starts the runtime through hostfxr · sends requests · runs Ring callbacks</text>
<rect x="20" y="232" width="720" height="40" rx="12" fill="url(#g1)"/>
<text x="380" y="257" text-anchor="middle" fill="#fff" font-weight="700">RingDotNet.Bridge.dll (C#): reflection, handle table, type conversion, delegates</text>
<rect x="20" y="288" width="230" height="34" rx="10" fill="var(--panel)" stroke="var(--line)"/><text x="135" y="310" text-anchor="middle" fill="var(--text)">.NET class library</text>
<rect x="265" y="288" width="230" height="34" rx="10" fill="var(--panel)" stroke="var(--line)"/><text x="380" y="310" text-anchor="middle" fill="var(--text)">WinForms · WPF · ASP.NET · EF</text>
<rect x="510" y="288" width="230" height="34" rx="10" fill="var(--panel)" stroke="var(--line)"/><text x="625" y="310" text-anchor="middle" fill="var(--text)">Your DLLs and NuGet packages</text>
</g></svg>

## The extension and the bridge

`ring_dotnet.dll` is a normal Ring extension written in C. When the first .NET call is made it:

1. finds the installed .NET runtime and starts it **inside the Ring process** with `hostfxr` (no separate process, no IPC),
2. loads `RingDotNet.Bridge.dll`, a small C# assembly,
3. keeps one entry point for requests: `dotnet_invoke(request)`. (The extension also has the functions for callbacks and for releasing objects, below.)

The bridge uses reflection. A Ring call such as `oSB.Append(", ")` becomes a request `call [handle, "Append", ", "]`; the bridge finds the right overload from the argument types, invokes it, and returns the result.

## Handles

.NET objects never leave .NET. Ring holds a **handle** (a number) inside a `DotNetObject`, and the bridge keeps the real object in a table. The generated wrapper classes are `DotNetObject`s with typed methods, so `oSB.Append(...)` and `oSB.callMethod("Append",[...])` do the same thing.

### Releasing objects

A handle keeps its object alive, so handles must be released. Each wrapper object holds a **managed pointer** (a Ring pointer with a function that runs when Ring drops the value). When the wrapper is dropped, the pointer queues the handle, and the queued handles are released in groups of 32, so a program that makes thousands of objects does not grow without end. `release()` releases one handle at once, and `dnFlush()` releases the queued ones now (the tutorial [Memory and the garbage collector](tut-98-memory.html)).

## The wire format

Values travel as a compact tagged text: `s5:Hello` (string), `n2:42` (number), `l...` (list), `o3:17` (object handle), `c...` (callback), `e...` (error). Numbers that are not whole travel as the 8 bytes of the double, so there is **no loss of precision**. Binary data (`byte[]`) travels as a Ring string: a Ring text can hold any byte. A `ByteBuffer` object (`dnBuffer`) is the one case where Ring holds a live array, for the methods that fill an array that you pass in.

## Generated wrapper classes

`tools/dotnettools/gendotnet.ring` reads the **manifest** (`tools/dotnettools/dotnetmanifest.ring`) and uses reflection to write one Ring class per .NET class into `libraries/dotnetlib/generated/` (two files per namespace: a loader and the classes). These files are plain Ring source with real inheritance, properties (as attributes with `getX`/`setX`), events and enums. `using { "System.IO" }` loads one namespace on demand. A class index lets the library import the right namespace automatically when a returned object has a type that is not loaded yet.

## Results are wrapped by their real type

When a method returns an object, the bridge sends the list of its type and base types. `dnWrapObject` looks for the **most specific** generated class (importing its namespace if needed) and creates it. If no class exists the result is a plain `DotNetObject` — use `callMethod` and `getProp` on it.

## Callbacks: Ring code called from .NET

`dnCallback("...")` passes Ring code where .NET expects a delegate. The bridge builds a delegate of the exact type with a compiled expression; when .NET invokes it, the C extension runs the Ring function on the **Ring thread** and returns its result. Callbacks run synchronously during a call, which is why events from timers on other threads are ignored (see [Rules and limits](gotchas.html)).

## Threads

| Thread | What runs there |
|---|---|
| The Ring thread | All Ring code, all calls into .NET and all callbacks. With `dnUseDesktop()` it is an **STA** thread and runs the message loop in `Application.Run()`. |
| .NET threads | Kestrel connections, tasks, timers. They never call Ring directly. The web server queues requests and Ring handles them in `serveOne()`. |

## Runtime modes

The runtime is configured with one of four `runtimeconfig.json` files: base (`RingDotNet.Bridge`), desktop (`RingDotNet.Desktop`), web (`RingDotNet.Web`) and all (`RingDotNet.All`). `dnUseDesktop()`, `dnUseWeb()` and `dnUseAll()` select the file before the runtime starts. `dnUseData()` only loads the Entity Framework assemblies; an `AssemblyResolve` handler in the bridge finds them next to it.

## Speed

A call from Ring to .NET is a request that Ring packs, the extension sends to the bridge, and the bridge runs by reflection. The numbers below are for a Windows computer with Ring 1.28 and .NET 9; `samples/UsingDotNet/tests/bench_calls.ring` measures them on yours.

| Call | Time | Calls in a second |
|---|---|---|
| a method that returns a text, a number or a yes/no (`oList.Contains("a")`), a property read (`oSB.Length`) | 2 to 3 µs | 350,000 to 450,000 |
| a static method with numbers (`new Math().Max(1,2)`) | 3 to 4 µs | about 300,000 |
| a method that returns an object (`oSB.Append("x")`) | about 60 µs | about 17,000 |
| `new StringBuilder("x")` | about 25 µs | about 40,000 |

How the time is spent:

- The first group is packed and read **in C**: the generated method calls `dotnet_call` with the handle of the object, the name of the method (a ready wire item) and the arguments, and the extension builds the request, calls the bridge and returns the text, number or yes/no. The call into .NET itself (decoding, reflection, encoding the answer) takes about 0.5 µs.
- The bridge **remembers the overload** that it chose for a kind of arguments (the type; for a number, whole or not and its range; a text only when no overload could read it as an enum or another type), so `Math.Max`, which has 14 overloads, costs about the same as a method with one.
- A method that returns an **object** takes more time: Ring makes the wrapper object with its guard and copies it at each `return` level.
- A call with an **object or a list as an argument** takes the Ring path (`dnSend`, about 8 µs), and so does a call with named arguments.
- Fewer crossings are faster than faster crossings: `toList()` copies a whole collection in one request, and a loop that reads 500 items with `Item(i)` makes 500 requests.

## Packages

| File | Role |
|---|---|
| `ring_dotnet.dll` | C extension |
| `RingDotNet.Bridge.dll` | reflection bridge |
| `RingDotNet.Web.dll` | request queue and Kestrel host |
| `RingDotNet.Data.dll` | `RingDb` and `RingTypedDb` (Entity Framework) |
| `Microsoft.EntityFrameworkCore*.dll`, `e_sqlite3.dll` ... | Entity Framework Core and SQLite |

## Where to go next

- [Core concepts](concepts.html): how .NET names, overloads, properties and enums look in Ring.
- [The basics](tutorials.html#the-basics): the first tutorial chapter, if you prefer to learn by writing programs.
