---
title: "Tutorial 57: Money"
lead: Why 0.1 + 0.2 is not 0.3, why money is kept as whole cents, how rounding rules differ, and how to split 100.00 into three shares without losing a cent.
---

## What you will learn

- why fractions are inexact in every computer language,
- the cents rule: whole numbers inside, decimals only for display,
- rounding rules: banker's rounding and school rounding,
- splitting an amount fairly,
- taxes on the total, not on each line.

## The problem

Computers store numbers in binary. Just as 1/3 cannot be written exactly in decimal (0.3333…), 0.1 cannot be written exactly in binary, so `0.1 + 0.2` is `0.30000000000000004` and **is not equal** to `0.3`. Ten additions of 0.1 do not give exactly 1. For physics this is fine; for money it is not: a shop must never be one cent off.

## The program

{{file:docs/tutorials/t58_money.ring}}

{{output:docs/tutorials/t58_money.ring}}

## How it works

### Cents as integers

Convert to **whole cents** when the amount comes in (`toCents("19.99")` → `1999`), calculate with integers (they are exact), and turn them back to text only for display (`showMoney`). Three items of 19.99 are `5997` cents: no error is possible.

> [!NOTE] The .NET `Decimal` type is exact, but a `decimal` that crosses the bridge becomes a Ring number (a binary fraction again). In Ring, whole cents are the safe way. A database keeps money in integer columns for the same reason.

### Rounding

Percentages create parts of cents (7.5 % of 1999 is 149.925). You need a rule, and the rule must be written down:

- **banker's rounding** (`ToEven`, the default of `Math.Round`): half cases go to the even neighbour, `0.5 → 0`, `1.5 → 2`, `2.5 → 2`. Over many numbers it does not favour up or down.
- **school rounding** (`AwayFromZero`): halves go up, `2.5 → 3`. This is what most invoices and tax rules expect.

`Math.Round` takes the mode by name: `oMath.Round([ :value = 2.5, :mode = "AwayFromZero" ])`.

### Splitting fairly

100.00 divided by three is 33.333… `splitCents` gives each share `floor(10000 / 3)` = 3333 cents and hands the remaining cent to the first shares: 33.34, 33.33, 33.33. The sum is exactly 100.00. Never round every share separately — the shares might add up to 99.99 or 100.01.

### Taxes

The invoice calculates the tax **once on the subtotal**. Rounding the tax of each line separately gives a different total, and tax laws usually say which way is right. Always check the rules of your country.

## What you learned

- binary fractions are inexact,
- whole cents for calculation, text for display,
- rounding modes,
- fair splitting,
- tax on the total.

## Exercises

1. Add a discount of 15 % to the invoice and decide when to round.
2. Write `showMoneyIn(nCents, cCulture)` using `CultureInfo` ([tutorial 33](tut-33-cultures.html)).
3. Split 10.00 between 7 people and check the sum.

## Next

[Tutorial 58: Undo and redo](tut-58-undo.html)
