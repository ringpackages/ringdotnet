---
title: "Tutorial 77: XSLT"
lead: XSLT is a language that turns an XML document into text, CSV, HTML or other XML by following a stylesheet. .NET compiles stylesheets with XslCompiledTransform; this lesson makes a report, a CSV file and an HTML table from the same data.
---

## What you will learn

- what a stylesheet is and how `XslCompiledTransform` runs it,
- templates, `for-each`, `sort`, `sum` and filters,
- three outputs from one input: text, CSV and HTML,
- how this class looks from Ring.

## The idea

You have data in XML ([tutorial 72](tut-72-xml.html)) and you want a report. You can walk the tree in Ring, or you can write a **stylesheet**: a small XML document of *templates* ("when you see this part of the input, write this"). The advantage is that the stylesheet is **data**: change it, and the report changes, without touching the program.

```xml
<xsl:template match="/library">
  <xsl:for-each select="book">
    <xsl:sort select="@year" data-type="number" order="descending"/>
    <xsl:value-of select="title"/> (<xsl:value-of select="@year"/>)
  </xsl:for-each>
</xsl:template>
```

`select` and `match` are **XPath** expressions ([tutorial 72](tut-72-xml.html)).

## The program

{{file:docs/tutorials/t77_xslt.ring}}

{{output:docs/tutorials/t77_xslt.ring}}

## How it works

### The Ring side

Everything happens in `transform`: it writes the stylesheet text to a file, then

```ring
oTransform = new XslCompiledTransform()
oTransform.Load_(cSheet)                 # compile the stylesheet (Load is a Ring keyword, so the method is Load_)
oTransform.Transform([ :inputUri = cInput, :resultsFile = cOutput ])     # input file -> output file
```

`Load_` and `Transform` take file names in this form; the output file is read back with `File.ReadAllText`. Compiling is the slow part, so a program that transforms many documents compiles the stylesheet once and calls `Transform` many times.

### Three stylesheets

1. **Text.** `xsl:output method="text"` writes plain text. `for-each select="book"` repeats for every book; `xsl:sort` orders them by year, newest first (`data-type="number"`, otherwise `1965` sorts after `1937` only by luck); `sum(book/price)` adds the prices. `<xsl:text>&#10;</xsl:text>` writes a new line.
2. **CSV.** The same structure, with a *filter*: `book[price &lt; 10]` keeps only the cheap books (`&lt;` is `<` inside XML).
3. **HTML.** `method="html" indent="yes"` writes a table. In `<tr class="{@genre}">` the braces put the value of the attribute into the output (an *attribute value template*), so each row gets its genre as a CSS class.

> [!TIP] Writing XSLT strings in Ring code gets crowded. Keep stylesheets in their own `.xsl` files next to the program and pass the path to `Load_`; designers can then change the layout of a report without reading Ring.

### When to use it

- The result is a **document** with a fixed structure (reports, feeds, HTML pages from XML data).
- The people who change the layout are not the people who write the program.
- Not for logic: loops with counters, calls to your own functions and file access are easier in Ring.

## What you learned

- `XslCompiledTransform`, `Load_` and `Transform`,
- templates, `for-each`, `sort`, `sum`, filters,
- text, CSV and HTML output,
- attribute value templates `{@name}`.

## Exercises

1. Write a stylesheet that outputs only the titles of the science fiction books.
2. Add a `<xsl:if test="price > 10">` that marks expensive books with `*`.
3. Make the HTML a complete page (`<html><body>…`) with a heading and the total price.
4. Transform an XML file that you create with `XDocument` ([tutorial 72](tut-72-xml.html)).

## Next

[Tutorial 47: Markdown to HTML](tut-47-markdown.html)
