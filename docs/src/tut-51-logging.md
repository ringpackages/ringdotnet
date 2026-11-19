---
title: "Logging"
lead: Programs that run without a person watching need a diary. This lesson writes a logger class with levels, timestamps, a file and rotation.
---

## What you will learn

- what to log and at which level,
- appending lines to a file,
- the minimum level (development versus production),
- logging an error you caught,
- rotation: a log must not grow forever.

## The program

{{file:samples/UsingDotNet/tutorials/ch06_logging.ring}}

{{output:samples/UsingDotNet/tutorials/ch06_logging.ring}}

## How it works

A line has a time, a **level** and a message. The level says how important it is: `DEBUG` (details for the developer), `INFO` (normal events), `WARN` (something is wrong but the program goes on), `ERROR` (an operation failed). The logger has a **minimum level**: lines below it are not written, so step 1 skips the debug line, and step 2 shows everything and then only errors.

`File.AppendAllText` adds a line at the end of the file. The clock can be fixed with `setClock` so that the output of the tutorial is the same every run; a real logger leaves it empty and uses the real time.

Step 3 shows the main reason for logs: `try` / `catch` writes the error text and the program continues.

**Rotation** (step 4): before each line the logger checks the size (`FileInfo.Length`). When it is over the limit, `small.log` is renamed to `small.log.1` (an older `.1` is deleted first) and a new file starts. The disk never fills with one endless file.

> [!WARNING] Never write passwords, tokens or personal data in a log. Logs are copied around, and nobody protects them like a database.

## What you learned

- levels and a minimum level,
- `AppendAllText`,
- logging caught errors,
- rotation with `FileInfo` and `File.Move`.

## Exercises

1. Keep three old files (`.1`, `.2`, `.3`).
2. Add a `fatal` level and a `--verbose` option like in the tutorial [A command-line tool](tut-50-cli.html).
3. Write a log line for each request of the web server in the tutorial [A small web site](tut-26-website.html).

## Next

[Tracing](tut-136-tracing.html)
