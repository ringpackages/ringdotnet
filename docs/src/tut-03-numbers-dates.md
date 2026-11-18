---
title: "Tutorial 3: Numbers, dates and times"
lead: Math functions, converting text to numbers without crashing, numbers of any size, random numbers, and the date and time classes DateTime and TimeSpan.
---

## What you will learn

- `Math` for rounding, roots and powers,
- `TryParse`: turn text into a number safely,
- `BigInteger`: numbers without a limit,
- `Random`,
- `DateTime`, `TimeSpan`, parsing dates and formatting in different cultures.

## The program

{{file:docs/tutorials/t03_numbers_dates.ring}}

{{output:docs/tutorials/t03_numbers_dates.ring}}

## How it works

### Math

`Math` is a class of static functions: `Round`, `Sqrt`, `Pow`, `Abs`, `Floor`, `Min`, `Max`. `Round` has several versions (round to a whole number, round to some digits), so the program uses **named arguments**: `Round([ :value = 3.14159, :digits = 2 ])`. The names come from the .NET documentation, and the order does not matter.

### TryParse: no crash

`Int32.Parse("abc")` raises an error. `TryParse` never does: it returns a list `[worked, value]`. A method that has an `out` parameter in C# returns its results as a list in Ring: first the return value (here true or false), then the `out` values.

```ring
aResult = new Int32().TryParse("123")
if aResult[1]
	? "the number is " + aResult[2]
ok
```

### BigInteger

A Ring number is a 64-bit floating point number: after about 15 digits it loses precision. `BigInteger` stores any size exactly. The program computes 30! = `265252859812191058636308480000000`. Create one from text with `Parse("1")`, and do arithmetic with methods: `Multiply(a,b)`, `Add`, `Pow`.

### Random

`new Random(42)` starts a random generator with a *seed*. The same seed always gives the same numbers, which is useful in tests. Leave the seed out (`new Random()`) for numbers that change every run. `Next_` takes a minimum and a maximum (the maximum is *not* included, so `1` and `7` give a die). The trailing `_` is there because `Next` is a Ring keyword.

### DateTime

A `DateTime` has a year, month, day, hour, minute and second. Two ways to create one:

```ring
oDate = new DateTime(2024,12,25)                                              # year, month, day
oDate = dnNew("DateTime",[ :year = 2024, :month = 12, :day = 25, :hour = 18, :minute = 30, :second = 0 ])
```

Properties: `Year`, `Month`, `Day`, `DayOfWeek` (a text like `Wednesday`). **Dates never change**: `AddDays(10)` returns a *new* date. That is why you can chain: `oDate.AddDays(10).AddHours(-3)`.

### TimeSpan

The difference between two dates is a `TimeSpan`: `Subtract` gives it, and it has `Days`, `Hours` and `TotalHours` (the whole span in hours, with decimals).

### Formats and cultures

`ToString_1("dddd, dd MMMM yyyy HH:mm")` formats a date with a pattern. Some letters: `yyyy` year, `MM` month number, `MMMM` month name, `dd` day, `dddd` weekday, `HH` hour (24), `mm` minute. A *culture* changes the language: `ToString_2("D", new CultureInfo("de-DE"))` writes the long date in German.

## What you learned

- `Math` functions and named arguments,
- `TryParse` for safe conversion,
- `BigInteger` for exact big numbers,
- dates are values that you copy, never change,
- format patterns and cultures.

## Exercises

1. Print how many days are left until the end of this year.
2. Parse the text `"15/03/2024"` with `ParseExact` and a format of `dd/MM/yyyy`.
3. Compute 100! with `BigInteger` and print how many digits it has.
4. Throw a die 10 times with `Random` and count how many sixes you get.
5. Print today's date in three cultures (`en-US`, `fr-FR`, `ja-JP`).

## Next

[Tutorial 4: Collections and LINQ](tut-04-collections.html).
