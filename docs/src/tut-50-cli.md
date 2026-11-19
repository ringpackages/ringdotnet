---
title: "A command-line tool"
lead: A real command-line program has arguments, options with values, a usage text, clear error messages and an exit code that other programs can check.
---

## What you will learn

- reading the arguments of a program (`sysargv`),
- options with and without values (`--top 5`, `--help`),
- printing a usage text and clear error messages,
- exit codes: `0` success, non-zero a problem,
- keeping the logic in a function that is easy to test.

## The program

{{file:samples/UsingDotNet/tutorials/ch06_cli.ring}}

{{output:samples/UsingDotNet/tutorials/ch06_cli.ring}}

## How it works

`sysargv` holds `[ring, program, arg1, arg2, ...]`, so your arguments start at item 3. `run(aArguments)` does everything and **returns an exit code** instead of stopping the program: the demonstration calls it with several lists of arguments, a real use passes the real ones. This is the trick that makes a command-line tool easy to test.

`parseArguments` walks the list. A word that starts with `--` is an option; `--top` and `--min` take the next word as their value, and it is checked with a regular expression (`^[0-9]+$`). Any other word is the file. A mistake prints one clear line (`error: --top needs a number`) and returns `false`.

The exit codes follow a habit: `0` fine, `1` the *command line* is wrong, `2` something outside is wrong (the file is missing). Scripts and batch files test them.

> [!TIP] Always show the usage text for `--help`, and after a wrong command line. It is the documentation people read first.

## What you learned

- arguments, options and values,
- usage text and error lines,
- exit codes,
- a `run` function that is easy to test.

## Exercises

1. Add `--ignore-case false` to count `The` and `the` separately.
2. Add `--sort alpha` to sort by word instead of by count.
3. Read the text from the keyboard when no file is given.

## Next

[Logging](tut-51-logging.html)
