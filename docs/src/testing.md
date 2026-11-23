---
title: Testing
lead: Every feature has a test, every sample and application tests itself, and your own programs can do the same.
---

## The test suite

```bash
sh samples/UsingDotNet/tests/run.sh ring.exe
```

`samples/UsingDotNet/tests/run.sh` runs:

1. every `samples/UsingDotNet/tests/test_*.ring` (language bridge, collections, LINQ, system, IO, net, services, web, data, entity framework, keyboard, WPF, your own assemblies...),
2. the package tests (see below),
3. the console samples,
4. every tutorial program (the ones with a window test themselves with `--selftest`, the others just have to run without an error),
5. every Windows Forms and WPF sample with `--selftest`,
6. every application with `--selftest`,

and prints `0 failed` when everything passes. It needs the package `bin` folder on the PATH; the script adds it for you.

Programs run four at a time, and the windows of the programs that run themselves are invisible and not in the taskbar, so the run takes a few minutes and does not take over your screen. The tutorials about packages run `dotnet publish`: they need the .NET SDK and, the first time, the internet to get the packages; they run one at a time, because several builds together fail. A tutorial that makes errors on purpose says `# errors on purpose` on its first lines, and then only an error that was not caught fails it. While you work, run the **quick tier**, which is only the tests and the console samples and takes about 25 seconds:

```bash
sh samples/UsingDotNet/tests/run.sh ring.exe --quick
```

Options: `--no-packages` leaves out the package tests, `--packages-only` runs only them, `--jobs N` runs N programs at the same time (`--jobs 1` runs them one after the other, which is easier to read when something fails), and `--show` keeps the windows visible so you can watch them (or set the environment variable `RINGDOTNET_SHOW`). Run everything before a commit.

On **Linux** the same script runs the tests, the samples and the package tests; the Windows Forms and WPF programs are the only ones that cannot pass there, because they need the Windows Desktop runtime. The package tests restore the packages again for the system (a package with a native library has one for each system), so the cache of one system is not used by the other.

| Test file | Covers |
|---|---|
| `test_foundation.ring`, `test_runtime.ring`, `test_after_error.ring` | the bridge: types, overloads, properties, enums, errors, a call after a caught error |
| `test_collections.ring`, `test_linq.ring` | typed collections, LINQ |
| `test_operators.ring`, `test_span.ring`, `test_refstruct.ring` (also IAsyncEnumerable), `test_pointer.ring`, `test_exceptions.ring` | operators and conversions of .NET types, Span parameters and results, ref structs, pointers, exception and attribute classes |
| `test_system.ring`, `test_io.ring`, `test_net.ring`, `test_services.ring` | the class library |
| `test_access.ring` | Microsoft Access through ODBC (`System.Data.Odbc`): makes an `.accdb` file with ADOX, tables, parameters, NULL, Unicode, transactions. Windows with the 64-bit Access Database Engine only; it prints `SKIPPED` and passes anywhere else |
| `test_desktop.ring`, `test_keyboard.ring` | Windows Forms, key handling |
| `test_wpf.ring` | WPF |
| `test_web.ring` | ASP.NET Core server |
| `test_data*.ring` | Entity Framework: schema, relations, transactions, migrations, providers, queries, hooks, entities |
| `test_userassembly.ring` | your own assemblies: generated classes, interfaces, explicit implementations, extension methods (also of a struct taken by reference and of a delegate type), enum parameters, `params` arrays, `dnIsNull`, renamed classes |
| `test_import_folder.ring`, `test_classindex.ring`, `test_interface_members.ring` | loading generated classes from a folder, the class index, interfaces that inherit members |
| `test_native_call.ring`, `test_handles.ring`, `test_overload_choice.ring`, `test_named.ring`, `test_guard.ring` | the native call path, the release of handles, the choice of an overload, named arguments, the managed pointers |
| `test_binary.ring`, `test_encodings.ring` | binary data: every byte value in texts, streams, files, Base64, hashes and byte buffers; legacy code pages (Windows-1256, Shift-JIS, Latin-1) as bytes |
| `test_channels.ring` | `System.Threading.Channels`: generic types without a Ring class, read with `getProp` and `callMethod`, an `out` value, an optional parameter left out |
| `test_extension_methods.ring`, `test_more_classes.ring`, `test_new_forms.ring` | extension methods and `@` names, classes added after the coverage audit, the forms of `new` |
| `test_using*.ring` | `using { }` and the runtime mode that the namespaces start |
| `test_ready_classes.ring`, `test_smoke_classes.ring` | every ready generic class is a real object; about 200 classes of twenty namespaces are created and given harmless calls (`ToString`, `Equals`, the `Get`, `To` and `Is` methods) |

## Package tests

`samples/UsingDotNet/tests/packages/pkgtest_*.ring` are real programs against NuGet packages: FluentValidation, AutoMapper and MediatR (with a helper project, see below), Stateless, Cronos, Hashids, UnitsNet, BCrypt.Net, AngleSharp, DynamicExpresso, Ardalis.GuardClauses, SharpCompress, K4os LZ4, Google.Protobuf, Portable.BouncyCastle, Ical.Net, OneOf, NSubstitute, Lucene.Net, Microsoft.Extensions.DependencyInjection and Configuration, System.Linq.Async, MoreLINQ, Tomlyn, DiffPlex, Sqids, Handlebars.Net, Fluid, CliWrap, Castle DynamicProxy (a helper project with the interceptor), Slugify, Fastenshtein, Semver, HtmlSanitizer, MimeKit, NetTopologySuite, JsonSchema.Net, libphonenumber, IPNetwork2, LiteDB, MessagePack and CommandLineParser (a helper project with the classes that have the attributes), Roslyn (compiles and runs C# in memory), System.Reactive, LibGit2Sharp (a native library), FluentAssertions, xunit.assert, Shouldly, Dapper with classes (`Query<Person>`), Quartz (jobs on other threads, a helper project), Newtonsoft.Json, CsvHelper, SharpZipLib, HtmlAgilityPack, Serilog, Spectre.Console, Scriban, Markdig, YamlDotNet, Humanizer, Jint, NodaTime, Math.NET Numerics, Bogus, Polly, Dapper with Microsoft.Data.Sqlite, the SQLite provider used directly (whole numbers, fractions, blobs, transactions), a loop that creates thousands of objects (handle release), and text in Arabic, Chinese and emoji, plus every byte value, through JSON, YAML, Markdown and LZ4, Flurl (URLs built and taken apart), QRCoder (PNG bytes and SVG of a QR code), TimeZoneConverter (IANA and Windows zone names, daylight saving), SmartFormat (plurals, conditions, lists), Ulid (a struct identifier), Sprache (parser combinators: a delegate type with extension methods, called on the object), ByteSize (a struct with operators), DotLiquid (templates over a Hash), Fare (random text from a regular expression), ReverseMarkdown (HTML to Markdown), Stubble (Mustache templates), FuzzySharp (fuzzy matching), ClosedXML (an Excel workbook, saved and read again), System.IO.Hashing (CRC-32 and xxHash over bytes), RecyclableMemoryStream (pooled streams, every byte value), NCalc (expressions, parameters, functions), Sep (a CSV reader on spans and ref structs), MiniExcel (an xlsx written and read as rows), Microsoft.Extensions.Caching.Memory (a cache, an out value, expiry), SimpleBase (Base16, Base32 and Base58), Otp.NET (the HOTP and TOTP test vectors), Argon2 (password hashes), Unidecode.NET (Unicode to ASCII), CommonMark.NET (Markdown), UAParser (user agent rules), NUglify (minified JavaScript, CSS and HTML), ExCSS (a CSS parser), BitFaster.Caching (a generic LRU cache), AutoFixture (generated test data), Autofac (a container of .NET types), PdfPig (text from a PDF file), System.Linq.Dynamic.Core (LINQ conditions as text), Mapster (object mapping with two type arguments), Pidgin (parser combinators on classes), Jsonata.Net.Native (JSONata queries over JSON text), GeoJSON.Net (geometry objects with Newtonsoft.Json), ZXing.Net (a QR code encoded, drawn as pixel bytes and decoded again), jose-jwt (signed tokens with a byte key), NLog (a configuration made in code, a memory target), RestSharp (requests and addresses built without sending), Snappier and ZstdSharp (compression of byte arrays through spans), log4net (a repository configured in code), VaderSharp2 (sentiment scores), Porter2Stemmer (word stems), Fizzler (CSS selectors over HtmlAgilityPack nodes), SqlKata (a query builder compiled for several databases), System.Threading.RateLimiting (limiters made from options), MimeMapping (media types of file names), NCrontab (cron schedules), DiffMatchPatch (diffs and patches of texts), FluentResults (result objects), Ben.Demystifier (readable stack traces), ExcelDataReader (an xlsx read row by row), Microsoft.Extensions.FileSystemGlobbing (file patterns over a folder), CSharpFunctionalExtensions (Result and Maybe), Microsoft.Extensions.Primitives (string values, segments and tokens), PeterO.Cbor (CBOR bytes), Newtonsoft.Json.Bson (BSON bytes in a memory stream), Crc32.NET (checksums), NetMQ (sockets talking through an in-process address), Apache.Avro (schemas), Pluralize.NET (English plurals), ConsoleTables (text tables), Figgle (ASCII art text), Fractions (exact fractions with operators), MathNet.Spatial (3D points and vectors) ProjNet (coordinate transformations), Mono.Cecil (the metadata of an assembly file), DotNetZip (a zip archive in memory) SmartReader (the article of an HTML page), LazyCache (a cache with a Ring callback that makes the value), ICSharpCode.Decompiler (C# source from an assembly file) DocumentFormat.OpenXml (a Word document built as objects), SimpleInjector (a container with Ring delegates), Sylvan.Data.Csv (a CSV text as a data reader) and Makaretu.Dns (DNS messages in the wire format). Each one asks `dnAssert` about what the package gives back (HTML, a deserialized list, a determinant, a retried call, rows from a query), so a change of the bridge that breaks a library fails here before it fails in a program.

A test is a Ring file in `samples/UsingDotNet/tests/packages`, next to `pkg.ring`, and it starts with `pkgUse` (run one with `ring pkgtest_markdig.ring` in that folder):

```ring
load "pkg.ring"
pkgUse("markdig",[["Markdig","1.6.0"]],[["Markdig.dll",["Markdig","Markdig.Syntax"]]])
pkgImport("markdig","Markdig.dll","Markdig")
```

`pkgUse` restores the packages with `dotnet publish` and makes the Ring classes of the DLLs (only the namespaces that you list: the classes of a type that a method returns must be in the list; a DLL listed with no namespaces is only loaded), and keeps both in `packages/.cache`, so only the first run is slow. The versions are pinned, so a test says what works with those versions. A computer that cannot reach nuget.org on the first run prints `SKIPPED` and the runner shows `skipped`, not `FAILED`. The cache is large (hundreds of megabytes after the first full run) and is not in git; it is made again whenever it is deleted. To add a package, copy one of the tests, and run `sh run.sh --packages-only`. A package that needs a class written in .NET (a validator that derives from `AbstractValidator<T>`, a mapping profile, request handlers, an interceptor that calls a Ring callback, a class with `[MessagePackObject]` or `[Option]` attributes, a job of a scheduler) uses a small helper project: `packages/helpers/PkgHelpers`, `CastleHelpers`, `AttributeHelpers` and `QuartzHelpers` have those classes, and `pkgUseProject("fluentvalidation","helpers/PkgHelpers",[["FluentValidation.dll",[...]],["PkgHelpers.dll",["PkgHelpers"]]])` publishes it (the packages it references come with it) and wraps the DLLs in the order given (a package first, then the helper whose classes derive from it). The cache is made again when a file of the helper project changed. The newest versions of many packages are audited by `tools/dotnettools/auditpackages.py` (see [The generator](generator.html)).

## dnAssert

```ring
load "dotnet.ring"
using { "System" }

dnAssert("max",new Math().Max(3,9),9)
dnAssert("abs",new Math().Abs(-5),5)
dnTestSummary()
```

```output
TESTS: 2 passed, 0 failed
```

A failing assertion prints `FAIL: name expected <9> got <3>` and counts a failure. `dnTestSummary()` returns the number of failures.

## Programs that test themselves

The checks of a window program are kept in a file of their own, so the program stays as short as the lesson that shows it. The program is the usual one (here it is the file `counter.ring`):

```ring
oForm = uiForm("Click counter",260,130)
...
uiRun(oForm)
```

and next to it, in the folder `selftest`, the file with the same name (`selftest/counter.ring`) holds the checks:

```ring
func selfTest
	oForm.Controls.Item(1).PerformClick()
	dnAssert("one click",oCount.Text,"1 clicks")
```

```bash
ring counter.ring               # the normal program
ring counter.ring --selftest    # the test: prints SELFTEST OK
```

With `--selftest`, `uiRun` loads that file, shows the form, runs `selfTest()` once the form is shown, closes the form and prints the result. The form must be in the global variable `oForm` (WPF: `oWindow`, with `wpfRun`). A program without a `selftest` file runs normally; the functions `uiTest(oForm, code)` and `uiEnd()` (`wpfTest`, `wpfEnd`) do the same steps by hand for a program that keeps its checks inside. `uiMessage()` prints instead of showing a dialog in a test, and `uiAsk()` prints the question and answers yes.

## Typing keys in tests

`uiSendKeys(oForm,"12{+}30{ENTER}")` types into the focused control of **your own form**. It posts window messages through the real Windows Forms key processing, so it behaves like a user and can never type into another program (which `SendKeys` could). Keys: `{LEFT} {RIGHT} {UP} {DOWN} {ENTER} {ESC} {BACKSPACE} {TAB} {DELETE}`, `{+}` for a plus sign.

## Testing the screenshots

The screenshots in this documentation are made by `docs/tools/shoot_all.sh`: it starts each sample, finds its window, captures it with `PrintWindow` and closes it.

## Where to go next

- [Rules and limits](rules-and-limits.html): the points to know before a long program.
- The tutorial chapter [Testing and release](tutorials.html#testing-and-release) shows tests in a real project.
