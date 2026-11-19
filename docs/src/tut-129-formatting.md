---
title: "Formatting numbers and dates"
lead: The same number can be written as 1234.5678, 1,234.57, 123,456.8 % or 4D2. A format string says which. This lesson uses String.Format and the format methods for fixed decimals, thousands separators, percent, custom patterns, alignment in tables, dates and durations.
---

## What you will learn

- the **placeholder** `{0:format}` of `String.Format`,
- the standard number formats `F`, `N`, `E`, `P`, `C` and `G`,
- whole numbers in other bases with `Convert.ToString`,
- **custom patterns** (`0.00`, `#,##0.00`, `0.0%`),
- **alignment** `{0,10}` and `{0,-10}` for tables,
- date patterns (`yyyy-MM-dd`, `d MMMM yyyy`) and the standard date letters,
- patterns for durations (`TimeSpan`),
- why the program uses the **invariant culture**.

The tutorial [Cultures](tut-33-cultures.html) showed that the same format gives different texts in different countries. This lesson is about the formats themselves.

## The program

{{file:samples/UsingDotNet/tutorials/ch02_formatting.ring}}

{{output:samples/UsingDotNet/tutorials/ch02_formatting.ring}}

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnStatic`, `dnNewGeneric`, `callMethod`, `getProp`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### The invariant culture

Decimal separators, thousands separators, month names and money symbols depend on the **culture**. The program passes `new CultureInfo("en-US").InvariantCulture` to every call, so the output is the same on every computer. For text that goes to a file or to another program (data) use the invariant culture. For text that a person reads use the culture of that person, which is the default when you leave the provider out.

### Placeholders

`String.Format` takes a text with **placeholders**: `{0}` is the first value, `{1}` the second. After a colon comes the format of that value: `{0:N2}`. In Ring the values are named `:arg0`, `:arg1` and so on, and the text is `:format`: `oString.Format([ :provider = oCulture, :format = "{0:N2}", :arg0 = 1234.5678 ])`.

### Standard number formats

One letter, and often a number of digits. **F** is fixed: `F2` always has two decimals. **N** is the same with thousands separators. **E** is scientific. **P** is a percent: the value is multiplied by 100 (`0.256` is `25.6 %`). **C** is money. **G** is the shortest general form. The number after the letter means decimals for `F`, `N`, `P` and `C`.

### Whole numbers

The formats `D` (zeros in front) and `X` (hexadecimal) are made for whole-number *types*. A Ring number reaches `String.Format` as a `double`, so those two do not apply. `Convert.ToString(255, 16)` gives `ff` (bases 2, 8, 10 and 16 work), and Ring's `right("000000" + n, 6)` puts zeros in front. `Convert.ToString` is called with `dnStatic` because `ToString` is also a method of every object.

### Custom patterns

A custom pattern draws the number: `0` is a digit that is always written (a zero if there is none), `#` is a digit that is written only when there is one, `,` is the thousands separator, `.` the decimal point and `%` multiplies by 100 and adds the sign. `000.0` gives `003.1`; `#.##` gives `.5` for `0.5` and `12` for `12`, with no zeros. Text in single quotes is written as it is (`0 'kg'`).

### Alignment

`{0,-14}` writes the value in 14 places, to the left; `{1,9:F2}` writes the second value in 9 places to the right, with two decimals. A table of prices lines up on the decimal point because every number has the same width and the same decimals. (In Ring programs that only print, `padRight` functions do the same; here the format does it in one text.)

### Dates and durations

The letters of a date pattern are the same everywhere: `yyyy` year, `MM` month number, `MMMM` month name, `dd` day, `dddd` day name, `HH` hours (24), `h` and `tt` hours (12) and AM/PM, `mm` minutes, `ss` seconds. A single letter is a ready-made pattern: `d` short date, `D` long date, `t` short time, `o` the **round trip** form that always reads back to the same moment (use it in files). The `:` and `/` in a pattern mean the separators of the culture. A `TimeSpan` has its own patterns: `hh\:mm\:ss` (the backslash says that the colon is just a colon) and `h' h 'm' min'`.

### A wrong pattern

A letter that is not a format raises `System.FormatException`, not a wrong text. The program catches it and prints the kind of the error.

## What you learned

- placeholders and the standard number formats,
- custom patterns and alignment,
- the date and duration patterns,
- the invariant culture for data.

## Exercises

1. Print the numbers 1 to 5 and their squares in two columns, with the squares aligned to the right.
2. Write `money(value)` that always gives two decimals and thousands separators.
3. Write the date of today in the forms `2030-03-09`, `9 Mar 2030` and `Saturday 9 March`.
4. Show a duration of 90061 seconds as `1 d 01:01:01` (the pattern `d' d 'hh\:mm\:ss`).

## Next

[Unicode and encodings](tut-52-unicode.html)
