---
title: "MIME types"
lead: A MIME type names the kind of a piece of data — text/html, image/png, application/json. A server sends it so that the browser knows what to do with the bytes, and a client sends a list of types it understands. This lesson maps file names to types, reads a Content-Type header, and chooses what to send for an Accept header.
---

## What you will learn

- what a **MIME type** (media type, content type) is,
- mapping file extensions to types (`FileExtensionContentTypeProvider`),
- adding a type of your own,
- reading `Content-Type` (type, subtype, `charset`),
- the `Accept` header, **quality** values and wildcards,
- **content negotiation** and the answer *406 Not Acceptable*.

The tutorial [HTTP](tut-09-http.html) and the tutorial [HttpClient in depth](tut-84-http-client.html) used HTTP from the client side and the tutorial [A tiny web framework](tut-55-miniweb.html) from the server side. Whenever a body is sent, a type must say what it is.

> [!NOTE] The content type classes (`Microsoft.AspNetCore.StaticFiles`, `Microsoft.Net.Http.Headers`) are part of the ASP.NET Core runtime, so the program has `"RingDotNet.Web"` in its `using { }` ([Getting started](getting-started.html)).

## The program

{{file:samples/UsingDotNet/tutorials/ch02_mime_types.ring}}

{{output:samples/UsingDotNet/tutorials/ch02_mime_types.ring}}

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnStatic`, `dnNewGeneric`, `callMethod`, `getProp`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### Type and subtype

A MIME type has the form **`type/subtype`**: the type is the family (`text`, `image`, `audio`, `video`, `application`) and the subtype the exact format (`html`, `png`, `json`). After a semicolon come **parameters**: `text/html; charset=utf-8` says that the text is encoded in UTF-8 (the tutorial [Unicode and encodings](tut-52-unicode.html) explains encodings). A server that sends the wrong type causes real problems: a browser that receives a script as `text/plain` does not run it, and one that receives a page as `text/plain` shows the source.

### From a file name

`FileExtensionContentTypeProvider.TryGetContentType(name)` answers `[ found, type ]` (the tutorial [Network tools](tut-81-network-tools.html) explains the out value) from the **extension** of the file name, ignoring case (`photo.JPG` is `image/jpeg`). The table is built into the library: it knows the usual web, office, audio and video formats, and the exact text for some extensions changes between versions (for example, JavaScript is `text/javascript` today and was `application/javascript` before), so a test must not depend on it. For an extension that is not in the table, the **right default** is `application/octet-stream`: *some bytes — download them, do not show them*. Never guess `text/html`.

`Mappings` is a dictionary you can extend: `Add(".ring", "text/x-ring")` teaches the provider a type of your own. Do this once, at the start of the program.

> [!WARNING] The extension is what the **name** says, not what the **content** is. A file called `photo.jpg` can hold anything. For files that users upload, do not trust the type that comes with them: check the first bytes of the file (the *magic numbers*, the tutorial [Binary files](tut-45-binary.html)) and send downloads with `Content-Disposition: attachment` and the header `X-Content-Type-Options: nosniff`.

### Reading Content-Type

`System.Net.Mime.ContentType` parses a header into `MediaType` and `CharSet`; the headers library `MediaTypeHeaderValue.Parse` gives `Type`, `SubType`, `Quality` and the parameters. Their `Type` and `SubType` are small structs (`StringSegment`) that are turned into text with `toString()`.

### Accept and quality

The client's **`Accept`** header lists the types it understands, separated by commas, each with an optional **quality** `q` from 0 to 1 (1 is the default; higher is better, and 0 means *never*). `*/*` means *anything* and `text/*` *any text type*. The program parses the header, gives each item its quality, and sorts them best first (a simple, stable sort, so types with the same quality keep their order: the client's order breaks ties).

### Content negotiation

The server **offers** some types, and the best answer is the offered type that the client likes most: for each type of the Accept list, from best to worst, take the first offer that it covers. In step 5, a client that sends `text/html, application/json;q=0.9, text/*;q=0.5, */*;q=0.1` gets `application/json` when the server offers JSON and CSV, gets `text/csv` when it offers CSV and plain text (matched by `text/*`), and gets a PNG only through `*/*`. If *nothing* fits — a client that accepts only JSON and a server that has only CSV — the correct answer is **406 Not Acceptable**, so that the client sees at once that the types do not agree, instead of receiving data it cannot use.

In real programs the negotiation also looks at the **language** (`Accept-Language`) and the **encoding** (`Accept-Encoding`: gzip, br, the tutorial [Compression](tut-88-compression.html)), with the same quality rules.

## What you learned

- `type/subtype` and parameters such as `charset`,
- `TryGetContentType`, the default `application/octet-stream`, and your own `Mappings`,
- the extension is not the content,
- the `Accept` list, quality and wildcards,
- negotiation and *406 Not Acceptable*.

## Exercises

1. Make the web server of the tutorial [A tiny web framework](tut-55-miniweb.html) send the right `Content-Type` for the files of a folder.
2. Parse `Accept-Language: ar, en;q=0.8, fr;q=0.5` with the same functions and choose a language from the list of the languages you have.
3. Write `isAllowedUpload(name)` that accepts only `image/png`, `image/jpeg` and `application/pdf`.
4. Add `*/*;q=0` to an Accept header and see how it changes the answer.

## Next

[Writing JSON as a stream](tut-100-json-writer.html)
