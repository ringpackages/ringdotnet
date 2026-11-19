---
title: Tutorials
lead: Step-by-step lessons for people who are new to .NET. Each one explains the ideas first, then builds a small program you can run, with the real output and screenshots.
---

## How to use the tutorials

Every tutorial has a program in the folder `docs/tutorials`. Read the explanation, run the program, change it, and do the **exercises** at the end. The programs are real: they are tested together with the rest of the package, so the output you see here is the output you will get.

```bash
cd docs/tutorials
ring t01_first_look.ring            # a console tutorial
ring g01c_counter.ring              # a window
ring g01c_counter.ring --selftest   # the same program checks itself and closes
```

> [!TIP] You do not need to know .NET to start. If you know Ring, you can follow every tutorial. The first two pages explain the .NET words that you will meet.

## Start here

<div class="cards">
<a class="card" href="tut-concepts.html"><div class="ic">🧭</div><b>.NET for Ring programmers</b><span>What .NET is, and the words you will meet: runtime, class library, assembly, namespace, class, object, static, property, method, event, struct, enum, null.</span></a>
<a class="card" href="tut-reading-docs.html"><div class="ic">📖</div><b>Reading the .NET documentation</b><span>How to find a class on Microsoft Learn and turn what you read into Ring code.</span></a>
</div>

## The chapters

The tutorials are grouped by **topic**. Read **The basics** first, in order; after that, choose the chapter that you need. The pages inside a chapter lead from one to the next, and the last page of a chapter points to the next chapter.

| Chapter | What it is about | Tutorials |
|---|---|---|
| [The basics](#the-basics) | Console programs that use the class library: text, numbers, collections, files, JSON and XML, errors, hashing, HTTP, tasks and processes | 10 |
| [Text and data formats](#text-and-data-formats) | Regular expressions, Unicode and encodings, comparing and escaping text, URLs and domain names, MIME types, JSON in three styles, XML and XSLT, Markdown and spelling | 14 |
| [Numbers, dates and money](#numbers-dates-and-money) | The number types and their limits, big numbers, number systems, exact money, vectors, randomness and statistics, then dates, time zones, calendars and cultures | 12 |
| [Collections and algorithms](#collections-and-algorithms) | Arrays, sets and other data structures, collections for many threads, enums and identifiers, undo and queues, recursion and an expression calculator | 9 |
| [Files and streams](#files-and-streams) | Paths, streams, binary files, compression (GZip, ZIP, tar), file patterns, and projects that work on many files: a log analyzer, a duplicate finder, a backup tool | 10 |
| [Processes and performance](#processes-and-performance) | Asking the computer about itself, command-line tools and logging, starting and talking to other programs, tasks that wait, releasing resources, measuring speed and memory, and the Windows Registry | 11 |
| [Networking and the web](#networking-and-the-web) | IP addresses and networks, TCP and UDP sockets, HttpClient and REST, web services and small web sites, route templates, and e-mail messages | 11 |
| [Security](#security) | Hashing, encryption and signing, certificates, protecting data, logins and sessions, identities and claims, and rate limiting | 7 |
| [Databases and services](#databases-and-services) | SQL and Entity Framework, reports, Microsoft Access, and the services of an application: settings and configuration, caching and dependency injection | 9 |
| [Windows Forms](#windows-forms) | Windows with controls, layout, dialogs and menus, timers, drawing, images and charts (Windows only) | 11 |
| [WPF](#wpf) | XAML windows, layout and styles, and animation (Windows only) | 3 |
| [Projects with windows](#projects-with-windows) | Complete programs: a to-do list, Tic-Tac-Toe, a command runner, an address book with a database, a sorting lab, a maze, an image filter lab and a chat (Windows only) | 8 |
| [Libraries, testing and release](#libraries-testing-and-release) | Giving Ring code to .NET (callbacks and events), exploring and building code with reflection and expression trees, using a library written in C#, testing, and giving your program to others | 6 |

## Where to start

| If you want to... | Read |
|---|---|
| understand the vocabulary | [.NET for Ring programmers](tut-concepts.html), [Reading the .NET documentation](tut-reading-docs.html) |
| learn the class library step by step | the chapter **The basics** (ten tutorials) |
| work with text, JSON and XML | **Text and data formats** |
| calculate with numbers, dates and money | **Numbers, dates and money** |
| read, write and pack files | **Files and streams** |
| talk to other computers, build a web service | **Networking and the web** |
| store data | **Databases and services** |
| protect data and users | **Security** |
| build programs with windows | **Windows Forms**, then **WPF** and **Projects with windows** |
| go deeper: callbacks, reflection, your own C# library, tests | **Libraries, testing and release** |
| give your program to other people | the tutorial [Giving your program to others](tut-119-distribution.html) |

## The basics

Console programs that use the class library: text, numbers, collections, files, JSON and XML, errors, hashing, HTTP, tasks and processes. Start here and read them in order.

<div class="cards">
<a class="card" href="tut-01-first-look.html"><div class="ic">🌱</div><b>A first look</b><span>Objects, types, properties, methods, static members, structs, collections and null.</span></a>
<a class="card" href="tut-02-text.html"><div class="ic">🌱</div><b>Working with text</b><span>Ring's own text functions and what .NET adds: Join, Format, StringBuilder, regular expressions, Base64, encodings.</span></a>
<a class="card" href="tut-03-numbers-dates.html"><div class="ic">🌱</div><b>Numbers, dates and times</b><span>Math, parsing safely, big numbers, random numbers, DateTime, TimeSpan and cultures.</span></a>
<a class="card" href="tut-04-collections.html"><div class="ic">🌱</div><b>Collections and LINQ</b><span>Lists, dictionaries, sets, queues, stacks, sorting and asking questions with LINQ.</span></a>
<a class="card" href="tut-05-files.html"><div class="ic">🌱</div><b>Files and folders</b><span>Path, Directory, File, readers and writers, file information and zip.</span></a>
<a class="card" href="tut-06-json-xml.html"><div class="ic">🌱</div><b>JSON and XML</b><span>Read, search, change and write structured data.</span></a>
<a class="card" href="tut-07-errors.html"><div class="ic">🌱</div><b>When things go wrong</b><span>Exceptions, try/catch, checking before acting, your own errors and cleaning up.</span></a>
<a class="card" href="tut-08-security.html"><div class="ic">🌱</div><b>Hashing and encryption</b><span>Checksums, password hashes, HMAC, random tokens and AES.</span></a>
<a class="card" href="tut-09-http.html"><div class="ic">🌱</div><b>HTTP</b><span>A web server and a web client in one program.</span></a>
<a class="card" href="tut-10-tasks-processes.html"><div class="ic">🌱</div><b>Time, tasks and other programs</b><span>Stopwatch, tasks, the environment and running another program.</span></a>
</div>

## Text and data formats

Regular expressions, Unicode and encodings, comparing and escaping text, URLs and domain names, MIME types, JSON in three styles, XML and XSLT, Markdown and spelling.

<div class="cards">
<a class="card" href="tut-29-regex.html"><div class="ic">🔤</div><b>Regular expressions in depth</b><span>Patterns, groups, replace, split, greedy and lazy, validation.</span></a>
<a class="card" href="tut-129-formatting.html"><div class="ic">🔤</div><b>Formatting numbers and dates</b><span>Format strings: decimals, thousands, percent, patterns, alignment, dates and durations.</span></a>
<a class="card" href="tut-144-mailmerge.html"><div class="ic">🔤</div><b>Project: mail merge</b><span>A template with fields, CSV data, Regex.Replace with a callback and a check for missing data.</span></a>
<a class="card" href="tut-152-highlighter.html"><div class="ic">🔤</div><b>Project: a syntax highlighter</b><span>One regular expression with named groups, tokens, HTML spans and escaped text.</span></a>
<a class="card" href="tut-52-unicode.html"><div class="ic">🔤</div><b>Unicode and encodings</b><span>Bytes, code points and letters; UTF-8, UTF-16 and mojibake.</span></a>
<a class="card" href="tut-132-text-encodings.html"><div class="ic">🔤</div><b>Text files and encodings</b><span>The bytes of a text, the BOM, reading Latin-1 and UTF-16 files, strict UTF-8 and line endings.</span></a>
<a class="card" href="tut-97-comparers.html"><div class="ic">🔤</div><b>Comparing text</b><span>Ordinal and culture comparison, StringComparer, and the Turkish i.</span></a>
<a class="card" href="tut-104-text-readers-writers.html"><div class="ic">🔤</div><b>Text readers and writers</b><span>StringWriter, StringReader, capturing Console output, String.Format.</span></a>
<a class="card" href="tut-86-escaping.html"><div class="ic">🔤</div><b>Escaping</b><span>The right encoding for HTML, URLs, JavaScript, JSON, XML, regular expressions and SQL.</span></a>
<a class="card" href="tut-64-urls.html"><div class="ic">🔤</div><b>URLs and encodings</b><span>Uri, query strings, percent-encoding, relative addresses and Base64.</span></a>
<a class="card" href="tut-138-base64-hex.html"><div class="ic">🔤</div><b>Bytes as text: Base64 and hex</b><span>Base64, the URL-safe form, hexadecimal, padding, wrong input and data URIs.</span></a>
<a class="card" href="tut-117-domain-names.html"><div class="ic">🔤</div><b>International domain names</b><span>Punycode, IdnMapping and look-alike letters (homograph attacks).</span></a>
<a class="card" href="tut-121-mime-types.html"><div class="ic">🔤</div><b>MIME types</b><span>File extensions, Content-Type, Accept and content negotiation.</span></a>
<a class="card" href="tut-100-json-writer.html"><div class="ic">🔤</div><b>Writing JSON as a stream</b><span>Utf8JsonWriter, indentation, escaping and JsonSerializer options.</span></a>
<a class="card" href="tut-80-json-nodes.html"><div class="ic">🔤</div><b>JSON as a tree</b><span>JsonNode: read, edit, build, merge and clone JSON.</span></a>
<a class="card" href="tut-72-xml.html"><div class="ic">🔤</div><b>XML in depth</b><span>XDocument, XPath, building and changing elements, bad XML.</span></a>
<a class="card" href="tut-77-xslt.html"><div class="ic">🔤</div><b>XSLT</b><span>Turn XML into text, CSV and HTML with XslCompiledTransform.</span></a>
<a class="card" href="tut-47-markdown.html"><div class="ic">🔤</div><b>Project: Markdown to HTML</b><span>Blocks, inline formatting, regular expressions, and escaping first.</span></a>
<a class="card" href="tut-66-spelling.html"><div class="ic">🔤</div><b>A spell checker</b><span>A set of words, the edit distance table and the best suggestions.</span></a>
</div>

## Numbers, dates and money

The number types and their limits, big numbers, number systems, exact money, vectors, randomness and statistics, then dates, time zones, calendars and cultures.

<div class="cards">
<a class="card" href="tut-101-number-types.html"><div class="ic">🔢</div><b>Number types</b><span>Limits, checked conversion, TryParse, Int128 and floating point.</span></a>
<a class="card" href="tut-126-rounding.html"><div class="ic">🔢</div><b>Rounding and the Math class</b><span>Round modes, Floor, Ceiling, Truncate, limits, and one rounding rule for money.</span></a>
<a class="card" href="tut-90-big-numbers.html"><div class="ic">🔢</div><b>Big numbers</b><span>BigInteger for exact big whole numbers, and Complex numbers.</span></a>
<a class="card" href="tut-67-bases.html"><div class="ic">🔢</div><b>Number systems and big numbers</b><span>Binary and hex, bits, the 2^53 limit and BigInteger.</span></a>
<a class="card" href="tut-57-money.html"><div class="ic">🔢</div><b>Money</b><span>Why 0.1 + 0.2 is not 0.3: whole cents, rounding rules and fair splitting.</span></a>
<a class="card" href="tut-99-vectors.html"><div class="ic">🔢</div><b>Vectors and matrices</b><span>Vector3, dot and cross products, Matrix3x2 transformations.</span></a>
<a class="card" href="tut-69-random.html"><div class="ic">🔢</div><b>Randomness</b><span>Seeds, dice, a correct shuffle, weighted choices, Guids and secure numbers.</span></a>
<a class="card" href="tut-44-statistics.html"><div class="ic">🔢</div><b>Statistics and simulation</b><span>Mean, median, mode, deviation, primes, gcd and a Monte Carlo estimate of pi.</span></a>
<a class="card" href="tut-103-dates-and-times.html"><div class="ic">🔢</div><b>Dates and times</b><span>DateOnly, TimeOnly, DateTimeOffset, TimeSpan and month-end rules.</span></a>
<a class="card" href="tut-68-timezones.html"><div class="ic">🔢</div><b>Time zones</b><span>UTC, local time, daylight saving, a meeting and a flight across zones.</span></a>
<a class="card" href="tut-43-calendar.html"><div class="ic">🔢</div><b>Calendars and dates</b><span>Month tables, ages, business days, birthdays and safe date arithmetic.</span></a>
<a class="card" href="tut-76-calendars.html"><div class="ic">🔢</div><b>Other calendars</b><span>Hijri, Persian, Hebrew, Japanese and Thai dates; Arabic names with ar-SA.</span></a>
<a class="card" href="tut-135-workdays.html"><div class="ic">🔢</div><b>Working days</b><span>Business days, holidays, ISO weeks, quarters, month ends and ages.</span></a>
<a class="card" href="tut-33-cultures.html"><div class="ic">🔢</div><b>Cultures</b><span>Formatting, parsing, sorting and case in different languages.</span></a>
</div>

## Collections and algorithms

Arrays, sets and other data structures, collections for many threads, enums and identifiers, undo and queues, recursion and an expression calculator.

<div class="cards">
<a class="card" href="tut-106-arrays.html"><div class="ic">🧺</div><b>Arrays</b><span>Typed arrays, Array.Sort, BinarySearch, Copy and two dimensions.</span></a>
<a class="card" href="tut-107-sets.html"><div class="ic">🧺</div><b>Sets</b><span>HashSet: union, intersection, difference and removing duplicates.</span></a>
<a class="card" href="tut-92-data-structures.html"><div class="ic">🧺</div><b>More data structures</b><span>PriorityQueue, SortedSet, SortedDictionary, LinkedList and BitArray.</span></a>
<a class="card" href="tut-89-concurrent-collections.html"><div class="ic">🧺</div><b>Collections for many threads</b><span>Concurrent queue, stack, blocking collection and dictionary.</span></a>
<a class="card" href="tut-65-enums.html"><div class="ic">🧺</div><b>Enums and flags</b><span>Named choices as text, comma-separated flags and your own bit flags.</span></a>
<a class="card" href="tut-93-identifiers.html"><div class="ic">🧺</div><b>Identifiers and versions</b><span>Guid, Version, and sorting version numbers by number.</span></a>
<a class="card" href="tut-58-undo.html"><div class="ic">🧺</div><b>Undo, redo and queues</b><span>Stacks and queues; two stacks make undo and redo.</span></a>
<a class="card" href="tut-75-recursion.html"><div class="ic">🧺</div><b>Recursion</b><span>Factorial, the Towers of Hanoi, permutations, a folder tree and a flood fill.</span></a>
<a class="card" href="tut-54-expression.html"><div class="ic">🧺</div><b>An expression calculator</b><span>Tokens, a recursive-descent parser, precedence and clear errors.</span></a>
</div>

## Files and streams

Paths, streams, binary files, compression (GZip, ZIP, tar), file patterns, and projects that work on many files: a log analyzer, a duplicate finder, a backup tool.

<div class="cards">
<a class="card" href="tut-59-paths.html"><div class="ic">📁</div><b>Paths and the environment</b><span>Path.Combine, special folders, valid names and environment variables.</span></a>
<a class="card" href="tut-56-streams.html"><div class="ic">📁</div><b>Streams and compression</b><span>MemoryStream, StreamWriter, GZip, and one pattern for memory and files.</span></a>
<a class="card" href="tut-45-binary.html"><div class="ic">📁</div><b>Binary files</b><span>BinaryWriter and BinaryReader, a file format, a hex dump, little endian.</span></a>
<a class="card" href="tut-130-random-access.html"><div class="ic">📁</div><b>Random access and file locks</b><span>Fixed-size records, Seek, changing a record in place, SetLength and FileShare.</span></a>
<a class="card" href="tut-88-compression.html"><div class="ic">📁</div><b>Compression</b><span>GZip, Deflate and Brotli streams, sizes, round trips and a .gz file.</span></a>
<a class="card" href="tut-108-zip-in-memory.html"><div class="ic">📁</div><b>ZIP archives in memory</b><span>ZipArchive on a MemoryStream: entries, levels and updates.</span></a>
<a class="card" href="tut-96-tar.html"><div class="ic">📁</div><b>Tar archives</b><span>Create, list, read and unpack tar files.</span></a>
<a class="card" href="tut-112-globbing.html"><div class="ic">📁</div><b>File patterns (globbing)</b><span>**/*.ring, include and exclude rules, matching lists of paths.</span></a>
<a class="card" href="tut-123-file-info.html"><div class="ic">📁</div><b>File information</b><span>FileInfo: size, times, attributes, read-only files, copying and temporary files.</span></a>
<a class="card" href="tut-124-disks.html"><div class="ic">📁</div><b>Disks and free space</b><span>DriveInfo, the sizes of a disk, will it fit, and sizes for people.</span></a>
<a class="card" href="tut-122-watch-folder.html"><div class="ic">📁</div><b>Watching a folder</b><span>FileSystemWatcher: created, changed, renamed and deleted files, with a child program.</span></a>
<a class="card" href="tut-21-log-analyzer.html"><div class="ic">📁</div><b>Project: a log analyzer</b><span>Files, regular expressions, dictionaries, LINQ and a JSON report in one program.</span></a>
<a class="card" href="tut-31-duplicates.html"><div class="ic">📁</div><b>Project: duplicate files</b><span>Folders, content hashes and a dictionary find the copies.</span></a>
<a class="card" href="tut-46-backup.html"><div class="ic">📁</div><b>Project: a backup tool</b><span>Zip by date, keep the newest few, restore and verify.</span></a>
<a class="card" href="tut-141-renamer.html"><div class="ic">📁</div><b>Project: rename many files</b><span>Rules, a preview, conflict checks, renaming and undo with a log.</span></a>
<a class="card" href="tut-145-diff.html"><div class="ic">📁</div><b>Project: compare two files</b><span>The longest common subsequence, a diff with context, and a similarity in percent.</span></a>
<a class="card" href="tut-147-checksums.html"><div class="ic">📁</div><b>Project: check that files did not change</b><span>SHA-256 checksums in the sha256sum format, verify, and protecting the list.</span></a>
</div>

## Processes and performance

Asking the computer about itself, command-line tools and logging, starting and talking to other programs, tasks that wait, releasing resources, measuring speed and memory, and the Windows Registry.

<div class="cards">
<a class="card" href="tut-74-system.html"><div class="ic">⚙️</div><b>Asking the computer</b><span>The system, processors, memory, drives and the running programs.</span></a>
<a class="card" href="tut-50-cli.html"><div class="ic">⚙️</div><b>A command-line tool</b><span>Arguments, options, usage text and exit codes.</span></a>
<a class="card" href="tut-51-logging.html"><div class="ic">⚙️</div><b>Logging</b><span>Levels, timestamps, a log file and rotation.</span></a>
<a class="card" href="tut-136-tracing.html"><div class="ic">⚙️</div><b>Tracing</b><span>Trace and listeners: memory and file listeners, indents, conditions and categories.</span></a>
<a class="card" href="tut-85-feed-programs.html"><div class="ic">⚙️</div><b>Working with other programs</b><span>Standard input, chaining, environment, exit codes, time limits and Kill.</span></a>
<a class="card" href="tut-79-processes-talk.html"><div class="ic">⚙️</div><b>Two programs talking</b><span>Named pipes between processes, Process.Start, and a mutex for one copy.</span></a>
<a class="card" href="tut-82-shared-memory.html"><div class="ic">⚙️</div><b>Shared memory</b><span>Memory-mapped files shared by two programs, and a file edited in place.</span></a>
<a class="card" href="tut-83-tasks-waiting.html"><div class="ic">⚙️</div><b>Tasks that wait</b><span>Task.Delay, WhenAll, WhenAny, time limits and cancellation.</span></a>
<a class="card" href="tut-71-dispose.html"><div class="ic">⚙️</div><b>Releasing resources</b><span>Locked files, Dispose, and a clean-up that runs after an error.</span></a>
<a class="card" href="tut-53-speed.html"><div class="ic">⚙️</div><b>Speed: measure first</b><span>Stopwatch, a cache, StringBuilder against +=, and the cost of bridge calls.</span></a>
<a class="card" href="tut-98-memory.html"><div class="ic">⚙️</div><b>Memory and the garbage collector</b><span>GC, weak references, generations and release().</span></a>
<a class="card" href="tut-118-registry.html"><div class="ic">⚙️</div><b>The Windows Registry</b><span>Keys, values of every kind, listing and cleaning up (Windows).</span></a>
</div>

## Networking and the web

IP addresses and networks, TCP and UDP sockets, HttpClient and REST, web services and small web sites, route templates, and e-mail messages.

<div class="cards">
<a class="card" href="tut-81-network-tools.html"><div class="ic">🌐</div><b>Network tools</b><span>IPAddress, Dns, Ping, interfaces and a port check, all on this computer.</span></a>
<a class="card" href="tut-102-ip-networks.html"><div class="ic">🌐</div><b>IP networks</b><span>CIDR, IPNetwork.Contains and a private-address allow list.</span></a>
<a class="card" href="tut-25-sockets.html"><div class="ic">🌐</div><b>Sockets</b><span>A TCP server and client that talk line by line.</span></a>
<a class="card" href="tut-91-udp.html"><div class="ic">🌐</div><b>UDP</b><span>Datagrams between sockets, answers, time limits and lost messages.</span></a>
<a class="card" href="tut-84-http-client.html"><div class="ic">🌐</div><b>HttpClient in depth</b><span>Headers, status codes, EnsureSuccessStatusCode, cancelling and saving a download.</span></a>
<a class="card" href="tut-39-rest-client.html"><div class="ic">🌐</div><b>A REST client</b><span>GET and POST with JSON, status codes, timeouts and errors.</span></a>
<a class="card" href="tut-16-web-service.html"><div class="ic">🌐</div><b>A web service with a database</b><span>JSON over HTTP, stored with Entity Framework.</span></a>
<a class="card" href="tut-26-website.html"><div class="ic">🌐</div><b>A small web site</b><span>HTML pages, a form, a guestbook, status codes and the escaping rule.</span></a>
<a class="card" href="tut-55-miniweb.html"><div class="ic">🌐</div><b>A tiny web framework</b><span>Routes with parameters, a catch-all handler and escaped templates.</span></a>
<a class="card" href="tut-120-routes.html"><div class="ic">🌐</div><b>Route templates</b><span>users/{id}, optional, default and catch-all parts, choosing a route.</span></a>
<a class="card" href="tut-150-shortener.html"><div class="ic">🌐</div><b>Project: a link shortener</b><span>Base 62 codes, a 302 redirect, a catch-all handler, visit counts and address checks.</span></a>
<a class="card" href="tut-94-mail-messages.html"><div class="ic">🌐</div><b>E-mail messages</b><span>MailAddress, MailMessage, recipients and text plus HTML views.</span></a>
</div>

## Security

Hashing, encryption and signing, certificates, protecting data, logins and sessions, identities and claims, and rate limiting.

<div class="cards">
<a class="card" href="tut-78-crypto.html"><div class="ic">🔒</div><b>Protecting and signing messages</b><span>AES, HMAC (encrypt-then-MAC), PBKDF2 keys and RSA signatures.</span></a>
<a class="card" href="tut-105-signatures.html"><div class="ic">🔒</div><b>Digital signatures</b><span>ECDsa keys, signing, verifying and sharing the public key.</span></a>
<a class="card" href="tut-116-certificates.html"><div class="ic">🔒</div><b>Certificates</b><span>Self-signed X.509 certificates, PFX and PEM, signing and trust.</span></a>
<a class="card" href="tut-113-data-protection.html"><div class="ic">🔒</div><b>Protecting data</b><span>The Data Protection API: purposes, tampering, keys and expiring tokens.</span></a>
<a class="card" href="tut-49-login.html"><div class="ic">🔒</div><b>Login, sessions and cookies</b><span>Registration, safe passwords, a session cookie and a protected page.</span></a>
<a class="card" href="tut-95-claims.html"><div class="ic">🔒</div><b>Identities and claims</b><span>Claims, identities, roles and a permission check.</span></a>
<a class="card" href="tut-114-rate-limiting.html"><div class="ic">🔒</div><b>Rate limiting</b><span>Token bucket, concurrency limiter, leases and one limiter per client.</span></a>
</div>

## Databases and services

SQL and Entity Framework, reports, Microsoft Access, and the services of an application: settings and configuration, caching and dependency injection.

<div class="cards">
<a class="card" href="tut-17-databases.html"><div class="ic">🗄️</div><b>Databases step by step</b><span>Tables, rows, searches, relations, queries, transactions and files.</span></a>
<a class="card" href="tut-30-tables.html"><div class="ic">🗄️</div><b>Tabular data</b><span>CSV, DataTable, DataView, Compute, sorting, filtering and grouping.</span></a>
<a class="card" href="tut-73-sql-reports.html"><div class="ic">🗄️</div><b>Reports with SQL</b><span>JOIN, GROUP BY, HAVING, LEFT JOIN and sub-queries.</span></a>
<a class="card" href="tut-27-entities.html"><div class="ic">🗄️</div><b>Entity objects and migrations</b><span>Rows as tracked objects, navigation properties, and changing a database that has data.</span></a>
<a class="card" href="tut-115-access.html"><div class="ic">🗄️</div><b>Microsoft Access databases</b><span>An .accdb file through ODBC: tables, parameters, joins, totals and transactions (Windows).</span></a>
<a class="card" href="tut-32-settings.html"><div class="ic">🗄️</div><b>Settings</b><span>Defaults, a JSON file, special folders, and a damaged file.</span></a>
<a class="card" href="tut-111-configuration.html"><div class="ic">🗄️</div><b>Configuration</b><span>JSON, memory and environment sources; the last one wins.</span></a>
<a class="card" href="tut-109-memory-cache.html"><div class="ic">🗄️</div><b>Caching</b><span>MemoryCache, absolute and sliding expiration, GetOrCreate.</span></a>
<a class="card" href="tut-110-dependency-injection.html"><div class="ic">🗄️</div><b>Dependency injection</b><span>The service container, three lifetimes and scopes.</span></a>
</div>

## Windows Forms

Windows with controls, layout, dialogs and menus, timers, drawing, images and charts (Windows only).

<div class="cards">
<a class="card" href="tut-11-first-window.html"><div class="ic">🪟</div><b>Your first window</b><span>A form, a label, a button, an event — with and without the helper functions.</span></a>
<a class="card" href="tut-12-controls.html"><div class="ic">🪟</div><b>A form with many controls</b><span>Text boxes, number box, combo box, check box, list box and validation.</span></a>
<a class="card" href="tut-128-inputs.html"><div class="ic">🪟</div><b>More input controls</b><span>Date picker, track bar, radio buttons, tool tips and the error marker.</span></a>
<a class="card" href="tut-146-keyboard.html"><div class="ic">🪟</div><b>The keyboard in a form</b><span>KeyPress filters, Enter and Escape buttons, tab order, access keys and test keys.</span></a>
<a class="card" href="tut-23-layout.html"><div class="ic">🪟</div><b>Layout and richer controls</b><span>Split bars, tabs, table layout, and a data grid with a filter.</span></a>
<a class="card" href="tut-134-listview.html"><div class="ic">🪟</div><b>A list with columns</b><span>ListView details: columns, check boxes, sorting by a header, removing checked rows.</span></a>
<a class="card" href="tut-142-grid.html"><div class="ic">🪟</div><b>Editing a grid</b><span>DataGridView with text, check box and combo box columns, cell events and totals.</span></a>
<a class="card" href="tut-13-editor.html"><div class="ic">🪟</div><b>A small text editor</b><span>Menus, a status bar, open and save, dock layout.</span></a>
<a class="card" href="tut-133-richtext.html"><div class="ic">🪟</div><b>Formatted text</b><span>RichTextBox: bold and colored words, find and mark, save and load RTF.</span></a>
<a class="card" href="tut-127-clipboard.html"><div class="ic">🪟</div><b>The clipboard</b><span>Text, a table for a spreadsheet, a picture, and leaving the clipboard as it was.</span></a>
<a class="card" href="tut-40-dialog.html"><div class="ic">🪟</div><b>Your own dialog</b><span>A modal form that asks for data, validates it and returns it; tested with a timer.</span></a>
<a class="card" href="tut-137-closing.html"><div class="ic">🪟</div><b>Closing a window</b><span>FormClosing and Cancel: ask to save changes, and a question that a test can answer.</span></a>
<a class="card" href="tut-149-windows.html"><div class="ic">🪟</div><b>More than one window</b><span>Show with an owner, one copy of a tool window, talking windows and OpenForms.</span></a>
<a class="card" href="tut-41-menus.html"><div class="ic">🪟</div><b>Menus, toolbars, shortcuts</b><span>Write each action once and reach it from a menu, a toolbar, a context menu and a key.</span></a>
<a class="card" href="tut-34-timers.html"><div class="ic">🪟</div><b>Timers and progress</b><span>A stopwatch, a progress bar, and a long job in small steps.</span></a>
<a class="card" href="tut-14-animation.html"><div class="ic">🪟</div><b>Drawing and animation</b><span>A canvas, a timer and the keyboard: a bouncing ball and a paddle.</span></a>
<a class="card" href="tut-139-paint.html"><div class="ic">🪟</div><b>Drawing with the mouse</b><span>MouseDown, MouseMove and MouseUp: a paint program with colors, pen sizes and a test.</span></a>
<a class="card" href="tut-22-images.html"><div class="ic">🪟</div><b>Images</b><span>Draw, read and change pixels, make a gray copy, resize and save PNG files.</span></a>
<a class="card" href="tut-125-screenshot.html"><div class="ic">🪟</div><b>Screens and pictures of windows</b><span>Screen, CopyFromScreen, DrawToBitmap, and checking a window by its pixels.</span></a>
<a class="card" href="tut-36-chart.html"><div class="ic">🪟</div><b>A chart</b><span>Scaling values to pixels, a round axis, bars, labels, saving, testing pixels.</span></a>
<a class="card" href="tut-42-browser.html"><div class="ic">🪟</div><b>A folder browser</b><span>TreeView, ListView, recursion and the Tag property: a small Explorer.</span></a>
</div>

## WPF

XAML windows, layout and styles, and animation (Windows only).

<div class="cards">
<a class="card" href="tut-15-wpf.html"><div class="ic">🎨</div><b>WPF</b><span>XAML windows, finding elements, events and data binding.</span></a>
<a class="card" href="tut-38-wpf-layout.html"><div class="ic">🎨</div><b>WPF layout and styles</b><span>Grid rows and columns, one Style for all buttons, a keypad.</span></a>
<a class="card" href="tut-131-wpf-binding.html"><div class="ic">🎨</div><b>WPF data binding</b><span>Controls that follow each other in XAML: slider, text box, check box and list.</span></a>
<a class="card" href="tut-140-wpf-menu.html"><div class="ic">🎨</div><b>WPF menus and tabs</b><span>Menu, checkable items, TabControl, ComboBox, DatePicker and Expander in XAML.</span></a>
<a class="card" href="tut-148-wpf-lists.html"><div class="ic">🎨</div><b>WPF lists and dynamic content</b><span>Fill a ListBox from Ring, move and remove items, and make controls in code.</span></a>
<a class="card" href="tut-70-wpf-animation.html"><div class="ic">🎨</div><b>WPF animation</b><span>Move, fade and rotate with DoubleAnimation, easing and AutoReverse.</span></a>
</div>

## Projects with windows

Complete programs: a to-do list, Tic-Tac-Toe, a command runner, an address book with a database, a sorting lab, a maze, an image filter lab and a chat (Windows only).

<div class="cards">
<a class="card" href="tut-24-todo.html"><div class="ic">🧩</div><b>Project: a to-do list</b><span>A complete window application that remembers its tasks in a JSON file.</span></a>
<a class="card" href="tut-35-tictactoe.html"><div class="ic">🧩</div><b>Project: Tic-Tac-Toe</b><span>Rules and state in testable functions, nine buttons from a loop.</span></a>
<a class="card" href="tut-143-quiz.html"><div class="ic">🧩</div><b>Project: a quiz</b><span>Questions as data, radio buttons, one button with two jobs, a score and best scores.</span></a>
<a class="card" href="tut-37-runner.html"><div class="ic">🧩</div><b>Project: a command runner</b><span>A window around a command-line tool: output, errors, exit codes.</span></a>
<a class="card" href="tut-48-addressbook.html"><div class="ic">🧩</div><b>Project: an address book</b><span>A window, a data grid and a database that stay consistent; search as you type.</span></a>
<a class="card" href="tut-60-sorting.html"><div class="ic">🧩</div><b>Watching sorting algorithms</b><span>Bubble, selection and insertion sort animated, with counters.</span></a>
<a class="card" href="tut-61-maze.html"><div class="ic">🧩</div><b>A maze</b><span>A stack makes the maze, a queue finds the shortest way.</span></a>
<a class="card" href="tut-62-filters.html"><div class="ic">🧩</div><b>An image filter lab</b><span>Pixels as numbers, filters as functions, and a BMP file written by hand.</span></a>
<a class="card" href="tut-63-chat.html"><div class="ic">🧩</div><b>A chat over TCP</b><span>A relay server, two clients and a timer that polls the sockets.</span></a>
</div>

## Libraries, testing and release

Giving Ring code to .NET (callbacks and events), exploring and building code with reflection and expression trees, using a library written in C#, testing, and giving your program to others.

<div class="cards">
<a class="card" href="tut-19-callbacks.html"><div class="ic">📦</div><b>Callbacks and events</b><span>Give Ring code to .NET: function names, code texts, events, errors and the thread rule.</span></a>
<a class="card" href="tut-20-reflection.html"><div class="ic">📦</div><b>Exploring .NET with reflection</b><span>Ask a class what it can do: properties, methods, parameters, enums.</span></a>
<a class="card" href="tut-151-inspector.html"><div class="ic">📦</div><b>Project: an object inspector</b><span>GetType, GetProperties and GetValue: the properties of any object in a list.</span></a>
<a class="card" href="tut-87-expressions.html"><div class="ic">📦</div><b>Expression trees</b><span>Code as data: build, print, compile and call functions at run time.</span></a>
<a class="card" href="tut-18-csharp-library.html"><div class="ic">📦</div><b>A library written in C#</b><span>Build a small C# library, wrap it and call it from Ring.</span></a>
<a class="card" href="tut-28-testing.html"><div class="ic">📦</div><b>Testing your programs</b><span>Testable functions, dnAssert, testing errors, self-testing windows.</span></a>
<a class="card" href="tut-119-distribution.html"><div class="ic">📦</div><b>Giving your program to others</b><span>Ring2EXE, what the other computer needs, a self check.</span></a>
</div>

After the tutorials: the [Core concepts](concepts.html) page lists the naming rules, the [Class reference](api.html) lists every class, and the [applications](gallery-apps.html) are bigger programs to read.
