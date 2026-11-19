---
title: "URLs and encodings"
lead: Addresses, query strings and Base64 look simple until a space or an ampersand arrives. This lesson takes a URL apart, builds and reads query strings safely, resolves relative addresses and encodes bytes as text.
---

## What you will learn

- the parts of a URL and the `Uri` class,
- percent-encoding of special characters (`WebUtility.UrlEncode` / `UrlDecode`),
- building and reading a query string,
- combining a base address with a relative path,
- Base64, and why it is not encryption,
- checking that an address is valid.

## The parts of a URL

```text
https://shop.example.com:8443/products/shoes?color=red&size=42#reviews
└scheme┘ └─────host─────┘└port┘└───path───┘ └──── query ────┘└fragment┘
```

The **query** holds `name=value` pairs separated by `&`. The **fragment** (after `#`) stays in the browser and is never sent to the server.

## The program

{{file:docs/tutorials/t64_urls.ring}}

{{output:docs/tutorials/t64_urls.ring}}

## How it works

### Uri

`new Uri(text)` parses the address and gives you `Scheme`, `Host`, `Port`, `AbsolutePath`, `Query` and `Fragment`. Never cut an address with `substr` and `find`: ports, user names, `?` inside a fragment and many other details make it go wrong. If no port is written, the port of the scheme is used (80 for `http`, 443 for `https`).

### Encoding

Some characters have a meaning in an address: `&` separates parameters, `=` joins a name and a value, `?` starts the query, `%` starts an escape. If the *text of the user* contains them, they must be **percent-encoded** or they change the meaning: `rock & roll` would become two parameters. `WebUtility.UrlEncode` turns each special character into `%` and two hex digits (`&` → `%26`) and a space into `+`; `UrlDecode` reverses it.

### Building and reading a query

`buildUrl` encodes each **value** and puts `=` and `&` between them yourself — the separators must *not* be encoded. `parseQuery` does the reverse: first split on `&`, then on the first `=`, and decode each value **last**. If you decoded first, an encoded `%26` would turn into a real `&` and break the split.

> [!WARNING] Never build addresses or SQL or HTML by adding user text to a string without encoding it for that place. The same rule applies to all three: *encode for the place where the text goes*.

### Relative addresses

A page at `/docs/guide/index.html` that links to `../images/logo.png` means `/docs/images/logo.png`. `Uri(baseUri, relativeUri)` does this resolution for you; because the constructor takes two values it is written with named arguments: `dnNew("Uri",[ :baseUri = oBase, :relativeUri = "..." ])`.

### Base64

Base64 writes **any bytes** with 64 safe characters (letters, digits, `+`, `/`). It is used in e-mails, JSON and data URLs. It makes the data about a third bigger and it is **not encryption** — anyone can decode it. For secrets use the tutorial [Hashing and encryption](tut-08-security.html).

### Checking an address

`IsWellFormedUriString(text, "Absolute")` answers yes or no without raising an error. The enum argument is written as text (the tutorial [Enums and flags](tut-65-enums.html)).

## What you learned

- `Uri` and its parts,
- encoding and decoding for query strings,
- the order: split first, decode last,
- relative addresses with named constructor arguments,
- Base64.

## Exercises

1. Write `getParameter(cUrl, cName)` that returns one value of the query of an address.
2. Build the URL of a search for the text `C# & Ring` and check it with `Uri`.
3. Turn a small text file into a Base64 data URL (`data:text/plain;base64,...`).

## Next

[International domain names](tut-117-domain-names.html)
