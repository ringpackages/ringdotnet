---
title: "Unicode and encodings"
lead: Why len() of a text is not the number of letters you see, what UTF-8 and UTF-16 are, and what goes wrong when the wrong encoding is used.
---

## What you will learn

- the difference between bytes, code points and the letters you see,
- UTF-8 and UTF-16 and what `Encoding` does,
- why reading with the wrong encoding gives garbage,
- why two texts that look the same can be different,
- asking .NET what kind of character something is.

## The three levels

- A **byte** is what is stored in a file.
- A **code point** is the number Unicode gives to a character (`é` is 233, an emoji is 128512).
- A **text element** is what you see as one letter. It can be several code points: `e` plus a combining accent looks like `é`.

An **encoding** turns text into bytes. **UTF-8** uses 1 byte for English letters and up to 4 for others; it is the standard for files and the web. **UTF-16** is what .NET uses inside. A Ring text is a sequence of bytes (the text of a program and of most files is UTF-8), so `len()` counts **bytes**.

## The program

{{file:samples/UsingDotNet/tutorials/ch02_unicode.ring}}

{{output:samples/UsingDotNet/tutorials/ch02_unicode.ring}}

## How it works

The table compares four counts for six texts. For `Ring` they are all the same; for `café` the byte count is 5 but you see 4 letters; Russian and Arabic use two bytes per letter; Japanese three; an emoji four (two units in UTF-16). `StringInfo.LengthInTextElements` counts what a person sees. Its constructor that takes the text is written `new StringInfo().@New([ :value = cText ])`.

Step 2 turns `é` into two bytes (195 and 169) and reads them again as **Latin-1**: the result is `Ã©`, the classic *mojibake*. The rule: **the encoding that wrote the bytes must be the one that reads them**. When you read text files, say it: `File.ReadAllText(path, encoding)`.

Steps 4 and 5 show that `é` can be one code point or two. They look the same, but compared as bytes they differ. Compare with a culture-aware method (`String.Compare`) when users type text.

> [!NOTE] `left()`, `right()` and `substr()` of Ring work on bytes. For text with accents or other alphabets do not cut by number; use .NET classes or split on spaces and separators.

## What you learned

- bytes, code points, text elements,
- `Encoding.UTF8`, `Unicode`, `Latin1`, `GetBytes`, `GetString`,
- mojibake and how to avoid it,
- comparing text in a culture-aware way,
- `CharUnicodeInfo.GetUnicodeCategory`.

## Exercises

1. Write a text to a file in UTF-8 and in UTF-16 and compare the file sizes.
2. Count the letters of your own name with `len()` and with `StringInfo`.
3. Find out what `Encoding.ASCII.GetBytes("é")` returns, and why.

## Next

[Text files and encodings](tut-132-text-encodings.html)
