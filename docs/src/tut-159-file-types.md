---
title: "What kind of file is it?"
lead: The name of a file is only a habit. Many formats start with a few fixed bytes, the magic number, and a program that wants to know what a file really is reads the first bytes. This lesson builds a signature table, tells text from binary data, finds names that tell a lie, and shows why an upload check must not trust the name.
---

## What you will learn

- **magic numbers**: the first bytes of PNG, GIF, JPEG, ZIP, GZip, PDF and Windows programs,
- reading the **first n bytes** of a file into a byte buffer,
- a **signature table** and the function that uses it,
- telling **text** from **binary** data,
- comparing what the **name** says with what the **bytes** say,
- why an upload check needs the bytes.

## The program

{{file:samples/UsingDotNet/tutorials/ch05_file_types.ring}}

{{output:samples/UsingDotNet/tutorials/ch05_file_types.ring}}

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnBuffer`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### The first bytes

A PNG picture always starts with the bytes `137 80 78 71 13 10 26 10` (the second to the fourth are the letters `PNG`), a GIF with `GIF8`, a JPEG with `255 216 255`, a ZIP file with `PK` and the codes 3 and 4, a GZip file with `31 139`, a PDF with `%PDF-` and a Windows program with `MZ`. `firstBytes` opens the file with a `FileStream`, reads up to 16 bytes into a byte buffer and returns them as a Ring text; it does not read the rest of the file, so it is fast for any size. A file that is shorter than 16 bytes gives fewer bytes, and an empty file gives none.

### The table

`aSignatures` is a Ring list of `[name, mime type, start bytes]`. `detect` compares the start of the file with each entry (`left(cStart, len(signature)) = signature`) and returns the first match. The table is **data**: a new format is a new line. The MIME types are the ones of the tutorial [MIME types](tut-121-mime-types.html), and a web server could send them in the `Content-Type` header.

### Text or binary

A file that matches no signature is either **text** or *unknown binary data*. The check is: no NUL byte, no control character except tab and the line ends, and valid UTF-8 (the strict decoder of the tutorial [Text files and encodings](tut-132-text-encodings.html)). The program looks only at the first bytes, so a file that is text at the start and binary later is called text; for a real decision look at more bytes.

### The name tells a lie

The extension is just part of the name. After the program renamed the PNG to `notes.txt` and the text to `photo2.jpg`, `checkName` compares the type that the extension promises with the type that the bytes show, and says *THE NAME SAYS text BUT THE BYTES SAY PNG picture*. The same file with the right name says that the name fits.

### Why this is a security matter

A web site that lets users upload pictures must not trust the file name or the type that the browser sends, because the sender chooses both. `isPicture` looks at the bytes: `notes.txt` is accepted as a picture (it is one), `program.exe` is refused although a user could have named it `photo.png`. This is only the **first** check: somebody can put a PNG header in front of other data, so a real service opens the picture with an image library and refuses what it cannot read, and it stores the uploaded file under a name that it makes itself, never under the sender's name or in a folder where files are run.

> [!NOTE] The program writes only the first bytes of each sample file (and filler after them), which is all that the detection reads. Real files of these formats have more structure after the signature.

## What you learned

- the first bytes of common formats,
- reading the start of a file into a buffer,
- a signature table and text or binary,
- names that tell a lie and the upload check.

## Exercises

1. Add the signatures of `BMP` (`BM`), `RAR` and `7z` (look up their first bytes).
2. Make `detectAll(folder)` that prints the type of every file of a folder and lists the files whose name does not fit.
3. Detect a text file with a **byte order mark** and tell UTF-8 from UTF-16 (the tutorial [Text files and encodings](tut-132-text-encodings.html)).
4. Read the first 4 bytes of a ZIP file made by `ZipFile.CreateFromDirectory` and check `PK`.

## Next

[Compression](tut-88-compression.html)
