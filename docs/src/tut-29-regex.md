---
title: "Regular expressions in depth"
lead: A regular expression is a tiny language for describing text. This lesson builds the vocabulary step by step — characters, classes, quantifiers, anchors, groups, replacing, splitting and validating.
---

## What you will learn

- the building blocks of a pattern,
- finding, replacing and splitting,
- groups and named groups,
- greedy and lazy matching,
- validating input,
- escaping text that is not a pattern.

## Why learn them

Whenever a job says "find the part of the text that looks like...", a regular expression does it in one line: phone numbers, dates, e-mails, log lines, codes. The same patterns work in every language, so what you learn here is useful everywhere.

## The program

{{file:docs/tutorials/t29_regex.ring}}

{{output:docs/tutorials/t29_regex.ring}}

## The building blocks

| Pattern | Matches | Example |
|---|---|---|
| `abc` | exactly those letters | `Bob` |
| `.` | any one character | `b.b` finds `bob`, `bab` |
| `\d` `\w` `\s` | a digit, a letter/digit/underscore, a space | `\d+` finds `555` |
| `[abc]` `[a-z]` `[^0-9]` | one of these, a range, not these | `[A-Z]` |
| `+` `*` `?` | one or more, zero or more, zero or one | `\d+` |
| `{3}` `{2,4}` | exactly three, two to four | `\d{3}-\d{4}` |
| `^` `$` | the start, the end of the text | `^Ann` |
| `\b` | the edge of a word | `\bcat\b` |
| `a\|b` | a or b | `Ann\|Cy` |
| `( )` | a group | `(ab)+` |
| `(?<name> )` | a named group | `(?<year>\d{4})` |

## How the program uses them

- `IsMatch` answers yes or no (step 1).
- `Match(text).Value` is the first match, `Matches(text)` finds all of them: use `Count` and `Item(i)` (steps 2, 3).
- **Groups** pick parts of a match: `Groups.Item("year").Value`. The pattern `(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})` gives the three numbers of a date (step 5).
- **Alternation** `Ann|Cy` finds either name (step 6).
- **Replace** can use the groups in the replacement text (`$1`, `$2`, `$3`): turning `2024-05-17` into `17/05/2024` is one call (step 7).
- **Split** cuts a text at every match of the pattern: `,\s*` is "a comma and any spaces" (step 8).

### Greedy or lazy

`<.*>` takes as much as possible: from the first `<` to the *last* `>`, the whole `<b>bold</b> and <i>italic</i>`. Adding `?` (`<.*?>`) makes it take as little as possible: just `<b>`. When a pattern matches too much, try the lazy form.

### Options

Options change how a pattern behaves. They are enums, so in Ring they are texts: `dnNew("Regex",[ :pattern = "BOB", :options = "IgnoreCase" ])`. Others: `Multiline`, `Singleline`, `Compiled` (faster for patterns used many times).

### Validation

To check that the **whole** text has a shape, anchor the pattern: `^([01]\d|2[0-3]):[0-5]\d$` accepts `18:30` and `23:59` but not `7:5` or `24:00`. Without `^` and `$`, `IsMatch` only asks whether the pattern occurs *somewhere* in the text.

### Escaping

Characters such as `.` `*` `+` `?` `(` `[` `\` have a meaning in a pattern. If you want to search for a text that a user typed, escape it first: `Regex.Escape("a.b*c")` gives `a\.b\*c`, which matches exactly `a.b*c`.

## Good habits

- Build a pattern in small steps and test each step.
- Put a pattern with comments in a variable with a clear name.
- Prefer a simple pattern plus some code over one unreadable pattern.
- Never use a regex to parse a language with nesting (HTML, JSON): use a parser (the tutorial [JSON and XML](tut-06-json-xml.html)).

## What you learned

- classes, quantifiers, anchors, groups, alternation,
- `IsMatch`, `Match`, `Matches`, `Replace`, `Split`,
- greedy vs lazy,
- anchored patterns for validation, `Escape` for user text.

## Exercises

1. Write a pattern for a Ring variable name that starts with `n` or `c` followed by a capital letter (`nCount`, `cName`) and find them all in a source file.
2. Validate a simple e-mail address and test it with five good and five bad examples.
3. Replace every run of spaces and tabs in a text by a single space.
4. Extract all `#hashtags` from a sentence.

## Next

[Formatting numbers and dates](tut-129-formatting.html)
