---
title: "A project: Markdown to HTML"
lead: Write a small converter from the Markdown that people like to type into the HTML that browsers need — headings, paragraphs, lists, bold, italic, code and links — with regular expressions and a StringBuilder.
---

## What you will learn

- converting one text format into another,
- a line-by-line scan with a little state,
- inline formatting with regular expressions,
- why you escape first,
- a Ring feature to know: using objects during definition, `x = new Class().Method(x)`.

## Markdown in one minute

*Markdown* is a way to write formatted text with plain characters: `# Title` is a heading, `**bold**`, `*italic*`, code between back-quotes, `- item` a list item, `[text](address)` a link. Many sites turn it into HTML.

## The program

{{file:samples/UsingDotNet/tutorials/t47_markdown.ring}}

{{output:samples/UsingDotNet/tutorials/t47_markdown.ring}}

## How it works

### Two levels

A document has **blocks** (headings, paragraphs, lists) and, inside the blocks, **inline** parts (bold, links). The program handles them separately:

- `markdownToHtml` decides what each *line* is,
- `inlineHtml` formats what is *inside* a line.

### Blocks: a scan with state

The function goes through the lines. The one thing it must remember is whether it is **inside a list**: the first `- ` line opens `<ul>`, further items continue it, and the first line that is not an item (or an empty line) closes it with `</ul>`. Headings are recognised by the number of `#`: check `###` first, then `##`, then `#`, otherwise the line is a paragraph. A `StringBuilder` collects the output without copying the text again and again.

### Inline: escape first

> [!WARNING] The first step of `inlineHtml` is to replace `&`, `<` and `>` by their HTML codes. Without it, a line such as `- <fresh> fruit` would produce a `<fresh>` tag that the browser tries to read, and a malicious document could contain a `<script>`. **Escape first, then add your own tags**, so the only tags in the output are yours. (The result in the output: `&lt;fresh&gt; fruit`.)

### Inline: regular expressions

| Pattern | Replacement | Result |
|---|---|---|
| a back-quote, some text, a back-quote | `<code>$1</code>` | code |
| `\*\*(.+?)\*\*` | `<strong>$1</strong>` | bold |
| `\*(.+?)\*` | `<em>$1</em>` | italic |
| `\[([^\]]+)\]\(([^)]+)\)` | `<a href='$2'>$1</a>` | link |

`$1` and `$2` are the captured groups (the tutorial [Regular expressions in depth](tut-29-regex.html)); `.+?` is lazy so that two bold parts in one line are two separate matches. **Bold before italic**: both use the star, and `**x**` must be taken first.

### Using objects during definition

Look at how the steps are written: each result goes to a **new variable** (`cSafe`, `cCode`, `cBold`...). The tempting form is `cText = new Regex(...).Replace(cText, ...)`, but it fails with an odd error ("no method matches the 2 arguments"). The reason is a Ring feature, [using objects during definition](https://ring-lang.github.io/doc1.28/oop.html#using-objects-during-definition) (Ring 1.19+): when you write `x = new Class()...`, Ring stores the new object in `x` **first**, so that the object can be used while the rest of the expression runs (for example by a method call or an overloaded operator), and only then stores the final result in `x`. So when `.Replace(cText, ...)` is evaluated, `cText` already holds the `Regex` object, not your text. The feature is useful in Ring code that defines objects; for plain .NET calls, just use a different variable name.

## What you learned

- block-level and inline conversion are separate jobs,
- state for lists, `StringBuilder` for output,
- escape before formatting,
- lazy regexes, ordering of the steps,
- with `x = new Class().Method(x)` the variable already holds the new object (using objects during definition): use another variable.

## Exercises

1. Add numbered lists (`1. item`) and `<ol>`.
2. Add `> quote` lines as `<blockquote>`.
3. Add code blocks between three backticks lines.
4. Read a `.md` file from disk and write the matching `.html` file.

## Next

[A spell checker](tut-66-spelling.html)
