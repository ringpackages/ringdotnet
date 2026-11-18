---
title: "Tutorial 67: Number systems and big numbers"
lead: Binary, octal and hexadecimal, bits and shifts, and numbers too large for a normal Ring number. This lesson shows how to convert between bases, why hexadecimal is everywhere, and where a number stops being exact.
---

## What you will learn

- writing a number in base 2, 8, 10 and 16 and reading it back,
- why programmers like hexadecimal (colors, bytes),
- counting bits and shifting,
- how negative numbers look in binary,
- the limit of a Ring number (a `double`) and how `BigInteger` removes it.

## Bases

The number *two hundred fifty-five* can be written in any **base**:

| Base | Name | Digits | 255 is |
|---|---|---|---|
| 2 | binary | 0 1 | `11111111` |
| 8 | octal | 0–7 | `377` |
| 10 | decimal | 0–9 | `255` |
| 16 | hexadecimal | 0–9 a–f | `ff` |

Computers store bits, so base 2 is what they use; but it is long to read. **One hexadecimal digit is exactly 4 bits**, so a byte is exactly two hex digits (`00` to `ff`). That is why colors (`#ff8000`), memory addresses, hashes and byte dumps ([tutorial 45](tut-45-binary.html)) are written in hex.

## The program

{{file:docs/tutorials/t67_bases.ring}}

{{output:docs/tutorials/t67_bases.ring}}

## How it works

### Converting

`Convert.ToString(number, base)` writes a number in a base and `Convert.ToInt32(text, base)` reads it. In Ring the two-argument forms are called `ToString_2` and `ToInt32_2`. A color is three numbers: `hex2` writes each as two hex digits, with a leading zero when needed, and the reverse takes each pair of digits.

### Bits

`BitOperations.PopCount(n)` counts the one-bits (255 has 8, 256 has 1) and `IsPow2(n)` tests for a power of two — a number that is a power of two has exactly one bit set. In Ring, `1 << 10` shifts the bits left (multiplies by 2 ten times: 1024) and `1024 >> 3` shifts right (divides by 8). The operators `&`, `|` and `~` are explained in [tutorial 65](tut-65-enums.html).

A negative number such as −5 is stored in **two's complement**: write 5 (`000…0101`), turn all the bits over (`111…1010`) and add 1 (`111…1011`). The output of step 5 is exactly that, 32 bits long.

### Where Ring numbers stop

A Ring number is a 64-bit `double`. It has 53 bits for the digits, so it is exact only up to **2⁵³ = 9,007,199,254,740,992**. Above that, `+ 1` can be lost (step 6), and `Int64.MaxValue` (9,223,372,036,854,775,807) is shown rounded. For a bank balance, an id or a hash that is bigger than that, use text or `BigInteger`.

### BigInteger

`System.Numerics.BigInteger` has **no size limit** and is always exact. Create it from text (`Parse`) and call its methods (`Multiply`, `Add`, `Pow`...); `ToString()` returns the digits. Step 7 squares a 30-digit number; step 8 computes 30! (265252859812191058636308480000000, 33 digits), which a `double` could only approximate.

> [!NOTE] Pass big numbers around as **text**. If a value crosses the bridge as a Ring number it becomes a `double` and loses its exactness.

## What you learned

- `Convert.ToString` and `ToInt32` with a base,
- hex, bytes and colors,
- `PopCount`, `IsPow2`, `<<`, `>>`,
- two's complement,
- the 2⁵³ limit and `BigInteger`.

## Exercises

1. Write `toBinary(n)` yourself with division by 2 and compare with `Convert`.
2. Compute 100! and count its digits.
3. Parse a color like `#1e90ff` into three numbers and back.
4. Find the largest power of two below 10 million with `PopCount` or `IsPow2`.

## Next

[Tutorial 68: Time zones](tut-68-timezones.html)
