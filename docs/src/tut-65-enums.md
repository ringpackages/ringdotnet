---
title: "Tutorial 65: Enums and flags"
lead: Many .NET methods take or return a choice from a fixed list — a day of the week, a file attribute, a mode. This lesson shows how enums look in Ring, how to check and parse them, how flags combine, and how to make your own bit flags.
---

## What you will learn

- what an **enum** is and how it looks in Ring (a text),
- listing the names, testing a name, parsing a text,
- **flags**: several choices at once (`ReadOnly, Hidden`),
- your own flags with the bit operators `&`, `|` and `~`.

## Enums

An **enum** is a type with a fixed set of named values: `DayOfWeek` (`Sunday` … `Saturday`), `FileAttributes`, `StringComparison`, `Environment.SpecialFolder`. In C# you write `DayOfWeek.Friday`; behind the name there is a number. In Ring an enum value is simply **the text of its name**: you read `oDate.DayOfWeek` and get `"Friday"`, and when a method wants an enum you pass `"Friday"`. You never need the numbers.

## The program

{{file:docs/tutorials/t65_enums.ring}}

{{output:docs/tutorials/t65_enums.ring}}

## How it works

### Comparing

Step 1 compares the value with a text: `oDate.DayOfWeek = "Friday"`. It reads like English and cannot be confused with another number.

### Names, `IsDefined` and `Parse`

`Enum.GetNames(type)` lists all the names ([tutorial 20](tut-20-reflection.html) explains `dnType`). `IsDefined` asks whether a text is a valid name; use `IsDefined([ :enumType = type, :value = text ])` (the two-argument form). `Enum.Parse` checks and converts: a wrong name raises an error that says *Requested value 'Funday' was not found*. When the text comes from a user or a file, either test it first or `try` / `catch` ([tutorial 7](tut-07-errors.html)).

### Flags

Some enums are **flags**: the values can be combined. A file can be `ReadOnly` *and* `Hidden`. In Ring the combination is a text with the names separated by commas: `"ReadOnly, Hidden"`. `File.SetAttributes(path, "ReadOnly, Hidden")` sets both, and `File.GetAttributes(path)` returns the same kind of text. To test one flag, look for its name in the text (`substr(text, "Hidden") > 0`).

> [!NOTE] Take care with names that contain other names. `"Directory"` is not part of `"ReadOnly, Hidden"`, but `"Read"` is part of `"ReadOnly"`. Search for whole names (surround the text with commas and spaces, or split it on commas) when this can happen.

### Your own flags with bits

In your own code you can do the same with numbers. Give each option its own **bit**: `1`, `2`, `4`, `8`, … (powers of two). Then any combination is one number:

| Operation | Ring | Meaning |
|---|---|---|
| combine / add | `a \| b` | the options of both |
| test | `(value & C_READ) != 0` | is the bit set? |
| remove | `value & ~C_WRITE` | clear the bit |

Read and write are `1 | 2 = 3`; adding run (`4`) gives `7`; removing write leaves `5`. Parentheses are needed around `&` in a comparison. The same technique stores many yes/no settings in one number, or in one database column.

## What you learned

- enum values are texts in Ring,
- `GetNames`, `IsDefined`, `Parse`,
- flag enums are comma-separated texts,
- bit flags with `|`, `&` and `~`.

## Exercises

1. Print all the names of `FileAttributes`, then read the attributes of a folder with `File.GetAttributes` and decide whether it is a directory.
2. Add a `C_DELETE = 8` option and a function `parse("read,write")` that turns a text into the number.
3. Use `StringComparison` (`"OrdinalIgnoreCase"`) with `String.Equals` to compare two texts without regard to case.

## Next

[Tutorial 66: A spell checker](tut-66-spelling.html)
