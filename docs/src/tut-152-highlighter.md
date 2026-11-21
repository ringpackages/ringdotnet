---
title: "A project: a syntax highlighter"
lead: A highlighter shows code in colors. This project splits code into tokens with one regular expression that has a named group for each kind, turns the tokens into HTML spans with escaped text, and checks that nothing was lost.
---

## What you will learn

- **tokens**: comments, strings, numbers, words and the rest,
- one regular expression with **named groups** and the alternatives in the right **order**,
- `Regex.Matches` and `Groups.Item(name).Success`,
- keywords and names,
- HTML output with **escaped** text,
- a check: without the tags the text is the original,
- what a pattern like this cannot do.

The tutorial [Regular expressions in depth](tut-29-regex.html) explained groups and alternatives. This project uses them to read a language.

## The program

{{file:samples/UsingDotNet/tutorials/ch02_highlighter.ring}}

{{output:samples/UsingDotNet/tutorials/ch02_highlighter.ring}}

> [!NOTE] This program uses a generic function (`dnStatic`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### One pattern for all the tokens

The pattern is a list of alternatives separated by `|`, each one a **named group**: `(?<comment>#[^\n]*)` is a `#` and everything to the end of the line, `(?<string>"[^"\n]*")` is a double quote, characters that are not a quote or a line break, and a double quote, `(?<number>\b\d+(?:\.\d+)?\b)` is a whole number or a number with a decimal point, `(?<word>[A-Za-z_]\w*)` is a name or a keyword, and `(?<other>[\s\S])` is *any* character, including line breaks. Because the last alternative matches every character, the matches cover the whole text, and every character belongs to one token. The pattern is in single quotes in Ring because it has double quotes.

### The order

At each place the regular expression tries the alternatives from the first to the last, and the first that matches wins. A comment must come first, so that the words *print it* in `# print it` are not read as words; a string comes before the numbers, so that the `3` in `"line 3"` is not a number; and `other` is last, because it matches everything. A `#` in a string (step 6) is part of the string, because the string alternative matches at the quote, and the matching never looks at the `#` on its own.

### Tokens

`Regex.Matches(text, pattern)` returns the matches in order. For each match the program asks the groups `Groups.Item("comment").Success` and so on, and the first group that is true is the kind of the token. The result is a list of `[kind, text]`. A `word` is a **keyword** when it is in the list of keywords of the language (`for`, `to`, `next`) and a **name** otherwise (`i`, `x`, `radius`). A new language is a new pattern and a new list.

### HTML

Each comment, string, number and keyword becomes `<span class="comment">...</span>` (and so on); a style sheet gives each class a color. Names and the other characters stay plain. The text of **every** token is **escaped** first: `<` becomes `&lt;`, `>` becomes `&gt;` and `&` becomes `&amp;`. Code is full of these characters, and a browser would read them as tags. `&` is replaced first, so that the `&` of the other two replacements is not replaced again (the tutorial [Escaping](tut-86-escaping.html)).

### The check

A highlighter must not change the code. The program removes the tags it added (`</?span[^>]*>`) and compares the rest with the escaped original: they are equal. This one test finds most mistakes: a lost character, a changed space, a token that was written twice.

### What it cannot do

A pattern is not a parser. It does not know a string that continues on the next line, a quote inside a string (`"a \" b"`), or a comment in the style `/* ... */` unless there is an alternative for it. Real highlighters add alternatives, and for languages with a complicated syntax they use a real parser. For a small language, one pattern is often enough.

## What you learned

- tokens with named groups in one pattern,
- the order of the alternatives,
- keywords and names,
- escaped HTML and the check of the result.

## Exercises

1. Add a group for operators (`[+\-*/=<>]+`) and a class for them.
2. Add a style sheet and a page that shows the highlighted code (the tutorial [A project: Markdown to HTML](tut-47-markdown.html)).
3. Add an alternative for strings with single quotes.
4. Count the tokens of each kind and print a table.

## Where to go next

This was the last tutorial of the chapter **Text and data formats**. The next chapter is **Numbers, dates and money**: it starts with [Number types](tut-101-number-types.html). The [Tutorials](tutorials.html) page lists all the chapters, and you can start any of them.
