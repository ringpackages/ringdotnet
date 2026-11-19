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

## Part 1 — The class library (console programs)

<div class="cards">
<a class="card" href="tut-01-first-look.html"><div class="ic">1</div><b>A first look</b><span>Objects, types, properties, methods, static members, structs, collections and null.</span></a>
<a class="card" href="tut-02-text.html"><div class="ic">2</div><b>Working with text</b><span>Ring's own text functions and what .NET adds: Join, Format, StringBuilder, regular expressions, Base64, encodings.</span></a>
<a class="card" href="tut-03-numbers-dates.html"><div class="ic">3</div><b>Numbers, dates and times</b><span>Math, parsing safely, big numbers, random numbers, DateTime, TimeSpan and cultures.</span></a>
<a class="card" href="tut-04-collections.html"><div class="ic">4</div><b>Collections and LINQ</b><span>Lists, dictionaries, sets, queues, stacks, sorting and asking questions with LINQ.</span></a>
<a class="card" href="tut-05-files.html"><div class="ic">5</div><b>Files and folders</b><span>Path, Directory, File, readers and writers, file information and zip.</span></a>
<a class="card" href="tut-06-json-xml.html"><div class="ic">6</div><b>JSON and XML</b><span>Read, search, change and write structured data.</span></a>
<a class="card" href="tut-07-errors.html"><div class="ic">7</div><b>When things go wrong</b><span>Exceptions, try/catch, checking before acting, your own errors and cleaning up.</span></a>
<a class="card" href="tut-08-security.html"><div class="ic">8</div><b>Hashing and encryption</b><span>Checksums, password hashes, HMAC, random tokens and AES.</span></a>
<a class="card" href="tut-09-http.html"><div class="ic">9</div><b>HTTP</b><span>A web server and a web client in one program.</span></a>
<a class="card" href="tut-10-tasks-processes.html"><div class="ic">10</div><b>Time, tasks and other programs</b><span>Stopwatch, tasks, the environment and running another program.</span></a>
</div>

## Part 2 — Programs with windows, web and data

<div class="cards">
<a class="card" href="tut-11-first-window.html"><div class="ic">11</div><b>Your first window</b><span>A form, a label, a button, an event — with and without the helper functions.</span></a>
<a class="card" href="tut-12-controls.html"><div class="ic">12</div><b>A form with many controls</b><span>Text boxes, number box, combo box, check box, list box and validation.</span></a>
<a class="card" href="tut-13-editor.html"><div class="ic">13</div><b>A small text editor</b><span>Menus, a status bar, open and save, dock layout.</span></a>
<a class="card" href="tut-14-animation.html"><div class="ic">14</div><b>Drawing and animation</b><span>A canvas, a timer and the keyboard: a bouncing ball and a paddle.</span></a>
<a class="card" href="tut-15-wpf.html"><div class="ic">15</div><b>WPF</b><span>XAML windows, finding elements, events and data binding.</span></a>
<a class="card" href="tut-16-web-service.html"><div class="ic">16</div><b>A web service with a database</b><span>JSON over HTTP, stored with Entity Framework.</span></a>
<a class="card" href="tut-17-databases.html"><div class="ic">17</div><b>Databases step by step</b><span>Tables, rows, searches, relations, queries, transactions and files.</span></a>
<a class="card" href="tut-18-csharp-library.html"><div class="ic">18</div><b>A library written in C#</b><span>Build a small C# library, wrap it and call it from Ring.</span></a>
</div>

## Part 3 — Going further

<div class="cards">
<a class="card" href="tut-19-callbacks.html"><div class="ic">19</div><b>Callbacks and events</b><span>Give Ring code to .NET: function names, code texts, events, errors and the thread rule.</span></a>
<a class="card" href="tut-20-reflection.html"><div class="ic">20</div><b>Exploring .NET with reflection</b><span>Ask a class what it can do: properties, methods, parameters, enums.</span></a>
<a class="card" href="tut-21-log-analyzer.html"><div class="ic">21</div><b>Project: a log analyzer</b><span>Files, regular expressions, dictionaries, LINQ and a JSON report in one program.</span></a>
<a class="card" href="tut-22-images.html"><div class="ic">22</div><b>Images</b><span>Draw, read and change pixels, make a gray copy, resize and save PNG files.</span></a>
<a class="card" href="tut-23-layout.html"><div class="ic">23</div><b>Layout and richer controls</b><span>Split bars, tabs, table layout, and a data grid with a filter.</span></a>
<a class="card" href="tut-24-todo.html"><div class="ic">24</div><b>Project: a to-do list</b><span>A complete window application that remembers its tasks in a JSON file.</span></a>
<a class="card" href="tut-25-sockets.html"><div class="ic">25</div><b>Sockets</b><span>A TCP server and client that talk line by line.</span></a>
<a class="card" href="tut-26-website.html"><div class="ic">26</div><b>A small web site</b><span>HTML pages, a form, a guestbook, status codes and the escaping rule.</span></a>
<a class="card" href="tut-27-entities.html"><div class="ic">27</div><b>Entity objects and migrations</b><span>Rows as tracked objects, navigation properties, and changing a database that has data.</span></a>
<a class="card" href="tut-28-testing.html"><div class="ic">28</div><b>Testing your programs</b><span>Testable functions, dnAssert, testing errors, self-testing windows.</span></a>
</div>

## Part 4 — More lessons and projects

<div class="cards">
<a class="card" href="tut-29-regex.html"><div class="ic">29</div><b>Regular expressions in depth</b><span>Patterns, groups, replace, split, greedy and lazy, validation.</span></a>
<a class="card" href="tut-30-tables.html"><div class="ic">30</div><b>Tabular data</b><span>CSV, DataTable, DataView, Compute, sorting, filtering and grouping.</span></a>
<a class="card" href="tut-31-duplicates.html"><div class="ic">31</div><b>Project: duplicate files</b><span>Folders, content hashes and a dictionary find the copies.</span></a>
<a class="card" href="tut-32-settings.html"><div class="ic">32</div><b>Settings</b><span>Defaults, a JSON file, special folders, and a damaged file.</span></a>
<a class="card" href="tut-33-cultures.html"><div class="ic">33</div><b>Cultures</b><span>Formatting, parsing, sorting and case in different languages.</span></a>
<a class="card" href="tut-34-timers.html"><div class="ic">34</div><b>Timers and progress</b><span>A stopwatch, a progress bar, and a long job in small steps.</span></a>
<a class="card" href="tut-35-tictactoe.html"><div class="ic">35</div><b>Project: Tic-Tac-Toe</b><span>Rules and state in testable functions, nine buttons from a loop.</span></a>
<a class="card" href="tut-36-chart.html"><div class="ic">36</div><b>A chart</b><span>Scaling values to pixels, a round axis, bars, labels, saving, testing pixels.</span></a>
<a class="card" href="tut-37-runner.html"><div class="ic">37</div><b>Project: a command runner</b><span>A window around a command-line tool: output, errors, exit codes.</span></a>
<a class="card" href="tut-38-wpf-layout.html"><div class="ic">38</div><b>WPF layout and styles</b><span>Grid rows and columns, one Style for all buttons, a keypad.</span></a>
<a class="card" href="tut-39-rest-client.html"><div class="ic">39</div><b>A REST client</b><span>GET and POST with JSON, status codes, timeouts and errors.</span></a>
</div>

## Part 5 — Even more

<div class="cards">
<a class="card" href="tut-40-dialog.html"><div class="ic">40</div><b>Your own dialog</b><span>A modal form that asks for data, validates it and returns it; tested with a timer.</span></a>
<a class="card" href="tut-41-menus.html"><div class="ic">41</div><b>Menus, toolbars, shortcuts</b><span>Write each action once and reach it from a menu, a toolbar, a context menu and a key.</span></a>
<a class="card" href="tut-42-browser.html"><div class="ic">42</div><b>A folder browser</b><span>TreeView, ListView, recursion and the Tag property: a small Explorer.</span></a>
<a class="card" href="tut-43-calendar.html"><div class="ic">43</div><b>Calendars and dates</b><span>Month tables, ages, business days, birthdays and safe date arithmetic.</span></a>
<a class="card" href="tut-44-statistics.html"><div class="ic">44</div><b>Statistics and simulation</b><span>Mean, median, mode, deviation, primes, gcd and a Monte Carlo estimate of pi.</span></a>
<a class="card" href="tut-45-binary.html"><div class="ic">45</div><b>Binary files</b><span>BinaryWriter and BinaryReader, a file format, a hex dump, little endian.</span></a>
<a class="card" href="tut-46-backup.html"><div class="ic">46</div><b>Project: a backup tool</b><span>Zip by date, keep the newest few, restore and verify.</span></a>
<a class="card" href="tut-47-markdown.html"><div class="ic">47</div><b>Project: Markdown to HTML</b><span>Blocks, inline formatting, regular expressions, and escaping first.</span></a>
<a class="card" href="tut-48-addressbook.html"><div class="ic">48</div><b>Project: an address book</b><span>A window, a data grid and a database that stay consistent; search as you type.</span></a>
<a class="card" href="tut-49-login.html"><div class="ic">49</div><b>Login, sessions and cookies</b><span>Registration, safe passwords, a session cookie and a protected page.</span></a>
<a class="card" href="tut-50-cli.html"><div class="ic">50</div><b>A command-line tool</b><span>Arguments, options, usage text and exit codes.</span></a>
<a class="card" href="tut-51-logging.html"><div class="ic">51</div><b>Logging</b><span>Levels, timestamps, a log file and rotation.</span></a>
<a class="card" href="tut-52-unicode.html"><div class="ic">52</div><b>Unicode and encodings</b><span>Bytes, code points and letters; UTF-8, UTF-16 and mojibake.</span></a>
<a class="card" href="tut-53-speed.html"><div class="ic">53</div><b>Speed: measure first</b><span>Stopwatch, a cache, StringBuilder against +=, and the cost of bridge calls.</span></a>
<a class="card" href="tut-54-expression.html"><div class="ic">54</div><b>An expression calculator</b><span>Tokens, a recursive-descent parser, precedence and clear errors.</span></a>
<a class="card" href="tut-55-miniweb.html"><div class="ic">55</div><b>A tiny web framework</b><span>Routes with parameters, a catch-all handler and escaped templates.</span></a>
<a class="card" href="tut-56-streams.html"><div class="ic">56</div><b>Streams and compression</b><span>MemoryStream, StreamWriter, GZip, and one pattern for memory and files.</span></a>
<a class="card" href="tut-57-money.html"><div class="ic">57</div><b>Money</b><span>Why 0.1 + 0.2 is not 0.3: whole cents, rounding rules and fair splitting.</span></a>
<a class="card" href="tut-58-undo.html"><div class="ic">58</div><b>Undo, redo and queues</b><span>Stacks and queues; two stacks make undo and redo.</span></a>
<a class="card" href="tut-59-paths.html"><div class="ic">59</div><b>Paths and the environment</b><span>Path.Combine, special folders, valid names and environment variables.</span></a>
<a class="card" href="tut-60-sorting.html"><div class="ic">60</div><b>Watching sorting algorithms</b><span>Bubble, selection and insertion sort animated, with counters.</span></a>
<a class="card" href="tut-61-maze.html"><div class="ic">61</div><b>A maze</b><span>A stack makes the maze, a queue finds the shortest way.</span></a>
<a class="card" href="tut-62-filters.html"><div class="ic">62</div><b>An image filter lab</b><span>Pixels as numbers, filters as functions, and a BMP file written by hand.</span></a>
<a class="card" href="tut-63-chat.html"><div class="ic">63</div><b>A chat over TCP</b><span>A relay server, two clients and a timer that polls the sockets.</span></a>
<a class="card" href="tut-64-urls.html"><div class="ic">64</div><b>URLs and encodings</b><span>Uri, query strings, percent-encoding, relative addresses and Base64.</span></a>
<a class="card" href="tut-65-enums.html"><div class="ic">65</div><b>Enums and flags</b><span>Named choices as text, comma-separated flags and your own bit flags.</span></a>
<a class="card" href="tut-66-spelling.html"><div class="ic">66</div><b>A spell checker</b><span>A set of words, the edit distance table and the best suggestions.</span></a>
<a class="card" href="tut-67-bases.html"><div class="ic">67</div><b>Number systems and big numbers</b><span>Binary and hex, bits, the 2^53 limit and BigInteger.</span></a>
<a class="card" href="tut-68-timezones.html"><div class="ic">68</div><b>Time zones</b><span>UTC, local time, daylight saving, a meeting and a flight across zones.</span></a>
<a class="card" href="tut-69-random.html"><div class="ic">69</div><b>Randomness</b><span>Seeds, dice, a correct shuffle, weighted choices, Guids and secure numbers.</span></a>
<a class="card" href="tut-70-wpf-animation.html"><div class="ic">70</div><b>WPF animation</b><span>Move, fade and rotate with DoubleAnimation, easing and AutoReverse.</span></a>
<a class="card" href="tut-71-dispose.html"><div class="ic">71</div><b>Releasing resources</b><span>Locked files, Dispose, and a clean-up that runs after an error.</span></a>
<a class="card" href="tut-72-xml.html"><div class="ic">72</div><b>XML in depth</b><span>XDocument, XPath, building and changing elements, bad XML.</span></a>
<a class="card" href="tut-73-sql-reports.html"><div class="ic">73</div><b>Reports with SQL</b><span>JOIN, GROUP BY, HAVING, LEFT JOIN and sub-queries.</span></a>
<a class="card" href="tut-74-system.html"><div class="ic">74</div><b>Asking the computer</b><span>The system, processors, memory, drives and the running programs.</span></a>
<a class="card" href="tut-75-recursion.html"><div class="ic">75</div><b>Recursion</b><span>Factorial, the Towers of Hanoi, permutations, a folder tree and a flood fill.</span></a>
<a class="card" href="tut-76-calendars.html"><div class="ic">76</div><b>Other calendars</b><span>Hijri, Persian, Hebrew, Japanese and Thai dates; Arabic names with ar-SA.</span></a>
<a class="card" href="tut-77-xslt.html"><div class="ic">77</div><b>XSLT</b><span>Turn XML into text, CSV and HTML with XslCompiledTransform.</span></a>
<a class="card" href="tut-78-crypto.html"><div class="ic">78</div><b>Protecting and signing messages</b><span>AES, HMAC (encrypt-then-MAC), PBKDF2 keys and RSA signatures.</span></a>
<a class="card" href="tut-79-processes-talk.html"><div class="ic">79</div><b>Two programs talking</b><span>Named pipes between processes, Process.Start, and a mutex for one copy.</span></a>
<a class="card" href="tut-80-json-nodes.html"><div class="ic">80</div><b>JSON as a tree</b><span>JsonNode: read, edit, build, merge and clone JSON.</span></a>
<a class="card" href="tut-81-network-tools.html"><div class="ic">81</div><b>Network tools</b><span>IPAddress, Dns, Ping, interfaces and a port check, all on this computer.</span></a>
<a class="card" href="tut-82-shared-memory.html"><div class="ic">82</div><b>Shared memory</b><span>Memory-mapped files shared by two programs, and a file edited in place.</span></a>
<a class="card" href="tut-83-tasks-waiting.html"><div class="ic">83</div><b>Tasks that wait</b><span>Task.Delay, WhenAll, WhenAny, time limits and cancellation.</span></a>
<a class="card" href="tut-84-http-client.html"><div class="ic">84</div><b>HttpClient in depth</b><span>Headers, status codes, EnsureSuccessStatusCode, cancelling and saving a download.</span></a>
<a class="card" href="tut-85-feed-programs.html"><div class="ic">85</div><b>Working with other programs</b><span>Standard input, chaining, environment, exit codes, time limits and Kill.</span></a>
<a class="card" href="tut-86-escaping.html"><div class="ic">86</div><b>Escaping</b><span>The right encoding for HTML, URLs, JavaScript, JSON, XML, regular expressions and SQL.</span></a>
<a class="card" href="tut-87-expressions.html"><div class="ic">87</div><b>Expression trees</b><span>Code as data: build, print, compile and call functions at run time.</span></a>
<a class="card" href="tut-88-compression.html"><div class="ic">88</div><b>Compression</b><span>GZip, Deflate and Brotli streams, sizes, round trips and a .gz file.</span></a>
<a class="card" href="tut-89-concurrent-collections.html"><div class="ic">89</div><b>Collections for many threads</b><span>Concurrent queue, stack, blocking collection and dictionary.</span></a>
<a class="card" href="tut-90-big-numbers.html"><div class="ic">90</div><b>Big numbers</b><span>BigInteger for exact big whole numbers, and Complex numbers.</span></a>
<a class="card" href="tut-91-udp.html"><div class="ic">91</div><b>UDP</b><span>Datagrams between sockets, answers, time limits and lost messages.</span></a>
<a class="card" href="tut-92-data-structures.html"><div class="ic">92</div><b>More data structures</b><span>PriorityQueue, SortedSet, SortedDictionary, LinkedList and BitArray.</span></a>
<a class="card" href="tut-93-identifiers.html"><div class="ic">93</div><b>Identifiers and versions</b><span>Guid, Version, and sorting version numbers by number.</span></a>
<a class="card" href="tut-94-mail-messages.html"><div class="ic">94</div><b>E-mail messages</b><span>MailAddress, MailMessage, recipients and text plus HTML views.</span></a>
<a class="card" href="tut-95-claims.html"><div class="ic">95</div><b>Identities and claims</b><span>Claims, identities, roles and a permission check.</span></a>
<a class="card" href="tut-96-tar.html"><div class="ic">96</div><b>Tar archives</b><span>Create, list, read and unpack tar files.</span></a>
<a class="card" href="tut-97-comparers.html"><div class="ic">97</div><b>Comparing text</b><span>Ordinal and culture comparison, StringComparer, and the Turkish i.</span></a>
<a class="card" href="tut-98-memory.html"><div class="ic">98</div><b>Memory and the garbage collector</b><span>GC, weak references, generations and release().</span></a>
<a class="card" href="tut-99-vectors.html"><div class="ic">99</div><b>Vectors and matrices</b><span>Vector3, dot and cross products, Matrix3x2 transformations.</span></a>
<a class="card" href="tut-100-json-writer.html"><div class="ic">100</div><b>Writing JSON as a stream</b><span>Utf8JsonWriter, indentation, escaping and JsonSerializer options.</span></a>
<a class="card" href="tut-101-number-types.html"><div class="ic">101</div><b>Number types</b><span>Limits, checked conversion, TryParse, Int128 and floating point.</span></a>
<a class="card" href="tut-102-ip-networks.html"><div class="ic">102</div><b>IP networks</b><span>CIDR, IPNetwork.Contains and a private-address allow list.</span></a>
<a class="card" href="tut-103-dates-and-times.html"><div class="ic">103</div><b>Dates and times</b><span>DateOnly, TimeOnly, DateTimeOffset, TimeSpan and month-end rules.</span></a>
<a class="card" href="tut-104-text-readers-writers.html"><div class="ic">104</div><b>Text readers and writers</b><span>StringWriter, StringReader, capturing Console output, String.Format.</span></a>
<a class="card" href="tut-105-signatures.html"><div class="ic">105</div><b>Digital signatures</b><span>ECDsa keys, signing, verifying and sharing the public key.</span></a>
<a class="card" href="tut-106-arrays.html"><div class="ic">106</div><b>Arrays</b><span>Typed arrays, Array.Sort, BinarySearch, Copy and two dimensions.</span></a>
<a class="card" href="tut-107-sets.html"><div class="ic">107</div><b>Sets</b><span>HashSet: union, intersection, difference and removing duplicates.</span></a>
<a class="card" href="tut-108-zip-in-memory.html"><div class="ic">108</div><b>ZIP archives in memory</b><span>ZipArchive on a MemoryStream: entries, levels and updates.</span></a>
</div>

## Learning path

| If you want to... | Read |
|---|---|
| understand the vocabulary | [.NET for Ring programmers](tut-concepts.html), [Reading the .NET documentation](tut-reading-docs.html) |
| process data and files | tutorials 2–6 |
| write programs that do not crash | tutorial 7, then 8 |
| talk to other computers | tutorial 9, then 16 |
| build desktop programs | tutorials 11–15 |
| store data | tutorial 17 |
| use code that others wrote in C# | tutorial 18 |
| give Ring code to .NET, explore classes | tutorials 19, 20 |
| bigger projects | tutorials 21, 24 |
| images and richer windows | tutorials 22, 23 |
| network programs and web sites | tutorials 25, 26 |
| more databases and testing | tutorials 27, 28 |
| text patterns, tables, settings, cultures | tutorials 29, 30, 32, 33 |
| timers, games and charts | tutorials 34, 35, 36 |
| tools around other programs, WPF layout, web clients | tutorials 37, 38, 39 |
| dialogs, menus, trees and lists | tutorials 40, 41, 42 |
| dates, numbers, binary data, backups, text conversion | tutorials 43, 44, 45, 46, 47 |
| a database application, and logins for web sites | tutorials 48, 49 |

After the tutorials: the [Core concepts](concepts.html) page lists the naming rules, the [Class reference](api.html) lists every class, and the [applications](gallery-apps.html) are bigger programs to read.
