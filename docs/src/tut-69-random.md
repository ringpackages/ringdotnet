---
title: "Randomness"
lead: Dice, cards, loot tables and unique ids all need random numbers — but not the same kind. This lesson uses a seeded generator, shuffles a deck correctly, draws with weights, makes unique ids, and shows when ordinary random numbers are not safe.
---

## What you will learn

- the `Random` class and the **seed**,
- throwing dice and checking that they are fair,
- shuffling with the Fisher–Yates algorithm,
- weighted choices,
- `Guid` for unique ids,
- secure randomness for passwords and tokens.

## The program

{{file:samples/UsingDotNet/tutorials/ch03_random.ring}}

{{output:samples/UsingDotNet/tutorials/ch03_random.ring}}

## How it works

### Random numbers are calculated

`Random` does not roll dice: it follows a formula that gives numbers that *look* random. The starting value is the **seed**. The same seed gives the same numbers (step 1), which is exactly what you want for a test or a replay: a game level that is the same for the same seed, a simulation you can repeat. Without a seed, `new Random(NULL)` starts from the clock. `Next_(100)` gives 0…99 (`Next` is a Ring keyword, so the method is called `Next_`).

### Dice

`Next_(6) + 1` is 1…6. With 6,000 throws every side comes up about 1,000 times; the test in the program accepts 900–1100. *About* is the important word: with a random generator you test that the result is **in a range**, not that it is a fixed number — unless you fix the seed.

### Shuffling

A wrong shuffle is a classic bug. **Fisher–Yates** is right: go from the last card to the second; swap the card with a random card from the first position up to *itself*. Every order is equally likely. Swapping each card with *any* random card (`Next_(10)` every time) looks similar but gives some orders more often than others.

### Weighted choice

To draw "common" 70 %, "rare" 25 % and "legendary" 5 % of the time, pick a number from 0 to 99 and walk through the weights adding them up until the number is below the sum. The output shows about 6,950 / 2,580 / 470 for 10,000 draws.

### Guid

A `Guid` has 128 random bits, written as 36 characters. Two Guids are equal with a probability so small that nobody ever sees it, so you can create ids without asking a database or another computer. Use them as keys for records created on different machines.

### When it must be secure

Because `Random` is a formula, a person who sees a few of its numbers can calculate the next ones. For **passwords, tokens, keys and anything that guards a secret** use `RandomNumberGenerator` (the tutorial [Hashing and encryption](tut-08-security.html) and the tutorial [Login, sessions and cookies](tut-49-login.html) use it). Rule of thumb: games and simulations → `Random`; security → `RandomNumberGenerator`.

## What you learned

- seeds and repeatable randomness,
- ranges and testing random code,
- Fisher–Yates shuffling,
- weighted choice,
- `Guid`,
- `Random` against `RandomNumberGenerator`.

## Exercises

1. Throw two dice 36,000 times and print how often each sum (2…12) appears.
2. Write a password generator with `RandomNumberGenerator.GetInt32` and a list of allowed characters.
3. Shuffle a deck of 52 cards (numbers 1–52) and deal four hands of five.
4. Estimate the probability of at least one six in four throws by simulation, then calculate it exactly.

## Next

[Statistics and simulation](tut-44-statistics.html)
