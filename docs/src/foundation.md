---
title: The .NET class library
lead: A tour of the base class library as seen from Ring — dates, text, files, regex, compression, networking, cryptography, XML, JSON, data tables, reflection and big numbers. Every program on this page is a real sample and the output is real.
---

## What is wrapped

Every namespace below has generated classes, loaded on demand with `dnImport("Name")`.

| Area | Namespaces |
|---|---|
| Core | `System`, `System.Globalization`, `System.Numerics`, `System.Reflection`, `System.Runtime.InteropServices`, `System.Runtime.Loader`, `System.ComponentModel`, `System.Resources` |
| Text | `System.Text`, `System.Text.RegularExpressions`, `System.Text.Json`, `System.Text.Json.Nodes`, `System.Text.Encodings.Web`, `System.Text.Unicode` |
| Files and streams | `System.IO`, `System.IO.Compression`, `System.IO.Pipes`, `System.IO.MemoryMappedFiles`, `System.Formats.Tar` |
| Collections | `System.Collections`, `.Generic`, `.Specialized`, `.Concurrent`, `.ObjectModel` |
| Networking | `System.Net`, `.Http`, `.Http.Headers`, `.Sockets`, `.NetworkInformation`, `.Mail`, `.WebSockets`, `.Security`, `.Mime` |
| Security | `System.Security.Cryptography`, `.X509Certificates`, `System.Security.Claims`, `System.Security.Principal` |
| XML and data | `System.Xml`, `.Linq`, `.XPath`, `.Schema`, `.Serialization`, `.Xsl`, `System.Data`, `.Common`, `.SqlTypes` |
| Processes and threads | `System.Diagnostics`, `System.Threading`, `System.Threading.Tasks`, `System.Timers` |
| Graphics | `System.Drawing`, `.Drawing2D`, `.Imaging`, `.Text`, `.Printing` |
| UI | `System.Windows.Forms`, WPF — see [Windows Forms](winforms.html) and [WPF](wpf.html) |
| Web and data | ASP.NET Core, Entity Framework Core — see [ASP.NET Core](aspnet.html) and [Entity Framework](ef.html) |

Other namespaces and any DLL: [Your own assemblies](own-assemblies.html).

## Dates, strings, conversions, math

`DateTime`, `TimeSpan`, `Convert`, `Math`, `String` helpers, `Guid`, `Random`, `Environment`:

{{source:samples/UsingDotNet/test08_system.ring}}

{{output:samples/UsingDotNet/test08_system.ring}}

## Files, regular expressions and compression

`File`, `Directory`, `Path`, `StreamReader`/`StreamWriter`, `MemoryStream`, `Regex`, `GZipStream`:

{{source:samples/UsingDotNet/test09_io_regex.ring}}

{{output:samples/UsingDotNet/test09_io_regex.ring}}

## Networking

`Uri`, `IPAddress`, `Dns`, `HttpClient`, `WebUtility`, `Encoding` — a program that does not need the internet to run:

{{source:samples/UsingDotNet/test12_network.ring}}

{{output:samples/UsingDotNet/test12_network.ring}}

> [!TIP] For HTTP requests use `HttpClient`. Methods that return a `Task` give you an object: call `Wait()` and read `getProp("Result")`. A complete example is the self test of [`applications/WebApi`](aspnet.html).

## Cryptography and globalization

Hashes (`SHA256`, `MD5`), HMAC, random bytes, AES, culture-aware formatting:

{{source:samples/UsingDotNet/test13_security.ring}}

{{output:samples/UsingDotNet/test13_security.ring}}

## XML, JSON and data tables

`XmlDocument`, `XPath`, `System.Text.Json`, `DataTable` and `DataView` — no database needed:

{{source:samples/UsingDotNet/test14_xml_json_data.ring}}

{{output:samples/UsingDotNet/test14_xml_json_data.ring}}

## Reflection and big numbers

`Type`, `Assembly`, `MethodInfo`, `BigInteger`, `Complex`:

{{source:samples/UsingDotNet/test15_reflection_numbers.ring}}

{{output:samples/UsingDotNet/test15_reflection_numbers.ring}}

## Processes and threads

```ring
using {
	"System.Diagnostics"
	"System.Threading.Tasks"
}

oInfo = new ProcessStartInfo() {
	FileName = "cmd"
	Arguments = "/c ver"
	RedirectStandardOutput = True
	UseShellExecute = False
	CreateNoWindow = True
}
oProcess = new Process().Start_1(oInfo)
? trim(oProcess.StandardOutput.ReadToEnd())
oProcess.WaitForExit()

oTask = new Task().Delay(30)                    # a Task: wait for it on the Ring thread
oTask.Wait()
? oTask.IsCompleted

oResult = new Task().FromResult("done")
? oResult.getProp("Result")                      # the Result of a Task<T>
```

> [!WARNING] .NET threads can **not** run Ring code. A callback invoked from a pool thread prints a message on stderr and does nothing. Use tasks for pure .NET work (HTTP, files, hashing), then `Wait()` for them on the Ring thread.

## A bigger example

`samples/UsingDotNet/test16_forms_app.ring` and `demo_todo.ring` combine collections, files, JSON and a form. For complete programs see [Applications](gallery-apps.html).
