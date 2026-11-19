---
title: "XML in depth"
lead: XML is still everywhere — configuration files, office documents, feeds, web services. This lesson reads a document with XDocument, finds nodes with XPath, builds a new element, changes and removes nodes, and handles broken XML.
---

## What you will learn

- the structure of an XML document: elements, attributes, text,
- reading with `XDocument` (LINQ to XML),
- searching with **XPath**,
- creating, changing and removing elements,
- saving and reading back,
- what happens with bad XML.

## The data

```xml
<library>
  <book id="1" year="1937"><title>The Hobbit</title><price>9.5</price></book>
  <book id="2" year="1965"><title>Dune</title><price>12</price></book>
  ...
</library>
```

An **element** has a name and can contain text and other elements; an **attribute** (`id="1"`) belongs to an element. There is exactly one **root** element. The tutorial [JSON and XML](tut-06-json-xml.html) read XML in a simple way; here are the tools for real documents.

## The program

{{file:samples/UsingDotNet/tutorials/t72_xml.ring}}

{{output:samples/UsingDotNet/tutorials/t72_xml.ring}}

## How it works

### XDocument

`new XDocument().Parse(text)` builds the tree. `oDocument.Root` is the root element. `Elements(NULL)` gives all child elements (`NULL` because the method has other forms, see [Core concepts](concepts.html)), and `.toList()` makes a Ring list. For each element `Attribute("year").Value` reads an attribute and `Element("title").Value` the text of a child. The values are always **texts**: convert with `number()` when you need a number (step 2 adds the prices).

### XPath

XPath describes a path through the tree:

| XPath | Finds |
|---|---|
| `/library/book` | all books under the root |
| `//book` | every book at any depth |
| `/library/book[@year>1950]` | books with a year attribute above 1950 |
| `//book[@id='3']/title` | the title of book 3 |

It is part of `XmlDocument` (`SelectNodes`, `SelectSingleNode`). One short expression replaces loops with `if`s.

### Creating and changing

An element is created with a name and optional content: `dnNew("XElement",[ :name = "title", :content = "Foundation" ])`. `SetAttributeValue("id","4")` adds an attribute, `Add(child)` appends a child. To change a text assign `element.Value`; `Remove()` deletes an element from its parent. `ToString()` gives indented XML text, which `File.WriteAllText` can save.

### Bad XML

XML is strict: every tag must be closed and tags must nest. `Parse` raises an error with the line and the problem (step 7). Always parse data that comes from outside inside `try` / `catch` (the tutorial [When things go wrong](tut-07-errors.html)).

> [!WARNING] Text that you put into XML must be escaped (`<` → `&lt;`, `&` → `&amp;`). When you build elements with `XElement` this is done for you. Never build XML by adding strings together.

## What you learned

- elements, attributes, the root,
- `XDocument`: `Root`, `Elements`, `Element`, `Attribute`,
- XPath with `XmlDocument`,
- building, changing and removing,
- errors in bad XML.

## Exercises

1. Write the books as a table: title, year and price in columns (the tutorial [Tabular data](tut-30-tables.html)).
2. Use XPath to find the books cheaper than 10.
3. Add a `<tags>` element with several `<tag>` children to each book.
4. Convert the list of books to JSON (the tutorial [JSON and XML](tut-06-json-xml.html)) and back.

## Next

[XSLT](tut-77-xslt.html)
