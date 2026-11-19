---
title: "Tutorial 101: Number types"
lead: A Ring number is always a double, but .NET has many number types with different sizes and limits. This lesson shows the limits of Byte, Int16, Int32, Int64 and Int128, what happens when a number does not fit, how to read a typed number safely, and why 0.1 + 0.2 is not 0.3.
---

## What you will learn

- the **integer types** and their limits,
- `MinValue` and `MaxValue`,
- checked conversion with `Convert` (an error, not a wrong number),
- `TryParse` for text that a user typed,
- integer division and the remainder (`Math.DivRem`),
- `Int128` and `UInt128`,
- `Single` and `Double`, and comparing numbers with decimals.

[Tutorial 3](tut-03-numbers-dates.html) used numbers and dates, [tutorial 57](tut-57-money.html) used `Decimal` for money and [tutorial 90](tut-90-big-numbers.html) used `BigInteger`. This lesson is about the **fixed-size** types that .NET methods ask for.

## The program

{{file:docs/tutorials/t101_number_types.ring}}

{{output:docs/tutorials/t101_number_types.ring}}

## How it works

### Many types, one Ring number

In Ring there is one number type, a double (exact for whole numbers up to 9007199254740992). .NET has `Byte` (0 to 255), `Int16` (about plus or minus 32 thousand), `Int32` (about plus or minus 2 thousand million), `Int64`, `Int128` and others, signed and unsigned, and `Single`, `Double` and `Decimal` for fractions. When Ring calls a method, the bridge converts the Ring number into the type the method asks for. A number that **does not fit** raises an error instead of wrapping around, so a wrong value is found at the call.

`Byte.MaxValue` and the other limits are static fields (read through any object of the class: `new Byte().MaxValue`). The limit of `Int64` is 9223372036854775807, but as a Ring number it cannot be shown exactly, so it prints rounded (step 1). For exact big values use a text: `Int64.Parse("9223372036854775807")`, and `Int128`/`BigInteger` ([tutorial 90](tut-90-big-numbers.html)).

### Checked conversion

`Convert.ToByte(200)` is 200; `Convert.ToByte(300)` and `Convert.ToByte(-1)` raise an error (*Value was either too large or too small for an unsigned byte*), which the program catches with `try`. The `Convert` methods are the **checked** way to narrow a number: they never give you a silently wrong value. (In C# the operator `(byte)300` does give a wrong value, 44, unless the code is marked `checked`; the bridge always checks.)

### TryParse

For text that a user typed, `Int32.TryParse(text)` answers `[ success, number ]` ([tutorial 81](tut-81-network-tools.html) explains the out value). `"42"` and `"-7"` work, spaces around the number are allowed, and `"3000000000"` (too big for an Int32), `"12abc"` and `""` answer *no*. Always use `TryParse` for input: it is a yes or no, not an error.

### Division

`Math.DivRem(a, b)` gives `[ quotient, remainder ]` of whole numbers. The quotient is rounded **toward zero**: `-17` divided by `5` is `-3` with remainder `-2`, and the remainder has the sign of the first number. (Ring's own `%` and `/` work on doubles; use `DivRem` when the type must stay an integer.)

### Int128

`Int128` and `UInt128` hold numbers up to 39 digits. They are made from text (`Parse`) and shown with `ToString()`, because a Ring number cannot hold them.

### Single and Double

A `Single` (float) has about 7 decimal digits and a `Double` about 15. `16777216` is 2 to the power of 24: after it, a `Single` can not add 1 (the answer stays 16777216) while a `Double` can. Fractions like 0.1 are **not exact** in binary, so `0.1 + 0.2` is `0.30000000000000004` and is *not equal* to `0.3`. Never compare fractions with `=`: test that the **difference is small** (`fabs(a - b) < 0.0000001`), or use `Decimal` for money.

> [!NOTE] Ring prints a number that has decimals with two digits (`0.30`). The value inside is the full double; print with `string(n)` or round when you need the form.

## What you learned

- one Ring number, many .NET types,
- limits with `MinValue` and `MaxValue`,
- `Convert.ToByte` and the others raise an error when the number does not fit,
- `TryParse` for user input,
- `DivRem`, `Int128`, `Single` against `Double`,
- compare fractions with a small difference.

## Exercises

1. Write `readPort(cText)` that returns a port number (1 to 65535) or -1, with `UInt16.TryParse`.
2. Find the first number that a `Single` can not increase by 1 (16777216) with a loop of `Convert.ToSingle`.
3. Print the limits of `SByte`, `UInt16`, `UInt32` and `UInt64`.
4. Add the amounts 0.1 ten times in a loop and compare the sum with 1 in both ways.

## Next

[Tutorial 102: IP networks](tut-102-ip-networks.html)
