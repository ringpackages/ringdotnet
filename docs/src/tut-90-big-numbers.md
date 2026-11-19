---
title: "Big numbers"
lead: A Ring number is a double, so whole numbers are exact only up to about nine quadrillion. BigInteger keeps every digit of a whole number of any size, and Complex works with numbers that have an imaginary part.
---

## What you will learn

- the limit of a Ring number and why it exists,
- `BigInteger`: `Parse`, `Add`, `Multiply`, `Pow`, `Remainder`, `ModPow`, `GreatestCommonDivisor`, `Compare`,
- exact factorials and Fibonacci numbers,
- `Complex`: the real and imaginary parts, `Magnitude`, `Multiply`.

(The tutorial [Money](tut-57-money.html) used `Decimal` for exact decimals; this lesson is about exact *large* whole numbers.)

## The program

{{file:samples/UsingDotNet/tutorials/ch03_big_numbers.ring}}

{{output:samples/UsingDotNet/tutorials/ch03_big_numbers.ring}}

## How it works

### The limit of Ring numbers

A double stores 53 bits of precision. Whole numbers are exact up to 2^53 = 9007199254740992; above that, `+ 1` can be lost, as step 1 shows (it prints the same number).

### BigInteger

A `BigInteger` is a struct from `System.Numerics`. In Ring you create it from a **text** (`Parse("9007199254740992")`), calculate with the **static methods** (`Add`, `Multiply`, `Pow`, ...) and show it with `ToString()`. The operators `+` and `*` of Ring do not work on these objects, so every step is a method call. The first object is a handle to reach the static methods (`new BigInteger()`); `One` and `Zero` are ready-made values. Step 2 adds 1 to 2^53 and keeps the result exact.

### Factorials, powers, Fibonacci

The loops of steps 3 and 5 are the ordinary ones, with `Multiply` and `Add` in place of `*` and `+`. 30! has 33 digits and fib(100) has 21; the results are exact. `Pow(number, exponent)` takes a normal whole exponent. `ModPow(number, exponent, modulus)` computes the remainder of a huge power **without ever building** the huge number; public-key cryptography is built on it (the tutorial [Protecting and signing messages](tut-78-crypto.html)). Step 4 shows that `ModPow` and `Remainder(Pow(...))` give the same answer.

### Comparing

Compare big numbers with `Compare`: it answers -1, 0 or 1. Do not compare their texts: as texts `"9"` is larger than `"10"`.

### Complex numbers

A `Complex` has `Real` and `Imaginary` parts. `i` is `Complex(0, 1)` and `i * i` is -1, which step 7 shows. The constructor has several forms, so it is made with names (`dnNew("Complex",[ :real = 0, :imaginary = 1 ])`). `Magnitude` is the distance from zero: 5 for 3 + 4i. `Multiply`, `Add`, `Divide`, `Sqrt`, `Exp`, `Pow` and the trigonometric functions are static methods. Functions such as `Pow` work with doubles inside and may give results like -6.999999999999998; use `Multiply` when you need exact whole values.

## What you learned

- Ring numbers are exact up to 2^53,
- `BigInteger` is created from a text and used through static methods,
- `Pow`, `ModPow`, `GreatestCommonDivisor`, `Compare`,
- `Complex` with `Real`, `Imaginary` and `Magnitude`.

## Exercises

1. Print 100! and count its digits.
2. Find the first Fibonacci number with 100 digits.
3. Write `isEven(oBig)` with `Remainder`, and test it with 2^100 and 2^100 + 1.
4. Multiply two complex numbers by hand and check the result with `Multiply`.

## Next

[Number systems and big numbers](tut-67-bases.html)
