---
title: "Working with text"
lead: Ring already has good text functions. This lesson shows when to use Ring's own, and what .NET adds — joining, formatting, building long texts, regular expressions, Base64 and encodings.
---

## What you will learn

- which text jobs Ring does by itself and which need .NET,
- `String` helpers (`Join`, `Format`, `Compare`, `IsNullOrWhiteSpace`),
- `StringBuilder` for long texts,
- regular expressions with `Regex`,
- Base64 and UTF-8.

## Texts between Ring and .NET

A Ring text is a .NET `string` as soon as you pass it to a .NET method. A .NET method that returns a string gives you a Ring text.

One rule is important: **a .NET string is not an object in Ring**, it is just a Ring text. That means you cannot call a .NET *instance* method such as `Trim()` on it. For those jobs Ring has its own functions: `trim()`, `upper()`, `lower()`, `substr()`, `left()`. Use **Ring's functions for the basics**, and .NET for what Ring does not have. The *static* methods of the class `String` (`Join`, `Format`...) work fine because they take the text as an argument.

## The program

{{file:docs/tutorials/t02_text.ring}}

{{output:docs/tutorials/t02_text.ring}}

## How it works

### Ring first

`upper(trim(cSentence))` is Ring. The words are found by turning spaces into new lines and reading each line as an item: `str2list(substr(cSentence," ",nl))`.

### String's static helpers

| Call | Result |
|---|---|
| `oString.Join("-",aWords)` | all the words with `-` between them |
| `oString.Format([ :format = "{0} has {1} items", :arg0 = "The list", :arg1 = 3 ])` | `{0}`, `{1}` are replaced by the arguments |
| `oString.IsNullOrWhiteSpace("   ")` | true for empty or blank text |
| `oString.Compare("apple","banana")` | `-1` if the first sorts before the second, `0` if equal, `1` if after |

`String.Format` exists in several forms, so in Ring it is one method that takes a list of named values: the pattern (`format`) and the values (`arg0`, `arg1`).

### Title case needs a culture

Capital letters depend on the language. `new CultureInfo("en-US").TextInfo.ToTitleCase(...)` makes `Ring Meets Dot Net`. A *culture* describes how a language writes text, numbers and dates.

### StringBuilder for long texts

Adding to a Ring text in a loop copies the text every time. A `StringBuilder` grows in place, so use it when you build a big text (a report, a file). `AppendLine(NULL)` adds a new line; `NULL` means "no argument" for a method that has several versions.

### Base64 and numbers in other bases

`Convert.Format([ :value = 255, :toBase = 16 ])` writes a number in base 16 (`ff`). `Convert.ToBase64String("Ring")` encodes bytes as text (`UmluZw==`); Base64 is how binary data is sent in e-mail and web pages.

### Regular expressions

A *regular expression* (regex) is a pattern for text. `[a-z]+@[a-z]+\.com` means "letters, an @, letters, `.com`". `Regex` can:

| Method | Job |
|---|---|
| `Matches(text)` | find all the places that match |
| `Replace(text, replacement)` | replace every match |
| `IsMatch(text)` | does the text match? |

`^[0-9]+$` means "only digits from the start to the end": the text `12345` matches, `12x45` does not.

### Encodings

A computer stores bytes, not letters. An *encoding* says how letters become bytes. **UTF-8** is the standard: `Ring` is 4 bytes, but `Ring é` is 7, because `é` needs two bytes.

## What you learned

- Use Ring's own functions for basic text work; call `String`'s static helpers when you need `Join`, `Format`, `Compare`.
- `StringBuilder` builds long texts efficiently.
- `Regex` finds, tests and replaces patterns.
- Text, bytes and encodings are different things.

## Exercises

1. Use `Regex` to find every number in `"I have 3 cats and 12 fish"`. (Pattern: `[0-9]+`.)
2. Use `String.Format` with a list of named values to print `Ann is 31 years old` from the values `"Ann"` and `31`.
3. Write a function `isEmail(cText)` that returns true when `Regex.IsMatch` says the text looks like `name@site.com`.
4. Encode your name to Base64 with `Convert.ToBase64String`, then decode it with `Convert.FromBase64String`.

## Next

[Numbers, dates and times](tut-03-numbers-dates.html)
