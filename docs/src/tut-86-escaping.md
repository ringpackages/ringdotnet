---
title: "Escaping"
lead: Text from a user must never be put into HTML, a URL, JavaScript, JSON, XML, a regular expression or SQL as it is. Each place has its own special characters and its own encoder. This lesson shows the tool for each place and the attack that it stops.
---

## What you will learn

- why text must be **encoded for the place** where it goes,
- HTML: `WebUtility.HtmlEncode` and `HtmlEncoder`,
- URLs: `UrlEncoder`,
- JavaScript: `JavaScriptEncoder`,
- JSON: `JsonEncodedText`,
- XML: `XElement` escapes for you,
- regular expressions: `Regex.Escape`,
- SQL: parameters, never joined text.

## The rule

A text has no meaning by itself; the **place** gives it one. `<b>` is just letters in a text file and a command in an HTML page. If the text of a visitor reaches a place without being encoded, the visitor can write *commands* for that place: a script that runs in other people's browsers (*cross-site scripting*), SQL that reads your whole database (*SQL injection*). The defence is always the same: **encode for the place where the text goes**, with a tool that knows that place.

| Place | Danger | Tool |
|---|---|---|
| HTML | `<`, `>`, `&`, quotes | `WebUtility.HtmlEncode`, `HtmlEncoder` |
| URL | `&`, `=`, space, non-ASCII | `UrlEncoder` |
| JavaScript string | quotes, `</script>` | `JavaScriptEncoder` |
| JSON | quotes, new lines | `JsonEncodedText`, or a JSON class |
| XML | `<`, `&` | `XElement` |
| regular expression | `. + * ( ) [ ]` | `Regex.Escape` |
| SQL | `'` and everything else | **parameters** |

## The program

{{file:docs/tutorials/t86_escaping.ring}}

{{output:docs/tutorials/t86_escaping.ring}}

## How it works

### HTML

`HtmlEncode` replaces `<`, `>`, `&` and quotes by entities (`&lt;`, `&amp;`, …). The browser then *shows* `<script>` instead of running it. Step 2 puts the same name into a page twice: without encoding, the `onerror` handler would run in the visitor's browser. `HtmlEncoder.Default.Encode` (namespace `System.Text.Encodings.Web`) is the stricter encoder that ASP.NET uses; the two differ in details such as `&#39;` against `&#x27;`. `HtmlDecode` reverses the encoding.

### URL, JavaScript, JSON

`UrlEncoder` turns space, `&`, `/` and non-ASCII letters into `%XX`; encode each *value*, not the whole address (the tutorial [URLs and encodings](tut-64-urls.html)). `JavaScriptEncoder` writes quotes and `<` as `\u0022` and `\u003C`, so a text inside a script cannot close the string or the script tag. `JsonEncodedText.Encode` gives `\n`, `\t` and `\u0022`; for a whole document build a `JsonObject` (the tutorial [JSON as a tree](tut-80-json-nodes.html)) and let it write the text.

### XML

`XElement` stores the text and writes it with the correct escapes (`&lt;script&gt;`) when you call `ToString()` (the tutorial [XML in depth](tut-72-xml.html)). Never build XML by joining strings.

### Regular expressions

A user who searches for `1+1=2 (a.b)*` means **those characters**, not a pattern. `Regex.Escape` puts a backslash in front of each special character, and the escaped pattern matches the text itself. (The instance `new Regex("x")` is only used to reach the static method.)

### SQL

`oDb.where("People","Name = {0}",[cAttack])` sends the text as a *parameter*: the database receives the statement and the value separately, so the value can never become part of the statement. The attack text `x' OR '1'='1` finds no rows. If you had written `"Name = '" + cAttack + "'"`, the statement would read `Name = 'x' OR '1'='1'` and return every row. This is the most important line of the lesson: **never join user text into SQL.**

> [!WARNING] Encoding is for *output*. It does not replace checking input (a number must be a number, a name must have a sensible length) and it does not make a text safe for a *different* place: HTML-encoded text is not URL-safe. Encode at the moment you put the text into the place, and only once.

## What you learned

- text is encoded for the place,
- `WebUtility`, `HtmlEncoder`, `UrlEncoder`, `JavaScriptEncoder`, `JsonEncodedText`, `Regex.Escape`,
- `XElement` escapes by itself,
- SQL parameters stop injection.

## Exercises

1. Make the tiny web site of the tutorial [A small web site](tut-26-website.html) safe: where does it show a visitor's text?
2. Write a function `link(cText, cAddress)` that builds `<a href="…">…</a>` with the right encoding for the address and for the text.
3. Search a text file for a phrase that the user types, using `Regex.Escape`.
4. Try the attack text `'; DROP TABLE People; --` as a parameter and check that the table is still there.

## Next

[URLs and encodings](tut-64-urls.html)
