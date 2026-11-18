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

After the tutorials: the [Core concepts](concepts.html) page lists the naming rules, the [Class reference](api.html) lists every class, and the [applications](gallery-apps.html) are bigger programs to read.
