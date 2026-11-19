---
title: "A project: analyze a log file"
lead: Put several lessons to work in one useful program — read a text file, take each line apart with a regular expression, count with a dictionary, summarise with LINQ and write a JSON report.
---

## What you will learn

- how to plan a small data-processing program,
- combining `File`, `Regex`, `NumberDictionary`, LINQ and JSON,
- writing helper functions for the things you do many times.

## The task

A server writes lines like these to a log file:

```text
2024-05-17 08:15:02 ERROR [db] connection lost
2024-05-17 08:16:10 INFO [web] request done
```

We want to know: how many lines of each level, which parts have errors, which error texts occur, and to save a short report.

## The plan

1. Read the file line by line.
2. Cut each line into *date, time, level, part, text* with a regular expression. Lines that do not match are skipped.
3. Count with a dictionary: lines per level, errors per part.
4. Collect the error texts and ask LINQ for the distinct ones, sorted.
5. Write a JSON report.

The program makes its own sample log first, so that you can run it anywhere.

## The program

{{file:docs/tutorials/t21_log_analyzer.ring}}

{{output:docs/tutorials/t21_log_analyzer.ring}}

## How it works

### The regular expression

```text
^(?<date>\d{4}-\d{2}-\d{2}) (?<time>\d{2}:\d{2}:\d{2}) (?<level>[A-Z]+) \[(?<part>\w+)\] (?<text>.+)$
```

Read it left to right: four digits, a dash, two digits... then a space, a time, a word in capital letters (the level), a word in square brackets (the part), and the rest of the line. `(?<level>...)` is a **named group**: after a match, `oMatch.Groups.Item("level").Value` reads it. `oMatch.Success` says whether the line matched at all; the last line of the sample file does not, so it is skipped (30 of 31 lines were understood).

### Counting with a dictionary

A dictionary maps a key to a number. To count you read the old value (0 if the key is new), add one and write it back. The helper `count(oDictionary, cKey)` hides the `TryGetValue` detail, which returns `[found, value]`.

### LINQ

`dnQuery(aErrors).Distinct().OrderBy(...).ToList()` removes duplicates and sorts: three different errors out of nine.

### The report

A JSON object is simple text: the helper builds `{"lines":30,"errors":9,"different":3}`. For real data, `JsonSerializer` and `webJson` (tutorial 16) do this for you.

### Habits that the program shows

| Habit | Where |
|---|---|
| one function per job (`makeLog`, `count`, `webJsonText`) | the bottom of the file |
| skip bad input instead of crashing | `if not oMatch.Success loop ok` |
| clean up temporary files | `File.Delete` at the end |
| steps numbered in the output | `STEP 1 ... STEP 5` |

## What you learned

- plan: read → parse → count → summarise → write,
- named regex groups make parsing readable,
- dictionaries count,
- small helper functions keep `main` short.

## Exercises

1. Count the errors **per day**: put the date in a dictionary.
2. Print the busiest hour (use the first two characters of the time).
3. Take the file name from the command line (`sysargv[3]`) and report an error if it does not exist.
4. Write the report with `webJson` instead of the helper (with `"RingDotNet.Web"` in the `using` block).

## Next

[A project: find duplicate files](tut-31-duplicates.html)
