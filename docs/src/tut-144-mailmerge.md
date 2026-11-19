---
title: "A project: mail merge"
lead: A mail merge makes many letters from one template and a table of data. This project finds the {fields} of a template with a regular expression, replaces each one through a callback that .NET calls, formats numbers and dates, and reports missing data before any letter is made.
---

## What you will learn

- a template with `{name}` and `{name:format}` **fields**,
- reading CSV text into rows, and keeping **empty** values,
- `Regex.Replace` with a **callback** (a function that .NET calls for each match),
- groups of a match: the name and the format,
- reusing the formats of the tutorial [Formatting numbers and dates](tut-129-formatting.html),
- finding **missing data** before sending.

The same pattern makes e-mails, invoices and reports: a template, data, and a function that fills the holes.

## The program

{{file:docs/tutorials/t144_mailmerge.ring}}

{{output:docs/tutorials/t144_mailmerge.ring}}

## How it works

### The template and the data

The template is a text with fields in braces. A field is `{name}` or `{name:format}`: the part after the colon is a format string for a number (`N2` gives `1,234.50`) or a date (`d MMMM yyyy` gives `9 March 2030`). The data is a CSV text: the first line has the names of the columns and each other line is one letter. `readCsv` makes a list of rows, and each row is a list of `[name, value]` pairs that is read with the name of the column: `aRow["city"]`. `splitKeep` splits a line at the commas and **keeps the empty values**, so Cy's empty city is an empty value and not a missing one.

### The pattern

`\{(\w+)(?::([^}]+))?\}` means: an opening brace, then group 1 (one or more letters, digits or underscores: the name), then an optional part (a colon and group 2, which is everything up to the closing brace: the format), and the closing brace. The tutorial [Regular expressions in depth](tut-29-regex.html) explains groups. The first step uses the same pattern with `Regex.Matches` to list the fields of the template.

### The callback

`Regex.Replace(template, pattern, dnCallback("replaceField"))` calls the Ring function once for each match. A callback that is the **name** of a function gets the .NET arguments as a list: `aArgs[1]` is the `Match`, and `Groups.Item(1).Value` and `Groups.Item(2).Value` are the name and the format. The function **returns** the text that replaces the field. It looks in `aFields`, the row that is being merged: a global, because the callback has no other way to receive it. The callback runs while `Regex.Replace` is running, on the Ring thread, which is the case that callbacks support (the tutorial [Callbacks and events](tut-19-callbacks.html)).

### Formats

`formatValue` turns the value into a date when it has the form `2030-03-09`, and into a number otherwise, and writes it with `String.Format` and the invariant culture. The same template gives the same letters on every computer. A field without a format is replaced by the value as it is.

### Missing data

A letter with a hole in it must not be sent. When a field has no column, or the value is empty, the callback adds the name to `aMissing` and puts a visible mark (`[shop?]`) in the letter. Step 4 runs every row first, only to collect the problems: Cy has no city and every row lacks the column `shop`, which only the template knows. Step 5 repairs the data and shows that there are no problems left, and then the letters can be written.

> [!NOTE] The callback must not raise an error: an error inside it stops the whole `Replace`. It returns a mark for a missing field instead, and the program decides afterwards what to do with the problems.

## What you learned

- fields with formats in a template,
- reading CSV with empty values,
- `Regex.Replace` with a Ring callback,
- groups of a match,
- checking the data before the letters are made.

## Exercises

1. Write each letter into a file named after the person (`File.WriteAllText`).
2. Add the field `{amount:C}` and look at the result with a culture of your own.
3. Read the data from a real CSV file, with a column of text that has a comma inside quotes (the tutorial [Tabular data](tut-30-tables.html)).
4. Count how many times each field was used in all the letters.

## Next

[Unicode and encodings](tut-52-unicode.html)
