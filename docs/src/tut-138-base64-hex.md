---
title: "Bytes as text: Base64 and hexadecimal"
lead: Bytes can hold any value, but an e-mail, a JSON file or a URL accepts only text. Base64 and hexadecimal turn bytes into safe letters and digits and back. This lesson encodes and decodes both, looks at the size and the padding, the form for URLs, wrong input and data URIs.
---

## What you will learn

- **Base64**: 3 bytes become 4 characters, and `=` fills the end,
- the **padding** and the size of the result,
- sending *all* 256 byte values through text,
- the **URL-safe** form (`-` and `_`, no `=`),
- **hexadecimal** with `Convert.ToHexString` and `FromHexString`,
- the errors of wrong input,
- **data URIs**, and a hash written in hexadecimal.

The tutorial [URLs and encodings](tut-64-urls.html) used Base64 for one purpose. This lesson looks at the encodings themselves.

## The program

{{file:samples/UsingDotNet/tutorials/ch02_base64_hex.ring}}

{{output:samples/UsingDotNet/tutorials/ch02_base64_hex.ring}}

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnStatic`, `dnNewGeneric`, `callMethod`, `getProp`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### Base64

Base64 takes the bytes in groups of three (24 bits) and writes each group as four characters of 6 bits, taken from `A-Z`, `a-z`, `0-9`, `+` and `/`. The result is **a third longer** than the data: 11 bytes become 16 characters. `Convert.ToBase64String` and `FromBase64String` are static methods, called with `dnStatic`. A `byte[]` is a Ring text of bytes in this package, so the text goes in and comes out as it is.

### Padding

When the data is not a multiple of three bytes, the last group is short and the result is filled with `=`: one byte gives `==`, two bytes give `=`, three give none. The number of `=` tells how many bytes were missing. A decoder needs the length to be a multiple of four, which is why the function `addPadding` exists for texts that lost their `=`.

### Any bytes

Base64 works for every byte value, not only for text: step 3 sends all 256 values through and gets the same bytes back. This is why Base64 is used for pictures in JSON, for attachments in e-mail and for keys and certificates.

### Base64 for URLs

The signs `+` and `/` have a meaning in URLs and in file names, and `=` separates values. The **URL-safe** form replaces `+` with `-`, `/` with `_`, and leaves out the `=`. The bytes `251 255` show it: `+/8=` becomes `-_8`. A decoder puts the signs back and adds the padding again. Tokens in links, the parts of a JSON Web Token and file names made from hashes use this form.

### Hexadecimal

`Convert.ToHexString` writes each byte as two digits (`0-9`, `A-F`): the result is **twice as long** as the data, but a person can read it and compare it. `000F10FF` shows the bytes `0`, `15`, `16` and `255`; the zeros in front are part of the text. Hashes, color codes and the dumps of a debugger use hexadecimal.

### Wrong input

A character that is not in the alphabet (`!` and a space in `not base64!`) or a hexadecimal text of an odd length raises `System.FormatException`. A program that decodes text from outside uses `try` and `catch` and treats the error as *this is not valid data*.

### Data URIs

A **data URI** puts a small file into the text of a page or a style sheet: `data:text/plain;base64,SGVsbG8=` has the type, the word `base64` and the Base64 text. It saves a request for small pictures but makes the page bigger by a third, so it is for tiny files only.

> [!NOTE] Base64 and hexadecimal are **encodings, not encryption**: anyone can decode them. Do not use them to hide a password (the tutorial [Hashing and encryption](tut-08-security.html)).

## What you learned

- Base64 and its padding and size,
- the URL-safe form,
- hexadecimal with `ToHexString` and `FromHexString`,
- the error of wrong input,
- data URIs.

## Exercises

1. Write `toBase64Url(bytes)` and `fromBase64Url(text)` as one function each.
2. Encode a small PNG file and make a data URI of it (`data:image/png;base64,...`).
3. Write a hex dump that prints 16 bytes per line with the offset (the tutorial [Binary files](tut-45-binary.html) has one).
4. Compare the lengths of Base64 and hexadecimal for 1000 bytes.

## Next

[International domain names](tut-117-domain-names.html)
