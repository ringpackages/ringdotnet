---
title: "Testing your programs"
lead: Tests tell you in seconds whether a change broke something. This lesson shows how to write small testable functions, check them with dnAssert, test that errors are raised, and make a window test itself.
---

## What you will learn

- why and when to test,
- writing code that is easy to test,
- `dnAssert` and `dnTestSummary`,
- testing for errors,
- self-testing programs for windows.

## Why test?

A test is a small program that checks that another piece of code gives the right answers. You run all the tests after every change: if one fails, you know *what* broke and *when*. The tests of this package (`samples/UsingDotNet/tests/run.sh`) are what makes it possible to change the generator and regenerate 4,500 classes with confidence.

## Make code testable

| Do | Because |
|---|---|
| small functions with one job | each can be tested alone |
| **return** results instead of printing or showing them | a test can check a returned value |
| pass data **in** as parameters instead of reading globals | a test can try many inputs |
| keep window code thin: the logic is in functions | logic is easy to test, windows are not |

## The program

{{file:samples/UsingDotNet/tutorials/ch13_testing.ring}}

{{output:samples/UsingDotNet/tutorials/ch13_testing.ring}}

### When a test fails

The program has a switch that breaks one test on purpose:

```bash
ring ch13_testing.ring --break
```

{{output:samples/UsingDotNet/tutorials/ch13_testing.ring --break}}

A failure prints the name of the test, what was **expected** and what was **got**. `dnTestSummary()` prints the totals and returns the number of failures (use it to set an exit code in a script).

## How it works

### dnAssert

`dnAssert("name", actual, expected)` compares two values. Texts are compared as text, numbers as numbers (with a small tolerance for decimals). A good name says *what should be true*: "30 is FizzBuzz", "spaces only", "a week".

### What to test

| Kind | Example in the program |
|---|---|
| normal cases | `fizzBuzz(3)` is `Fizz` |
| the edges | an empty text, spaces only, the same day |
| surprising input | many spaces between words |
| errors | a text that is not a number |

### Testing an error

You cannot assert an error directly, so catch it, remember that it happened, and assert on the flag and the message:

```ring
lRaised = False
try
	toNumber("abc")
catch
	lRaised = True
	dnAssert("the message says why",cCatchError,"Not a number: abc")
done
dnAssert("an error was raised",lRaised,True)
```

### Windows that test themselves

A window program can run its own test: put `func selfTest` in a file with the name of the program in a `selftest` folder next to it. When the program is started with `--selftest`, `uiRun` loads that file, the window opens, `selfTest()` runs (which clicks buttons with `PerformClick()` and checks the labels), closes, and prints `SELFTEST OK`. The tutorials [Your first window](tut-11-first-window.html), [Drawing and animation](tut-14-animation.html), [Layout and richer controls](tut-23-layout.html) and [A project: a to-do list that remembers](tut-24-todo.html) all have such a file. `uiSendKeys(oForm,"12{+}30{ENTER}")` types into the form through the real key processing. See [Testing](testing.html) for the details and the `samples/UsingDotNet/tests/run.sh` script that runs everything.

### Run them all

A single script that runs every test and reports a total is what turns tests from a chore into a habit:

```bash
sh samples/UsingDotNet/tests/run.sh ring.exe      # 0 failed
```

## What you learned

- small, returning functions are testable,
- `dnAssert` + `dnTestSummary`,
- test the normal case, the edges, and the errors,
- windows can test themselves,
- run all tests after every change.

## Exercises

1. Write `isLeapYear(nYear)` and test years 1900, 2000, 2023 and 2024.
2. Write a function that formats a number of seconds as `h:mm:ss` and test five values, including 0 and 3600.
3. Add a test for a function that you wrote in an earlier tutorial.
4. Break a function on purpose and see which tests fail.

## Next

[Giving your program to others](tut-119-distribution.html)
