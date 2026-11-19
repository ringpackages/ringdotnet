---
title: "Statistics and simulation"
lead: Mean, median, mode, standard deviation, a histogram, prime numbers and an estimate of pi from random points — small formulas written as small functions, and checked against .NET.
---

## What you will learn

- the common statistics and how to compute them,
- writing each formula as a function,
- cross-checking with LINQ,
- the sieve of Eratosthenes,
- a *Monte Carlo* simulation with a seeded `Random`.

## The program

{{file:samples/UsingDotNet/tutorials/ch03_statistics.ring}}

{{output:samples/UsingDotNet/tutorials/ch03_statistics.ring}}

## The statistics

| Name | Meaning | Function |
|---|---|---|
| **Mean** | the average: sum ÷ count | `mean` |
| **Median** | the middle value of the sorted list (the average of the two middle ones when the count is even) | `median` |
| **Mode** | the value that occurs most often | `mode` |
| **Standard deviation** | how far values are from the mean, typically: the square root of the average squared distance | `stdDev` |

For the data `4 8 15 16 23 42 8 15 8 4` (sorted: `4 4 8 8 8 15 15 16 23 42`):

- the **mean** is `14.3`;
- the **median**: there are ten values, so the middle is the pair at positions 5 and 6, which are `8` and `15`: `(8 + 15) / 2 = 11.5`;
- the **mode** is `8` (it occurs three times);
- the **standard deviation** is about `10.85`: the values are spread out.

The mean is pulled up by the single large value `42`; the median is not. That is why reports often use the **median** for incomes and house prices.

## How it works

### One function per formula

Each statistic is a small function with one job that takes a list and returns a number. You can test each alone (see the tutorial [Testing your programs](tut-28-testing.html)), reuse them, and the main program reads like a description of the results. The program also asks LINQ for the average (`dnQuery(aData).Average("")`) and gets the same `14.3`: when two independent ways agree, you can trust the code.

### The histogram

A histogram counts how often each value occurs and shows it as a bar of `#` characters. The program collects the distinct values (`find` prevents duplicates), sorts them, and for each prints the value and a bar as long as the count.

### The sieve of Eratosthenes

To find all primes up to 100: write down every number from 2; take the first unmarked number (2), mark all its multiples (4, 6, 8...) as not prime; take the next unmarked number (3), mark its multiples; continue up to √100. What stays unmarked is prime. The code keeps a list of 100 flags and marks multiples with `for nMultiple = nNumber * nNumber to nLimit step nNumber`. There are 25 primes up to 100, the last is 97.

### gcd and lcm

Euclid's algorithm: the greatest common divisor of two numbers is the same as that of the smaller one and the remainder of their division. Repeat until the remainder is 0. The least common multiple follows: `a × b ÷ gcd`.

### A simulation

Throw random points into the unit square. The quarter circle of radius 1 has an area of π/4 and the square has an area of 1, so the share of points that fall inside the circle (`x² + y² ≤ 1`) is about π/4. With 20000 points the estimate is close to `3.14`. `new Random(2024)` uses a **seed**: the same seed gives the same random numbers every time, which makes a simulation repeatable (leave the seed out for different numbers every run). More points give a better estimate, slowly: ten times more points give about three times more accuracy.

> [!NOTE] Ring prints a number with two decimals (`3.16`); the value itself is more precise. `decimals(6)` at the start of a program shows more.

## What you learned

- mean, median, mode, standard deviation,
- histograms from counts,
- the sieve, gcd, lcm,
- simulation with a seeded `Random`,
- verify a result with a second method.

## Exercises

1. Compute the 90th percentile of a list.
2. Simulate 1000 throws of two dice and print the histogram of the sums.
3. Find all perfect numbers below 10000 (a number that equals the sum of its divisors).
4. Estimate the probability that two random people in a group of 23 share a birthday (the birthday paradox) with 10000 simulated groups.

## Next

[Dates and times](tut-103-dates-and-times.html)
