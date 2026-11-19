---
title: "JSON and XML"
lead: Programs exchange data as text in a structure. JSON and XML are the two common structures; this lesson reads, searches, changes and writes both.
---

## What you will learn

- what JSON and XML are,
- reading a JSON document and its nested values,
- loading XML, looping over elements, XPath queries, adding an element.

## JSON and XML in one minute

**JSON** looks like Ring lists and objects:

```text
{"name":"Ring","year":2016,"tags":["fast","small"],"author":{"first":"Mahmoud"}}
```

- `{ }` an object of *properties*, `[ ]` an array, texts in quotes, numbers without.

**XML** is a tree of *elements* with *attributes*:

```text
<book id="1" year="1999"><title>Learn Ring</title></book>
```

JSON is lighter and used by web services; XML is older and used in files and configuration.

## The program

{{file:samples/UsingDotNet/tutorials/ch01_json_xml.ring}}

{{output:samples/UsingDotNet/tutorials/ch01_json_xml.ring}}

## How it works

### JSON: write

`JsonSerializer.Serialize(aList)` turns a Ring list into JSON text: a list of values becomes an *array*, nested lists become nested arrays. (To make a JSON *object* from `[name, value]` pairs, the web library has `webJson(...)`: see the tutorial [A web service with a database](tut-16-web-service.html).)

### JSON: read

`JsonDocument.Parse(text)` reads a JSON text. `RootElement` is the top value. From an element you:

| Want | Call |
|---|---|
| a property of an object | `GetProperty("name")` |
| an item of an array | `Item(0)` |
| how many items | `GetArrayLength()` |
| the value as text / number | `GetString()` / `GetInt32()` |

Chain them to go deep: `oRoot.GetProperty("author").GetProperty("first").GetString()`. `Dispose()` frees the document when you are done.

### XML: load and loop

`XmlDocument.LoadXml(text)` (or `Load(file)`) reads XML. `SelectNodes("//book")` finds all the `book` elements; the `Count` and the `Item(index)` of the result let you loop. For one element: `GetAttribute("id")` reads an attribute and `InnerText` the text inside.

### XPath

*XPath* is a small query language for XML. Examples:

| XPath | Means |
|---|---|
| `//book` | every `book` anywhere |
| `//book[@year > 2000]` | the books whose `year` is above 2000 |
| `//book[@id='2']/price` | the `price` of the book with id 2 |

### Change and save

`CreateElement("book")`, `SetAttribute`, `InnerText` and `AppendChild` build new nodes; `OuterXml` is the whole document as text. `Save(file)` writes it to a file.

## What you learned

- JSON for web data, XML for documents,
- read JSON by following properties,
- XPath asks questions of XML.

## Exercises

1. Read a JSON text with an array of three numbers and print their sum.
2. Find the cheapest book in the XML of the program with XPath and a loop.
3. Save the changed XML to a file with `oDoc.Save(cPath)` and read it back.
4. Turn the Ring list `[1,[2,3],"four"]` into JSON and read it back with `JsonDocument`.

## Next

[When things go wrong](tut-07-errors.html)
