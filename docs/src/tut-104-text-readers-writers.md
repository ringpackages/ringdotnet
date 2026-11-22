---
title: "Text readers and writers"
lead: StringWriter and StringReader are text streams that live in memory. This lesson uses them to write code that works with any writer (a string, a file, the console), to read text line by line, to capture the output of code that prints, and to format text with String.Format.
---

## What you will learn

- `StringWriter` and `StringReader`,
- the base classes `TextWriter` and `TextReader`, and why a function should take one,
- reading line by line with `ReadLine` and `Peek`,
- `Console.SetOut` to capture output,
- composite formatting with `String.Format` (`{0}`, alignment, formats).

The tutorial [Files and folders](tut-05-files.html) wrote and read files and the tutorial [Streams and compression](tut-56-streams.html) explained streams. A **string** can be a stream too, and that is very useful.

## The program

{{file:samples/UsingDotNet/tutorials/ch02_text_readers_writers.ring}}

{{output:samples/UsingDotNet/tutorials/ch02_text_readers_writers.ring}}

## How it works

### StringWriter

A `StringWriter` has the same methods as a `StreamWriter` (`Write`, `WriteLine`), but it collects the text in memory; `ToString()` gives it back. Use it to build a longer text piece by piece, and above all as a **test double** for a file or the console. `WriteLine(NULL)` ends the current line without adding text. (Windows ends a line with two characters, `CR LF`, and Linux with one, `LF`; the program removes `char(13)` so the output is the same everywhere.)

### StringReader

`StringReader` reads a text like a file: `ReadLine` gives one line, `ReadToEnd` the rest. It has no `EndOfStream`; `Peek()` answers the next character without taking it, and **-1** means that nothing is left, so `while oReader.Peek() != -1` reads all the lines.

### One function, many writers

`StringWriter` and `StreamWriter` both derive from **`TextWriter`**. The function `writeReport(oWriter, ...)` only calls `WriteLine`, so it does not know where the text goes: step 3 calls it with a string and with a file and gets the same report. This is a good habit for your own functions: *take a writer as a parameter* instead of writing to a fixed place. The function is then easy to test (give it a `StringWriter` and look at the result) and easy to reuse (give it a network stream). The same is true for readers and `TextReader`.

### Capturing the console

`Console.SetOut(writer)` redirects everything that .NET code writes with `Console.WriteLine` into a writer; the program saves the old writer (`Console.Out`) first and puts it back, because forgetting that hides every later message. It is the way to check the output of a .NET method that prints. Ring's own `?` and `see` do not go through `Console`, so they are not captured.

### Composite formatting

`String.Format("{0} bought {1} items for {2:0.00}", args)` puts the values into numbered places. After a colon comes a **format**: `0.00` is two decimals (12.50), `00000` pads with zeros (00042), `0.##` shows up to two decimals and no more (0.25). The format `P0` writes a percentage, but where the `%` goes depends on the culture of the computer (`25%` or `25 %`), so a test must not compare it as text. A comma sets the width: `{0,-8}` is left-aligned in 8 characters and `{1,8}` right-aligned. The method has several forms, so it takes names (`:format` and `:args`). A whole number from Ring is an `Int32` in the array, so `D5` (zeros in front) and `X4` (hexadecimal) work for it; a number with a fraction is a `Double`, and those two formats raise *Format specifier was invalid* for it.

## What you learned

- `StringWriter` and `StringReader` for text in memory,
- `Peek` and `ReadLine` to read all lines,
- functions that take a `TextWriter` can write anywhere,
- `Console.SetOut` captures output (and must be undone),
- `String.Format` with places, alignment and formats.

## Exercises

1. Write `numberedLines(oReader, oWriter)` that copies a text and puts a line number before each line.
2. Write a test that captures the output of `Console.WriteLine` and checks it.
3. Make a table with `String.Format` and aligned columns for a list of products and prices.
4. Read a CSV text with `StringReader` and cut each line into fields with Ring (`str2list(substr(cLine,",",nl))`, see the tutorial [Working with text](tut-02-text.html)).

## Next

[Escaping](tut-86-escaping.html)
