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

`samples/UsingDotNet/tests/packages/pkgtest_*.ring` are real programs against NuGet packages: 188 tests, one for each package (the ML.NET package has several). Each one asks `dnAssert` about what the package gives back (HTML, a deserialized list, a determinant, a retried call, rows from a query), so a change of the bridge that breaks a library fails here before it fails in a program. The packages that need a class written in .NET have a small helper project, and the tests that need a native library (LibGit2Sharp, ML.NET, SQLite) run on Windows and on Linux.

### Writing a package test

A test is a Ring file in `samples/UsingDotNet/tests/packages`, next to `pkg.ring`, and it starts with `pkgUse` (run one with `ring pkgtest_markdig.ring` in that folder):

```ring
load "pkg.ring"
pkgUse("markdig",[["Markdig","1.6.0"]],[["Markdig.dll",["Markdig","Markdig.Syntax"]]])
pkgImport("markdig","Markdig.dll","Markdig")
```

To add a package, copy one of the tests and run it, or run all of them with `sh run.sh --packages-only`. What `pkgUse` does:

- It restores the packages with `dotnet publish` and makes the Ring classes of the DLLs. Only the namespaces that you list get classes: the classes of a type that a method returns must be in the list, and a DLL listed with no namespaces is only loaded.
- It keeps both in `packages/.cache`, so only the first run is slow. The cache is large (hundreds of megabytes after the first full run) and is not in git; it is made again whenever it is deleted. The Ring classes of a package are made again, with the packages kept, whenever the generator, the bridge or the generated library changed since they were made, so a test never runs on classes of an old generator.
- The versions are pinned, so a test says what works with those versions.
- A computer that cannot reach nuget.org on the first run prints `SKIPPED`, and the runner shows `skipped`, not `FAILED`.

### Helper projects

A package that needs a class written in .NET uses a small helper project: a validator that derives from `AbstractValidator<T>`, a mapping profile, request handlers, an interceptor that calls a Ring callback, a class with `[MessagePackObject]` or `[Option]` attributes, a job of a scheduler, the rows of an ML.NET model (that helper also references the ML.NET packages for OLS, time series, LightGBM and recommendation). On Linux the MKL library of ML.NET needs the Intel OpenMP runtime (`libiomp5`, for example `apt install libiomp5`); without it the tests that use MKL print a `NOTE` and leave those checks out. `packages/helpers/` has `PkgHelpers`, `CastleHelpers`, `AttributeHelpers`, `QuartzHelpers` and `MlHelpers` with those classes.

`pkgUseProject` publishes a helper project (the packages it references come with it) and wraps the DLLs in the order given: a package first, then the helper whose classes derive from it. The cache is made again when a file of the helper project changed.

```ring
pkgUseProject("fluentvalidation","helpers/PkgHelpers",[["FluentValidation.dll",[...]],["PkgHelpers.dll",["PkgHelpers"]]])
```

The ML.NET tests share their setup in `packages/mlcommon.ring`: `load "mlcommon.ring"` and `mlUse()` restore ML.NET and import its namespaces; `mlNew(seed)` makes a context, `mlColumns([["x","Single"],...])` and `mlLoadCsv(oMl,file,columns)` read a CSV file, `mlColumn(oData,type,name)` gives a column as a Ring list, and `mlWrite(name,text)` writes a file in the cache folder. The AutoML test uses `mlUseAuto()` and the helper project `MlAutoHelpers`, in a cache folder of its own: AutoML brings the deep learning packages, about 400 megabytes.

### Newer versions

The newest versions of many packages are audited by `tools/dotnettools/auditpackages.ring` (see [The generator](generator.html)).

### What the tests cover

Each table lists the packages of an area. The second column is the name of the test file (`pkgtest_<name>.ring`).

#### HTML, Markdown and templates

| Package | Test | What it checks |
|---|---|---|
| AngleSharp | `anglesharp` | an HTML5 parser with the DOM of a browser: CSS selectors, attributes, text, and changing the document |
| HtmlAgilityPack | `htmlagilitypack` | HTML parsed (also bad HTML), XPath, attributes, text, and changing the document |
| Fizzler | `fizzler` | CSS selectors over HtmlAgilityPack nodes |
| HtmlSanitizer | `htmlsanitizer` | unsafe HTML made safe (scripts, event handlers and bad URLs removed), with the lists of allowed tags and attributes |
| SmartReader | `smartreader` | the article of a web page (title, author, text) taken from HTML text |
| ReverseMarkdown | `reversemarkdown` | HTML converted to Markdown |
| Markdig | `markdig` | Markdown to HTML (a static method, then a pipeline object) and the parsed document |
| CommonMark.NET | `commonmark` | the reference Markdown converter and the CommonMark syntax tree |
| Scriban | `scriban` | templates over a Ring list and values: loops, conditions, functions and parse errors |
| Fluid | `fluid` | Liquid templates: a parser, a template context with values, filters, loops, and the errors of parsing |
| DotLiquid | `dotliquid` | templates over a Hash: variables, filters, loops and conditions |
| Handlebars.Net | `handlebars` | templates with values, each, if and blocks; the compiled template is called with a dictionary |
| Stubble | `stubble` | Mustache templates: sections, inverted sections, escaping and partials |
| SmartFormat | `smartformat` | named and indexed placeholders, plurals, conditions and lists |
| ExCSS | `excss` | a CSS parser: the style sheet as objects (rules, selectors, properties) |
| NUglify | `nuglify` | minified JavaScript, CSS and HTML |

#### Parsers, expressions and scripting

| Package | Test | What it checks |
|---|---|---|
| Esprima | `esprima` | the syntax tree of JavaScript source (declarations, functions, expressions, modules) and syntax errors |
| GraphQL-Parser | `graphqlparser` | the syntax tree of a GraphQL document: operations, variables, fields with arguments, selections, fragments |
| Gherkin | `gherkin` | the parser of feature files: features, scenarios, steps, tags, tables, other languages |
| Sprache | `sprache` | parser combinators: a delegate type with extension methods, called on the object |
| Pidgin | `pidgin` | parser combinators on classes, with the input type and the result type as generic arguments |
| Superpower | `superpower` | parser combinators over text with generic type arguments and a callback |
| NCalc | `ncalc` | expressions with parameters and functions, and expressions that are wrong |
| DynamicExpresso | `dynamicexpresso` | C# expressions evaluated at run time, with variables from Ring |
| System.Linq.Dynamic.Core | `dynamiclinq` | LINQ conditions and orderings written as text |
| Jint | `jint` | a JavaScript engine in the process: values go in, scripts run, functions are called, results come back |
| Jsonata.Net.Native | `jsonata` | JSONata queries over JSON text: sums, filters, paths, functions, errors |
| CommandLineParser | `commandlineparser` | options as a class with attributes (a helper project), the parser result and a Ring callback |
| Mono.Options | `monooptions` | an option set with Ring callbacks for the values and the arguments that are not options |
| System.CommandLine | `systemcommandline` | a root command with options, arguments and sub commands parsed from an array, and the action of a command |

#### Text and language helpers

| Package | Test | What it checks |
|---|---|---|
| Humanizer | `humanizer` | extension methods of strings, numbers and time spans |
| Unidecode.NET | `unidecode` | Unicode text turned into ASCII (Cyrillic, Greek, Chinese, accents, emoji) |
| Slugify | `slugify` | URL slugs from texts, with options and replacements of characters |
| Pluralize.NET | `pluralize` | English plurals and singulars |
| Porter2Stemmer | `porter2` | English words reduced to their stems |
| VaderSharp2 | `vader` | sentiment scores of English text |
| Figgle | `figgle` | text as ASCII art in a font |
| ConsoleTables | `consoletables` | a text table from column names and rows, in several formats |
| Spectre.Console | `spectre` | widgets (markup, tables, a panel, a rule) drawn on a test console that keeps the text |
| Fastenshtein | `fastenshtein` | the Levenshtein distance between texts |
| FuzzySharp | `fuzzysharp` | fuzzy matching: scores, the best match of a list |
| DiffPlex | `diffplex` | the differences between two texts, line by line and side by side |
| DiffMatchPatch | `diffmatchpatch` | character diffs, patches made from two texts and applied, fuzzy matching |
| Fare | `fare` | random text from a regular expression |
| UAParser | `uaparser` | a user agent text parsed into browser, system and device |
| MimeMapping | `mimemapping` | media types of file names and extensions, and the reverse |
| Text in other scripts and every byte | `encodings` | Arabic, Chinese and emoji through JSON, YAML, Markdown and a hash, and all 256 byte values through LZ4 and a ZIP |

#### JSON, serialization and data formats

| Package | Test | What it checks |
|---|---|---|
| Newtonsoft.Json | `newtonsoft` | serialize, deserialize with type arguments, and LINQ to JSON (JObject, JArray, SelectToken) |
| Newtonsoft.Json.Bson | `bson` | BSON bytes written to a memory stream and read back |
| JsonSchema.Net | `jsonschema` | a JSON Schema from text, instances checked against it, and the results of the evaluation |
| NJsonSchema | `njsonschema` | schemas read from text, made from a sample document and used to validate JSON texts |
| JsonPatch.Net | `jsonpatch` | RFC 6902 patches (add, replace, remove, move, copy, test), differences of two documents and JSON pointers |
| YamlDotNet | `yaml` | a dictionary serialized, and deserialized with a type argument |
| Tomlyn | `tomlyn` | TOML text to a model (tables, arrays, values) and back |
| CsvHelper | `csvhelper` | a CSV text read row by row with a header and typed fields, and written back |
| Sep | `sep` | a CSV reader built on spans and ref structs |
| Sylvan.Data.Csv | `sylvancsv` | a CSV text as a data reader, quoted fields and Arabic text |
| MessagePack | `messagepack` | a class with attributes (a helper project) serialized to bytes and back |
| Google.Protobuf | `protobuf` | the well-known messages (Timestamp, Duration, Struct), binary and JSON serialization, ByteString |
| Apache.Avro | `avro` | schemas parsed from JSON text into objects and written back |
| PeterO.Cbor | `cbor` | CBOR objects encoded to bytes and decoded again, with the encodings of the CBOR specification |
| GeoJSON.Net | `geojson` | geometry objects that serialize with Newtonsoft.Json: positions, points, line strings, features |
| SharpKml | `sharpkml` | KML documents built as objects, written as text and read again |

#### Compression, hashing and identifiers

| Package | Test | What it checks |
|---|---|---|
| SharpCompress | `sharpcompress` | ZIP archives in memory, with entries, names and sizes |
| SharpZipLib | `sharpziplib` | a ZIP archive in memory, GZip of a text, and Tar |
| DotNetZip | `dotnetzip` | a zip archive made in memory from texts and bytes, saved to a stream, read back, with a password |
| K4os LZ4 | `lz4` | LZ4 blocks and frames over byte strings |
| Snappier | `snappier` | Snappy compression of byte arrays through spans |
| ZstdSharp | `zstdsharp` | Zstandard compression and decompression with levels |
| System.IO.Hashing | `iohashing` | CRC-32 and xxHash over bytes, with known check values |
| Crc32.NET | `crc32net` | CRC-32 and CRC-32C checksums as numbers and as a hash algorithm object |
| SimpleBase | `simplebase` | Base16, Base32 and Base58 encodings, round trips and known values |
| Hashids | `hashids` | short ids from numbers and back, with a salt and a minimum length |
| Sqids | `sqids` | short unique ids from numbers and back, with an alphabet and a minimum length |
| NanoidDotNet | `nanoid` | random ids with a chosen size and alphabet |
| Ulid | `ulid` | a struct identifier: parsing, text, time, ordering, 16 bytes |
| RecyclableMemoryStream | `recyclable` | pooled memory streams: write, seek, read, every byte value |

#### Security and identity

| Package | Test | What it checks |
|---|---|---|
| BCrypt.Net | `bcrypt` | password hashes with a salt and a cost, and the check of a password |
| Argon2 | `argon2` | a password hash in the standard encoded text, and its check |
| Portable.BouncyCastle | `bouncycastle` | digests, HMAC, hex and AES in CBC mode with padding |
| Otp.NET | `otpnet` | the HOTP and TOTP test vectors |
| jose-jwt | `josejwt` | signed tokens with a byte key, decoded again and checked with a wrong key |
| System.IdentityModel.Tokens.Jwt | `identitymodeljwt` | signed tokens, validation rules, expired and tampered tokens |

#### Documents, images and calendars

| Package | Test | What it checks |
|---|---|---|
| ClosedXML | `closedxml` | an Excel workbook, saved and read again |
| NPOI | `npoi` | an xlsx written, a formula calculated, the file read back |
| MiniExcel | `miniexcel` | an xlsx written and read as rows |
| ExcelDataReader | `exceldatareader` | an xlsx read row by row |
| DocumentFormat.OpenXml | `openxml` | a Word document built as objects, saved and opened again |
| PdfPig | `pdfpig` | text and page data from a PDF file |
| QuestPDF | `questpdf` | a PDF made from a description in code, with pieces that are Ring callbacks, read back with PdfPig |
| SixLabors.ImageSharp | `imagesharp` | pixels, processing steps in a callback, PNG and JPEG in memory |
| QRCoder | `qrcoder` | a QR code as PNG bytes, as a matrix of modules and as SVG |
| ZXing.Net | `zxing` | a QR code encoded, drawn as pixel bytes and decoded again |
| Ical.Net | `icalnet` | a calendar with an event and a recurrence, written as iCalendar text and read back |
| MimeKit | `mimekit` | an e-mail message built offline, written as MIME text and parsed back |

#### Dates, units, math and geography

| Package | Test | What it checks |
|---|---|---|
| NodaTime | `nodatime` | dates, times, periods, instants and time zones |
| TimeZoneConverter | `timezoneconverter` | IANA and Windows zone names, daylight saving |
| Cronos | `cronos` | cron expressions and the next time a schedule fires |
| NCrontab | `ncrontab` | cron schedules, ranges of occurrences, seconds |
| ColorHelper | `colorhelper` | colors converted between RGB, HEX, HSL, HSV and CMYK |
| UnitsNet | `unitsnet` | quantities with units, conversions, operators, parsing |
| ByteSize | `bytesize` | a struct with operators, unit conversions and parsing |
| Fractions | `fractions` | exact fractions with operators, reduction and conversion |
| Math.NET Numerics | `mathnet` | special functions, statistics, matrices and vectors |
| MathNet.Spatial | `spatial` | 3D points and vectors |
| Combinatorics | `combinatorics` | permutations, combinations and variations of a list |
| QuikGraph | `quikgraph` | generic graphs, a topological order, Dijkstra with a cost callback |
| NetTopologySuite | `nettopologysuite` | geometries from WKT and coordinates: area, distance, relations, overlay, WKT back |
| ProjNet | `projnet` | coordinate transformations between WGS84 and Web Mercator |
| libphonenumber | `phonenumbers` | phone numbers parsed, validated and formatted for many countries |
| IPNetwork2 | `ipnetwork` | CIDR networks: parse, contain, subnet, supernet, usable addresses |
| Semver | `semver` | semantic versions: parse, compare, precedence, prerelease and build |
| Enums.NET | `enumsnet` | generic helpers for enums and flags |

#### Databases and search

| Package | Test | What it checks |
|---|---|---|
| Microsoft.Data.Sqlite | `sqlite` | connections, commands, parameters, readers and transactions: whole numbers, fractions, blobs |
| Dapper with Sqlite | `dapper` | an in-memory database, queries with parameters, rows as dictionaries |
| Dapper with classes | `dappertyped` | `Query<Person>` mapping rows to objects of a .NET class, and an object as the parameters |
| SqlKata | `sqlkata` | a query builder compiled for several databases |
| LiteDB | `litedb` | a document database in memory: documents, queries, updates, deletes, indexes |
| Lucene.Net | `lucene` | a full-text index in memory, queries by term and by phrase, scores |
| Microsoft.Data.Analysis | `dataanalysis` | a DataFrame of typed columns, filters, sorting, and a CSV read into a frame |

#### Networking and messaging

| Package | Test | What it checks |
|---|---|---|
| Flurl | `flurl` | URLs built and taken apart |
| RestSharp | `restsharp` | requests and addresses built without sending |
| NetMQ | `netmq` | sockets talking through an in-process address |
| Makaretu.Dns | `dns` | DNS messages in the wire format |
| prometheus-net | `prometheus` | counters, gauges and histograms written in the Prometheus text format |

#### Containers, mapping and application building blocks

| Package | Test | What it checks |
|---|---|---|
| Microsoft.Extensions.DependencyInjection | `dependencyinjection` | a service collection and a provider: singletons, transients made by a Ring callback, scopes |
| Microsoft.Extensions.Configuration | `configuration` | a configuration built from an in-memory dictionary and a JSON stream (the later source wins), sections, keys with colons |
| Autofac | `autofac` | a container of .NET types, resolved by type |
| SimpleInjector | `simpleinjector` | a container with Ring delegates |
| MediatR | `mediatr` | requests and handlers (a helper project), a mediator built from dependency injection, a request sent and a notification published |
| AutoMapper | `automapper` | a mapping profile (a helper project), objects and lists mapped with type arguments |
| Mapster | `mapster` | object mapping with two type arguments |
| FluentValidation | `fluentvalidation` | rules in a validator class (a helper project), validation results |
| Ardalis.GuardClauses | `guardclauses` | argument checks that raise errors with the name and the message |
| Stateless | `stateless` | a state machine with generic states and triggers |
| OneOf | `oneof` | a value that is one of several types, with Match and Switch callbacks |
| FluentResults | `fluentresults` | result objects instead of exceptions |
| CSharpFunctionalExtensions | `functional` | Result and Maybe |
| Microsoft.Extensions.Primitives | `primitives` | string values, segments and tokens |
| Microsoft.Extensions.FileSystemGlobbing | `globbing` | file patterns matched against a folder |
| CommunityToolkit.Mvvm | `mvvmtoolkit` | commands with callbacks, their event, and the messenger |
| Castle DynamicProxy | `castle` | a proxy of an interface answered by a Ring callback (a helper project with the interceptor) |

#### Caching, concurrency and resilience

| Package | Test | What it checks |
|---|---|---|
| Polly | `polly` | a resilience pipeline with a retry around a Ring function |
| System.Threading.RateLimiting | `ratelimiting` | token bucket and fixed window limiters made from options |
| Quartz | `quartz` | a scheduler with jobs on other threads (a helper project) |
| Nito.AsyncEx | `nitoasyncex` | locks, a producer and consumer queue, a countdown event, a double ended queue |
| System.Reactive | `reactive` | observables, subjects and operators with Ring callbacks |
| System.Linq.Async | `linqasync` | LINQ over asynchronous streams |
| MoreLINQ | `morelinq` | extra LINQ methods (Batch, Pairwise, Shuffle and more) |
| LazyCache | `lazycache` | a cache whose value is made by a Ring callback on a miss |
| BitFaster.Caching | `bitfaster` | a generic LRU cache |
| Microsoft.Extensions.Caching.Memory | `memorycache` | a cache with options, an out value, and expiry |
| Microsoft.Extensions.ObjectPool | `objectpool` | pools of reusable objects, with a provider and a reset policy |

#### Logging and diagnostics

| Package | Test | What it checks |
|---|---|---|
| Serilog | `serilog` | a logger that writes to a file: levels, message templates, properties |
| NLog | `nlog` | a configuration made in code and a memory target |
| log4net | `log4net` | a repository configured in code with a memory appender |
| Ben.Demystifier | `demystifier` | readable stack traces from an exception of a Ring call |

#### Developer tools and code analysis

| Package | Test | What it checks |
|---|---|---|
| Roslyn | `roslyn` | C# text parsed into a syntax tree, walked, compiled and run in memory |
| Mono.Cecil | `cecil` | the metadata of an assembly file: modules, types, methods, parameters, attributes |
| ICSharpCode.Decompiler | `decompiler` | C# source text from an assembly file |
| LibGit2Sharp | `libgit2sharp` | a Git repository made in a folder (a native library): commits, history, branches, tags |
| CliWrap | `cliwrap` | a program run with arguments and its output and exit code read |

#### Testing helpers and test data

| Package | Test | What it checks |
|---|---|---|
| FluentAssertions | `fluentassertions` | `Should()` assertions that raise errors when a check fails |
| Shouldly | `shouldly` | `ShouldBe` and the like on any object |
| xunit.assert | `xunitassert` | the `Assert` class: generic Equal, collections, strings, exceptions |
| NSubstitute | `nsubstitute` | a substitute of an interface with return values and received calls |
| AutoFixture | `autofixture` | test data for any type |
| Bogus | `bogus` | fake data from a seeded generator |

#### Machine learning (ML.NET)

| Package | Test | What it checks |
|---|---|---|
| ML.NET linear regression | `mlnet_regression` | an SDCA model with weights, metrics and a prediction engine, trained from rows made in Ring (a helper project has the row classes) |
| ML.NET more classifiers | `mlnet_classifiers` | linear SVM, averaged perceptron, SGD and SDCA for a yes or no; naive Bayes, maximum entropy and one-versus-all for several classes |
| ML.NET more regression and tools | `mlnet_regressors` | OLS (native MKL: left out on a Linux computer without libiomp5), online gradient descent, Poisson, tweedie, additive models, LightGBM (native), a train and test split, cross validation, and the importance of each feature |
| ML.NET time series | `mlnet_timeseries` | spike detection (IID and SSA), change point detection, and a forecast of the next values (the SSA parts use the native MKL library and are left out on a Linux computer without libiomp5) |
| ML.NET recommendation | `mlnet_recommendation` | matrix factorization (native) learns the taste of users from ratings and scores pairs it has not seen |
| ML.NET data transforms | `mlnet_transforms` | min-max, mean-variance and binning scalers, missing values replaced, rows filtered, columns chosen and dropped, keys, one-hot and hashing, words and word bags |
| ML.NET logistic regression | `mlnet_logistic` | two trainers, accuracy, AUC, probabilities and the confusion matrix |
| ML.NET decision trees | `mlnet_trees` | FastTree and FastForest for a number and for a yes or no |
| ML.NET clustering and PCA | `mlnet_clustering` | k-means with cluster distances and metrics, and principal components |
| ML.NET saved and loaded models | `mlnet_persistence` | a trained model saved to a file or a stream and loaded again, also by another context, with the same predictions; a pipeline with a text and a category saved with its transforms; a file that is not a model |
| ML.NET anomaly detection | `mlnet_anomaly` | RandomizedPca trained on normal rows gives high scores and the anomaly label to rows that are far from them, with the area under the curve |
| ML.NET ranking | `mlnet_ranking` | FastTree and LightGBM rankers over queries of documents, with NDCG and DCG |
| ML.NET calibrators | `mlnet_calibration` | Platt, naive and isotonic calibrators turn the score of a linear SVM or a perceptron into a probability |
| ML.NET AutoML | `mlnet_automl` | experiments for a number, a yes or no and several classes, the settings of an experiment, the inferred columns of a CSV file, and the best model used like any other (a restore of hundreds of megabytes) |
| ML.NET chess end game example | `mlnet_chess` | the example of samples/UsingDotNet/tests/packages/ChessEndgame run as a user runs it: a split of 70 and 30 percent, many algorithms trained and tested, the models saved, evaluated and used to predict (see [the chess end game](ml-chess.html)) |
| ML.NET with a CSV file | `mlnet_columns` | any number of columns read with column definitions made in Ring, scores read as a column |
| ML.NET with in-memory rows | `mlnet_vectorrows` | one row class `VectorRow` for tables of any width |
| ML.NET with text columns | `mlnet_text` | a category one-hot encoded, a review featurized into word counts, a text label mapped to classes and back |
| ML.NET with row classes made at run time | `mlnet_runtimeclass` | row classes defined by Ring with System.Reflection.Emit (numbers, texts, yes/nos), found by the bridge by their names |

#### The bridge itself

| Package | Test | What it checks |
|---|---|---|
| Handle release | `handlechurn` | loops that make thousands of objects from real packages must give their .NET handles back |

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
