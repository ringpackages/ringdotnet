---
title: "Rounding and the Math class"
lead: Rounding looks simple until a total is a cent wrong. This lesson uses the Math class for the two rounding modes, for the digits after the point, for Floor, Ceiling and Truncate, for Clamp-style limits, powers and logarithms, and shows how the rounding rule changes the total of a bill.
---

## What you will learn

- `Round` and its **modes**: `ToEven` and `AwayFromZero`,
- `Round` with a number of digits,
- `Floor`, `Ceiling` and `Truncate`, and what they do to negative numbers,
- the remainder operator `%`,
- keeping a number between a minimum and a maximum,
- `Sign`, `Abs`, `Pow`, `Sqrt`, `Cbrt` and the logarithms,
- why money needs **one** rounding rule.

The tutorial [Numbers, dates, times](tut-03-numbers-dates.html) used the basic functions and the tutorial [Money](tut-57-money.html) showed why money needs care. This lesson is about the rules of rounding.

> [!NOTE] Ring shows a number with two decimals unless you change it with `decimals(n)`. The program uses `decimals(3)` for the step with digits, so that the third decimal is visible.

## The program

{{file:samples/UsingDotNet/tutorials/t126_rounding.ring}}

{{output:samples/UsingDotNet/tutorials/t126_rounding.ring}}

## How it works

### Two modes for the middle

A number that is exactly in the middle between two whole numbers (`2.5`) must go one way. **`ToEven`** (the default of .NET, also called *banker's rounding*) goes to the neighbor that is even: `0.5` and `2.5` go down, `1.5` and `3.5` go up. Over many numbers the errors cancel, so the sum of the rounded numbers stays close to the real sum. **`AwayFromZero`** is the rule taught at school: `2.5` becomes `3` and `-2.5` becomes `-3`. The mode is a text, written in the named values of the call: `Round([ :value = 2.5, :mode = "AwayFromZero" ])`.

### Digits

`:digits = 2` rounds to hundredths. The middle of a digit follows the same modes: `0.125` is between `0.12` and `0.13`, and `ToEven` chooses `0.12`.

### Floor, Ceiling, Truncate

All three give a whole number and differ only for negative numbers: `Floor` goes down (`-2.2` becomes `-3`), `Ceiling` goes up (`-2.2` becomes `-2`) and `Truncate` cuts the decimals (`-2.2` becomes `-2`). Ring has its own `floor()`; `Math` adds `Ceiling` and `Truncate`.

### The remainder

`17 % 5` is `2`. For a negative first number the remainder is negative too (`-17 % 5` is `-2`), as in C# and Java. When you need a result that is never negative (the index of a circular list, for example) add the divisor and take the remainder again: `((n % m) + m) % m`.

### Limits

`clamp(value, min, max)` keeps a value inside a range: a volume from 0 to 100, a color part from 0 to 255. The `Math` class has `Clamp`, but its versions are made for each number type, so a small Ring function that compares is simpler. `Sign` gives `-1`, `0` or `1`, and `Abs` the size without the sign.

### Powers and logarithms

`Pow(2, 10)` is `1024`, `Sqrt(144)` is `12`, `Cbrt(27)` is `3` (the cube root). `Log10(1000)` is `3`, `Log2(1024)` is `10`, and `Log(x)` is the natural logarithm. The constants are `Math.PI` and `Math.E`.

### Rounding money

Ten items of `0.125` cost `1.25`. Each item rounded to cents with `ToEven` is `0.12`, so the total is `1.20`; with `AwayFromZero` each is `0.13` and the total is `1.30`. The right answer depends on the rule that the shop (or the law of the country) uses, and it must be **the same rule everywhere** in the program: round each line, or round only the final amount, but never mix them. For exact amounts keep money in whole cents (`125` for `1.25`), as the tutorial [Money](tut-57-money.html) does.

## What you learned

- `Round` with `ToEven` and `AwayFromZero`, with and without digits,
- `Floor`, `Ceiling` and `Truncate`,
- the remainder of negative numbers,
- limits with a small `clamp` function,
- one rounding rule for money.

## Exercises

1. Write `roundToStep(value, step)` that rounds to the nearest `0.05` (the smallest coin) and test it with `1.02` and `1.03`.
2. Write `mod(n, m)` that is never negative and use it for the days of a week.
3. Add the prices `19.99`, `5.49` and `0.5` rounded to cents with both modes.
4. Print `Log2` of the powers of two from 1 to 1024 in a table.

## Next

[Big numbers](tut-90-big-numbers.html)
