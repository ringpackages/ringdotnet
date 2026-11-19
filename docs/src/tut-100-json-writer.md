---
title: "Writing JSON as a stream"
lead: Utf8JsonWriter writes a JSON text piece by piece into a stream, with exact control of the form and without building the whole document in memory first. This lesson writes an object with nested parts, shows the escaping and the checks the writer does, and uses JsonSerializer with options.
---

## What you will learn

- `Utf8JsonWriter`: start and end of objects and arrays, properties and values,
- indented and compact output (`JsonWriterOptions`),
- `Flush` and why the writer needs it,
- the escaping that is done for you, and the errors for invalid structure,
- `JsonSerializer` and `JsonSerializerOptions` for objects and collections.

The tutorial [JSON and XML](tut-06-json-xml.html) read and wrote JSON as a tree and the tutorial [JSON as a tree](tut-80-json-nodes.html) built it from nodes. A tree is easy to change but it keeps the whole document in memory. A **writer** is the other style: you say what comes next, and it goes straight to a stream (a file, a network connection, a `MemoryStream`).

## The program

{{file:samples/UsingDotNet/tutorials/ch02_json_writer.ring}}

{{output:samples/UsingDotNet/tutorials/ch02_json_writer.ring}}

## How it works

### Writing the document

The writer is made on a stream (`dnNew("Utf8JsonWriter",[ :utf8Json = oStream, :options = oOptions ])`). Then you call, in order, what the document contains:

| Call | Writes |
|---|---|
| `WriteStartObject(NULL)` / `WriteEndObject()` | `{` and `}` (with a name, `WriteStartObject("address")`, it is a property of the object around it) |
| `WriteStartArray("skills")` / `WriteEndArray()` | `[` and `]` |
| `WriteString("name","Ann")` | a property with a text value |
| `WriteNumber("age",31)`, `WriteBoolean("active",True)`, `WriteNull("manager")` | properties with other values |
| `WriteStringValue("ring")`, `WriteNumberValue(4)` | a value inside an array (it has no name) |

The names and the commas, colons and quotes are added by the writer: you never write a `,` yourself. `JsonWriterOptions` is a struct; its property `Indented = True` makes the readable form with two spaces for each level. Without it (step 2) the text is compact, `[1,4,9]`, which is what a program sends over a network.

> [!NOTE] The writer has several forms of each method, and Ring takes the plain `WriteString("name","Ann")` (two values) or `WriteStartObject(NULL)` (no name). If you get *"less number of parameters"*, look at the method in the [class reference](api.html): a method with two or more values is called with them in order.

### Flush

The writer keeps its output in a **buffer** and sends it to the stream in blocks. `Flush()` sends what is waiting: without it the stream can still be empty (or incomplete) when you read it. `Dispose()` flushes and releases the writer, so close it when you are done (the tutorial [Releasing resources](tut-71-dispose.html)).

### Escaping and checks

The text `a "quoted" line` followed by a new line and `<tag> & more` is written as `a "quoted" line\nand a <tag> & more`: quotes, new lines and the characters `<`, `>`, `&` are escaped, so the output is valid JSON and also safe to put into a web page (the tutorial [Escaping](tut-86-escaping.html)). The writer also **checks the structure**: ending an object that was not started raises an error (here caught with `try`). Such an error is a bug in *your* program that you can find at once, instead of a broken file that a receiver finds later.

### JsonSerializer

`JsonSerializer.Serialize(object)` turns a .NET object — a list, a dictionary, an object of your own library — into JSON in one call. `JsonSerializerOptions` change the form: `WriteIndented`, `PropertyNamingPolicy` (for example camelCase), `DefaultIgnoreCondition` (skip null values) and more. The method has several forms, so with options it takes names: `Serialize([ :value = oScores, :options = oIndent ])`. Use the serializer when you have *objects*, and the writer when you want to control *every token* or write very large output.

## What you learned

- `Utf8JsonWriter` writes JSON into a stream, token by token,
- indented and compact forms,
- `Flush` and `Dispose`,
- escaping and structure checks are done for you,
- `JsonSerializer` for whole objects.

## Exercises

1. Write an array of 1000 objects with `id` and `square` into a file (the tutorial [Files and folders](tut-05-files.html)), and read it back with `JsonDocument` (the tutorial [JSON and XML](tut-06-json-xml.html)).
2. Write the nested folder structure of a directory as JSON with a recursive function.
3. Make `JsonSerializerOptions` with `PropertyNamingPolicy = JsonNamingPolicy.CamelCase` and look at the names.
4. Write a number with many decimals with `WriteNumber` and look at how it is written.

## Next

[JSON as a tree](tut-80-json-nodes.html)
