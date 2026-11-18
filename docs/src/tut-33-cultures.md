---
title: "Tutorial 33: Cultures"
lead: "1,234.5" and "1.234,5" are the same number written in two languages. This lesson shows how .NET writes, reads, sorts and capitalises text for different cultures, and when to avoid culture altogether.
---

## What you will learn

- what a culture is,
- formatting numbers, money and dates for other cultures,
- reading numbers with the right culture,
- the invariant culture for data,
- comparing and changing the case of text per language.

## What is a culture?

A **culture** is a language plus, optionally, a country: `en-US` (English in the United States), `de-DE` (German in Germany), `ar-EG` (Arabic in Egypt). It decides:

- the symbols: the decimal separator (`.` or `,`), the thousands separator, the currency sign,
- the order and names of dates: `7/4/2024`, `04.07.2024`, the names of days and months,
- the rules for sorting and for upper and lower case.

Every `ToString` and `Parse` that you call without saying a culture uses the culture of the **computer's user**. That is exactly right for text that people read, and exactly wrong for data that programs exchange.

## The program

{{file:docs/tutorials/t33_cultures.ring}}

{{output:docs/tutorials/t33_cultures.ring}}

## How it works

### Writing

`String.Format(culture, "{0:N2}", value)` formats with a **format code**: `N2` is a number with two decimals and a thousands separator, `C` is currency, `D` (on a date) the long date. The same value `1234567.891` becomes `1,234,567.89` in English, `1.234.567,89` in German, `1 234 567,89` in French (with a special space) and uses Arabic digits for `ar-EG`.

### Reading

`Double.Parse(text, culture)` reads a number *written in that culture*. The text `1.234,5` is `1234.5` for the German culture, but an **error** or a different number for the English culture, where the comma means "thousands". `TryParse` avoids the error and returns `[worked, value]`. **Always say which culture a text was written in.**

### The invariant culture

`InvariantCulture` is a fixed culture that never changes with the computer: `.` for decimals, no thousands separator problems. Use it for **files, network messages, JSON, logs** — anything a program writes for another program. Use the user's culture only for what you show to people.

> [!WARNING] The most common internationalisation bug: a program that writes `3.5` on one computer and `3,5` on another, then fails to read the file. Format and parse data with the invariant culture.

### Comparing and sorting

`String.Compare(a, b, ...)` takes how to compare: `"Ordinal"` compares the character codes (`a` = 97 comes after `B` = 66), the English alphabet puts `a` before `b`. Other languages sort letters differently (in Swedish `ö` comes after `z`). Use a culture comparison to sort names for people, ordinal to compare identifiers and keys.

### Upper and lower case

`ToUpper` depends on the culture: in Turkish the capital of `i` is `İ` (with a dot), so `title` becomes `TİTLE`. Use the invariant culture for identifiers and keys.

## What you learned

- a culture is a set of writing rules,
- say the culture when you format or parse,
- invariant for data, user culture for people,
- sorting and case depend on the language.

## Exercises

1. Print today's date in a short format in six cultures of your choice.
2. Parse `"3,5"` with `fr-FR` and with `en-US`: which works?
3. Sort the words `zebra apple Ärger Öl ananas` in German and in Swedish.
4. Write a function `toData(nNumber)` that formats a number with the invariant culture, and `fromData(cText)` that reads it back. Test both.

## Next

[Tutorial 34: Timers and progress](tut-34-timers.html).
