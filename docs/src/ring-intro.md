---
title: Quick introduction to Ring
lead: Ring is small and quick to learn. This page shows everything you need to read the rest of this documentation — values, lists, decisions, functions, classes, errors and files — with programs you can run. No .NET yet.
---

## Who this page is for

If you already write Ring, skip to [Getting started](getting-started.html). If you come from C#, Python, JavaScript or another language, read this page once: Ring has a few habits that surprise people, and they are the same habits that make the .NET error messages look strange. The five programs are in `docs/tutorials` (`r01_ring_basics.ring` … `r05_ring_errors_files.ring`); run one with:

```bash
ring r01_ring_basics.ring
```

> [!NOTE] This is a quick tour, not the manual. The Ring language documentation (<https://ring-lang.github.io/doc1.28/>) explains everything in depth.

## 1. Values, text and numbers

{{file:docs/tutorials/r01_ring_basics.ring}}

{{output:docs/tutorials/r01_ring_basics.ring}}

What to remember:

- **No declarations.** A variable gets its type from the value. A name's first letter is only a habit (`n` number, `c` text, `a` list, `o` object, `l` yes/no); this documentation uses it.
- **All numbers are doubles.** `7 / 2` is `3.5` (printed as `3.50`), and a number is exact only up to 2⁵³ ([tutorial 67](tut-67-bases.html)).
- **`+` follows its left side.** `"Count: " + 3` joins, `5 + "5"` adds, and `3 + " items"` is an error. Use `string(n)` when in doubt.
- **Indexes start at 1**, also for text. `len()` counts bytes ([tutorial 52](tut-52-unicode.html)).
- **`^` is a bit operation**; power is `**` or `pow()`.
- `True` and `False` are `1` and `0`.

## 2. Lists

{{file:docs/tutorials/r02_ring_lists.ring}}

{{output:docs/tutorials/r02_ring_lists.ring}}

A **list** is the only collection. It can hold numbers, texts, lists and objects. A list of `[name, value]` pairs is a dictionary; `:name` is just the text `"name"`, and `aPerson[:name]` reads a value by key. This pair form is how this package passes **named arguments** to .NET: `[ :server = "x", :port = 80 ]` ([Core concepts](concepts.html)).

> [!WARNING] Assigning a list or an object **copies** it, and `[oObject, "text"]` copies the object into the new list. Passing a list to a function does not copy it.

## 3. Decisions, loops, functions

{{file:docs/tutorials/r03_ring_flow.ring}}

{{output:docs/tutorials/r03_ring_flow.ring}}

- Blocks end with a word, not a brace: `ok` closes `if`, `next` closes `for`, `end` closes `while`, `off` closes `switch`. `but` is *else if*.
- **A `func` swallows what follows it**, so the code that starts your program goes *before* the functions, or inside `func main`, which Ring calls by itself at the end of the file.
- There are **no default parameters and no overloading**. Calling a function with too few or too many values is an error — this is why overloaded .NET methods need the `NULL` and named-argument forms of this package.
- A variable at the top of the file is global; a variable made in a function is local.

## 4. Classes and objects

{{file:docs/tutorials/r04_ring_classes.ring}}

{{output:docs/tutorials/r04_ring_classes.ring}}

- `new Person("Ann",31)` makes an object and calls `init`. The braces `new Person(...) { city = "Oslo" }` set attributes while the object is made; this is the style used everywhere in this documentation (`oForm = new Form() { Text = "Hi" }`). The object is used with braces only if `init` ends with `return self`.
- `class Student from Person` is inheritance; `super.init(...)` and `super.describe()` call the parent.
- **Classes go last in the file.** A `func` that appears after a class becomes a method of it.
- Assigning an object to another variable **copies** it: change the copy and the original stays.

## 5. Errors, files and other files

{{file:docs/tutorials/r05_ring_errors_files.ring}}

{{output:docs/tutorials/r05_ring_errors_files.ring}}

- `try … catch … done` catches errors; the message is in `cCatchError`. `raise("text")` makes an error. This is how every .NET exception arrives in Ring ([tutorial 7](tut-07-errors.html)).
- `load "file.ring"` runs another file. The first line of every RingDotNet program is `load "dotnet.ring"`.
- `sysargv` holds the command line ([tutorial 50](tut-50-cli.html)).

## Ring against other languages

| You expect | In Ring |
|---|---|
| declarations, types | none: the value has the type |
| `==` to compare | `=` (the context decides); `!=` for different |
| arrays from 0 | lists from **1** |
| integers and decimals | one number type, a double |
| `"a" + 1` and `1 + "a"` the same | the left side decides |
| methods overloaded by parameters | one function per name; extra values are an error |
| `{ }` blocks | words: `ok`, `next`, `end`, `off`, `done` |
| `string` is characters | text is **bytes** (UTF-8) |
| references to objects | objects and lists are **copied** on assignment |
| reserved words | `or`, `in`, `to`, `on`, `do`... — also inside names: `oR` is read as `or`, so use `oReader` |

## What comes next

A Ring program uses .NET with two lines:

```ring
load "dotnet.ring"
using { "System" "System.Text" }

oBuilder = new StringBuilder("Hello")
? oBuilder.Append(", Ring!").ToString()
```

Continue with [Getting started](getting-started.html), then [Core concepts](concepts.html) (how .NET names, overloads, properties and enums look in Ring) and the [tutorials](tutorials.html). The Ring-specific traps are collected in [Gotchas & limits](gotchas.html).
