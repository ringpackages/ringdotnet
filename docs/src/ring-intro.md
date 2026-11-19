---
title: Quick introduction to Ring
lead: Ring is small and quick to learn. This page shows everything you need to read the rest of this documentation — values, lists, decisions, functions, classes, errors and files — with programs you can run. No .NET yet.
---

## Who this page is for

This is an appendix: the rest of the documentation does not depend on reading it in order. If you already write Ring, go back to [Getting started](getting-started.html). If you come from C#, Python, JavaScript or another language, read this page once: Ring differs from some languages in a few ways, and knowing them helps when you read Ring code and the messages that come from .NET. The five programs are in `samples/UsingDotNet/tutorials` (`ring_basics.ring` … `ring_errors_files.ring`); run one with:

```bash
ring ring_basics.ring
```

> [!NOTE] This is a quick tour, not the manual. The Ring language documentation (<https://ring-lang.github.io/doc1.28/>) explains everything in depth.

> [!NOTE] **Syntax styles.** Ring allows more than one syntax style for the same program. This documentation uses one of them, the first style: blocks are closed with words (`ok`, `next`, `end`, `off`) and statements are written one to a line. Ring also allows braces `{ }` for control structures (`if`, `for`, `while`, `switch`) and for functions; a program written with braces runs the same way, and you can use the style you prefer in your own programs.

## 1. Values, text and numbers

{{file:samples/UsingDotNet/tutorials/ring_basics.ring}}

{{output:samples/UsingDotNet/tutorials/ring_basics.ring}}

What to remember:

- **No declarations.** A variable gets its type from the value. A name's first letter is a naming convention (`n` number, `c` text, `a` list, `o` object, `l` yes/no); this documentation uses it.
- **All numbers are doubles.** `7 / 2` is `3.5` (printed as `3.50`), and a number is exact only up to 2⁵³ (the tutorial [Number systems and big numbers](tut-67-bases.html)).
- **`+` follows its left side.** `"Count: " + 3` joins, `5 + "5"` adds, and `3 + " items"` is an error. Use `string(n)` when in doubt.
- **Indexes start at 1**, also for text. `len()` counts bytes (the tutorial [Unicode and encodings](tut-52-unicode.html)).
- **`^` is a bit operation**; power is `**` or `pow()`.
- **Comparing text:** `=` and `!=` compare text exactly (`"Abc"` and `"abc"` are different); `<` and `>` compare numbers, so for the order of two texts use `strcmp(a, b)` (less than 0, 0 or more than 0).
- **A text that looks like a number is still a text:** `isNumber("12")` is false. `0 + "12"` converts it to 12 and raises an error when the text is not a number (use `try` and `catch`).
- **Names are not case sensitive, keywords included:** `cAll` is the keyword `call` and `oR` is `or`, so a variable or a function is not given such a name.
- `True` and `False` are `1` and `0`.

## 2. Lists

{{file:samples/UsingDotNet/tutorials/ring_lists.ring}}

{{output:samples/UsingDotNet/tutorials/ring_lists.ring}}

A **list** is the only collection. It can hold numbers, texts, lists and objects. A list of `[name, value]` pairs is a dictionary; `:name` is just the text `"name"`, and `aPerson[:name]` reads a value by key. This pair form is how this package passes **named arguments** to .NET: `[ :server = "x", :port = 80 ]` ([Core concepts](concepts.html)).

> [!NOTE] Assigning a list or an object **copies** it, and `[oObject, "text"]` puts a copy of the object into the new list. A list passed to a function is not copied: the function works on the original.

## 3. Decisions, loops, functions

{{file:samples/UsingDotNet/tutorials/ring_flow.ring}}

{{output:samples/UsingDotNet/tutorials/ring_flow.ring}}

- In the style used here, blocks end with a word: `ok` closes `if`, `next` closes `for`, `end` closes `while`, `off` closes `switch`. `but` is *else if*. (Braces are also allowed, see the note at the top.)
- **A `func` continues until the next `func` or `class`**, so the code that starts your program goes *before* the functions, or inside `func main`, which Ring calls by itself at the end of the file.
- A Ring function takes a **fixed number of parameters**: there are no default values and no overloading, and a call with another number of values is an error. For overloaded .NET methods, RingDotNet therefore offers the `NULL` and named-argument forms ([Core concepts](concepts.html)).
- A variable at the top of the file is global; a variable made in a function is local.

## 4. Classes and objects

{{file:samples/UsingDotNet/tutorials/ring_classes.ring}}

{{output:samples/UsingDotNet/tutorials/ring_classes.ring}}

- `new Person("Ann",31)` makes an object and calls `init`. The braces `new Person(...) { city = "Oslo" }` set attributes while the object is made; this is the style used everywhere in this documentation (`oForm = new Form() { Text = "Hi" }`). The object is used with braces only if `init` ends with `return self`.
- `class Student from Person` is inheritance; `super.init(...)` and `super.describe()` call the parent.
- **Classes are written last in the file**: a `func` written after a class belongs to that class.
- Assigning an object to another variable **copies** it: change the copy and the original stays.

## 5. Errors, files and other files

{{file:samples/UsingDotNet/tutorials/ring_errors_files.ring}}

{{output:samples/UsingDotNet/tutorials/ring_errors_files.ring}}

- `try … catch … done` catches errors; the message is in `cCatchError`. `raise("text")` makes an error. This is how every .NET exception arrives in Ring (the tutorial [When things go wrong](tut-07-errors.html)).
- `load "file.ring"` runs another file. The first line of every RingDotNet program is `load "dotnet.ring"`.
- `sysargv` holds the command line (the tutorial [A command-line tool](tut-50-cli.html)).

## Ring and other languages

Some differences from other popular languages, as facts:

| Often in other languages | In Ring |
|---|---|
| declarations, types | none: the value has the type |
| `==` to compare | `=` (the context decides); `!=` for different |
| arrays from 0 | lists from **1** |
| integers and decimals | one number type, a double |
| `"a" + 1` and `1 + "a"` the same | the left side decides |
| methods overloaded by parameters | one function per name, with a fixed number of parameters |
| `{ }` blocks | words in the first style (`ok`, `next`, `end`, `off`, `done`); braces are allowed too |
| `string` is characters | text is **bytes** (UTF-8) |
| references to objects | objects and lists are **copied** on assignment |
| keywords are not case sensitive | `or`, `in`, `to`, `on`, `do`... also apply to names that spell them: `oR` is read as `or`, so a name like `oReader` is used instead |

## Where to go next

A Ring program uses .NET with two lines:

```ring
load "dotnet.ring"
using { "System" "System.Text" }

oBuilder = new StringBuilder("Hello")
? oBuilder.Append(", Ring!").ToString()
```

Then:

- [Getting started](getting-started.html): install the package and run the first program.
- [Core concepts](concepts.html): how .NET names, overloads, properties and enums look in Ring.
- The tutorial chapter [The basics](tutorials.html#the-basics): ten short lessons.
- [Rules and limits](gotchas.html): the points of Ring that matter when you use .NET.
